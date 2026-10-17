import { TEST_DATABASE_URL } from './helpers/test-db-url';

// e2e tests always run against the dedicated test database, never the dev one.
process.env.NODE_ENV = 'test';
process.env.DATABASE_URL = TEST_DATABASE_URL;
// Auth routes are rate limited; most e2e files would trip the limiter, so it is off unless a test opts in.
process.env.RATE_LIMIT_ENABLED ??= 'false';
// BullMQ workers run inside the app under test; isolate them per test DB so parallel runs and dev servers can't steal jobs.
process.env.QUEUE_PREFIX ??= `bull-test-${new URL(TEST_DATABASE_URL).pathname.slice(1)}`;
// Counters in shared Redis would leak between test runs (a 60 s window); the Redis store has its own spec.
process.env.RATE_LIMIT_STORAGE ??= 'memory';
process.env.LOG_LEVEL ??= 'silent';
