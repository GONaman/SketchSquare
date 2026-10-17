import { HttpStatus, Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Prisma } from '@prisma/client';
import type { AuthUser } from '../common/decorators/current-user.decorator';
import { ApiException } from '../common/errors/api-exception';
import { Page, PageQueryDto, decodeCursor, toPage } from '../common/pagination';
import { Env } from '../config/env.schema';
import { PrismaService } from '../prisma/prisma.service';
import { StorageService } from '../storage/storage.service';
import {
  DRAWING_SUMMARY_SELECT,
  DrawingSummary,
  toDrawingSummary,
} from './drawing-summary';

export const DETAIL_REVIEWS_PAGE = 10;
export const VIEW_DEDUPE_HOURS = 24;

export interface SheetView {
  id: string;
  type: string;
  isPreview: boolean;
  previewUrl: string | null;
  originalMime: string;
  fileName: string;
  sizeBytes: number;
}

export interface ReviewView {
  id: string;
  rating: number;
  comment: string | null;
  reviewer: { id: string; fullName: string };
  createdAt: Date;
  updatedAt: Date;
}

export interface ViewerFlags {
  isOwner: boolean;
  isPurchased: boolean;
  inCart: boolean;
  canDownload: boolean;
  freeDownloadsRemaining: number | null;
  myReview: ReviewView | null;
}

export type DrawingDetail = DrawingSummary & {
  description: string;
  bedrooms: number | null;
  tags: string[];
  viewCount: number;
  purchaseCount: number;
  failureReason: string | null;
  sheets: SheetView[];
  reviews: Page<ReviewView>;
  viewer: ViewerFlags;
};

const REVIEW_SELECT = {
  id: true,
  rating: true,
  comment: true,
  createdAt: true,
  updatedAt: true,
  buyer: { select: { id: true, fullName: true } },
} satisfies Prisma.ReviewSelect;

type ReviewRow = Prisma.ReviewGetPayload<{ select: typeof REVIEW_SELECT }>;

export const toReviewView = (r: ReviewRow): ReviewView => ({
  id: r.id,
  rating: r.rating,
  comment: r.comment,
  reviewer: { id: r.buyer.id, fullName: r.buyer.fullName },
  createdAt: r.createdAt,
  updatedAt: r.updatedAt,
});

const notFound = () =>
  new ApiException(HttpStatus.NOT_FOUND, 'NOT_FOUND', 'Drawing not found');

const isSearchable = (d: {
  status: string;
  architect: { verificationStatus: string };
}) => d.status === 'PUBLISHED' && d.architect.verificationStatus === 'APPROVED';

@Injectable()
export class DrawingDetailService {
  private readonly logger = new Logger(DrawingDetailService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly storage: StorageService,
    private readonly config: ConfigService<Env, true>,
  ) {}

  /**
   * Published drawings are visible to every approved user. Any other status (draft, processing, failed, removed…)
   * is visible only to the owner and admins, and 404s for everyone else so existence is not leaked.
   */
  async get(viewer: AuthUser, id: string): Promise<DrawingDetail> {
    const d = await this.prisma.drawing.findUnique({
      where: { id },
      select: {
        ...DRAWING_SUMMARY_SELECT,
        architectId: true,
        description: true,
        bedrooms: true,
        tags: true,
        viewCount: true,
        purchaseCount: true,
        failureReason: true,
        architect: {
          select: {
            ...DRAWING_SUMMARY_SELECT.architect.select,
            verificationStatus: true,
          },
        },
        // Replaces the summary's single-cover select: sheet metadata only, never original keys.
        sheets: {
          orderBy: [{ createdAt: 'asc' }, { id: 'asc' }],
          select: {
            id: true,
            type: true,
            isPreview: true,
            previewKey: true,
            originalMime: true,
            fileName: true,
            sizeBytes: true,
          },
        },
      },
    });

    const isOwner = d?.architectId === viewer.id;
    const isAdmin = viewer.role === 'ADMIN';
    const searchable = d ? isSearchable(d) : false;
    if (!d || !(searchable || isOwner || isAdmin)) throw notFound();
    const privileged = isOwner || isAdmin;

    const viewCount =
      !isOwner && !isAdmin && searchable
        ? await this.recordView(d.id, viewer.id, d.viewCount)
        : d.viewCount;

    const cover = d.sheets.find((s) => s.isPreview && s.previewKey);
    const summary = toDrawingSummary(
      { ...d, sheets: cover ? [{ previewKey: cover.previewKey }] : [] },
      (key) => this.storage.previewUrl(key),
    );

    const [reviews, flags] = await Promise.all([
      this.reviewsPage(d.id, DETAIL_REVIEWS_PAGE),
      this.viewerFlags(viewer, d, isOwner),
    ]);

    return {
      ...summary,
      description: d.description,
      bedrooms: d.bedrooms,
      tags: d.tags,
      viewCount,
      purchaseCount: d.purchaseCount,
      failureReason: privileged ? d.failureReason : null,
      sheets: d.sheets.map((s) => ({
        id: s.id,
        type: s.type,
        isPreview: s.isPreview,
        previewUrl: s.isPreview ? this.storage.previewUrl(s.previewKey) : null,
        originalMime: s.originalMime,
        fileName: s.fileName,
        sizeBytes: s.sizeBytes,
      })),
      reviews,
      viewer: flags,
    };
  }

