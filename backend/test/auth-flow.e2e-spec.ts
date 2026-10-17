import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { Role } from '@prisma/client';
import request from 'supertest';
import { App } from 'supertest/types';
import { AppModule } from '../src/app.module';
import { configureApp } from '../src/app.setup';
import { PrismaService } from '../src/prisma/prisma.service';
import { createTestUser } from './helpers/auth';
import { resetDb } from './helpers/db';
import { waitForEmail } from './helpers/mailpit';

describe('Architect onboarding journey (e2e)', () => {
  let app: INestApplication<App>;
  let prisma: PrismaService;
  const http = () => request(app.getHttpServer());

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

  it('signup → blocked → submit COA → admin approves → access, and refresh keeps working', async () => {
    const email = `journey-${Date.now()}@example.com`;
    const signup = await http()
      .post('/auth/signup')
      .send({
        email,
        password: 'Sup3rSecret!',
        fullName: 'Journey Architect',
        phone: '+919876543210',
        address: '12 MG Road',
        city: 'Pune',
      })
      .expect(201);
    const {
      tokens: { accessToken, refreshToken },
      user,
    } = signup.body as {
      tokens: { accessToken: string; refreshToken: string };
      user: { id: string; verificationStatus: string };
    };
    expect(user.verificationStatus).toBe('PENDING');
    const auth = { Authorization: `Bearer ${accessToken}` };

    const blocked = await http().get('/cart').set(auth).expect(403);
    expect((blocked.body as { error: { code: string } }).error.code).toBe(
      'VERIFICATION_REQUIRED',
    );

    await http()
      .post('/verification')
      .set(auth)
      .field('coaRegistrationNumber', 'CA/2018/54321')
      .attach('document', Buffer.from('%PDF-1.4 coa'), 'coa.pdf')
      .expect(201);
    await http().get('/cart').set(auth).expect(403);

    const admin = await createTestUser(app, { role: Role.ADMIN });
    const list = await http()
      .get('/admin/verifications')
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .expect(200);
    const item = (
      list.body as { items: { id: string; user: { id: string } }[] }
    ).items[0];
    expect(item.user.id).toBe(user.id);
    await http()
      .post(`/admin/verifications/${item.id}/approve`)
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .expect(201);

    // same access token works immediately: approval status is read from the DB, not the token
    await http().get('/cart').set(auth).expect(200);
    await waitForEmail(email, 'Welcome to SketchSquare');

    const refreshed = await http()
      .post('/auth/refresh')
      .send({ refreshToken })
      .expect(200);
    const next = (refreshed.body as { tokens: { accessToken: string } }).tokens;
    await http()
      .get('/cart')
      .set('Authorization', `Bearer ${next.accessToken}`)
      .expect(200);
    await http()
      .post('/auth/login')
      .send({ email, password: 'wrong-password' })
      .expect(401);
  });
});
