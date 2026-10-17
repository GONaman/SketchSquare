import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { parse } from 'dotenv';
import { validateEnv } from './env.schema';

describe('validateEnv', () => {
  it('applies local-dev defaults for an empty environment', () => {
    const env = validateEnv({});
    expect(env.PORT).toBe(3000);
    expect(env.FREE_DOWNLOAD_LIMIT).toBe(20);
    expect(env.PLATFORM_FEE_BPS).toBe(1000);
    expect(env.MIN_WITHDRAWAL_PAISE).toBe(50000);
    expect(env.S3_FORCE_PATH_STYLE).toBe(true);
    expect(env.PAYOUT_PROVIDER).toBe('stub');
    expect(env.CONTRIBUTION_FREE_PER_PAID).toBe(1);
    expect(env.PLAGIARISM_PHASH_THRESHOLD).toBe(8);
    expect(env.PLAGIARISM_PLOT_TOLERANCE_PCT).toBe(5);
  });

  it('coerces numbers and booleans from strings', () => {
    const env = validateEnv({ PORT: '4000', S3_FORCE_PATH_STYLE: 'false' });
    expect(env.PORT).toBe(4000);
    expect(env.S3_FORCE_PATH_STYLE).toBe(false);
  });

  it('treats empty strings as unset', () => {
    const env = validateEnv({ RAZORPAY_KEY_ID: '', S3_PUBLIC_ENDPOINT: '' });
    expect(env.RAZORPAY_KEY_ID).toBeUndefined();
    expect(env.S3_PUBLIC_ENDPOINT).toBeUndefined();
  });

  it('rejects invalid values with a readable message', () => {
    expect(() => validateEnv({ PAYOUT_PROVIDER: 'bogus' })).toThrow(
      /PAYOUT_PROVIDER/,
    );
    expect(() => validateEnv({ PLATFORM_FEE_BPS: '20000' })).toThrow(
      /PLATFORM_FEE_BPS/,
    );
    expect(() => validateEnv({ PLAGIARISM_PHASH_THRESHOLD: '65' })).toThrow(
      /PLAGIARISM_PHASH_THRESHOLD/,
    );
  });

  it('rejects a wildcard CORS allowlist in production only', () => {
    const prod = {
      NODE_ENV: 'production',
      DATABASE_URL: 'postgresql://u:p@db/x',
      REDIS_URL: 'redis://r',
      S3_ENDPOINT: 'https://s3.example.com',
      S3_ACCESS_KEY_ID: 'k',
      S3_SECRET_ACCESS_KEY: 's',
      S3_PREVIEWS_PUBLIC_URL: 'https://cdn.example.com',
      JWT_ACCESS_SECRET: 'a',
      JWT_REFRESH_SECRET: 'b',
    };
    expect(() => validateEnv(prod)).toThrow(/CORS_ORIGINS/);
    expect(() => validateEnv({ ...prod, CORS_ORIGINS: '*' })).toThrow(
      /CORS_ORIGINS/,
    );
    expect(() =>
      validateEnv({ ...prod, CORS_ORIGINS: 'https://a.example, *' }),
    ).toThrow(/CORS_ORIGINS/);
    expect(
      validateEnv({ ...prod, CORS_ORIGINS: 'https://app.example.com' })
        .CORS_ORIGINS,
    ).toBe('https://app.example.com');
    expect(validateEnv({ CORS_ORIGINS: '*' }).CORS_ORIGINS).toBe('*');
  });

  it('accepts .env.example as-is', () => {
    const example = parse(
      readFileSync(join(__dirname, '../../.env.example'), 'utf8'),
    );
    expect(() => validateEnv(example)).not.toThrow();
    expect(example.FREE_DOWNLOAD_LIMIT).toBe('20');
  });
});
