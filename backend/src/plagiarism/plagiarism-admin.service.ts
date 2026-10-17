import { HttpStatus, Injectable, Logger } from '@nestjs/common';
import { DrawingStatus, PlagiarismFlagStatus, Prisma } from '@prisma/client';
import { decodeCursor, Page, toPage } from '../common/pagination';
import { ApiException } from '../common/errors/api-exception';
import {
  DrawingWithRelations,
  toDrawingSummary,
  toSheetResponse,
} from '../drawings/drawing.mapper';
import { MailService } from '../mail/mail.service';
import { PrismaService } from '../prisma/prisma.service';
import { StorageService } from '../storage/storage.service';

const DRAWING_INCLUDE = {
  category: true,
  architect: true,
  sheets: true,
} satisfies Prisma.DrawingInclude;

const FLAG_INCLUDE = {
  drawing: { include: DRAWING_INCLUDE },
  matchedDrawing: { include: DRAWING_INCLUDE },
  sheet: true,
  matchedSheet: true,
} satisfies Prisma.PlagiarismFlagInclude;

type FlagRow = Prisma.PlagiarismFlagGetPayload<{
  include: typeof FLAG_INCLUDE;
}>;

const notFound = () =>
  new ApiException(
    HttpStatus.NOT_FOUND,
    'NOT_FOUND',
    'Plagiarism flag not found',
  );
const conflict = (message: string) =>
  new ApiException(HttpStatus.CONFLICT, 'CONFLICT', message);

@Injectable()
export class PlagiarismAdminService {
  private readonly logger = new Logger(PlagiarismAdminService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly storage: StorageService,
    private readonly mail: MailService,
  ) {}

  private readonly previewUrl = (key: string | null | undefined) =>
    this.storage.previewUrl(key);

  private toDrawingView(d: DrawingWithRelations) {
    return {
      ...toDrawingSummary(d, this.previewUrl),
      description: d.description,
      sheets: [...d.sheets]
        .filter((s) => s.isPreview)
        .sort((a, b) => a.createdAt.getTime() - b.createdAt.getTime())
        .map((s) => toSheetResponse(s, this.previewUrl)),
    };
  }

  private toItem(f: FlagRow) {
    return {
      id: f.id,
      status: f.status,
      hammingDistance: f.hammingDistance,
      reviewNote: f.reviewNote,
      reviewedAt: f.reviewedAt,
      createdAt: f.createdAt,
      drawing: this.toDrawingView(f.drawing),
      matchedDrawing: this.toDrawingView(f.matchedDrawing),
      flaggedSheet: {
        id: f.sheet.id,
        previewUrl: this.previewUrl(f.sheet.previewKey),
      },
      matchedSheet: {
        id: f.matchedSheet.id,
        previewUrl: this.previewUrl(f.matchedSheet.previewKey),
      },
    };
  }

  /** Oldest first. PENDING only lists flags whose drawing is still UNDER_REVIEW (the owner may have deleted it meanwhile). */
  async list(
    status: PlagiarismFlagStatus,
    cursor: string | undefined,
    limit: number,
  ): Promise<Page<ReturnType<PlagiarismAdminService['toItem']>>> {
    const after = decodeCursor<{ at: string; id: string }>(cursor);
    const rows = await this.prisma.plagiarismFlag.findMany({
      where: {
        status,
        ...(status === PlagiarismFlagStatus.PENDING && {
          drawing: { status: DrawingStatus.UNDER_REVIEW },
        }),
        ...(after && {
          OR: [
            { createdAt: { gt: new Date(after.at) } },
            { createdAt: new Date(after.at), id: { gt: after.id } },
          ],
        }),
      },
      include: FLAG_INCLUDE,
      orderBy: [{ createdAt: 'asc' }, { id: 'asc' }],
      take: limit + 1,
    });
    const page = toPage(rows, limit, (last) => ({
      at: last.createdAt.toISOString(),
      id: last.id,
    }));
    return { ...page, items: page.items.map((f) => this.toItem(f)) };
  }

  approve(flagId: string, adminId: string): Promise<{ ok: true }> {
    return this.decide(flagId, adminId, 'APPROVED');
  }

  reject(
    flagId: string,
    adminId: string,
    reason: string,
  ): Promise<{ ok: true }> {
    return this.decide(flagId, adminId, 'REJECTED', reason);
  }

  /** The decision is about the drawing: it resolves every PENDING flag of that drawing at once. */
  private async decide(
    flagId: string,
    adminId: string,
    decision: 'APPROVED' | 'REJECTED',
    reason?: string,
  ): Promise<{ ok: true }> {
    const flag = await this.prisma.plagiarismFlag.findUnique({
      where: { id: flagId },
      select: {
        id: true,
        status: true,
        drawingId: true,
        matchedDrawingId: true,
        drawing: {
          select: {
            title: true,
            architect: { select: { email: true, fullName: true } },
          },
        },
      },
    });
    if (!flag) throw notFound();
    if (flag.status !== PlagiarismFlagStatus.PENDING) {
      throw conflict('This flag has already been decided');
    }

    const approved = decision === 'APPROVED';
    await this.prisma.$transaction(async (tx) => {
      const moved = await tx.drawing.updateMany({
        where: { id: flag.drawingId, status: DrawingStatus.UNDER_REVIEW },
        data: approved
          ? { status: DrawingStatus.PUBLISHED, failureReason: null }
          : { status: DrawingStatus.REMOVED, failureReason: reason },
      });
      if (moved.count === 0)
        throw conflict('Drawing is no longer under review');
      const resolved = await tx.plagiarismFlag.updateMany({
        where: {
          drawingId: flag.drawingId,
          status: PlagiarismFlagStatus.PENDING,
        },
        data: {
          status: decision,
          reviewNote: reason ?? null,
          reviewedById: adminId,
          reviewedAt: new Date(),
        },
      });
      if (resolved.count === 0) throw conflict('Flag was decided concurrently');
      await tx.auditLog.create({
        data: {
          actorId: adminId,
          action: `plagiarism.${approved ? 'approve' : 'reject'}`,
          entityType: 'PlagiarismFlag',
          entityId: flagId,
          metadata: {
            drawingId: flag.drawingId,
            matchedDrawingId: flag.matchedDrawingId,
            ...(reason && { reason }),
          },
        },
      });
    });

    const { title, architect } = flag.drawing;
    const send = approved
      ? this.mail.sendDrawingApproved(
          architect.email,
          architect.fullName,
          title,
        )
      : this.mail.sendDrawingRejected(
          architect.email,
          architect.fullName,
          title,
          reason ?? '',
        );
    await send.catch((err: unknown) =>
      this.logger.error(`Decision email not queued: ${String(err)}`),
    );
    return { ok: true };
  }
}
