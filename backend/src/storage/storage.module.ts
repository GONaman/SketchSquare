import { Global, Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { S3Client } from '@aws-sdk/client-s3';
import { Env } from '../config/env.schema';
import { S3_CLIENT } from './storage.constants';
import { StorageService } from './storage.service';

export { S3_CLIENT };

/** Provides the raw S3 client (MinIO locally, S3/R2 in prod). `StorageService` builds on top of it. */
@Global()
@Module({
  providers: [
    {
      provide: S3_CLIENT,
      inject: [ConfigService],
      useFactory: (config: ConfigService<Env, true>) =>
        new S3Client({
          endpoint: config.get('S3_ENDPOINT', { infer: true }),
          region: config.get('S3_REGION', { infer: true }),
          forcePathStyle: config.get('S3_FORCE_PATH_STYLE', { infer: true }),
          credentials: {
            accessKeyId: config.get('S3_ACCESS_KEY_ID', { infer: true }),
            secretAccessKey: config.get('S3_SECRET_ACCESS_KEY', {
              infer: true,
            }),
          },
        }),
    },
    StorageService,
  ],
  exports: [S3_CLIENT, StorageService],
})
export class StorageModule {}
