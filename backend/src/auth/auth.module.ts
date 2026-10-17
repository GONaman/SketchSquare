import { Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { APP_GUARD } from '@nestjs/core';
import { JwtModule } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import type Redis from 'ioredis';
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { Env } from '../config/env.schema';
import { REDIS_CLIENT } from '../redis/redis.module';
import { buildThrottlerOptions } from '../security/throttler.config';
import { ApprovedGuard } from './guards/approved.guard';
import { JwtAuthGuard } from './guards/jwt-auth.guard';
import { RolesGuard } from './guards/roles.guard';
import { JwtStrategy } from './jwt.strategy';
import { PasswordService } from './password/password.service';
import { TokenService } from './tokens/token.service';

/**
 * Registers the global guards. Order matters: rate limit → authenticate → role check → approval check.
 * Feature modules only need the decorators (see docs/CONVENTIONS.md); import AuthModule to inject
 * TokenService / PasswordService.
 */
@Module({
  imports: [
    PassportModule,
    JwtModule.register({}),
    ThrottlerModule.forRootAsync({
      inject: [ConfigService, REDIS_CLIENT],
      useFactory: (config: ConfigService<Env, true>, redis: Redis) =>
        buildThrottlerOptions(
          {
            RATE_LIMIT_ENABLED: config.get('RATE_LIMIT_ENABLED', {
              infer: true,
            }),
            RATE_LIMIT_WRITE_PER_MIN: config.get('RATE_LIMIT_WRITE_PER_MIN', {
              infer: true,
            }),
            RATE_LIMIT_STORAGE: config.get('RATE_LIMIT_STORAGE', {
              infer: true,
            }),
            QUEUE_PREFIX: config.get('QUEUE_PREFIX', { infer: true }),
          },
          redis,
        ),
    }),
  ],
  controllers: [AuthController],
  providers: [
    AuthService,
    JwtStrategy,
    TokenService,
    PasswordService,
    { provide: APP_GUARD, useClass: ThrottlerGuard },
    { provide: APP_GUARD, useClass: JwtAuthGuard },
    { provide: APP_GUARD, useClass: RolesGuard },
    { provide: APP_GUARD, useClass: ApprovedGuard },
  ],
  exports: [TokenService, PasswordService],
})
export class AuthModule {}
