import './helpers/enable-write-limit';
import { INestApplication } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import request from 'supertest';
import { App } from 'supertest/types';
import { Role, VerificationStatus } from '@prisma/client';
import { randomUUID } from 'node:crypto';
import { buildCommerceApp } from './helpers/commerce-app';
import { bearer, createTestUser } from './helpers/auth';
import { resetDb } from './helpers/db';
import { PrismaService } from '../src/prisma/prisma.service';
import { StorageService } from '../src/storage/storage.service';

const errorCode = (body: unknown) =>
  (body as { error: { code: string } }).error.code;

describe('Security hardening (e2e)', () => {
  let app: INestApplication<App>;
  let prisma: PrismaService;
  const http = () => request(app.getHttpServer());

  beforeAll(async () => {
    ({ app, prisma } = await buildCommerceApp());
  });
  beforeEach(() => resetDb(prisma));
  afterAll(async () => {
    await resetDb(prisma);
    await app.close();
  });

  describe('headers and CORS', () => {
    it('sends helmet headers and hides the framework', async () => {
      const res = await http().get('/health');
      expect(res.headers['x-content-type-options']).toBe('nosniff');
      expect(res.headers['strict-transport-security']).toBeDefined();
      expect(res.headers['x-frame-options']).toBeDefined();
      expect(res.headers['x-powered-by']).toBeUndefined();
    });

    it('answers preflight only for allow-listed origins', async () => {
      const allowed = await http()
        .options('/auth/login')
        .set('Origin', 'https://admin.example.com')
        .set('Access-Control-Request-Method', 'POST');
      expect(allowed.headers['access-control-allow-origin']).toBe(
        'https://admin.example.com',
      );

      const denied = await http()
        .options('/auth/login')
        .set('Origin', 'https://evil.example.com')
        .set('Access-Control-Request-Method', 'POST');
      expect(denied.headers['access-control-allow-origin']).toBeUndefined();
    });

    it('does not reflect a disallowed origin on normal responses', async () => {
      const res = await http()
        .get('/health')
        .set('Origin', 'https://evil.example.com');
      expect(res.headers['access-control-allow-origin']).toBeUndefined();
    });
  });

  describe('request size limit', () => {
    it('rejects an oversized JSON body before it reaches a handler', async () => {
      const res = await http()
        .post('/auth/login')
        .send({ email: 'a@example.com', password: 'x'.repeat(200 * 1024) });
      expect(res.status).toBe(413);
      expect(errorCode(res.body)).toBe('UPLOAD_INVALID');
    });
  });

  describe('write rate limit', () => {
    it('limits every non-GET route per client, but not reads', async () => {
      const user = await createTestUser(app);
      const post = () =>
        http()
          .post('/category-requests')
          .set(...bearer(user))
          .send({ name: 'Rate limited category' });
      for (let i = 0; i < 5; i++) {
        expect((await post()).status).toBeLessThan(429);
      }
      const limited = await post();
      expect(limited.status).toBe(429);
      expect(errorCode(limited.body)).toBe('RATE_LIMITED');

      for (let i = 0; i < 10; i++) {
        await http()
          .get('/categories')
          .set(...bearer(user))
          .expect(200);
      }
    });
  });

  describe('admin audit log', () => {
    it('records category request approve and reject with the acting admin', async () => {
      const admin = await createTestUser(app, {
        role: Role.ADMIN,
        verificationStatus: VerificationStatus.PENDING,
      });
      const member = await createTestUser(app);
      const [a, b] = await Promise.all(
        ['Pavilions', 'Bunkers'].map((requestedName) =>
          prisma.categoryRequest.create({
            data: { userId: member.user.id, requestedName },
          }),
        ),
      );

      await http()
        .post(`/admin/category-requests/${a.id}/approve`)
        .set(...bearer(admin))
        .expect(200);
      await http()
        .post(`/admin/category-requests/${b.id}/reject`)
        .set(...bearer(admin))
        .expect(200);
      // A failed (conflicting) review must not leave an audit row behind.
      await http()
        .post(`/admin/category-requests/${b.id}/reject`)
        .set(...bearer(admin))
        .expect(409);

      const rows = await prisma.auditLog.findMany({
        orderBy: { createdAt: 'asc' },
      });
      expect(rows.map((r) => [r.action, r.entityId, r.actorId])).toEqual([
        ['category-request.approve', a.id, admin.user.id],
        ['category-request.reject', b.id, admin.user.id],
      ]);
    });
  });

  describe('object storage exposure', () => {
    it('serves nothing anonymously from originals or kyc, but previews are public-read', async () => {
      const config = app.get(ConfigService);
      const base = config.getOrThrow<string>('S3_ENDPOINT').replace(/\/+$/, '');
      const probe = async (bucketKey: string) =>
        (
          await fetch(
            `${base}/${config.getOrThrow<string>(bucketKey)}/${randomUUID()}.png`,
          )
        ).status;
      // Anonymous requests to a private bucket are denied (403) even for missing keys; a public-read bucket says 404.
      expect(await probe('S3_BUCKET_ORIGINALS')).toBe(403);
      expect(await probe('S3_BUCKET_KYC')).toBe(403);
      expect(await probe('S3_BUCKET_PREVIEWS')).toBe(404);
    });

    it('presigned links are short-lived', async () => {
      const storage = app.get(StorageService);
      const expires = (url: string) =>
        Number(new URL(url).searchParams.get('X-Amz-Expires'));
      expect(expires(await storage.presignOriginalDownload('k/file.pdf'))).toBe(
        300,
      );
      const upload = await storage.presignOriginalUpload({
        key: 'k/file.pdf',
        contentType: 'application/pdf',
        sizeBytes: 10,
      });
      expect(expires(upload.uploadUrl)).toBeLessThanOrEqual(900);
    });
  });
});
