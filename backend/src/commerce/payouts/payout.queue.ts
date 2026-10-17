import { Inject, Injectable } from '@nestjs/common';
import { InjectQueue } from '@nestjs/bullmq';
import { ConfigService } from '@nestjs/config';
import { Queue } from 'bullmq';
import { Env } from '../../config/env.schema';
import { PAYOUT_PROVIDER, type PayoutProvider } from './payout.provider';

export const PAYOUT_QUEUE_NAME = 'payouts';
export const PAYOUT_QUEUE = Symbol('PAYOUT_QUEUE');

export interface PayoutJob {
  withdrawalId: string;
}

export interface PayoutQueue {
  /** Idempotent per withdrawal id: enqueueing twice must not cause two payouts. */
  enqueue(withdrawalId: string): Promise<void>;
}

export const PAYOUT_ATTEMPTS = 6;

/** BullMQ-backed queue; the job id is the withdrawal id so duplicates collapse. */
@Injectable()
export class BullPayoutQueue implements PayoutQueue {
  constructor(
    @InjectQueue(PAYOUT_QUEUE_NAME) private readonly queue: Queue<PayoutJob>,
    @Inject(PAYOUT_PROVIDER) private readonly provider: PayoutProvider,
    private readonly config: ConfigService<Env, true>,
  ) {}

  async enqueue(withdrawalId: string): Promise<void> {
    // The stub pays instantly; a short delay lets the app show the REQUESTED/PROCESSING state like a real bank would.
    const delay = this.provider.isStub
      ? this.config.get('STUB_PAYOUT_DELAY_MS', { infer: true })
      : 0;
    const existing = await this.queue.getJob(withdrawalId);
    if (existing) {
      // Same job id collapses duplicates; a job that exhausted its retries is revived instead of silently ignored.
      if (await existing.isFailed()) await existing.retry();
      return;
    }
    await this.queue.add(
      'payout',
      { withdrawalId },
      {
        jobId: withdrawalId,
        delay,
        attempts: PAYOUT_ATTEMPTS,
        removeOnComplete: true,
        backoff: { type: 'exponential', delay: 5_000 },
      },
    );
  }
}
