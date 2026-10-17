import { Global, Module } from '@nestjs/common';
import { BullModule } from '@nestjs/bullmq';
import { ConfigService } from '@nestjs/config';
import { Env } from '../config/env.schema';
import { redisConnectionFromUrl } from './redis-connection';

/**
 * Shared BullMQ root connection (global). Feature modules only call `BullModule.registerQueue({ name })`
 * and use `@InjectQueue` / `@Processor`; never call `BullModule.forRoot*` again.
 */
@Global()
@Module({
  imports: [
    BullModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService<Env, true>) => ({
        connection: redisConnectionFromUrl(
          config.get('REDIS_URL', { infer: true }),
        ),
        prefix: config.get('QUEUE_PREFIX', { infer: true }),
        defaultJobOptions: {
          removeOnComplete: 1000,
          removeOnFail: 5000,
        },
      }),
    }),
  ],
  exports: [BullModule],
})
export class QueueModule {}
