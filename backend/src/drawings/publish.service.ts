import { InjectQueue } from '@nestjs/bullmq';
import { HttpStatus, Injectable, Logger } from '@nestjs/common';
import { DrawingStatus } from '@prisma/client';
import type { Queue } from 'bullmq';
import { ApiException } from '../common/errors/api-exception';
import { PrismaService } from '../prisma/prisma.service';
import {
  DRAWING_PROCESSING_QUEUE,
  MAX_PREVIEW_SHEETS,
  MIN_PREVIEW_SHEETS,
  PROCESS_DRAWING_JOB,
  PROCESSING_ATTEMPTS,
  ProcessDrawingJob,
} from './drawings.constants';
import { ContributionService } from './contribution.service';
import { DrawingsService } from './drawings.service';

const validation = (message: string) =>
  new ApiException(HttpStatus.BAD_REQUEST, 'VALIDATION_ERROR', message);

@Injectable()
export class PublishService {
  private readonly logger = new Logger(PublishService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly drawings: DrawingsService,
    private readonly contribution: ContributionService,
    @InjectQueue(DRAWING_PROCESSING_QUEUE)
    private readonly queue: Queue<ProcessDrawingJob>,
  ) {}

  /** DRAFT/FAILED → PROCESSING (atomically) and enqueue; publishing a PROCESSING drawing again is a no-op. */
  async publish(
    userId: string,
    drawingId: string,
  ): Promise<{ status: 'PROCESSING' }> {
    const drawing = await this.drawings.loadOwned(drawingId, userId);
    if (drawing.status === DrawingStatus.PROCESSING) {
      return { status: 'PROCESSING' };
    }
    if (
      drawing.status !== DrawingStatus.DRAFT &&
      drawing.status !== DrawingStatus.FAILED
    ) {
      throw new ApiException(
        HttpStatus.CONFLICT,
        'CONFLICT',
        'Drawing is already published',
      );
    }

    const previews = drawing.sheets.filter((s) => s.isPreview).length;
    if (drawing.sheets.length < 1) {
      throw validation('Add at least one sheet before publishing');
    }
    if (previews < MIN_PREVIEW_SHEETS || previews > MAX_PREVIEW_SHEETS) {
      throw validation(
        `Mark ${MIN_PREVIEW_SHEETS}-${MAX_PREVIEW_SHEETS} sheets as previews before publishing`,
      );
    }

    const claimed = await this.prisma.$transaction(async (tx) => {
      if (drawing.pricePaise > 0) {
        // Serialise paid publishes per architect so two concurrent requests cannot both slip past the contribution rule.
        await tx.$executeRaw`SELECT pg_advisory_xact_lock(hashtext(${userId}))`;
        await this.contribution.assertCanPublishPaid(userId, tx);
      }
      return tx.drawing.updateMany({
        where: {
          id: drawingId,
          status: { in: [DrawingStatus.DRAFT, DrawingStatus.FAILED] },
        },
        data: { status: DrawingStatus.PROCESSING, failureReason: null },
      });
    });
    if (claimed.count === 0) {
      // Lost a race: whoever won already queued the job (or the drawing moved on).
      const current = await this.prisma.drawing.findUnique({
        where: { id: drawingId },
        select: { status: true },
      });
      if (current?.status === DrawingStatus.PROCESSING) {
        return { status: 'PROCESSING' };
      }
      throw new ApiException(
        HttpStatus.CONFLICT,
        'CONFLICT',
        'Drawing cannot be published in its current state',
      );
    }

    try {
      await this.queue.add(
        PROCESS_DRAWING_JOB,
        { drawingId },
        {
          // BullMQ rejects ':' in custom ids; the timestamp lets a FAILED drawing be re-published.
          jobId: `publish_${drawingId}_${Date.now()}`,
          attempts: PROCESSING_ATTEMPTS,
          backoff: { type: 'exponential', delay: 2000 },
        },
      );
    } catch (err) {
      this.logger.error(
        `Could not enqueue drawing ${drawingId}: ${String(err)}`,
      );
      await this.prisma.drawing.updateMany({
        where: { id: drawingId, status: DrawingStatus.PROCESSING },
        data: { status: drawing.status },
      });
      throw new ApiException(
        HttpStatus.INTERNAL_SERVER_ERROR,
        'INTERNAL',
        'Could not start processing, please retry',
      );
    }
    return { status: 'PROCESSING' };
  }
}
