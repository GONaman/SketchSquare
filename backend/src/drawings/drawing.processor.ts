import { OnWorkerEvent, Processor, WorkerHost } from '@nestjs/bullmq';
import { Logger } from '@nestjs/common';
import type { Job } from 'bullmq';
import { DrawingProcessingService } from './drawing-processing.service';
import {
  DRAWING_PROCESSING_QUEUE,
  PROCESSING_ATTEMPTS,
  ProcessDrawingJob,
} from './drawings.constants';

@Processor(DRAWING_PROCESSING_QUEUE, { concurrency: 2 })
export class DrawingProcessor extends WorkerHost {
  private readonly logger = new Logger(DrawingProcessor.name);

  constructor(private readonly processing: DrawingProcessingService) {
    super();
  }

  async process(job: Job<ProcessDrawingJob>): Promise<string> {
    return this.processing.process(job.data.drawingId);
  }

  @OnWorkerEvent('failed')
  async onFailed(
    job: Job<ProcessDrawingJob> | undefined,
    error: Error,
  ): Promise<void> {
    if (!job) return;
    const attempts = job.opts.attempts ?? PROCESSING_ATTEMPTS;
    this.logger.warn(
      `Job ${job.id} attempt ${job.attemptsMade}/${attempts} failed: ${error.message}`,
    );
    if (job.attemptsMade >= attempts) {
      await this.processing.markFailed(job.data.drawingId, error);
    }
  }
}
