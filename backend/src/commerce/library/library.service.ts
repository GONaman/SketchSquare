import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Prisma } from '@prisma/client';
import { decodeCursor, Page, toPage } from '../../common/pagination';
import { Env } from '../../config/env.schema';
import { PrismaService } from '../../prisma/prisma.service';
import {
  DrawingSummaryView,
  drawingWithSheetsInclude,
  SheetView,
  toDrawingSummary,
  toSheetViews,
} from '../shared/drawing.mapper';

export interface LibraryItem {
  kind: 'PAID' | 'FREE';
  purchasedAt: Date;
  pricePaise: number;
  purchaseId: string | null;
  drawing: DrawingSummaryView & { sheets: SheetView[] };
}

interface LibraryRow {
  kind: 'PAID' | 'FREE';
  at: string;
  drawingId: string;
  pricePaise: number;
  purchaseId: string | null;
}

interface LibraryCursor extends Record<string, unknown> {
  at: string;
  drawingId: string;
  kind: string;
}

/** Everything the user may download again: PAID purchases plus free claims, newest first. */
@Injectable()
export class LibraryService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly config: ConfigService<Env, true>,
  ) {}

  async list(
    userId: string,
    cursor: string | undefined,
    limit: number,
  ): Promise<Page<LibraryItem>> {
    const c = decodeCursor<LibraryCursor>(cursor);
    // Timestamps are TIMESTAMP(3); fixed-width ISO text sorts chronologically and avoids any timezone cast.
    const after = c
      ? Prisma.sql`WHERE ("at", "drawingId", "kind") < (${String(c.at)}, ${String(c.drawingId)}::uuid, ${String(c.kind)})`
      : Prisma.empty;
    const rows = await this.prisma.$queryRaw<LibraryRow[]>`
      SELECT * FROM (
        SELECT 'PAID' AS "kind",
               to_char(COALESCE(p."paidAt", p."createdAt"), 'YYYY-MM-DD"T"HH24:MI:SS.MS') AS "at",
               p."drawingId", p."pricePaise", p."id"::text AS "purchaseId"
        FROM "Purchase" p WHERE p."buyerId" = ${userId}::uuid AND p."status" = 'PAID'
        UNION ALL
        SELECT 'FREE', to_char(f."createdAt", 'YYYY-MM-DD"T"HH24:MI:SS.MS'), f."drawingId", 0, NULL
        FROM "FreeDownload" f WHERE f."userId" = ${userId}::uuid
      ) lib
      ${after}
      ORDER BY "at" DESC, "drawingId" DESC, "kind" DESC
      LIMIT ${limit + 1}`;

    const page = toPage(rows, limit, (r) => ({
      at: r.at,
      drawingId: r.drawingId,
      kind: r.kind,
    }));
    const drawings = await this.prisma.drawing.findMany({
      where: { id: { in: page.items.map((r) => r.drawingId) } },
      include: drawingWithSheetsInclude,
    });
    const byId = new Map(drawings.map((d) => [d.id, d]));
    const base = this.config.get('S3_PREVIEWS_PUBLIC_URL', { infer: true });

    const items: LibraryItem[] = [];
    for (const r of page.items) {
      const d = byId.get(r.drawingId);
      if (!d) continue;
      items.push({
        kind: r.kind,
        purchasedAt: new Date(`${r.at}Z`),
        pricePaise: r.pricePaise,
        purchaseId: r.purchaseId,
        drawing: {
          ...toDrawingSummary(d, base),
          sheets: toSheetViews(d.sheets, base),
        },
      });
    }
    return { items, nextCursor: page.nextCursor };
  }
}
