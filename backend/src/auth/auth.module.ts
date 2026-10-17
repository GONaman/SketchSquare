import { Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { APP_GUARD } from '@nestjs/core';
import { JwtModule } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { Env } from '../config/env.schema';
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
      inject: [ConfigService],
      useFactory: (config: ConfigService<Env, true>) => ({
        // Generous global ceiling; auth routes tighten it with @Throttle.
        throttlers: [{ ttl: 60_000, limit: 300 }],
        skipIf: () => !config.get('RATE_LIMIT_ENABLED', { infer: true }),
      }),
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
