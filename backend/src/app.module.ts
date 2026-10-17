import { Module } from '@nestjs/common';
import { AuthModule } from './auth/auth.module';
import { AppConfigModule } from './config/config.module';
import { CommerceModule } from './commerce/commerce.module';
import { DrawingsModule } from './drawings/drawings.module';
import { DiscoveryModule } from './discovery/discovery.module';
import { HealthModule } from './health/health.module';
import { LedgerModule } from './ledger/ledger.module';
import { MailModule } from './mail/mail.module';
import { PrismaModule } from './prisma/prisma.module';
import { QueueModule } from './queue/queue.module';
import { RedisModule } from './redis/redis.module';
import { StorageModule } from './storage/storage.module';

@Module({
  imports: [
    AppConfigModule,
    PrismaModule,
    RedisModule,
    StorageModule,
    QueueModule,
    HealthModule,
    // Feature modules: add one line per module below.
    MailModule,
    AuthModule,
    LedgerModule,
    CommerceModule,
    DrawingsModule,
    DiscoveryModule,
  ],
})
export class AppModule {}
