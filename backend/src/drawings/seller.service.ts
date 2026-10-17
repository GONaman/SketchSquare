import { HttpStatus, Injectable } from '@nestjs/common';
import { DrawingStatus, Prisma, Role } from '@prisma/client';
import { ApiException } from '../common/errors/api-exception';
import { decodeCursor, Page, toPage } from '../common/pagination';
import { PrismaService } from '../prisma/prisma.service';
import { StorageService } from '../storage/storage.service';
import { toDrawingSummary } from './drawing.mapper';
import { MyDrawingsQueryDto } from './dto/my-drawings-query.dto';
import { DRAWING_INCLUDE } from './drawings.service';

const VIEWER_WINDOW_DAYS = 30;
// TIMESTAMP(3) rendered as fixed-width ISO text sorts chronologically and sidesteps timezone casts in keyset cursors.
const TS = 'YYYY-MM-DD"T"HH24:MI:SS.MS';

interface TimeCursor extends Record<string, unknown> {
  at: string;
  id: string;
}

interface PersonRow {
  at: string;
  id: string;
  userId: string;
  pricePaise: number | null;
}

export interface PersonSummary {
  id: string;
  fullName: string;
  city: string;
}

export interface ReviewItem {
  id: string;
  rating: number;
  comment: string | null;
  reviewer: { id: string; fullName: string };
  createdAt: Date;
  updatedAt: Date;
}

const badCursor = () =>
  new ApiException(
    HttpStatus.BAD_REQUEST,
    'VALIDATION_ERROR',
    'Invalid cursor',
  );

function timeCursor(cursor: string | undefined): TimeCursor | null {
  const c = decodeCursor<TimeCursor>(cursor);
  if (!c) return null;
  if (
    typeof c.at !== 'string' ||
    typeof c.id !== 'string' ||
    Number.isNaN(new Date(c.at).getTime())
  ) {
    throw badCursor();
  }
  return c;
}

