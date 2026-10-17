import { TEST_DATABASE_URL } from './helpers/test-db-url';

// e2e tests always run against the dedicated test database, never the dev one.
process.env.NODE_ENV = 'test';
process.env.DATABASE_URL = TEST_DATABASE_URL;
// Auth routes are rate limited; most e2e files would trip the limiter, so it is off unless a test opts in.
process.env.RATE_LIMIT_ENABLED ??= 'false';
