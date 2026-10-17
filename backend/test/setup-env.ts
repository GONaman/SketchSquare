// e2e tests always run against the dedicated test database, never the dev one.
process.env.NODE_ENV = 'test';
process.env.DATABASE_URL =
  process.env.TEST_DATABASE_URL ??
  'postgresql://sketch:sketch@localhost:5432/sketchsquare_test';
