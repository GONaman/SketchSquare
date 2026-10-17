import { TEST_DATABASE_URL } from './helpers/test-db-url';

// e2e tests always run against the dedicated test database, never the dev one.
process.env.NODE_ENV = 'test';
process.env.DATABASE_URL = TEST_DATABASE_URL;
