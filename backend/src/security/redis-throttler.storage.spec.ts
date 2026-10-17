import { Logger } from '@nestjs/common';
import type Redis from 'ioredis';
import { RedisThrottlerStorage } from './redis-throttler.storage';

describe('RedisThrottlerStorage fallback', () => {
  beforeAll(() => {
    jest.spyOn(Logger.prototype, 'warn').mockImplementation();
  });

  const downRedis = {
    eval: jest.fn().mockRejectedValue(new Error('ECONNREFUSED')),
  } as unknown as Redis;

  it('counts and blocks per process while Redis is down instead of failing the request', async () => {
    const storage = new RedisThrottlerStorage(downRedis, 'test');
    const hit = () => storage.increment('k', 60_000, 2, 60_000, 'write');
    expect((await hit()).totalHits).toBe(1);
    expect((await hit()).isBlocked).toBe(false);
    const third = await hit();
    expect(third).toMatchObject({ totalHits: 3, isBlocked: true });
    expect(third.timeToBlockExpire).toBeGreaterThan(0);
  });

  it('keeps separate counters per throttler name and key', async () => {
    const storage = new RedisThrottlerStorage(downRedis, 'test');
    await storage.increment('a', 60_000, 1, 60_000, 'write');
    expect(
      (await storage.increment('a', 60_000, 1, 60_000, 'default')).totalHits,
    ).toBe(1);
    expect(
      (await storage.increment('b', 60_000, 1, 60_000, 'write')).totalHits,
    ).toBe(1);
  });
});
