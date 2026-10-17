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

  it('accepts .env.example as-is', () => {
    const example = parse(
      readFileSync(join(__dirname, '../../.env.example'), 'utf8'),
    );
    expect(() => validateEnv(example)).not.toThrow();
    expect(example.FREE_DOWNLOAD_LIMIT).toBe('20');
  });
});
