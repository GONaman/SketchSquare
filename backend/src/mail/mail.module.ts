import { BullModule } from '@nestjs/bullmq';
import { Global, Module } from '@nestjs/common';
import { EmailProcessor } from './email.processor';
import { EMAIL_QUEUE } from './mail.types';
import { MailService } from './mail.service';

/** Global: inject `MailService` anywhere to send transactional email through the queue. */
@Global()
@Module({
  imports: [BullModule.registerQueue({ name: EMAIL_QUEUE })],
  providers: [MailService, EmailProcessor],
  exports: [MailService],
})
export class MailModule {}
