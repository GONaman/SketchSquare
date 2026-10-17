import { Logger } from '@nestjs/common';
import { ThrottlerStorage } from '@nestjs/throttler';
import type { ThrottlerStorageRecord } from '@nestjs/throttler/dist/throttler-storage-record.interface';
import type Redis from 'ioredis';

/**
 * Atomic fixed-window counter with a block period, so every API instance shares the same counters.
 * KEYS[1]=hits KEYS[2]=block; ARGV = ttlMs, limit, blockMs.
 * Returns {totalHits, ttlMs, blocked(0|1), blockTtlMs}.
 */
const INCREMENT_SCRIPT = `
local blockTtl = redis.call('PTTL', KEYS[2])
if blockTtl > 0 then
  local hits = tonumber(redis.call('GET', KEYS[1]) or '0')
  return {hits, redis.call('PTTL', KEYS[1]), 1, blockTtl}
end
local hits = redis.call('INCR', KEYS[1])
if hits == 1 then redis.call('PEXPIRE', KEYS[1], ARGV[1]) end
local ttl = redis.call('PTTL', KEYS[1])
if ttl < 0 then redis.call('PEXPIRE', KEYS[1], ARGV[1]); ttl = tonumber(ARGV[1]) end
if hits > tonumber(ARGV[2]) then
  redis.call('SET', KEYS[2], '1', 'PX', ARGV[3])
  return {hits, ttl, 1, tonumber(ARGV[3])}
end
return {hits, ttl, 0, 0}
`;

interface MemoryWindow {
  hits: number;
  expiresAt: number;
  blockedUntil: number;
}

/**
 * Redis-backed `ThrottlerStorage`. If Redis is unreachable it degrades to per-process counters
 * instead of failing requests (rate limiting must never take the API down).
 */
export class RedisThrottlerStorage implements ThrottlerStorage {
  private readonly logger = new Logger(RedisThrottlerStorage.name);
  private readonly memory = new Map<string, MemoryWindow>();
  private warned = false;

  constructor(
    private readonly redis: Redis,
    private readonly prefix: string,
  ) {}

  async increment(
    key: string,
    ttl: number,
    limit: number,
    blockDuration: number,
    throttlerName: string,
  ): Promise<ThrottlerStorageRecord> {
    const base = `${this.prefix}:throttle:${throttlerName}:${key}`;
    try {
      const [hits, ttlMs, blocked, blockTtlMs] = (await this.redis.eval(
        INCREMENT_SCRIPT,
        2,
        base,
        `${base}:blocked`,
        ttl,
        limit,
        blockDuration,
      )) as [number, number, number, number];
      this.warned = false;
      return {
        totalHits: hits,
        timeToExpire: Math.max(0, Math.ceil(ttlMs / 1000)),
        isBlocked: blocked === 1,
        timeToBlockExpire: Math.max(0, Math.ceil(blockTtlMs / 1000)),
      };
    } catch (err) {
      if (!this.warned) {
        this.logger.warn(
          `Redis unavailable, using in-memory rate limits: ${(err as Error).message}`,
        );
        this.warned = true;
      }
      return this.incrementInMemory(base, ttl, limit, blockDuration);
    }
  }

  private incrementInMemory(
    key: string,
    ttl: number,
    limit: number,
    blockDuration: number,
  ): ThrottlerStorageRecord {
    const now = Date.now();
    if (this.memory.size > 10_000) this.sweep(now);
    let w = this.memory.get(key);
    if (!w || w.expiresAt <= now) {
      w = { hits: 0, expiresAt: now + ttl, blockedUntil: 0 };
      this.memory.set(key, w);
    }
    if (w.blockedUntil > now) return this.record(w, now);
    w.hits += 1;
    if (w.hits > limit) w.blockedUntil = now + blockDuration;
    return this.record(w, now);
  }

  private record(w: MemoryWindow, now: number): ThrottlerStorageRecord {
    const blocked = w.blockedUntil > now;
    return {
      totalHits: w.hits,
      timeToExpire: Math.max(0, Math.ceil((w.expiresAt - now) / 1000)),
      isBlocked: blocked,
      timeToBlockExpire: blocked ? Math.ceil((w.blockedUntil - now) / 1000) : 0,
    };
  }

  private sweep(now: number): void {
    for (const [k, w] of this.memory) {
      if (w.expiresAt <= now && w.blockedUntil <= now) this.memory.delete(k);
    }
  }
}
