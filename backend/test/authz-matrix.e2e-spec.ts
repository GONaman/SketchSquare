import { INestApplication } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import request from 'supertest';
import { App } from 'supertest/types';
import { PrismaService } from '../src/prisma/prisma.service';
import { AUTHZ_MATRIX } from './authz-matrix';
import { bearer, createTestUser, TestUser } from './helpers/auth';
import { buildCommerceApp } from './helpers/commerce-app';
import { resetDb } from './helpers/db';
import { createCategory, createDrawing } from './helpers/fixtures';
import { enumerateRoutes, RouteInfo } from './helpers/routes';

interface Ctx {
  drawingId: string;
  sheetId: string;
}
interface OwnerScenario {
  route: string;
  /** Body/query to satisfy validation so the request reaches the ownership check. */
  body?: Record<string, unknown>;
  build?: (c: Ctx) => string;
  /** Status the drawing's owner must get (checked as a predicate). */
  owner: (status: number) => boolean;
  /** Non-owners (approved architect, admin) get this status, unless overridden. */
  other: number;
  admin?: number;
}

const notDenied = (s: number) => s !== 401 && s !== 403 && s < 500;
const ok = (s: number) => s >= 200 && s < 300;

const OWNER_SCENARIOS: OwnerScenario[] = [
  {
    route: 'PATCH /drawings/:id',
    body: { title: 'Renamed drawing' },
    owner: ok,
    other: 403,
  },
  { route: 'DELETE /drawings/:id', owner: ok, other: 403 },
  {
    route: 'POST /drawings/:id/publish',
    body: {},
    owner: notDenied,
    other: 403,
  },
  {
    route: 'POST /drawings/:drawingId/sheets/upload-url',
    body: {
      fileName: 'a.pdf',
      contentType: 'application/pdf',
      sizeBytes: 1000,
    },
    owner: ok,
    other: 403,
  },
  {
    route: 'POST /drawings/:drawingId/sheets',
    body: {
      type: 'ARCHITECTURAL',
      objectKey: 'sheets/none.pdf',
      isPreview: false,
      fileName: 'a.pdf',
      sizeBytes: 1000,
    },
    owner: notDenied,
    other: 403,
  },
  {
    route: 'PATCH /drawings/:drawingId/sheets/:sheetId',
    body: { isPreview: true },
    owner: (s) => s === 404,
    other: 403,
  },
  {
    route: 'DELETE /drawings/:drawingId/sheets/:sheetId',
    owner: ok,
    other: 403,
  },
  { route: 'GET /drawings/:id/buyers', owner: ok, other: 403 },
  { route: 'GET /drawings/:id/viewers', owner: ok, other: 403 },
  { route: 'GET /drawings/:id/interests', owner: ok, other: 403 },
  { route: 'GET /drawings/:id/interested', owner: ok, other: 403 },
];

const fill = (path: string, c: Ctx) =>
  path
    .replace(':drawingId', c.drawingId)
    .replace(':id', c.drawingId)
    .replace(':sheetId', c.sheetId);

const dummy = (path: string) => path.replace(/:\w+/g, () => randomUUID());

