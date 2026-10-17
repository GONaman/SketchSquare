import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { App } from 'supertest/types';
import { ShutdownState } from '../src/observability/graceful-shutdown';
import { bearer, createTestUser } from './helpers/auth';
import { buildCommerceApp } from './helpers/commerce-app';
import { resetDb } from './helpers/db';

describe('Observability (e2e)', () => {
  let app: INestApplication<App>;
  let prisma: Awaited<ReturnType<typeof buildCommerceApp>>['prisma'];
  const http = () => request(app.getHttpServer());

  beforeAll(async () => {
    ({ app, prisma } = await buildCommerceApp());
    await resetDb(prisma);
  });
  afterAll(async () => {
    await resetDb(prisma);
    await app.close();
  });

  describe('request ids', () => {
    it('adds X-Request-Id to success responses', async () => {
      const res = await http().get('/health');
      expect(res.headers['x-request-id']).toMatch(/^[0-9a-f-]{36}$/);
    });

    it('echoes a safe client-supplied id and replaces an unsafe one', async () => {
      const ok = await http().get('/health').set('X-Request-Id', 'trace-42');
      expect(ok.headers['x-request-id']).toBe('trace-42');
      const bad = await http()
        .get('/health')
        .set('X-Request-Id', 'bad id<script>');
      expect(bad.headers['x-request-id']).toMatch(/^[0-9a-f-]{36}$/);
    });

    it('is present on 401, 404, validation and body-limit errors', async () => {
      const u = await createTestUser(app);
      const responses = [
        await http().get('/me'),
        await http()
          .get('/no-such-route')
          .set(...bearer(u)),
        await http().post('/auth/login').send({ email: 'x' }),
        await http()
          .post('/auth/login')
          .send({ pad: 'x'.repeat(200_000) }),
      ];
      expect(responses.map((r) => r.status)).toEqual([401, 404, 400, 413]);
      for (const r of responses) {
        expect(r.headers['x-request-id']).toMatch(/^[0-9a-f-]{36}$/);
      }
    });
  });

  describe('/metrics (internal-only when METRICS_TOKEN is unset)', () => {
    it('serves Prometheus text to a private peer, with route templates as labels', async () => {
      await http().get('/health');
      const res = await http().get('/metrics');
      expect(res.status).toBe(200);
      expect(res.headers['content-type']).toMatch(/text\/plain/);
      expect(res.text).toContain('sketchsquare_http_requests_total');
      expect(res.text).toContain('sketchsquare_http_request_duration_seconds');
      expect(res.text).toContain('sketchsquare_process_cpu_user_seconds_total');
      expect(res.text).toMatch(/route="\/health"/);
    });

    it('rejects requests forwarded by a proxy', async () => {
      const res = await http()
        .get('/metrics')
        .set('X-Forwarded-For', '203.0.113.9');
      expect(res.status).toBe(403);
      expect((res.body as { error: { code: string } }).error.code).toBe(
        'FORBIDDEN',
      );
    });

    it('does not leak user ids or query strings into labels', async () => {
      const u = await createTestUser(app);
      await http()
        .get('/drawings/search?q=secretterm')
        .set(...bearer(u));
      const res = await http().get('/metrics');
      expect(res.text).not.toContain('secretterm');
      expect(res.text).not.toContain(u.user.id);
    });
  });

  describe('graceful shutdown', () => {
    it('/health turns 503 as soon as a shutdown begins', async () => {
      expect((await http().get('/health')).status).toBe(200);
      app.get(ShutdownState).begin();
      const res = await http().get('/health');
      expect(res.status).toBe(503);
      expect(res.body).toEqual({ status: 'error', shuttingDown: true });
    });
  });
});
