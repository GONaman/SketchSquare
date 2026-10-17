import { OnWorkerEvent, Processor, WorkerHost } from '@nestjs/bullmq';
import { Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Job } from 'bullmq';
import { createTransport, Transporter } from 'nodemailer';
import { Env } from '../config/env.schema';
import { renderEmail } from './email.templates';
import { EMAIL_QUEUE, EmailJob } from './mail.types';

@Processor(EMAIL_QUEUE)
export class EmailProcessor extends WorkerHost {
  private readonly logger = new Logger(EmailProcessor.name);
  private readonly transport: Transporter;
  private readonly from: string;

  constructor(config: ConfigService<Env, true>) {
    super();
    const user = config.get('SMTP_USER', { infer: true });
    this.transport = createTransport({
      host: config.get('SMTP_HOST', { infer: true }),
      port: config.get('SMTP_PORT', { infer: true }),
      secure: config.get('SMTP_SECURE', { infer: true }),
      auth: user
        ? { user, pass: config.get('SMTP_PASS', { infer: true }) }
        : undefined,
    });
    this.from = config.get('EMAIL_FROM', { infer: true });
  }

  async process(job: Job): Promise<void> {
    const email = { name: job.name, data: job.data as unknown } as EmailJob;
    const { subject, html, text } = renderEmail(email);
    await this.transport.sendMail({
      from: this.from,
      to: email.data.to,
      subject,
      html,
      text,
    });
  }

  @OnWorkerEvent('failed')
  onFailed(job: Job | undefined, err: Error): void {
    this.logger.warn(
      `Email job ${job?.name} (${job?.id}) failed (attempt ${job?.attemptsMade}): ${err.message}`,
    );
  }

  @OnWorkerEvent('error')
  onError(err: Error): void {
    this.logger.warn(`Email worker error: ${err.message}`);
  }
}