describe('Authorization matrix (e2e)', () => {
  let app: INestApplication<App>;
  let prisma: PrismaService;
  let routes: RouteInfo[];
  let pending: TestUser;
  let approved: TestUser;
  let owner: TestUser;
  let admin: TestUser;
  let categoryId: string;
  const http = () => request(app.getHttpServer());

  const call = (
    method: string,
    path: string,
    who: TestUser | null,
    body: Record<string, unknown> = {},
  ) => {
    const verb = method.toLowerCase() as
      'get' | 'post' | 'put' | 'patch' | 'delete';
    let req = http()[verb](path);
    if (who) req = req.set(...bearer(who));
    return ['post', 'put', 'patch'].includes(verb) ? req.send(body) : req;
  };

  beforeAll(async () => {
    ({ app, prisma } = await buildCommerceApp());
    await resetDb(prisma);
    routes = enumerateRoutes(app);
    pending = await createTestUser(app, { verificationStatus: 'PENDING' });
    approved = await createTestUser(app, { verificationStatus: 'APPROVED' });
    owner = await createTestUser(app, { verificationStatus: 'APPROVED' });
    admin = await createTestUser(app, {
      role: 'ADMIN',
      verificationStatus: 'PENDING',
    });
    categoryId = (await createCategory(prisma)).id;
  });

  afterAll(async () => {
    await resetDb(prisma);
    await app.close();
  });

  describe('coverage: every route has a matrix entry', () => {
    it('finds the routes programmatically', () => {
      expect(routes.length).toBeGreaterThan(50);
    });

    it('has no route missing from the matrix (add an entry to test/authz-matrix.ts)', () => {
      const missing = routes
        .map((r) => r.key)
        .filter((k) => !(k in AUTHZ_MATRIX));
      expect({ missing }).toEqual({ missing: [] });
    });

    it('has no stale matrix entry without a route', () => {
      const keys = new Set(routes.map((r) => r.key));
      const stale = Object.keys(AUTHZ_MATRIX).filter((k) => !keys.has(k));
      expect({ stale }).toEqual({ stale: [] });
    });

    it('declares the access level the guards actually enforce', () => {
      const wrong = routes
        .filter((r) => AUTHZ_MATRIX[r.key]?.access !== r.access)
        .map(
          (r) =>
            `${r.key}: matrix=${AUTHZ_MATRIX[r.key]?.access} actual=${r.access}`,
        );
      expect(wrong).toEqual([]);
    });

    it('has an owner scenario for every owner-scoped route (and no orphan scenarios)', () => {
      const flagged = Object.entries(AUTHZ_MATRIX)
        .filter(([, e]) => e.owner)
        .map(([k]) => k)
        .sort();
      expect(OWNER_SCENARIOS.map((s) => s.route).sort()).toEqual(flagged);
    });

    it('never exempts a write route from the write rate limit', () => {
      const exempt = routes
        .filter(
          (r) =>
            !['GET', 'HEAD', 'OPTIONS'].includes(r.method) &&
            r.skipsWriteThrottle,
        )
        .map((r) => r.key);
      expect(exempt).toEqual([]);
    });
  });

  describe('guards on every protected route', () => {
    const protectedRoutes = () =>
      routes.filter((r) => AUTHZ_MATRIX[r.key]?.access !== 'public');

    it('anonymous → 401 UNAUTHORIZED', async () => {
      const failures: string[] = [];
      for (const r of protectedRoutes()) {
        const res = await call(r.method, dummy(r.path), null);
        if (res.status !== 401) failures.push(`${r.key} → ${res.status}`);
      }
      expect(failures).toEqual([]);
    });

    it('unapproved architect → 403 VERIFICATION_REQUIRED (approved routes), 403 FORBIDDEN (admin), passes (authed)', async () => {
      const failures: string[] = [];
      for (const r of protectedRoutes()) {
        const access = AUTHZ_MATRIX[r.key].access;
        const res = await call(r.method, dummy(r.path), pending);
        const code = (res.body as { error?: { code?: string } }).error?.code;
        const good =
          access === 'approved'
            ? res.status === 403 && code === 'VERIFICATION_REQUIRED'
            : access === 'admin'
              ? res.status === 403 && code === 'FORBIDDEN'
              : res.status !== 401 && code !== 'VERIFICATION_REQUIRED';
        if (!good) failures.push(`${r.key} → ${res.status} ${code}`);
      }
      expect(failures).toEqual([]);
    });

    it('approved non-admin → 403 FORBIDDEN on admin routes, passes the guards elsewhere', async () => {
      const failures: string[] = [];
      for (const r of protectedRoutes()) {
        const access = AUTHZ_MATRIX[r.key].access;
        const res = await call(r.method, dummy(r.path), approved);
        const code = (res.body as { error?: { code?: string } }).error?.code;
        const good =
          access === 'admin'
            ? res.status === 403 && code === 'FORBIDDEN'
            : res.status !== 401 && code !== 'VERIFICATION_REQUIRED';
        if (!good) failures.push(`${r.key} → ${res.status} ${code}`);
      }
      expect(failures).toEqual([]);
    });

    it('admin passes the guards on every protected route (even when not verified)', async () => {
      const failures: string[] = [];
      for (const r of protectedRoutes()) {
        const res = await call(r.method, dummy(r.path), admin);
        const code = (res.body as { error?: { code?: string } }).error?.code;
        if (
          res.status === 401 ||
          code === 'VERIFICATION_REQUIRED' ||
          (res.status === 403 &&
            code === 'FORBIDDEN' &&
            !r.path.includes('/drawings'))
        ) {
          failures.push(`${r.key} → ${res.status} ${code}`);
        }
      }
      expect(failures).toEqual([]);
    });

    it('public routes do not demand a JWT', async () => {
      const failures: string[] = [];
      for (const r of routes.filter(
        (x) =>
          AUTHZ_MATRIX[x.key]?.access === 'public' &&
          !x.path.includes('/webhook'),
      )) {
        const res = await call(r.method, dummy(r.path), null);
        if (res.status === 401) failures.push(`${r.key} → ${res.status}`);
      }
      expect(failures).toEqual([]);
    });

    it('webhooks are public but reject unsigned requests', async () => {
      for (const path of [
        '/payments/razorpay/webhook',
        '/payments/razorpayx/webhook',
      ]) {
        const res = await call('POST', path, null, { event: 'x' });
        expect([400, 401]).toContain(res.status);
      }
    });
  });

  describe('owner-scoped routes', () => {
    const freshContext = async (): Promise<Ctx> => {
      const d = await createDrawing(prisma, {
        architectId: owner.user.id,
        categoryId,
        status: 'DRAFT',
      });
      return { drawingId: d.id, sheetId: randomUUID() };
    };

    for (const s of OWNER_SCENARIOS) {
      const [method, path] = s.route.split(' ');
      it(`${s.route}: non-owner → ${s.other}, owner allowed`, async () => {
        const nonOwner = await freshContext();
        const asApproved = await call(
          method,
          fill(path, nonOwner),
          approved,
          s.body,
        );
        expect(asApproved.status).toBe(s.other);
        const asAdmin = await call(method, fill(path, nonOwner), admin, s.body);
        expect(asAdmin.status).toBe(s.admin ?? s.other);
        const anon = await call(method, fill(path, nonOwner), null, s.body);
        expect(anon.status).toBe(401);
        const pend = await call(method, fill(path, nonOwner), pending, s.body);
        expect(pend.status).toBe(403);

        const mine = await freshContext();
        const asOwner = await call(method, fill(path, mine), owner, s.body);
        expect({
          route: s.route,
          status: asOwner.status,
          allowed: s.owner(asOwner.status),
        }).toEqual({
          route: s.route,
          status: asOwner.status,
          allowed: true,
        });
      });
    }

    it('GET /drawings/:id hides a draft from other architects (404) but not from the owner/admin', async () => {
      const c = await freshContext();
      expect(
        (await call('GET', `/drawings/${c.drawingId}`, owner)).status,
      ).toBe(200);
      expect(
        (await call('GET', `/drawings/${c.drawingId}`, admin)).status,
      ).toBe(200);
      expect(
        (await call('GET', `/drawings/${c.drawingId}`, approved)).status,
      ).toBe(404);
    });
  });
});
