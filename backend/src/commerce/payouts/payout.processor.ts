import { Processor, WorkerHost } from '@nestjs/bullmq';
import { Job } from 'bullmq';
import { PayoutService } from './payout.service';
import { PAYOUT_QUEUE_NAME, PayoutJob } from './payout.queue';

@Processor(PAYOUT_QUEUE_NAME)
export class PayoutProcessor extends WorkerHost {
  constructor(private readonly payouts: PayoutService) {
    super();
  }

  /** Throwing makes BullMQ retry with backoff; PayoutService is idempotent per withdrawal id. */
  async process(job: Job<PayoutJob>): Promise<string> {
    return this.payouts.process(job.data.withdrawalId);
  }
}
