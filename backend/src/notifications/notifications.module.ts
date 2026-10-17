import { BullModule } from '@nestjs/bullmq';
import { Global, Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Env } from '../config/env.schema';
import { DeviceTokensService } from './device-tokens.service';
import { FcmPushService } from './fcm-push.service';
import { PUSH_QUEUE } from './notification.types';
import { NotificationsController } from './notifications.controller';
import { NotificationsService } from './notifications.service';
import { PUSH_SERVICE, type PushService } from './push.service';
import { PushProcessor } from './push.processor';
import { StubPushService } from './stub-push.service';

/**
 * Global: inject `NotificationsService` anywhere and call `notify(userId, type, payload)`.
 * Push goes through FCM only when FCM_PROJECT_ID, FCM_CLIENT_EMAIL and FCM_PRIVATE_KEY are all set; otherwise it is stubbed.
 */
@Global()
@Module({
  imports: [BullModule.registerQueue({ name: PUSH_QUEUE })],
  controllers: [NotificationsController],
  providers: [
    NotificationsService,
    DeviceTokensService,
    PushProcessor,
    {
      provide: PUSH_SERVICE,
      inject: [ConfigService],
      useFactory: (config: ConfigService<Env, true>): PushService => {
        const projectId = config.get('FCM_PROJECT_ID', { infer: true });
        const clientEmail = config.get('FCM_CLIENT_EMAIL', { infer: true });
        const privateKey = config.get('FCM_PRIVATE_KEY', { infer: true });
        return projectId && clientEmail && privateKey
          ? new FcmPushService({ projectId, clientEmail, privateKey })
          : new StubPushService();
      },
    },
  ],
  exports: [NotificationsService],
})
export class NotificationsModule {}
