import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { App } from 'supertest/types';
import { AppModule } from '../src/app.module';
import { configureApp } from '../src/app.setup';
import { PrismaService } from '../src/prisma/prisma.service';
import { createTestUser } from './helpers/auth';
import { resetDb } from './helpers/db';
import { countEmails, waitForEmail } from './helpers/mailpit';

interface AuthBody {
  user: Record<string, unknown>;
  tokens: { accessToken: string; refreshToken: string; expiresIn: number };
}
const errCode = (body: unknown) =>
  (body as { error: { code: string } }).error.code;

describe('Auth endpoints (e2e)', () => {
  let app: INestApplication<App>;
  let prisma: PrismaService;
  const http = () => request(app.getHttpServer());
  const signupBody = (email: string) => ({
    email,
    password: 'Sup3rSecret!',
    fullName: 'Asha Rao',
    phone: '+91 98765-43210',
    address: '12 MG Road',
    city: 'Bengaluru',
  });
  let seq = 0;
  const uniqueEmail = () => `auth-${Date.now()}-${seq++}@example.com`;

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

  describe('signup', () => {
    it('creates a PENDING architect and returns user + tokens', async () => {
      const email = uniqueEmail();
      const res = await http()
        .post('/auth/signup')
        .send(signupBody(email.toUpperCase()))
        .expect(201);
      const body = res.body as AuthBody;
      expect(body.user).toMatchObject({
        email,
        role: 'ARCHITECT',
        verificationStatus: 'PENDING',
        phone: '+919876543210',
        freeDownloadsUsed: 0,
        freeDownloadLimit: 20,
        architectRating: 0,
        avatarUrl: null,
      });
      expect(body.user).not.toHaveProperty('passwordHash');
      expect(body.tokens.expiresIn).toBe(900);

      const row = await prisma.user.findUniqueOrThrow({ where: { email } });
      expect(row.passwordHash).toMatch(/^\$argon2id\$/);
    });

    it('409 CONFLICT on duplicate email (case-insensitive)', async () => {
      const email = uniqueEmail();
      await http().post('/auth/signup').send(signupBody(email)).expect(201);
      const res = await http()
        .post('/auth/signup')
        .send(signupBody(email.toUpperCase()))
        .expect(409);
      expect(errCode(res.body)).toBe('CONFLICT');
    });

    it('400 VALIDATION_ERROR with field details for bad input', async () => {
      const res = await http()
        .post('/auth/signup')
        .send({ email: 'nope', password: 'short', phone: 'abc' })
        .expect(400);
      const { error } = res.body as {
        error: { code: string; details: { fields: Record<string, string[]> } };
      };
      expect(error.code).toBe('VALIDATION_ERROR');
      expect(Object.keys(error.details.fields)).toEqual(
        expect.arrayContaining([
          'email',
          'password',
          'fullName',
          'phone',
          'address',
          'city',
        ]),
      );
    });

    it('cannot self-assign role or status', async () => {
      await http()
        .post('/auth/signup')
        .send({
          ...signupBody(uniqueEmail()),
          role: 'ADMIN',
          verificationStatus: 'APPROVED',
        })
        .expect(400);
    });
  });

  describe('login', () => {
    it('returns user + tokens for correct credentials (any email casing)', async () => {
      const u = await createTestUser(app, { email: 'login@example.com' });
      const res = await http()
        .post('/auth/login')
        .send({ email: 'Login@Example.com', password: u.password })
        .expect(200);
      const body = res.body as AuthBody;
      expect(body.user.id).toBe(u.user.id);
      expect(body.tokens.refreshToken).toBeTruthy();
    });

    it('wrong password and unknown email give the same 401', async () => {
      const u = await createTestUser(app, { email: 'login2@example.com' });
      const wrong = await http()
        .post('/auth/login')
        .send({ email: u.user.email, password: 'not-the-password' })
        .expect(401);
      const unknown = await http()
        .post('/auth/login')
        .send({ email: 'ghost@example.com', password: 'whatever123' })
        .expect(401);
      expect(errCode(wrong.body)).toBe('UNAUTHORIZED');
      expect(wrong.body).toEqual(unknown.body);
    });
  });

  describe('refresh / logout', () => {
    it('rotates tokens; the old refresh token is dead and its reuse revokes the new one', async () => {
      const u = await createTestUser(app);
      const first = await http()
        .post('/auth/refresh')
        .send({ refreshToken: u.refreshToken })
        .expect(200);
      const { tokens } = first.body as { tokens: AuthBody['tokens'] };
      expect(tokens.refreshToken).not.toBe(u.refreshToken);

      const reuse = await http()
        .post('/auth/refresh')
        .send({ refreshToken: u.refreshToken })
        .expect(401);
      expect(errCode(reuse.body)).toBe('UNAUTHORIZED');

      await http()
        .post('/auth/refresh')
        .send({ refreshToken: tokens.refreshToken })
        .expect(401);
    });

    it('refresh with garbage is 401, with missing body 400', async () => {
      await http()
        .post('/auth/refresh')
        .send({ refreshToken: 'garbage' })
        .expect(401);
      await http().post('/auth/refresh').send({}).expect(400);
    });

    it('logout is 204, idempotent, and kills the session', async () => {
      const u = await createTestUser(app);
      await http()
        .post('/auth/logout')
        .send({ refreshToken: u.refreshToken })
        .expect(204);
      await http()
        .post('/auth/logout')
        .send({ refreshToken: u.refreshToken })
        .expect(204);
      await http()
        .post('/auth/refresh')
        .send({ refreshToken: u.refreshToken })
        .expect(401);
    });
  });

  describe('forgot / reset password', () => {
    it('emails a reset token; reset changes the password, is single-use and revokes sessions', async () => {
      const u = await createTestUser(app, { email: uniqueEmail() });
      await http()
        .post('/auth/forgot-password')
        .send({ email: u.user.email })
        .expect(204);

      const mail = await waitForEmail(u.user.email, 'Reset your');
      const token = /Reset code: (\S+)/.exec(mail.Text)?.[1] as string;
      expect(token).toBeTruthy();
      expect(mail.HTML).toContain(`reset-password?token=${token}`);

      await http()
        .post('/auth/reset-password')
        .send({ token, newPassword: 'BrandNewPass1!' })
        .expect(204);

      await http()
        .post('/auth/login')
        .send({ email: u.user.email, password: u.password })
        .expect(401);
      await http()
        .post('/auth/login')
        .send({ email: u.user.email, password: 'BrandNewPass1!' })
        .expect(200);
      await http()
        .post('/auth/refresh')
        .send({ refreshToken: u.refreshToken })
        .expect(401);

      const reuse = await http()
        .post('/auth/reset-password')
        .send({ token, newPassword: 'AnotherPass22!' })
        .expect(400);
      expect(errCode(reuse.body)).toBe('VALIDATION_ERROR');
    });

    it('unknown emails also get 204 and no email is sent', async () => {
      const ghost = `ghost-${Date.now()}@example.com`;
      await http()
        .post('/auth/forgot-password')
        .send({ email: ghost })
        .expect(204);
      await new Promise((r) => setTimeout(r, 500));
      expect(await countEmails(ghost)).toBe(0);
    });

    it('rejects unknown, expired and too-weak reset requests', async () => {
      await http()
        .post('/auth/reset-password')
        .send({ token: 'nope', newPassword: 'BrandNewPass1!' })
        .expect(400);
      await http()
        .post('/auth/reset-password')
        .send({ token: 'nope', newPassword: 'short' })
        .expect(400);

      const u = await createTestUser(app);
      await http()
        .post('/auth/forgot-password')
        .send({ email: u.user.email })
        .expect(204);
      await prisma.passwordResetToken.updateMany({
        data: { expiresAt: new Date(Date.now() - 1000) },
      });
      const mail = await waitForEmail(u.user.email, 'Reset your');
      const token = /Reset code: (\S+)/.exec(mail.Text)?.[1] as string;
      await http()
        .post('/auth/reset-password')
        .send({ token, newPassword: 'BrandNewPass1!' })
        .expect(400);
    });
  });
});
