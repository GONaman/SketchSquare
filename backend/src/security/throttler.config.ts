import { ExecutionContext } from '@nestjs/common';
import { ThrottlerModuleOptions } from '@nestjs/throttler';
import type { Request } from 'express';
import type Redis from 'ioredis';
import { Env } from '../config/env.schema';
import { RedisThrottlerStorage } from './redis-throttler.storage';

const SAFE_METHODS = new Set(['GET', 'HEAD', 'OPTIONS']);

/**
 * Two named throttlers per client IP and route:
 * - `default`: generous ceiling for every request (routes tighten it with `@Throttle({ default })`).
 * - `write`: applies to every non-GET/HEAD/OPTIONS request, so a new write endpoint is limited without
 *   anyone remembering to decorate it (routes tighten it with `@Throttle({ write })`).
 */
export function buildThrottlerOptions(
  env: Pick<
    Env,
    | 'RATE_LIMIT_ENABLED'
    | 'RATE_LIMIT_WRITE_PER_MIN'
    | 'RATE_LIMIT_STORAGE'
    | 'QUEUE_PREFIX'
  >,
  redis: Redis,
): ThrottlerModuleOptions {
  const disabled = () => !env.RATE_LIMIT_ENABLED;
  const isRead = (ctx: ExecutionContext) =>
    disabled() ||
    SAFE_METHODS.has(ctx.switchToHttp().getRequest<Request>().method);
  return {
    throttlers: [
      { name: 'default', ttl: 60_000, limit: 300, skipIf: disabled },
      {
        name: 'write',
        ttl: 60_000,
        limit: env.RATE_LIMIT_WRITE_PER_MIN,
        skipIf: isRead,
      },
    ],
    ...(env.RATE_LIMIT_STORAGE === 'redis' && {
      storage: new RedisThrottlerStorage(redis, env.QUEUE_PREFIX),
    }),
  };
}
