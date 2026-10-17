import { Env } from './env.schema';

export interface GuardResult {
  /** Settings that make a production deployment unsafe or non-functional; boot is refused unless the escape hatch is set. */
  errors: string[];
  /** Worth fixing but not blocking. */
  warnings: string[];
}

const LOCAL_HOST = /^(localhost|127\.\d+\.\d+\.\d+|0\.0\.0\.0|::1|\[::1\])$/i;

function hostOf(url: string): string | undefined {
  try {
    return new URL(url).hostname;
  } catch {
    return undefined;
  }
}

const isLocal = (url: string) => LOCAL_HOST.test(hostOf(url) ?? '');

function checkSecret(name: string, value: string, errors: string[]) {
  if (/^dev-only/i.test(value) || /change-?me/i.test(value)) {
    errors.push(
      `${name} is a development placeholder; generate a random secret (e.g. openssl rand -base64 48)`,
    );
  } else if (value.length < 32) {
    errors.push(`${name} must be at least 32 characters`);
  }
}

/** Pure check of a validated production environment. Does nothing outside production. */
export function evaluateProductionGuard(env: Env): GuardResult {
  const errors: string[] = [];
  const warnings: string[] = [];
  if (env.NODE_ENV !== 'production') return { errors, warnings };

  checkSecret('JWT_ACCESS_SECRET', env.JWT_ACCESS_SECRET, errors);
  checkSecret('JWT_REFRESH_SECRET', env.JWT_REFRESH_SECRET, errors);
  if (env.JWT_ACCESS_SECRET === env.JWT_REFRESH_SECRET) {
    errors.push('JWT_ACCESS_SECRET and JWT_REFRESH_SECRET must differ');
  }

  if (
    env.S3_ACCESS_KEY_ID === 'minioadmin' ||
    env.S3_SECRET_ACCESS_KEY === 'minioadmin'
  ) {
    errors.push(
      'S3_ACCESS_KEY_ID/S3_SECRET_ACCESS_KEY are the MinIO defaults (minioadmin)',
    );
  }
  if (isLocal(env.S3_ENDPOINT)) {
    errors.push(
      'S3_ENDPOINT points at localhost; use the real object store endpoint',
    );
  }
  if (isLocal(env.S3_PREVIEWS_PUBLIC_URL)) {
    errors.push(
      'S3_PREVIEWS_PUBLIC_URL points at localhost; clients could not load previews',
    );
  }
  if (env.S3_PUBLIC_ENDPOINT && isLocal(env.S3_PUBLIC_ENDPOINT)) {
    errors.push(
      'S3_PUBLIC_ENDPOINT points at localhost; presigned URLs would be unusable for clients',
    );
  }

  if (/\/\/sketch:sketch@/.test(env.DATABASE_URL)) {
    errors.push('DATABASE_URL uses the development credentials sketch:sketch');
  }
  if (isLocal(env.DATABASE_URL))
    warnings.push('DATABASE_URL points at localhost');
  if (isLocal(env.REDIS_URL)) warnings.push('REDIS_URL points at localhost');

  if (!env.RAZORPAY_KEY_ID || !env.RAZORPAY_KEY_SECRET) {
    errors.push(
      'RAZORPAY_KEY_ID/RAZORPAY_KEY_SECRET are unset: checkout would run on the stub payment provider',
    );
  } else if (!env.RAZORPAY_WEBHOOK_SECRET) {
    errors.push(
      'RAZORPAY_WEBHOOK_SECRET is unset: payment webhooks cannot be verified',
    );
  }
  if (env.PAYOUT_PROVIDER === 'stub') {
    errors.push(
      'PAYOUT_PROVIDER=stub: payouts would never reach a bank (use razorpayx)',
    );
  } else if (
    !env.RAZORPAYX_KEY_ID ||
    !env.RAZORPAYX_KEY_SECRET ||
    !env.RAZORPAYX_ACCOUNT_NUMBER
  ) {
    errors.push(
      'PAYOUT_PROVIDER=razorpayx needs RAZORPAYX_KEY_ID, RAZORPAYX_KEY_SECRET and RAZORPAYX_ACCOUNT_NUMBER (otherwise the stub provider is used)',
    );
  } else if (!env.RAZORPAYX_WEBHOOK_SECRET) {
    errors.push(
      'RAZORPAYX_WEBHOOK_SECRET is unset: payout webhooks cannot be verified',
    );
  }

  if (!env.RATE_LIMIT_ENABLED)
    errors.push('RATE_LIMIT_ENABLED=false disables all rate limiting');
  if (isLocal(env.APP_BASE_URL)) {
    errors.push(
      'APP_BASE_URL points at localhost; password-reset links would be broken',
    );
  } else if (!env.APP_BASE_URL.startsWith('https://')) {
    warnings.push('APP_BASE_URL is not https');
  }
  if (env.SMTP_HOST === 'localhost' || env.SMTP_HOST === '127.0.0.1') {
    errors.push(
      'SMTP_HOST is localhost (Mailpit); transactional email would not be delivered',
    );
  }

  if (env.RATE_LIMIT_STORAGE === 'memory') {
    warnings.push(
      'RATE_LIMIT_STORAGE=memory: limits are per instance, not shared',
    );
  }
  if (!env.METRICS_TOKEN)
    warnings.push(
      'METRICS_TOKEN is unset: /metrics is reachable from private addresses only',
    );
  if (!env.SENTRY_DSN)
    warnings.push('SENTRY_DSN is unset: errors are logged but not reported');
  if (!env.FCM_PROJECT_ID || !env.FCM_CLIENT_EMAIL || !env.FCM_PRIVATE_KEY) {
    warnings.push('FCM_* are unset: push notifications use the logging stub');
  }
  if (env.TRUST_PROXY === 0) {
    warnings.push(
      'TRUST_PROXY=0: behind a load balancer every client shares one rate-limit key',
    );
  }
  return { errors, warnings };
}

/**
 * Throws when a production environment is unsafe. `ALLOW_UNSAFE_PRODUCTION=true` turns the refusal into a warning
 * (for staging or a first dry run); warnings are always written to stderr because the logger is not up yet.
 */
export function assertProductionSafe(
  env: Env,
  write: (line: string) => void = (l) => process.stderr.write(`${l}\n`),
): void {
  const { errors, warnings } = evaluateProductionGuard(env);
  for (const w of warnings) write(`[startup-guard] warning: ${w}`);
  if (errors.length === 0) return;
  if (env.ALLOW_UNSAFE_PRODUCTION) {
    for (const e of errors)
      write(
        `[startup-guard] UNSAFE (allowed by ALLOW_UNSAFE_PRODUCTION=true): ${e}`,
      );
    return;
  }
  throw new Error(
    `Refusing to start in production with unsafe configuration:\n${errors
      .map((e) => `  - ${e}`)
      .join(
        '\n',
      )}\nFix the settings above (see docs/DEPLOY.md). Escape hatch for staging only: ALLOW_UNSAFE_PRODUCTION=true.`,
  );
}
