import { Inject, Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { HeadBucketCommand, S3Client } from '@aws-sdk/client-s3';
import Redis from 'ioredis';
import { Env } from '../config/env.schema';
import { PrismaService } from '../prisma/prisma.service';
import { REDIS_CLIENT } from '../redis/redis.module';
import { S3_CLIENT } from '../storage/storage.module';

export type CheckState = 'up' | 'down';

export interface HealthReport {
  status: 'ok' | 'error';
  checks: { db: CheckState; redis: CheckState; s3: CheckState };
}

const CHECK_TIMEOUT_MS = 2000;

async function probe(fn: () => Promise<unknown>): Promise<CheckState> {
  let timer: NodeJS.Timeout | undefined;
  try {
    await Promise.race([
      fn(),
      new Promise((_, reject) => {
        timer = setTimeout(
          () => reject(new Error('timeout')),
          CHECK_TIMEOUT_MS,
        );
      }),
    ]);
    return 'up';
  } catch {
    return 'down';
  } finally {
    clearTimeout(timer);
  }
}

@Injectable()
export class HealthService {
  constructor(
    private readonly prisma: PrismaService,
    @Inject(REDIS_CLIENT) private readonly redis: Redis,
    @Inject(S3_CLIENT) private readonly s3: S3Client,
    private readonly config: ConfigService<Env, true>,
  ) {}

  async check(): Promise<HealthReport> {
    const [db, redis, s3] = await Promise.all([
      probe(() => this.prisma.$queryRaw`SELECT 1`),
      probe(() => this.redis.ping()),
      probe(() =>
        this.s3.send(
          new HeadBucketCommand({
            Bucket: this.config.get('S3_BUCKET_PREVIEWS', { infer: true }),
          }),
        ),
      ),
    ]);
    const checks = { db, redis, s3 };
    const ok = Object.values(checks).every((c) => c === 'up');
    return { status: ok ? 'ok' : 'error', checks };
  }
}
