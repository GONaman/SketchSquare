import { Injectable, Logger } from '@nestjs/common';
import { DrawingStatus } from '@prisma/client';
import { randomBytes } from 'node:crypto';
import { MailService } from '../mail/mail.service';
import { PlagiarismCheckService } from '../plagiarism/plagiarism-check.service';
import { PrismaService } from '../prisma/prisma.service';
import { StorageService } from '../storage/storage.service';
import { perceptualHash } from '../watermark/phash';
import { MIME_PDF, WatermarkService } from '../watermark/watermark.service';

const FAILURE_REASON_MAX = 500;

export type ProcessingOutcome =
  'published' | 'under_review' | 'blocked' | 'skipped';

/**
 * Turns the preview sheets of a PROCESSING drawing into watermarked public previews + perceptual hashes, runs the
 * plagiarism checks (exact SHA-256 duplicate → FAILED; similar preview → UNDER_REVIEW + PlagiarismFlag), and otherwise
 * flips the drawing to PUBLISHED. Only watermarked renders are ever written to the previews bucket.
 */
@Injectable()
export class DrawingProcessingService {
  private readonly logger = new Logger(DrawingProcessingService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly storage: StorageService,
    private readonly watermark: WatermarkService,
    private readonly plagiarism: PlagiarismCheckService,
    private readonly mail: MailService,
  ) {}

  /** Idempotent: does nothing unless the drawing is still PROCESSING (removed/republished drawings are left alone). */
  async process(drawingId: string): Promise<ProcessingOutcome> {
    const drawing = await this.prisma.drawing.findUnique({
      where: { id: drawingId },
      include: {
        sheets: true,
        architect: { select: { fullName: true, email: true } },
      },
    });
    if (drawing?.status !== DrawingStatus.PROCESSING) return 'skipped';

    const previews = drawing.sheets.filter((s) => s.isPreview);
    if (previews.length === 0) throw new Error('No preview sheets to process');

    const duplicate = await this.plagiarism.findExactDuplicate(
      drawing,
      drawing.sheets,
    );
    if (duplicate) {
      const reason = `"${duplicate.fileName}" is identical to a file already published on SketchSquare by another architect. Only original work can be published.`;
      const res = await this.prisma.drawing.updateMany({
        where: { id: drawingId, status: DrawingStatus.PROCESSING },
        data: { status: DrawingStatus.FAILED, failureReason: reason },
      });
      if (res.count > 0) {
        this.logger.warn(`Drawing ${drawingId} blocked: exact duplicate file`);
      }
      return res.count > 0 ? 'blocked' : 'skipped';
    }

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

    const matches = await this.plagiarism.findSimilarPreviews(
      drawing,
      rendered.map((r) => ({ sheetId: r.id, pHash: r.pHash })),
    );
    const underReview = matches.length > 0;

    const applied = await this.prisma.$transaction(async (tx) => {
      const flipped = await tx.drawing.updateMany({
        where: { id: drawingId, status: DrawingStatus.PROCESSING },
        data: {
          status: underReview
            ? DrawingStatus.UNDER_REVIEW
            : DrawingStatus.PUBLISHED,
          failureReason: null,
        },
      });
      if (flipped.count === 0) return false;
      for (const r of rendered) {
        await tx.drawingSheet.update({
          where: { id: r.id },
          data: { previewKey: r.previewKey, pHash: r.pHash },
        });
      }
      if (underReview) {
        await tx.plagiarismFlag.createMany({
          data: matches.map((m) => ({ drawingId, ...m })),
        });
      }
      return true;
    });
    if (!applied) return 'skipped';
    if (underReview) {
      this.logger.warn(
        `Drawing ${drawingId} held for review: ${matches.length} similar drawing(s)`,
      );
      await this.mail
        .sendDrawingUnderReview(
          drawing.architect.email,
          drawing.architect.fullName,
          drawing.title,
        )
        .catch((err: unknown) =>
          this.logger.error(`Under-review email not queued: ${String(err)}`),
        );
      return 'under_review';
    }
    return 'published';
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
