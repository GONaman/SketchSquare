import {
  Inject,
  Injectable,
  Logger,
  OnApplicationBootstrap,
  OnModuleDestroy,
} from '@nestjs/common';
import { PAYOUT_QUEUE, type PayoutQueue } from './payout.queue';
import { PayoutService } from './payout.service';

const MIN_AGE_MS = 30_000;
const SWEEP_INTERVAL_MS = 5 * 60_000;

/**
 * Re-enqueues withdrawals that were committed but never handed to (or finished by) a worker, e.g. Redis was down at
 * request time or the process crashed. Runs at boot and periodically; enqueueing is idempotent per withdrawal.
 */
@Injectable()
export class PayoutRecoveryService
  implements OnApplicationBootstrap, OnModuleDestroy
{
  private readonly logger = new Logger(PayoutRecoveryService.name);
  private timer?: NodeJS.Timeout;

  constructor(
    private readonly payouts: PayoutService,
    @Inject(PAYOUT_QUEUE) private readonly queue: PayoutQueue,
  ) {}

  onApplicationBootstrap(): void {
    if (process.env.NODE_ENV === 'test') return;
    void this.sweep();
    this.timer = setInterval(() => void this.sweep(), SWEEP_INTERVAL_MS);
    this.timer.unref();
  }

  onModuleDestroy(): void {
    if (this.timer) clearInterval(this.timer);
  }

  async sweep(): Promise<number> {
    try {
      const ids = await this.payouts.findUnstarted(MIN_AGE_MS);
      for (const id of ids) await this.queue.enqueue(id);
      if (ids.length) this.logger.log(`Re-enqueued ${ids.length} payout(s)`);
      return ids.length;
    } catch (err) {
      this.logger.error(
        `Payout recovery sweep failed: ${err instanceof Error ? err.message : String(err)}`,
      );
      return 0;
    }
  }
}
