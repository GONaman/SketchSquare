import { validateEnv } from './env.schema';
import {
  assertProductionSafe,
  evaluateProductionGuard,
} from './production-guard';

const safe = {
  NODE_ENV: 'production',
  CORS_ORIGINS: 'https://app.example.com',
  APP_BASE_URL: 'https://app.example.com',
  DATABASE_URL: 'postgresql://app:s3cret-pw@db.internal:5432/sketchsquare',
  REDIS_URL: 'redis://cache.internal:6379',
  S3_ENDPOINT: 'https://s3.ap-south-1.amazonaws.com',
  S3_ACCESS_KEY_ID: 'AKIAEXAMPLE',
  S3_SECRET_ACCESS_KEY: 'x'.repeat(40),
  S3_PREVIEWS_PUBLIC_URL: 'https://cdn.example.com/previews',
  JWT_ACCESS_SECRET: 'a'.repeat(48),
  JWT_REFRESH_SECRET: 'b'.repeat(48),
  RAZORPAY_KEY_ID: 'rzp_live_x',
  RAZORPAY_KEY_SECRET: 'secret',
  RAZORPAY_WEBHOOK_SECRET: 'whsec',
  PAYOUT_PROVIDER: 'razorpayx',
  RAZORPAYX_KEY_ID: 'rzpx',
  RAZORPAYX_KEY_SECRET: 'rzpxs',
  RAZORPAYX_ACCOUNT_NUMBER: '1234567890',
  RAZORPAYX_WEBHOOK_SECRET: 'xwh',
  SMTP_HOST: 'smtp.example.com',
  METRICS_TOKEN: 'm',
  SENTRY_DSN: 'https://k@sentry.example.com/1',
  FCM_PROJECT_ID: 'p',
  FCM_CLIENT_EMAIL: 'e@p.iam.gserviceaccount.com',
  FCM_PRIVATE_KEY: 'key',
  TRUST_PROXY: '1',
};

const guard = (over: Record<string, string> = {}) =>
  evaluateProductionGuard(validateEnv({ ...safe, ...over }));

describe('production startup guard', () => {
  it('accepts a fully configured production environment', () => {
    expect(guard()).toEqual({ errors: [], warnings: [] });
  });

  it('is inert outside production', () => {
    const env = validateEnv({});
    expect(evaluateProductionGuard(env)).toEqual({ errors: [], warnings: [] });
    expect(() => assertProductionSafe(env, () => undefined)).not.toThrow();
  });

  it.each([
    [
      'dev JWT secret',
      { JWT_ACCESS_SECRET: 'dev-only-access-secret-change-me' },
      'JWT_ACCESS_SECRET',
    ],
    ['short JWT secret', { JWT_REFRESH_SECRET: 'short' }, 'JWT_REFRESH_SECRET'],
    [
      'identical JWT secrets',
      { JWT_REFRESH_SECRET: 'a'.repeat(48) },
      'must differ',
    ],
    ['MinIO credentials', { S3_ACCESS_KEY_ID: 'minioadmin' }, 'MinIO defaults'],
    [
      'local S3 endpoint',
      { S3_ENDPOINT: 'http://localhost:9000' },
      'S3_ENDPOINT',
    ],
    [
      'local previews URL',
      { S3_PREVIEWS_PUBLIC_URL: 'http://localhost:9000/previews' },
      'S3_PREVIEWS_PUBLIC_URL',
    ],
    [
      'dev DB credentials',
      { DATABASE_URL: 'postgresql://sketch:sketch@db:5432/x' },
      'sketch:sketch',
    ],
    ['stub payments', { RAZORPAY_KEY_ID: '' }, 'stub payment provider'],
    [
      'missing webhook secret',
      { RAZORPAY_WEBHOOK_SECRET: '' },
      'RAZORPAY_WEBHOOK_SECRET',
    ],
    ['stub payouts', { PAYOUT_PROVIDER: 'stub' }, 'PAYOUT_PROVIDER=stub'],
    [
      'incomplete razorpayx',
      { RAZORPAYX_ACCOUNT_NUMBER: '' },
      'RAZORPAYX_ACCOUNT_NUMBER',
    ],
    [
      'missing payout webhook secret',
      { RAZORPAYX_WEBHOOK_SECRET: '' },
      'RAZORPAYX_WEBHOOK_SECRET',
    ],
    ['rate limit off', { RATE_LIMIT_ENABLED: 'false' }, 'RATE_LIMIT_ENABLED'],
    [
      'local base URL',
      { APP_BASE_URL: 'http://localhost:3000' },
      'APP_BASE_URL',
    ],
    ['Mailpit SMTP', { SMTP_HOST: 'localhost' }, 'SMTP_HOST'],
  ])('flags %s', (_name, over, fragment) => {
    const { errors } = guard(over);
    expect(errors.some((e) => e.includes(fragment))).toBe(true);
  });

  it('only warns about optional integrations', () => {
    const { errors, warnings } = guard({
      METRICS_TOKEN: '',
      SENTRY_DSN: '',
      FCM_PROJECT_ID: '',
      TRUST_PROXY: '0',
      RATE_LIMIT_STORAGE: 'memory',
    });
    expect(errors).toEqual([]);
    expect(warnings).toHaveLength(5);
  });

  it('refuses to boot with every problem listed, and the escape hatch downgrades it', () => {
    const env = validateEnv({
      ...safe,
      JWT_ACCESS_SECRET: 'dev-only-access-secret-change-me',
      PAYOUT_PROVIDER: 'stub',
    });
    expect(() => assertProductionSafe(env, () => undefined)).toThrow(
      /JWT_ACCESS_SECRET[\s\S]*PAYOUT_PROVIDER=stub[\s\S]*ALLOW_UNSAFE_PRODUCTION/,
    );

    const lines: string[] = [];
    const hatch = validateEnv({
      ...safe,
      JWT_ACCESS_SECRET: 'dev-only-access-secret-change-me',
      ALLOW_UNSAFE_PRODUCTION: 'true',
    });
    expect(() =>
      assertProductionSafe(hatch, (l) => lines.push(l)),
    ).not.toThrow();
    expect(lines.some((l) => l.includes('UNSAFE'))).toBe(true);
  });
});
