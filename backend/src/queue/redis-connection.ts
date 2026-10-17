export interface BullRedisConnection {
  host: string;
  port: number;
  username?: string;
  password?: string;
  db?: number;
  tls?: Record<string, never>;
  // Required by BullMQ workers (blocking commands must never be retried-and-failed).
  maxRetriesPerRequest: null;
}

/** Turns `redis[s]://[user:pass@]host:port[/db]` into BullMQ connection options. */
export function redisConnectionFromUrl(url: string): BullRedisConnection {
  const u = new URL(url);
  const dbPart = u.pathname.replace('/', '');
  return {
    host: u.hostname,
    port: u.port ? Number(u.port) : 6379,
    username: u.username ? decodeURIComponent(u.username) : undefined,
    password: u.password ? decodeURIComponent(u.password) : undefined,
    db: dbPart ? Number(dbPart) : undefined,
    tls: u.protocol === 'rediss:' ? {} : undefined,
    maxRetriesPerRequest: null,
  };
}
