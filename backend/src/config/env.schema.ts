import { z } from 'zod';

const isProd = process.env.NODE_ENV === 'production';

// Local-dev defaults point at infra/docker-compose.yml; in production every one of these must be set explicitly.
const withDevDefault = (value: string) =>
  isProd ? z.string().min(1) : z.string().min(1).default(value);

const bool = (def: boolean) =>
  z
    .enum(['true', 'false'])
    .default(def ? 'true' : 'false')
    .transform((v) => v === 'true');

const int = (def: number) => z.coerce.number().int().nonnegative().default(def);

const optionalString = z.string().min(1).optional();

export const envSchema = z.object({
  NODE_ENV: z
    .enum(['development', 'test', 'production'])
    .default('development'),
  PORT: z.coerce.number().int().positive().default(3000),
  CORS_ORIGINS: z.string().default('*'),
  APP_BASE_URL: z.string().default('http://localhost:3000'),

  DATABASE_URL: withDevDefault(
    'postgresql://sketch:sketch@localhost:5432/sketchsquare',
  ),
  REDIS_URL: withDevDefault('redis://localhost:6379'),
  // Key prefix for BullMQ queues; tests set a unique one so parallel runs/dev servers never consume each other's jobs.
  QUEUE_PREFIX: z.string().min(1).default('bull'),

  S3_ENDPOINT: withDevDefault('http://localhost:9000'),
  // Host used inside presigned URLs handed to clients (an emulator needs 10.0.2.2 instead of localhost).
  S3_PUBLIC_ENDPOINT: optionalString,
  S3_REGION: z.string().min(1).default('us-east-1'),
  S3_ACCESS_KEY_ID: withDevDefault('minioadmin'),
  S3_SECRET_ACCESS_KEY: withDevDefault('minioadmin'),
  S3_FORCE_PATH_STYLE: bool(true),
  S3_BUCKET_ORIGINALS: z.string().min(1).default('originals'),
  S3_BUCKET_PREVIEWS: z.string().min(1).default('previews'),
  S3_BUCKET_KYC: z.string().min(1).default('kyc'),
  // Base URL under which preview objects are publicly readable (CDN in prod).
  S3_PREVIEWS_PUBLIC_URL: withDevDefault('http://localhost:9000/previews'),

  JWT_ACCESS_SECRET: withDevDefault('dev-only-access-secret-change-me'),
  JWT_REFRESH_SECRET: withDevDefault('dev-only-refresh-secret-change-me'),
  JWT_ACCESS_TTL_SECONDS: int(900),
  JWT_REFRESH_TTL_DAYS: int(30),
  PASSWORD_RESET_TTL_MINUTES: int(60),
  // Throttler on/off (e2e tests turn it off, the rate-limit test turns it back on).
  RATE_LIMIT_ENABLED: bool(true),

  SMTP_HOST: z.string().min(1).default('localhost'),
  SMTP_PORT: z.coerce.number().int().positive().default(1025),
  SMTP_SECURE: bool(false),
  SMTP_USER: optionalString,
  SMTP_PASS: optionalString,
  EMAIL_FROM: z
    .string()
    .min(1)
    .default('SketchSquare <no-reply@sketchsquare.local>'),

  FREE_DOWNLOAD_LIMIT: int(20),
  PLATFORM_FEE_BPS: z.coerce.number().int().min(0).max(10000).default(1000),
  MIN_WITHDRAWAL_PAISE: int(50000),
  // Contribution rule: free drawings an architect must have published per paid drawing they already have (0 = rule off).
  CONTRIBUTION_FREE_PER_PAID: int(1),
  // Plagiarism check at publish time: max pHash Hamming distance (of 64 bits) that flags a drawing, and the plot-size window compared.
  PLAGIARISM_PHASH_THRESHOLD: z.coerce.number().int().min(0).max(64).default(8),
  PLAGIARISM_PLOT_TOLERANCE_PCT: z.coerce.number().min(0).max(50).default(5),

  // Razorpay: when the key id/secret are unset the checkout runs in stub mode.
  RAZORPAY_KEY_ID: optionalString,
  RAZORPAY_KEY_SECRET: optionalString,
  RAZORPAY_WEBHOOK_SECRET: optionalString,

  // RazorpayX payouts: the real provider only activates when PAYOUT_PROVIDER=razorpayx and keys are set.
  PAYOUT_PROVIDER: z.enum(['stub', 'razorpayx']).default('stub'),
  RAZORPAYX_KEY_ID: optionalString,
  RAZORPAYX_KEY_SECRET: optionalString,
  RAZORPAYX_ACCOUNT_NUMBER: optionalString,
  RAZORPAYX_WEBHOOK_SECRET: optionalString,
  // Stub payouts settle after this delay so the app can show the in-progress state (0 = immediately).
  STUB_PAYOUT_DELAY_MS: int(2000),
});

export type Env = z.infer<typeof envSchema>;

export function validateEnv(raw: Record<string, unknown>): Env {
  // `FOO=` lines in a .env file arrive as empty strings; treat them as unset.
  const cleaned = Object.fromEntries(
    Object.entries(raw).filter(([, v]) => v !== ''),
  );
  const result = envSchema.safeParse(cleaned);
  if (!result.success) {
    const issues = result.error.issues
      .map((i) => `  - ${i.path.join('.')}: ${i.message}`)
      .join('\n');
    throw new Error(`Invalid environment configuration:\n${issues}`);
  }
  return result.data;
}
