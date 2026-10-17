import { Inject, Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
  DeleteObjectCommand,
  GetObjectCommand,
  HeadObjectCommand,
  PutObjectCommand,
  S3Client,
} from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { createHash } from 'node:crypto';
import { Readable } from 'node:stream';
import { Env } from '../config/env.schema';
import { S3_CLIENT } from './storage.constants';

export const UPLOAD_URL_TTL_SECONDS = 900;
export const DOWNLOAD_URL_TTL_SECONDS = 300;

export interface ObjectHead {
  sizeBytes: number;
  contentType: string | undefined;
}

export interface PresignedUpload {
  uploadUrl: string;
  headers: Record<string, string>;
}

function isNotFound(err: unknown): boolean {
  const e = err as {
    name?: string;
    $metadata?: { httpStatusCode?: number };
  };
  return (
    e?.name === 'NotFound' ||
    e?.name === 'NoSuchKey' ||
    e?.$metadata?.httpStatusCode === 404
  );
}

async function streamToBuffer(body: unknown): Promise<Buffer> {
  const chunks: Buffer[] = [];
  for await (const chunk of body as Readable) {
    chunks.push(
      Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk as Uint8Array),
    );
  }
  return Buffer.concat(chunks);
}

/** Thin, typed wrapper over S3 for the buckets the app uses. Originals and previews are separate buckets. */
@Injectable()
export class StorageService {
  private readonly signer: S3Client;
  private readonly originals: string;
  private readonly previews: string;
  private readonly previewsBaseUrl: string;

  constructor(
    @Inject(S3_CLIENT) private readonly s3: S3Client,
    config: ConfigService<Env, true>,
  ) {
    this.originals = config.get('S3_BUCKET_ORIGINALS', { infer: true });
    this.previews = config.get('S3_BUCKET_PREVIEWS', { infer: true });
    this.previewsBaseUrl = config
      .get('S3_PREVIEWS_PUBLIC_URL', { infer: true })
      .replace(/\/+$/, '');
    const publicEndpoint = config.get('S3_PUBLIC_ENDPOINT', { infer: true });
    // Presigned URLs embed the host in the signature, so sign with the endpoint clients can actually reach.
    this.signer = publicEndpoint
      ? new S3Client({
          endpoint: publicEndpoint,
          region: config.get('S3_REGION', { infer: true }),
          forcePathStyle: config.get('S3_FORCE_PATH_STYLE', { infer: true }),
          credentials: {
            accessKeyId: config.get('S3_ACCESS_KEY_ID', { infer: true }),
            secretAccessKey: config.get('S3_SECRET_ACCESS_KEY', {
              infer: true,
            }),
          },
        })
      : s3;
  }

  /**
   * Presigned PUT for the private originals bucket; the type is part of the signature, and so is the exact length
   * when `sizeBytes` is given (callers that cannot know it up front must verify the size after upload).
   */
  async presignOriginalUpload(params: {
    key: string;
    contentType: string;
    sizeBytes?: number;
    expiresInSeconds?: number;
  }): Promise<PresignedUpload> {
    const command = new PutObjectCommand({
      Bucket: this.originals,
      Key: params.key,
      ContentType: params.contentType,
      ContentLength: params.sizeBytes,
    });
    const signable = ['content-type'];
    if (params.sizeBytes !== undefined) signable.push('content-length');
    const uploadUrl = await getSignedUrl(this.signer, command, {
      expiresIn: params.expiresInSeconds ?? UPLOAD_URL_TTL_SECONDS,
      signableHeaders: new Set(signable),
    });
    return { uploadUrl, headers: { 'Content-Type': params.contentType } };
  }

  /** Short-lived (5 min) GET link for an object in the originals bucket; callers must have checked entitlement. */
  presignOriginalDownload(key: string, fileName?: string): Promise<string> {
    return getSignedUrl(
      this.signer,
      new GetObjectCommand({
        Bucket: this.originals,
        Key: key,
        ResponseContentDisposition: fileName
          ? `attachment; filename="${fileName.replace(/["\\\r\n]/g, '_')}"`
          : undefined,
      }),
      { expiresIn: DOWNLOAD_URL_TTL_SECONDS },
    );
  }

  async headOriginal(key: string): Promise<ObjectHead | null> {
    try {
      const out = await this.s3.send(
        new HeadObjectCommand({ Bucket: this.originals, Key: key }),
      );
      return {
        sizeBytes: out.ContentLength ?? 0,
        contentType: out.ContentType,
      };
    } catch (err) {
      if (isNotFound(err)) return null;
      throw err;
    }
  }

  async originalsObjectExists(key: string): Promise<boolean> {
    return (await this.headOriginal(key)) !== null;
  }

  /** Reads `length` bytes from the start of an original (magic-byte sniffing without downloading everything). */
  async readOriginalHead(key: string, length: number): Promise<Buffer> {
    const out = await this.s3.send(
      new GetObjectCommand({
        Bucket: this.originals,
        Key: key,
        Range: `bytes=0-${Math.max(0, length - 1)}`,
      }),
    );
    return streamToBuffer(out.Body);
  }

  async getOriginalBuffer(key: string): Promise<Buffer> {
    const out = await this.s3.send(
      new GetObjectCommand({ Bucket: this.originals, Key: key }),
    );
    return streamToBuffer(out.Body);
  }

  /** SHA-256 of an original, streamed so 50 MB files don't sit in memory. */
  async sha256Original(key: string): Promise<string> {
    const out = await this.s3.send(
      new GetObjectCommand({ Bucket: this.originals, Key: key }),
    );
    const hash = createHash('sha256');
    for await (const chunk of out.Body as Readable)
      hash.update(chunk as Buffer);
    return hash.digest('hex');
  }

  async putOriginal(
    key: string,
    body: Buffer,
    contentType: string,
  ): Promise<void> {
    await this.s3.send(
      new PutObjectCommand({
        Bucket: this.originals,
        Key: key,
        Body: body,
        ContentType: contentType,
      }),
    );
  }

  async deleteOriginal(key: string): Promise<void> {
    await this.s3.send(
      new DeleteObjectCommand({ Bucket: this.originals, Key: key }),
    );
  }

  async putPreview(key: string, body: Buffer): Promise<void> {
    await this.s3.send(
      new PutObjectCommand({
        Bucket: this.previews,
        Key: key,
        Body: body,
        ContentType: 'image/png',
        CacheControl: 'public, max-age=31536000, immutable',
      }),
    );
  }

  /** Public URL of a (watermarked) preview object. Originals never get a public URL. */
  previewUrl(key: string | null | undefined): string | null {
    return key ? `${this.previewsBaseUrl}/${key}` : null;
  }
}
