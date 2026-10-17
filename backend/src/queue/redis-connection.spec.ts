import { redisConnectionFromUrl } from './redis-connection';

describe('redisConnectionFromUrl', () => {
  it('parses a plain local url', () => {
    expect(redisConnectionFromUrl('redis://localhost:6379')).toMatchObject({
      host: 'localhost',
      port: 6379,
      password: undefined,
      db: undefined,
      tls: undefined,
      maxRetriesPerRequest: null,
    });
  });

  it('parses credentials, db and tls', () => {
    expect(
      redisConnectionFromUrl('rediss://user:p%40ss@cache.example.com:6380/2'),
    ).toMatchObject({
      host: 'cache.example.com',
      port: 6380,
      username: 'user',
      password: 'p@ss',
      db: 2,
      tls: {},
    });
  });

  it('defaults the port', () => {
    expect(redisConnectionFromUrl('redis://cache').port).toBe(6379);
  });
});
