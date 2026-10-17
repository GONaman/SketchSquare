import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { DrawingStatus, Prisma } from '@prisma/client';
import { Env } from '../config/env.schema';
import { PrismaService } from '../prisma/prisma.service';
import { dimensionBounds } from './similarity';

export interface PlagiarismMatch {
  /** The new drawing's preview sheet that matched. */
  sheetId: string;
  matchedSheetId: string;
  matchedDrawingId: string;
  hammingDistance: number;
}

export interface CheckedDrawing {
  id: string;
  architectId: string;
  plotLengthFt: number;
  plotBreadthFt: number;
}

/** Existing drawings a new upload is compared against; DRAFT/PROCESSING/FAILED/REMOVED ones are not "on the platform". */
const COMPARABLE_STATUSES = [
  DrawingStatus.PUBLISHED,
  DrawingStatus.UNDER_REVIEW,
];

@Injectable()
export class PlagiarismCheckService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly config: ConfigService<Env, true>,
  ) {}

  /**
   * Hard block: another architect already has a live drawing containing a byte-identical original (SHA-256).
   * Returns the name of the first offending sheet of the checked drawing.
   */
  async findExactDuplicate(
    drawing: CheckedDrawing,
    sheets: { fileName: string; sha256: string | null }[],
  ): Promise<{ fileName: string } | null> {
    const hashes = sheets.flatMap((s) => (s.sha256 ? [s.sha256] : []));
    if (hashes.length === 0) return null;
    const dup = await this.prisma.drawingSheet.findFirst({
      where: {
        sha256: { in: hashes },
        drawing: {
          architectId: { not: drawing.architectId },
          status: { in: COMPARABLE_STATUSES },
        },
      },
      select: { sha256: true },
    });
    if (!dup) return null;
    return sheets.find((s) => s.sha256 === dup.sha256) ?? null;
  }

  /**
   * Soft flag: for each new preview hash, other architects' live preview sheets on a similar plot (±tolerance,
   * incl. rotated) whose pHash is within the Hamming threshold. One match (the closest) per matched drawing.
   */
  async findSimilarPreviews(
    drawing: CheckedDrawing,
    previews: { sheetId: string; pHash: string }[],
  ): Promise<PlagiarismMatch[]> {
    const threshold = this.config.get('PLAGIARISM_PHASH_THRESHOLD', {
      infer: true,
    });
    const tolerance = this.config.get('PLAGIARISM_PLOT_TOLERANCE_PCT', {
      infer: true,
    });
    const [lMin, lMax] = dimensionBounds(drawing.plotLengthFt, tolerance);
    const [bMin, bMax] = dimensionBounds(drawing.plotBreadthFt, tolerance);

    const best = new Map<string, PlagiarismMatch>();
    for (const preview of previews) {
      // pHash is 16 hex chars = 64 bits; bit_count of the XOR is the Hamming distance.
      const rows = await this.prisma.$queryRaw<
        {
          matchedSheetId: string;
          matchedDrawingId: string;
          distance: number;
        }[]
      >(Prisma.sql`
        SELECT s."id" AS "matchedSheetId", s."drawingId" AS "matchedDrawingId",
               bit_count(('x' || s."pHash")::bit(64) # ('x' || ${preview.pHash})::bit(64))::int AS "distance"
        FROM "DrawingSheet" s
        JOIN "Drawing" d ON d."id" = s."drawingId"
        WHERE s."isPreview" AND s."pHash" IS NOT NULL
          AND d."architectId" <> ${drawing.architectId}::uuid
          AND d."status"::text IN (${Prisma.join(COMPARABLE_STATUSES)})
          AND (
            (d."plotLengthFt" BETWEEN ${lMin} AND ${lMax} AND d."plotBreadthFt" BETWEEN ${bMin} AND ${bMax})
            OR (d."plotLengthFt" BETWEEN ${bMin} AND ${bMax} AND d."plotBreadthFt" BETWEEN ${lMin} AND ${lMax})
          )
          AND bit_count(('x' || s."pHash")::bit(64) # ('x' || ${preview.pHash})::bit(64)) <= ${threshold}
        ORDER BY "distance", s."id"`);
      for (const row of rows) {
        const current = best.get(row.matchedDrawingId);
        if (!current || row.distance < current.hammingDistance) {
          best.set(row.matchedDrawingId, {
            sheetId: preview.sheetId,
            matchedSheetId: row.matchedSheetId,
            matchedDrawingId: row.matchedDrawingId,
            hammingDistance: row.distance,
          });
        }
      }
    }
    return [...best.values()].sort(
      (a, b) =>
        a.hammingDistance - b.hammingDistance ||
        a.matchedDrawingId.localeCompare(b.matchedDrawingId),
    );
  }
}