@Injectable()
export class SellerService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly storage: StorageService,
  ) {}

  private readonly previewUrl = (key: string | null | undefined) =>
    this.storage.previewUrl(key);

  /** The caller's own drawings (any status except REMOVED unless asked for) with per-drawing stats. */
  async listMine(userId: string, query: MyDrawingsQueryDto) {
    const cursor = timeCursor(query.cursor);
    const where: Prisma.DrawingWhereInput = {
      architectId: userId,
      status: query.status ?? { not: DrawingStatus.REMOVED },
    };
    if (cursor) {
      const at = new Date(cursor.at);
      where.OR = [
        { createdAt: { lt: at } },
        { createdAt: at, id: { lt: cursor.id } },
      ];
    }
    const rows = await this.prisma.drawing.findMany({
      where,
      include: DRAWING_INCLUDE,
      orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
      take: query.limit + 1,
    });
    const page = toPage(rows, query.limit, (d) => ({
      at: d.createdAt.toISOString(),
      id: d.id,
    }));
    return {
      items: page.items.map((d) => ({
        drawing: toDrawingSummary(d, this.previewUrl),
        stats: {
          viewCount: d.viewCount,
          purchaseCount: d.purchaseCount,
          avgRating: d.avgRating,
          ratingCount: d.ratingCount,
        },
      })),
      nextCursor: page.nextCursor,
    };
  }

  /** Owner-only (also for REMOVED drawings, so sellers keep their history). Missing → 404, someone else's → 403. */
  private async assertOwner(drawingId: string, userId: string): Promise<void> {
    const drawing = await this.prisma.drawing.findUnique({
      where: { id: drawingId },
      select: { architectId: true },
    });
    if (!drawing) {
      throw new ApiException(
        HttpStatus.NOT_FOUND,
        'NOT_FOUND',
        'Drawing not found',
      );
    }
    if (drawing.architectId !== userId) {
      throw new ApiException(
        HttpStatus.FORBIDDEN,
        'FORBIDDEN',
        'You do not own this drawing',
      );
    }
  }

  private async people(ids: string[]): Promise<Map<string, PersonSummary>> {
    const users = await this.prisma.user.findMany({
      where: { id: { in: ids } },
      select: { id: true, fullName: true, city: true },
    });
    return new Map(users.map((u) => [u.id, u]));
  }

  /** PAID purchases plus free claims, newest first. */
  async buyers(
    userId: string,
    drawingId: string,
    query: { cursor?: string; limit: number },
  ) {
    await this.assertOwner(drawingId, userId);
    const c = timeCursor(query.cursor);
    const after = c
      ? Prisma.sql`WHERE ("at", "id") < (${c.at}, ${c.id})`
      : Prisma.empty;
    const rows = await this.prisma.$queryRaw<PersonRow[]>`
      SELECT * FROM (
        SELECT to_char(COALESCE(p."paidAt", p."createdAt"), ${TS}) AS "at",
               p."id"::text AS "id", p."buyerId"::text AS "userId", p."pricePaise"
        FROM "Purchase" p WHERE p."drawingId" = ${drawingId}::uuid AND p."status" = 'PAID'
        UNION ALL
        SELECT to_char(f."createdAt", ${TS}), 'free-' || f."userId"::text, f."userId"::text, 0
        FROM "FreeDownload" f WHERE f."drawingId" = ${drawingId}::uuid
      ) b
      ${after}
      ORDER BY "at" DESC, "id" DESC
      LIMIT ${query.limit + 1}`;
    const page = toPage(rows, query.limit, (r) => ({ at: r.at, id: r.id }));
    const users = await this.people(page.items.map((r) => r.userId));
    return {
      items: page.items.flatMap((r) => {
        const buyer = users.get(r.userId);
        return buyer
          ? [
              {
                buyer,
                pricePaise: r.pricePaise ?? 0,
                purchasedAt: new Date(`${r.at}Z`),
              },
            ]
          : [];
      }),
      nextCursor: page.nextCursor,
    };
  }

  /** Distinct viewers in the last 30 days with their latest view, newest first. */
  async viewers(
    userId: string,
    drawingId: string,
    query: { cursor?: string; limit: number },
  ) {
    await this.assertOwner(drawingId, userId);
    const c = timeCursor(query.cursor);
    const after = c
      ? Prisma.sql`WHERE ("at", "id") < (${c.at}, ${c.id})`
      : Prisma.empty;
    const rows = await this.prisma.$queryRaw<PersonRow[]>`
      SELECT * FROM (
        SELECT to_char(MAX(v."viewedAt"), ${TS}) AS "at",
               v."viewerId"::text AS "id", v."viewerId"::text AS "userId", NULL::int AS "pricePaise"
        FROM "DrawingView" v
        WHERE v."drawingId" = ${drawingId}::uuid
          AND v."viewedAt" >= now() - make_interval(days => ${VIEWER_WINDOW_DAYS}::int)
        GROUP BY v."viewerId"
      ) w
      ${after}
      ORDER BY "at" DESC, "id" DESC
      LIMIT ${query.limit + 1}`;
    const page = toPage(rows, query.limit, (r) => ({ at: r.at, id: r.id }));
    const users = await this.people(page.items.map((r) => r.userId));
    return {
      items: page.items.flatMap((r) => {
        const viewer = users.get(r.userId);
        return viewer ? [{ viewer, lastViewedAt: new Date(`${r.at}Z`) }] : [];
      }),
      nextCursor: page.nextCursor,
    };
  }

  /** Reviews of a drawing, newest first. Only published drawings are readable by others; owners/admins see any. */
  async reviews(
    viewer: { id: string; role: Role },
    drawingId: string,
    query: { cursor?: string; limit: number },
  ): Promise<Page<ReviewItem>> {
    const drawing = await this.prisma.drawing.findUnique({
      where: { id: drawingId },
      select: { architectId: true, status: true },
    });
    const privileged =
      drawing !== null &&
      (drawing.architectId === viewer.id || viewer.role === Role.ADMIN);
    if (
      !drawing ||
      (drawing.status !== DrawingStatus.PUBLISHED && !privileged)
    ) {
      throw new ApiException(
        HttpStatus.NOT_FOUND,
        'NOT_FOUND',
        'Drawing not found',
      );
    }
    const cursor = timeCursor(query.cursor);
    const where: Prisma.ReviewWhereInput = { drawingId };
    if (cursor) {
      const at = new Date(cursor.at);
      where.OR = [
        { createdAt: { lt: at } },
        { createdAt: at, id: { lt: cursor.id } },
      ];
    }
    const rows = await this.prisma.review.findMany({
      where,
      include: { buyer: { select: { id: true, fullName: true } } },
      orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
      take: query.limit + 1,
    });
    const page = toPage(rows, query.limit, (r) => ({
      at: r.createdAt.toISOString(),
      id: r.id,
    }));
    return {
      items: page.items.map((r) => ({
        id: r.id,
        rating: r.rating,
        comment: r.comment,
        reviewer: r.buyer,
        createdAt: r.createdAt,
        updatedAt: r.updatedAt,
      })),
      nextCursor: page.nextCursor,
    };
  }
}
