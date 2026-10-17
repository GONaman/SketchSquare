import { Global, Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { LoggerModule } from 'nestjs-pino';
import { Env } from '../config/env.schema';
import { ShutdownState } from './graceful-shutdown';
import { buildLoggerParams } from './logger.config';
import { MetricsController } from './metrics.controller';
import { MetricsService } from './metrics.service';

@Global()
@Module({
  imports: [
    LoggerModule.forRootAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (config: ConfigService<Env, true>) =>
        buildLoggerParams(config),
    }),
  ],
  controllers: [MetricsController],
  providers: [MetricsService, ShutdownState],
  exports: [MetricsService, ShutdownState],
})
export class ObservabilityModule {}