  /** Same visibility rule as the detail itself. */
  async listReviews(
    viewer: AuthUser,
    id: string,
    page: PageQueryDto,
  ): Promise<Page<ReviewView>> {
    const d = await this.prisma.drawing.findUnique({
      where: { id },
      select: {
        status: true,
        architectId: true,
        architect: { select: { verificationStatus: true } },
      },
    });
    if (
      !d ||
      !(
        isSearchable(d) ||
        d.architectId === viewer.id ||
        viewer.role === 'ADMIN'
      )
    ) {
      throw notFound();
    }
    return this.reviewsPage(id, page.limit, page.cursor);
  }

  /** Newest first; keyset on (createdAt, id). Shared by the detail's first page and the paging endpoint. */
  async reviewsPage(
    drawingId: string,
    limit: number,
    cursor?: string,
  ): Promise<Page<ReviewView>> {
    const c = decodeCursor<{ t: string; id: string }>(cursor);
    const at = c ? new Date(c.t) : null;
    if (c && (!c.id || !at || Number.isNaN(at.getTime()))) {
      throw new ApiException(
        HttpStatus.BAD_REQUEST,
        'VALIDATION_ERROR',
        'Invalid cursor',
      );
    }
    const rows = await this.prisma.review.findMany({
      where: {
        drawingId,
        ...(c && at
          ? {
              OR: [
                { createdAt: { lt: at } },
                { createdAt: at, id: { lt: c.id } },
              ],
            }
          : {}),
      },
      orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
      take: limit + 1,
      select: REVIEW_SELECT,
    });
    const page = toPage(rows, limit, (r) => ({
      t: r.createdAt.toISOString(),
      id: r.id,
    }));
    return { items: page.items.map(toReviewView), nextCursor: page.nextCursor };
  }

  private async viewerFlags(
    viewer: AuthUser,
    d: { id: string; pricePaise: number; status: string },
    isOwner: boolean,
  ): Promise<ViewerFlags> {
    const [purchase, inCart, claim, me, myReview] = await Promise.all([
      this.prisma.purchase.findFirst({
        where: { buyerId: viewer.id, drawingId: d.id, status: 'PAID' },
        select: { id: true },
      }),
      this.prisma.cartItem.findUnique({
        where: { userId_drawingId: { userId: viewer.id, drawingId: d.id } },
        select: { userId: true },
      }),
      this.prisma.freeDownload.findUnique({
        where: { userId_drawingId: { userId: viewer.id, drawingId: d.id } },
        select: { userId: true },
      }),
      this.prisma.user.findUnique({
        where: { id: viewer.id },
        select: { freeDownloadsUsed: true },
      }),
      this.prisma.review.findUnique({
        where: {
          buyerId_drawingId: { buyerId: viewer.id, drawingId: d.id },
        },
        select: REVIEW_SELECT,
      }),
    ]);
    const isPurchased = purchase !== null;
    const isFree = d.pricePaise === 0;
    const limit = this.config.get('FREE_DOWNLOAD_LIMIT', { infer: true });
    const remaining = Math.max(0, limit - (me?.freeDownloadsUsed ?? 0));
    const canClaimFree = isFree && d.status === 'PUBLISHED' && remaining > 0;
    return {
      isOwner,
      isPurchased,
      inCart: inCart !== null,
      canDownload:
        isOwner || isPurchased || (isFree && (claim !== null || canClaimFree)),
      freeDownloadsRemaining: isFree && !isOwner ? remaining : null,
      myReview: myReview ? toReviewView(myReview) : null,
    };
  }

  /**
   * One DrawingView per (viewer, drawing) per 24 h. The advisory lock serialises concurrent opens by the same
   * viewer so the check-then-insert cannot double count. Never fails the request: analytics must not break reads.
   */
  private async recordView(
    drawingId: string,
    viewerId: string,
    current: number,
  ): Promise<number> {
    try {
      return await this.prisma.$transaction(async (tx) => {
        await tx.$executeRaw`SELECT pg_advisory_xact_lock(hashtext(${drawingId}), hashtext(${viewerId}))`;
        const since = new Date(Date.now() - VIEW_DEDUPE_HOURS * 3_600_000);
        const seen = await tx.drawingView.findFirst({
          where: { drawingId, viewerId, viewedAt: { gt: since } },
          select: { id: true },
        });
        if (seen) return current;
        await tx.drawingView.create({ data: { drawingId, viewerId } });
        const updated = await tx.drawing.update({
          where: { id: drawingId },
          data: { viewCount: { increment: 1 } },
          select: { viewCount: true },
        });
        return updated.viewCount;
      });
    } catch (err) {
      this.logger.warn(
        `Could not record view of ${drawingId}: ${err instanceof Error ? err.message : String(err)}`,
      );
      return current;
    }
  }
}
