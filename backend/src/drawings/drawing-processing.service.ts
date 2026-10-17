import { Injectable, Logger } from '@nestjs/common';
import { DrawingStatus } from '@prisma/client';
import { randomBytes } from 'node:crypto';
import { PrismaService } from '../prisma/prisma.service';
import { StorageService } from '../storage/storage.service';
import { perceptualHash } from '../watermark/phash';
import { MIME_PDF, WatermarkService } from '../watermark/watermark.service';

const FAILURE_REASON_MAX = 500;

/**
 * Turns the preview sheets of a PROCESSING drawing into watermarked public previews + perceptual hashes,
 * then flips the drawing to PUBLISHED. Only watermarked renders are ever written to the previews bucket.
 */
@Injectable()
export class DrawingProcessingService {
  private readonly logger = new Logger(DrawingProcessingService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly storage: StorageService,
    private readonly watermark: WatermarkService,
  ) {}

  /** Idempotent: does nothing unless the drawing is still PROCESSING (removed/republished drawings are left alone). */
  async process(drawingId: string): Promise<'published' | 'skipped'> {
    const drawing = await this.prisma.drawing.findUnique({
      where: { id: drawingId },
      include: { sheets: true, architect: { select: { fullName: true } } },
    });
    if (drawing?.status !== DrawingStatus.PROCESSING) return 'skipped';

    const previews = drawing.sheets.filter((s) => s.isPreview);
    if (previews.length === 0) throw new Error('No preview sheets to process');

    const rendered: { id: string; previewKey: string; pHash: string }[] = [];
    for (const sheet of previews) {
      const original = await this.storage.getOriginalBuffer(sheet.originalKey);
      const result =
        sheet.originalMime === MIME_PDF
          ? await this.watermark.renderPdfPreview(
              original,
              drawing.architect.fullName,
            )
          : await this.watermark.renderImagePreview(
              original,
              drawing.architect.fullName,
            );
      // Hash the un-watermarked render so the same plan always hashes the same regardless of who posted it (W2).
      const pHash = await perceptualHash(result.base);
      const previewKey = `drawings/${drawingId}/${sheet.id}-${randomBytes(6).toString('hex')}.png`;
      await this.storage.putPreview(previewKey, result.watermarked);
      rendered.push({ id: sheet.id, previewKey, pHash });
    }

    const published = await this.prisma.$transaction(async (tx) => {
      const flipped = await tx.drawing.updateMany({
        where: { id: drawingId, status: DrawingStatus.PROCESSING },
        data: { status: DrawingStatus.PUBLISHED, failureReason: null },
      });
      if (flipped.count === 0) return false;
      for (const r of rendered) {
        await tx.drawingSheet.update({
          where: { id: r.id },
          data: { previewKey: r.previewKey, pHash: r.pHash },
        });
      }
      return true;
    });
    return published ? 'published' : 'skipped';
  }

  /** Called once retries are exhausted. */
  async markFailed(drawingId: string, error: unknown): Promise<void> {
    const reason = (
      error instanceof Error ? error.message : String(error)
    ).slice(0, FAILURE_REASON_MAX);
    const res = await this.prisma.drawing.updateMany({
      where: { id: drawingId, status: DrawingStatus.PROCESSING },
      data: { status: DrawingStatus.FAILED, failureReason: reason },
    });
    if (res.count > 0) {
      this.logger.warn(`Drawing ${drawingId} failed processing: ${reason}`);
    }
  }
}
