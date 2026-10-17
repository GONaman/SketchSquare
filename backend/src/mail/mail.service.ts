import { Injectable } from '@nestjs/common';
import { InjectQueue } from '@nestjs/bullmq';
import { Queue } from 'bullmq';
import { EMAIL_QUEUE, EmailJob } from './mail.types';

/** Enqueues emails on the `email` BullMQ queue; delivery (SMTP) happens in `EmailProcessor` with retries. */
@Injectable()
export class MailService {
  constructor(@InjectQueue(EMAIL_QUEUE) private readonly queue: Queue) {}

  private async enqueue(job: EmailJob): Promise<void> {
    await this.queue.add(job.name, job.data, {
      attempts: 5,
      backoff: { type: 'exponential', delay: 5_000 },
      // Reset tokens must not linger in Redis after delivery.
      removeOnComplete: job.name === 'password-reset' ? true : 1000,
    });
  }

  sendWelcome(to: string, fullName: string): Promise<void> {
    return this.enqueue({ name: 'welcome', data: { to, fullName } });
  }

  sendVerificationRejected(
    to: string,
    fullName: string,
    note: string,
  ): Promise<void> {
    return this.enqueue({
      name: 'verification-rejected',
      data: { to, fullName, note },
    });
  }

  sendPasswordReset(
    to: string,
    fullName: string,
    token: string,
    resetUrl: string,
  ): Promise<void> {
    return this.enqueue({
      name: 'password-reset',
      data: { to, fullName, token, resetUrl },
    });
  }

  sendDrawingUnderReview(
    to: string,
    fullName: string,
    title: string,
  ): Promise<void> {
    return this.enqueue({
      name: 'drawing-under-review',
      data: { to, fullName, title },
    });
  }
}
