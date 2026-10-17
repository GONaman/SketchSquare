import { OnWorkerEvent, Processor, WorkerHost } from '@nestjs/bullmq';
import { Inject, Logger } from '@nestjs/common';
import { Job } from 'bullmq';
import { PrismaService } from '../prisma/prisma.service';
import { PUSH_QUEUE, PushJob } from './notification.types';
import { PUSH_SERVICE, type PushService } from './push.service';

@Processor(PUSH_QUEUE)
export class PushProcessor extends WorkerHost {
  private readonly logger = new Logger(PushProcessor.name);

  constructor(
    private readonly prisma: PrismaService,
    @Inject(PUSH_SERVICE) private readonly push: PushService,
  ) {
    super();
  }

  async process(job: Job<PushJob>): Promise<void> {
    const n = await this.prisma.notification.findUnique({
      where: { id: job.data.notificationId },
      include: { user: { select: { deviceTokens: true } } },
    });
    // Not visible yet (writer's transaction still open) → throw so the queue retries with backoff.
    if (!n)
      throw new Error(`Notification ${job.data.notificationId} not found`);

    const targets = n.user.deviceTokens.map((d) => ({
      token: d.token,
      platform: d.platform,
    }));
    if (targets.length === 0) return;

    const result = await this.push.send(targets, {
      title: n.title,
      body: n.body,
      data: { ...(n.data as Record<string, string>), notificationId: n.id },
    });
    if (result.invalidTokens.length > 0) {
      await this.prisma.deviceToken.deleteMany({
        where: { token: { in: result.invalidTokens } },
      });
    }
  }

  @OnWorkerEvent('failed')
  onFailed(job: Job | undefined, err: Error): void {
    this.logger.warn(
      `Push job ${job?.id} failed (attempt ${job?.attemptsMade}): ${err.message}`,
    );
  }

  @OnWorkerEvent('error')
  onError(err: Error): void {
    this.logger.warn(`Push worker error: ${err.message}`);
  }
}
