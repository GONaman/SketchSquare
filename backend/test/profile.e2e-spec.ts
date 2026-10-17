/* eslint-disable @typescript-eslint/no-unsafe-member-access, @typescript-eslint/no-unsafe-argument -- supertest bodies are untyped */
import { INestApplication } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import sharp from 'sharp';
import request from 'supertest';
import { PrismaService } from '../src/prisma/prisma.service';
import { StorageService } from '../src/storage/storage.service';
import { bearer, createTestUser, TestUser } from './helpers/auth';
import { buildCommerceApp } from './helpers/commerce-app';
import { resetDb } from './helpers/db';

describe('Profile (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let storage: StorageService;
  let user: TestUser;

  const http = () => request(app.getHttpServer());

  const png = (width: number, height: number) =>
    sharp({
      create: {
        width,
        height,
        channels: 3,
        background: { r: 200, g: 30, b: 30 },
      },
    })
      .png()
      .toBuffer();

  async function uploadUrl(u: TestUser, contentType = 'image/png') {
    const res = await http()
      .post('/me/avatar/upload-url')
      .set(...bearer(u))
      .send({ contentType })
      .expect(200);
    return res.body as {
      uploadUrl: string;
      objectKey: string;
      headers: Record<string, string>;
    };
  }

  async function put(
    target: { uploadUrl: string },
    body: Buffer,
    type = 'image/png',
  ) {
    const res = await fetch(target.uploadUrl, {
      method: 'PUT',
      headers: { 'Content-Type': type },
      body: new Uint8Array(body),
    });
    expect(res.status).toBe(200);
  }

  const confirm = (u: TestUser, objectKey: string) =>
    http()
      .post('/me/avatar/confirm')
      .set(...bearer(u))
      .send({ objectKey });

  beforeAll(async () => {
    ({ app, prisma } = await buildCommerceApp());
    storage = app.get(StorageService);
  });

  afterAll(async () => {
    await app.close();
  });

  beforeEach(async () => {
    await resetDb(prisma);
    user = await createTestUser(app, { fullName: 'Asha Rao', city: 'Pune' });
  });

  describe('GET /me', () => {
    it('returns the contract User shape without secrets', async () => {
      const res = await http()
        .get('/me')
        .set(...bearer(user))
        .expect(200);
      expect(res.body).toMatchObject({
        id: user.user.id,
        email: user.user.email,
        fullName: 'Asha Rao',
        city: 'Pune',
        role: 'ARCHITECT',
        verificationStatus: 'APPROVED',
        avatarUrl: null,
        freeDownloadsUsed: 0,
        freeDownloadLimit: 20,
      });
      expect(res.body).toHaveProperty('address');
      expect(res.body).toHaveProperty('phone');
      expect(res.body).toHaveProperty('architectRating');
      expect(res.body).toHaveProperty('createdAt');
      expect(JSON.stringify(res.body)).not.toMatch(/passwordHash/i);
    });

    it('works for users who are not verified yet', async () => {
      const pending = await createTestUser(app, {
        verificationStatus: 'PENDING',
      });
      const res = await http()
        .get('/me')
        .set(...bearer(pending))
        .expect(200);
      expect(res.body.verificationStatus).toBe('PENDING');
    });

    it('requires a token', async () => {
      await http().get('/me').expect(401);
    });
  });

  describe('PATCH /me', () => {
    it('updates phone and city only', async () => {
      const res = await http()
        .patch('/me')
        .set(...bearer(user))
        .send({ phone: '+91 98765-43210', city: '  Mumbai ' })
        .expect(200);
      expect(res.body).toMatchObject({
        phone: '+919876543210',
        city: 'Mumbai',
        fullName: 'Asha Rao',
      });
      const row = await prisma.user.findUniqueOrThrow({
        where: { id: user.user.id },
      });
      expect(row.phone).toBe('+919876543210');
      expect(row.city).toBe('Mumbai');
    });

    it('can update a single field', async () => {
      const res = await http()
        .patch('/me')
        .set(...bearer(user))
        .send({ city: 'Delhi' })
        .expect(200);
      expect(res.body.city).toBe('Delhi');
      expect(res.body.phone).toBe(user.user.phone);
    });

    it('works while verification is pending', async () => {
      const pending = await createTestUser(app, {
        verificationStatus: 'PENDING',
      });
      await http()
        .patch('/me')
        .set(...bearer(pending))
        .send({ city: 'Kochi' })
        .expect(200);
    });

    it.each([
      ['fullName', 'Someone Else'],
      ['address', '5 New Street'],
    ])(
      'rejects %s with "cannot be changed" and changes nothing',
      async (field, value) => {
        const res = await http()
          .patch('/me')
          .set(...bearer(user))
          .send({ city: 'Chennai', [field]: value })
          .expect(400);
        expect(res.body.error.code).toBe('VALIDATION_ERROR');
        expect(res.body.error.message).toContain('cannot be changed');
        const row = await prisma.user.findUniqueOrThrow({
          where: { id: user.user.id },
        });
        expect(row.city).toBe('Pune');
        expect(row.fullName).toBe('Asha Rao');
        expect(row.address).toBe('1 Test Street');
      },
    );

    it('rejects other fields, bad values and empty bodies', async () => {
      for (const body of [
        { role: 'ADMIN' },
        { email: 'x@example.com' },
        { verificationStatus: 'APPROVED' },
        { phone: '12' },
        { phone: 'abcdefghijk' },
        { city: '' },
        { city: 'x'.repeat(101) },
        {},
      ]) {
        await http()
          .patch('/me')
          .set(...bearer(user))
          .send(body)
          .expect(400);
      }
      const row = await prisma.user.findUniqueOrThrow({
        where: { id: user.user.id },
      });
      expect(row.role).toBe('ARCHITECT');
    });

    it('requires a token', async () => {
      await http().patch('/me').send({ city: 'X' }).expect(401);
    });
  });

  describe('avatar', () => {
    it('validates the content type', async () => {
      for (const contentType of [
        'image/gif',
        'application/pdf',
        'text/plain',
      ]) {
        await http()
          .post('/me/avatar/upload-url')
          .set(...bearer(user))
          .send({ contentType })
          .expect(400);
      }
      await http()
        .post('/me/avatar/upload-url')
        .send({ contentType: 'image/png' })
        .expect(401);
    });

    it('uploads, resizes to 512px and publishes the avatar', async () => {
      const target = await uploadUrl(user);
      expect(target.objectKey).toMatch(
        new RegExp(`^avatar-uploads/${user.user.id}/[0-9a-f-]{36}\\.png$`),
      );
      await put(target, await png(1200, 800));

      const res = await confirm(user, target.objectKey).expect(200);
      expect(res.body.id).toBe(user.user.id);
      expect(res.body.avatarUrl).toMatch(
        new RegExp(`/avatars/${user.user.id}/[0-9a-f-]{36}\\.png$`),
      );
      expect(
        (await prisma.user.findUniqueOrThrow({ where: { id: user.user.id } }))
          .avatarUrl,
      ).toBe(res.body.avatarUrl);

      const img = await fetch(res.body.avatarUrl);
      expect(img.status).toBe(200);
      const meta = await sharp(Buffer.from(await img.arrayBuffer())).metadata();
      expect(meta).toMatchObject({ format: 'png', width: 512, height: 512 });

      // The raw upload is gone and cannot be confirmed again.
      expect(await storage.headOriginal(target.objectKey)).toBeNull();
      await confirm(user, target.objectKey).expect(400);
    });

    it('accepts jpeg and webp and a replaced avatar gets a new URL', async () => {
      const first = await uploadUrl(user, 'image/jpeg');
      await put(
        first,
        await sharp(await png(300, 300))
          .jpeg()
          .toBuffer(),
        'image/jpeg',
      );
      const a = await confirm(user, first.objectKey).expect(200);

      const second = await uploadUrl(user, 'image/webp');
      await put(
        second,
        await sharp(await png(100, 400))
          .webp()
          .toBuffer(),
        'image/webp',
      );
      const b = await confirm(user, second.objectKey).expect(200);
      expect(b.body.avatarUrl).not.toBe(a.body.avatarUrl);
    });

    it('rejects a missing upload', async () => {
      const target = await uploadUrl(user);
      const res = await confirm(user, target.objectKey).expect(400);
      expect(res.body.error.code).toBe('VALIDATION_ERROR');
    });

    it('rejects content that is not an image, and deletes it', async () => {
      const target = await uploadUrl(user);
      await put(target, Buffer.from('<?php echo 1; ?> definitely not a png'));
      await confirm(user, target.objectKey).expect(400);
      expect(await storage.headOriginal(target.objectKey)).toBeNull();
      expect(
        (await prisma.user.findUniqueOrThrow({ where: { id: user.user.id } }))
          .avatarUrl,
      ).toBeNull();
    });

    it('rejects images over 5 MB, and deletes them', async () => {
      const target = await uploadUrl(user);
      await put(target, Buffer.alloc(5 * 1024 * 1024 + 1, 1));
      const res = await confirm(user, target.objectKey).expect(400);
      expect(res.body.error.message).toContain('too large');
      expect(await storage.headOriginal(target.objectKey)).toBeNull();
    });

    it("cannot confirm someone else's upload or arbitrary keys", async () => {
      const other = await createTestUser(app);
      const theirs = await uploadUrl(other);
      await put(theirs, await png(64, 64));
      await confirm(user, theirs.objectKey).expect(400);
      expect(await storage.headOriginal(theirs.objectKey)).not.toBeNull();

      const original = `drawings/${randomUUID()}/plan.pdf`;
      for (const key of [
        original,
        `avatar-uploads/${user.user.id}/../${other.user.id}/${randomUUID()}.png`,
        `avatar-uploads/${user.user.id}/${randomUUID()}.pdf`,
        '',
      ]) {
        await confirm(user, key).expect(400);
      }
      expect(
        (await prisma.user.findUniqueOrThrow({ where: { id: other.user.id } }))
          .avatarUrl,
      ).toBeNull();
    });

    it('works while verification is pending', async () => {
      const pending = await createTestUser(app, {
        verificationStatus: 'PENDING',
      });
      const target = await uploadUrl(pending);
      await put(target, await png(64, 64));
      await confirm(pending, target.objectKey).expect(200);
    });
  });
});
