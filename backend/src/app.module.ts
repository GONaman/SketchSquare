import { Module } from '@nestjs/common';
import { AuditModule } from './audit/audit.module';
import { AuthModule } from './auth/auth.module';
import { AppConfigModule } from './config/config.module';
import { CommerceModule } from './commerce/commerce.module';
import { DrawingsModule } from './drawings/drawings.module';
import { DiscoveryModule } from './discovery/discovery.module';
import { EngagementModule } from './engagement/engagement.module';
import { HealthModule } from './health/health.module';
import { LedgerModule } from './ledger/ledger.module';
import { MailModule } from './mail/mail.module';
import { ObservabilityModule } from './observability/observability.module';
import { RefundsModule } from './refunds/refunds.module';
import { NotificationsModule } from './notifications/notifications.module';
import { PrismaModule } from './prisma/prisma.module';
import { QueueModule } from './queue/queue.module';
import { RedisModule } from './redis/redis.module';
import { VerificationModule } from './verification/verification.module';
import { StorageModule } from './storage/storage.module';

@Module({
  imports: [
    AppConfigModule,
    PrismaModule,
    RedisModule,
    StorageModule,
    QueueModule,
    AuditModule,
    ObservabilityModule,
    HealthModule,
    // Feature modules: add one line per module below.
    MailModule,
    AuthModule,
    LedgerModule,
    CommerceModule,
    DrawingsModule,
    DiscoveryModule,
    VerificationModule,
    EngagementModule,
    RefundsModule,
    NotificationsModule,
  ],
})
export class AppModule {}
