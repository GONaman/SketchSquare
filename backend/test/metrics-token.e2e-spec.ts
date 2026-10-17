import './helpers/enable-metrics-token';
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { App } from 'supertest/types';
import { buildCommerceApp } from './helpers/commerce-app';

describe('/metrics with METRICS_TOKEN (e2e)', () => {
  let app: INestApplication<App>;
  const http = () => request(app.getHttpServer());

  beforeAll(async () => {
    ({ app } = await buildCommerceApp());
  });
  afterAll(() => app.close());

  it('requires the bearer token', async () => {
    expect((await http().get('/metrics')).status).toBe(401);
    expect(
      (await http().get('/metrics').set('Authorization', 'Bearer wrong'))
        .status,
    ).toBe(401);
  });

  it('serves metrics with the right token, even when forwarded by a proxy', async () => {
    const res = await http()
      .get('/metrics')
      .set('Authorization', 'Bearer scrape-token-for-tests')
      .set('X-Forwarded-For', '203.0.113.9');
    expect(res.status).toBe(200);
    expect(res.text).toContain('sketchsquare_http_requests_total');
  });
});
