import './helpers/enable-rate-limit';
import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { App } from 'supertest/types';
import { AppModule } from '../src/app.module';
import { configureApp } from '../src/app.setup';

describe('Auth rate limiting (e2e)', () => {
  let app: INestApplication<App>;

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();
    app = moduleRef.createNestApplication();
    configureApp(app);
    await app.init();
  });

  afterAll(async () => {
    await app.close();
  });

  it('login is limited to 10/min per IP → 429 RATE_LIMITED', async () => {
    const attempt = () =>
      request(app.getHttpServer())
        .post('/auth/login')
        .send({ email: 'nobody@example.com', password: 'whatever123' });
    for (let i = 0; i < 10; i++) await attempt().expect(401);
    const res = await attempt().expect(429);
    expect((res.body as { error: { code: string } }).error.code).toBe(
      'RATE_LIMITED',
    );
  });
});
