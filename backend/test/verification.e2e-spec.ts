import { GetObjectCommand, S3Client } from '@aws-sdk/client-s3';
import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { Role, VerificationStatus } from '@prisma/client';
import request from 'supertest';
import { App } from 'supertest/types';
import { AppModule } from '../src/app.module';
import { configureApp } from '../src/app.setup';
import { PrismaService } from '../src/prisma/prisma.service';
import { S3_CLIENT } from '../src/storage/storage.constants';
import { bearer, createTestUser, TestUser } from './helpers/auth';
import { resetDb } from './helpers/db';
import { waitForEmail } from './helpers/mailpit';

const PDF = Buffer.from('%PDF-1.7\n%fake coa certificate\n');
const PNG = Buffer.concat([
  Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
  Buffer.alloc(32),
]);
const errCode = (body: unknown) =>
  (body as { error: { code: string } }).error.code;

describe('Verification + admin review (e2e)', () => {
  let app: INestApplication<App>;
  let prisma: PrismaService;
  const http = () => request(app.getHttpServer());
  let seq = 0;
  const pending = (overrides = {}) =>
    createTestUser(app, {
      email: `ver-${Date.now()}-${seq++}@example.com`,
      verificationStatus: VerificationStatus.PENDING,
      ...overrides,
    });
  const submit = (
    u: TestUser,
    opts: { coa?: string; file?: Buffer; name?: string } = {},
  ) => {
    return http()
      .post('/verification')
      .set(...bearer(u))
      .field('coaRegistrationNumber', opts.coa ?? 'CA/2015/12345')
      .attach('document', opts.file ?? PDF, opts.name ?? 'coa.pdf');
  };

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();
    app = moduleRef.createNestApplication();
    configureApp(app);
    await app.init();
    prisma = app.get(PrismaService);
  });

  beforeEach(() => resetDb(prisma));
  afterAll(async () => {
    await resetDb(prisma);
    await app.close();
  });

  describe('POST /verification, GET /verification/me', () => {
    it('stores the document in the kyc bucket and creates a PENDING request', async () => {
      const u = await pending();
      expect(
        (
          await http()
            .get('/verification/me')
            .set(...bearer(u))
            .expect(200)
        ).body,
      ).toEqual({ verification: null });

      const res = await submit(u, { coa: 'CA/2015/12345' }).expect(201);
      expect(res.body).toMatchObject({
        coaRegistrationNumber: 'CA/2015/12345',
        status: 'PENDING',
        reviewNote: null,
        reviewedAt: null,
      });
      expect(res.body).not.toHaveProperty('documentKey');

      const row = await prisma.verificationRequest.findFirstOrThrow({
        where: { userId: u.user.id },
      });
      expect(row.documentKey).toMatch(
        new RegExp(`^verification/${u.user.id}/.+\\.pdf$`),
      );
      const s3 = app.get<S3Client>(S3_CLIENT);
      const obj = await s3.send(
        new GetObjectCommand({ Bucket: 'kyc', Key: row.documentKey }),
      );
      expect(Buffer.from(await obj.Body!.transformToByteArray())).toEqual(PDF);

      const me = await http()
        .get('/verification/me')
        .set(...bearer(u))
        .expect(200);
      expect(
        (me.body as { verification: { id: string } }).verification.id,
      ).toBe(row.id);
    });

    it('rejects missing file, wrong type (even with .pdf name), bad COA number and oversize files', async () => {
      const u = await pending();
      const noFile = await http()
        .post('/verification')
        .set(...bearer(u))
        .field('coaRegistrationNumber', 'CA/2015/12345')
        .expect(400);
      expect(errCode(noFile.body)).toBe('UPLOAD_INVALID');

      const wrongType = await submit(u, {
        file: Buffer.from('MZ not a document'),
        name: 'coa.pdf',
      }).expect(400);
      expect(errCode(wrongType.body)).toBe('UPLOAD_INVALID');

      const badCoa = await submit(u, { coa: '!!' }).expect(400);
      expect(errCode(badCoa.body)).toBe('VALIDATION_ERROR');

      const big = Buffer.concat([PDF, Buffer.alloc(10 * 1024 * 1024)]);
      const tooBig = await submit(u, { file: big }).expect(413);
      expect(errCode(tooBig.body)).toBe('UPLOAD_INVALID');

      expect(await prisma.verificationRequest.count()).toBe(0);
    });

    it('requires a token and refuses APPROVED users and admins', async () => {
      await http().post('/verification').expect(401);
      const approved = await createTestUser(app);
      const res = await submit(approved).expect(409);
      expect(errCode(res.body)).toBe('CONFLICT');
      const admin = await createTestUser(app, { role: Role.ADMIN });
      await submit(admin).expect(403);
    });

    it('resubmitting while PENDING replaces the request (one row, old document removed)', async () => {
      const u = await pending();
      await submit(u, { coa: 'CA/2015/11111' }).expect(201);
      const first = await prisma.verificationRequest.findFirstOrThrow();
      await submit(u, {
        coa: 'CA/2015/22222',
        file: PNG,
        name: 'id.png',
      }).expect(201);
      const rows = await prisma.verificationRequest.findMany();
      expect(rows).toHaveLength(1);
      expect(rows[0]).toMatchObject({
        id: first.id,
        coaRegistrationNumber: 'CA/2015/22222',
      });
      expect(rows[0].documentKey).toMatch(/\.png$/);
      expect(rows[0].documentKey).not.toBe(first.documentKey);
    });
  });

  describe('admin review', () => {
    let admin: TestUser;
    beforeEach(async () => {
      admin = await createTestUser(app, { role: Role.ADMIN });
    });

    it('is forbidden for architects and anonymous callers', async () => {
      const arch = await createTestUser(app);
      await http().get('/admin/verifications').expect(401);
      const res = await http()
        .get('/admin/verifications')
        .set(...bearer(arch))
        .expect(403);
      expect(errCode(res.body)).toBe('FORBIDDEN');
      const id = '00000000-0000-4000-8000-000000000000';
      await http()
        .post(`/admin/verifications/${id}/approve`)
        .set(...bearer(arch))
        .expect(403);
      await http()
        .post(`/admin/verifications/${id}/reject`)
        .set(...bearer(arch))
        .send({ note: 'x' })
        .expect(403);
    });

    it('lists pending requests oldest-first with pagination and status filter', async () => {
      const users = [await pending(), await pending(), await pending()];
      for (const u of users) await submit(u).expect(201);

      const p1 = await http()
        .get('/admin/verifications?limit=2')
        .set(...bearer(admin))
        .expect(200);
      const b1 = p1.body as {
        items: { id: string; user: { email: string }; status: string }[];
        nextCursor: string | null;
      };
      expect(b1.items.map((i) => i.user.email)).toEqual([
        users[0].user.email,
        users[1].user.email,
      ]);
      expect(b1.items[0]).toMatchObject({
        status: 'PENDING',
        coaRegistrationNumber: 'CA/2015/12345',
      });
      expect(b1.items[0].user).toHaveProperty('address');
      expect(b1.nextCursor).toBeTruthy();

      const p2 = await http()
        .get(`/admin/verifications?limit=2&cursor=${b1.nextCursor}`)
        .set(...bearer(admin))
        .expect(200);
      const b2 = p2.body as typeof b1;
      expect(b2.items.map((i) => i.user.email)).toEqual([users[2].user.email]);
      expect(b2.nextCursor).toBeNull();

      const approved = await http()
        .get('/admin/verifications?status=APPROVED')
        .set(...bearer(admin))
        .expect(200);
      expect((approved.body as typeof b1).items).toHaveLength(0);
      await http()
        .get('/admin/verifications?status=BOGUS')
        .set(...bearer(admin))
        .expect(400);
    });

    it('detail returns a presigned document URL that serves the uploaded file', async () => {
      const u = await pending();
      await submit(u).expect(201);
      const row = await prisma.verificationRequest.findFirstOrThrow();
      const res = await http()
        .get(`/admin/verifications/${row.id}`)
        .set(...bearer(admin))
        .expect(200);
      const body = res.body as { documentUrl: string; reviewNote: null };
      expect(body.reviewNote).toBeNull();
      const file = await fetch(body.documentUrl);
      expect(file.status).toBe(200);
      expect(Buffer.from(await file.arrayBuffer())).toEqual(PDF);
      await http()
        .get('/admin/verifications/00000000-0000-4000-8000-000000000000')
        .set(...bearer(admin))
        .expect(404);
      await http()
        .get('/admin/verifications/not-a-uuid')
        .set(...bearer(admin))
        .expect(400);
    });

    it('approve: user becomes APPROVED, audit row written, welcome email delivered, second review is 409', async () => {
      const u = await pending();
      await submit(u).expect(201);
      const row = await prisma.verificationRequest.findFirstOrThrow();

      await http()
        .post(`/admin/verifications/${row.id}/approve`)
        .set(...bearer(admin))
        .expect(201)
        .expect({ ok: true });

      expect(
        (await prisma.user.findUniqueOrThrow({ where: { id: u.user.id } }))
          .verificationStatus,
      ).toBe('APPROVED');
      expect(
        await prisma.verificationRequest.findUniqueOrThrow({
          where: { id: row.id },
        }),
      ).toMatchObject({ status: 'APPROVED', reviewerId: admin.user.id });
      expect(
        await prisma.auditLog.count({
          where: { action: 'verification.approve', entityId: row.id },
        }),
      ).toBe(1);

      const mail = await waitForEmail(u.user.email, 'Welcome to SketchSquare');
      expect(mail.HTML).toContain('Hi Test Architect');

      const again = await http()
        .post(`/admin/verifications/${row.id}/approve`)
        .set(...bearer(admin))
        .expect(409);
      expect(errCode(again.body)).toBe('CONFLICT');
      await http()
        .post(`/admin/verifications/${row.id}/reject`)
        .set(...bearer(admin))
        .send({ note: 'late' })
        .expect(409);
    });

    it('reject: needs a note, stores it, emails the reason, and the architect can resubmit', async () => {
      const u = await pending();
      await submit(u).expect(201);
      const row = await prisma.verificationRequest.findFirstOrThrow();

      await http()
        .post(`/admin/verifications/${row.id}/reject`)
        .set(...bearer(admin))
        .send({})
        .expect(400);
      await http()
        .post(`/admin/verifications/${row.id}/reject`)
        .set(...bearer(admin))
        .send({ note: 'COA number does not match the certificate' })
        .expect(201)
        .expect({ ok: true });

      const mail = await waitForEmail(u.user.email, 'needs attention');
      expect(mail.Text).toContain('COA number does not match the certificate');

      const me = await http()
        .get('/verification/me')
        .set(...bearer(u))
        .expect(200);
      expect((me.body as { verification: object }).verification).toMatchObject({
        status: 'REJECTED',
        reviewNote: 'COA number does not match the certificate',
      });
      expect(
        (await prisma.user.findUniqueOrThrow({ where: { id: u.user.id } }))
          .verificationStatus,
      ).toBe('REJECTED');

      // resubmission after rejection creates a new PENDING request and resets the user's status
      await submit(u, { coa: 'CA/2015/99999' }).expect(201);
      expect(
        (await prisma.user.findUniqueOrThrow({ where: { id: u.user.id } }))
          .verificationStatus,
      ).toBe('PENDING');
      const latest = await http()
        .get('/verification/me')
        .set(...bearer(u))
        .expect(200);
      expect(
        (latest.body as { verification: { status: string } }).verification
          .status,
      ).toBe('PENDING');
      expect(await prisma.verificationRequest.count()).toBe(2);
    });
  });
});
