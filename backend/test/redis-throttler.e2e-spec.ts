import Redis from 'ioredis';
import { randomUUID } from 'node:crypto';
import { RedisThrottlerStorage } from '../src/security/redis-throttler.storage';

describe('RedisThrottlerStorage against Redis (e2e)', () => {
  const url = process.env.REDIS_URL ?? 'redis://localhost:6379';
  let a: Redis;
  let b: Redis;
  let prefix: string;

  beforeAll(() => {
    a = new Redis(url);
    b = new Redis(url);
  });
  beforeEach(() => {
    prefix = `throttle-test-${randomUUID()}`;
  });
  afterAll(async () => {
    for (const client of [a, b]) {
      const keys = await client.keys('throttle-test-*');
      if (keys.length) await client.del(...keys);
      client.disconnect();
    }
  });

  it('shares counters between API instances and blocks past the limit', async () => {
    const one = new RedisThrottlerStorage(a, prefix);
    const two = new RedisThrottlerStorage(b, prefix);
    expect(
      (await one.increment('ip', 60_000, 3, 60_000, 'write')).totalHits,
    ).toBe(1);
    expect(
      (await two.increment('ip', 60_000, 3, 60_000, 'write')).totalHits,
    ).toBe(2);
    expect(
      (await one.increment('ip', 60_000, 3, 60_000, 'write')).isBlocked,
    ).toBe(false);
    const blocked = await two.increment('ip', 60_000, 3, 60_000, 'write');
    expect(blocked.isBlocked).toBe(true);
    expect(blocked.timeToBlockExpire).toBeGreaterThan(0);
    expect(blocked.timeToExpire).toBeGreaterThan(0);
  });

  it('expires the window', async () => {
    const store = new RedisThrottlerStorage(a, prefix);
    await store.increment('ip', 300, 1, 300, 'default');
    expect(
      (await store.increment('ip', 300, 1, 300, 'default')).isBlocked,
    ).toBe(true);
    await new Promise((r) => setTimeout(r, 450));
    const fresh = await store.increment('ip', 300, 1, 300, 'default');
    expect(fresh).toMatchObject({ totalHits: 1, isBlocked: false });
  });
});
