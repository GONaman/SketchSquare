import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { App } from 'supertest/types';
import { AppModule } from '../src/app.module';
import { configureApp } from '../src/app.setup';
import { PrismaService } from '../src/prisma/prisma.service';
import { TestUser, bearer, createTestUser } from './helpers/auth';
import { resetDb } from './helpers/db';
import {
  createArchitect,
  createCategory,
  createDrawing,
} from './helpers/fixtures';

interface ErrBody {
  error: { code: string };
}
interface Req {
  id: string;
  requestedName: string;
  status: string;
  user?: { id: string };
}

describe('categories, cities, architects (e2e)', () => {
  let app: INestApplication<App>;
  let prisma: PrismaService;
  let user: TestUser;
  let admin: TestUser;
  const http = () => request(app.getHttpServer());
  const asUser = (r: request.Test) => r.set(...bearer(user));
  const asAdmin = (r: request.Test) => r.set(...bearer(admin));

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();
    app = moduleRef.createNestApplication();
    configureApp(app);
    await app.init();
    prisma = app.get(PrismaService);
  });

  beforeEach(async () => {
    await resetDb(prisma);
    user = await createTestUser(app);
    admin = await createTestUser(app, { role: 'ADMIN' });
  });

  afterAll(async () => {
    await resetDb(prisma);
    await app.close();
  });

  describe('categories', () => {
    it('requires authentication', async () => {
      await http().get('/categories').expect(401);
    });

    it('lists only active categories, sorted by name', async () => {
      await createCategory(prisma, 'Villa');
      await createCategory(prisma, 'Apartment');
      const hidden = await createCategory(prisma, 'Hidden');
      await prisma.category.update({
        where: { id: hidden.id },
        data: { isActive: false },
      });
      const res = await asUser(http().get('/categories')).expect(200);
      expect((res.body as { name: string }[]).map((c) => c.name)).toEqual([
        'Apartment',
        'Villa',
      ]);
      expect(Object.keys((res.body as object[])[0]).sort()).toEqual([
        'id',
        'name',
        'slug',
      ]);
    });

    describe('POST /category-requests', () => {
      const post = (name: unknown) =>
        asUser(http().post('/category-requests').send({ name }));

      it('creates a pending request with a normalised name', async () => {
        const res = await post('  Row   House ').expect(201);
        expect(res.body).toMatchObject({
          requestedName: 'Row House',
          status: 'PENDING',
        });
      });

      it('is idempotent for the same pending request', async () => {
        const a = (await post('Duplex').expect(201)).body as Req;
        const b = (await post('duplex').expect(201)).body as Req;
        expect(b.id).toBe(a.id);
        expect(await prisma.categoryRequest.count()).toBe(1);
      });

      it('rejects an existing category with 409 and bad names with 400', async () => {
        await createCategory(prisma, 'Villa');
        const dup = await post('villa').expect(409);
        expect((dup.body as ErrBody).error.code).toBe('CONFLICT');
        await post('x').expect(400);
        await post(123).expect(400);
        await post('a'.repeat(61)).expect(400);
      });
    });

    describe('admin category requests', () => {
      it('is admin-only', async () => {
        await asUser(http().get('/admin/category-requests')).expect(403);
        await asUser(
          http().post(
            '/admin/category-requests/00000000-0000-4000-8000-000000000000/approve',
          ),
        ).expect(403);
      });

      it('lists pending requests oldest-first with cursor paging', async () => {
        for (let i = 0; i < 3; i++) {
          await prisma.categoryRequest.create({
            data: {
              userId: user.user.id,
              requestedName: `Name ${i}`,
              createdAt: new Date(Date.UTC(2026, 0, 1, 0, 0, i)),
            },
          });
        }
        await prisma.categoryRequest.create({
          data: {
            userId: user.user.id,
            requestedName: 'Done',
            status: 'REJECTED',
          },
        });
        const first = (
          await asAdmin(http().get('/admin/category-requests?limit=2')).expect(
            200,
          )
        ).body as { items: Req[]; nextCursor: string };
        expect(first.items.map((r) => r.requestedName)).toEqual([
          'Name 0',
          'Name 1',
        ]);
        expect(first.items[0].user?.id).toBe(user.user.id);
        const second = (
          await asAdmin(
            http().get(
              `/admin/category-requests?limit=2&cursor=${first.nextCursor}`,
            ),
          ).expect(200)
        ).body as { items: Req[]; nextCursor: string | null };
        expect(second.items.map((r) => r.requestedName)).toEqual(['Name 2']);
        expect(second.nextCursor).toBeNull();
        const rejected = (
          await asAdmin(
            http().get('/admin/category-requests?status=REJECTED'),
          ).expect(200)
        ).body as { items: Req[] };
        expect(rejected.items.map((r) => r.requestedName)).toEqual(['Done']);
      });

      it('approve creates a category with a unique slug and is not repeatable', async () => {
        await createCategory(prisma, 'Row-House'); // occupies slug prefix only by name, not slug
        const a = await prisma.categoryRequest.create({
          data: { userId: user.user.id, requestedName: 'Row House' },
        });
        const res = await asAdmin(
          http().post(`/admin/category-requests/${a.id}/approve`),
        ).expect(200);
        const body = res.body as {
          ok: boolean;
          category: { name: string; slug: string };
        };
        expect(body.ok).toBe(true);
        expect(body.category.name).toBe('Row House');
        expect(body.category.slug).toMatch(/^row-house(-\d+)?$/);
        expect(
          await prisma.category.count({ where: { name: 'Row House' } }),
        ).toBe(1);
        expect(
          (
            await prisma.categoryRequest.findUniqueOrThrow({
              where: { id: a.id },
            })
          ).status,
        ).toBe('APPROVED');
        const again = await asAdmin(
          http().post(`/admin/category-requests/${a.id}/approve`),
        ).expect(409);
        expect((again.body as ErrBody).error.code).toBe('CONFLICT');
        await asAdmin(
          http().post(`/admin/category-requests/${a.id}/reject`),
        ).expect(409);
      });

      it('approve re-activates a disabled category instead of duplicating it', async () => {
        const c = await createCategory(prisma, 'Farmhouse');
        await prisma.category.update({
          where: { id: c.id },
          data: { isActive: false },
        });
        const r = await prisma.categoryRequest.create({
          data: { userId: user.user.id, requestedName: 'farmhouse' },
        });
        await asAdmin(
          http().post(`/admin/category-requests/${r.id}/approve`),
        ).expect(200);
        expect(
          (await prisma.category.findUniqueOrThrow({ where: { id: c.id } }))
            .isActive,
        ).toBe(true);
        expect(await prisma.category.count()).toBe(1);
      });

      it('two simultaneous approvals create exactly one category', async () => {
        const r = await prisma.categoryRequest.create({
          data: { userId: user.user.id, requestedName: 'Studio' },
        });
        const results = await Promise.all([
          asAdmin(http().post(`/admin/category-requests/${r.id}/approve`)),
          asAdmin(http().post(`/admin/category-requests/${r.id}/approve`)),
        ]);
        expect(results.map((x) => x.status).sort()).toEqual([200, 409]);
        expect(await prisma.category.count()).toBe(1);
      });

      it('reject marks the request and 404s for unknown ids', async () => {
        const r = await prisma.categoryRequest.create({
          data: { userId: user.user.id, requestedName: 'Nope' },
        });
        await asAdmin(
          http().post(`/admin/category-requests/${r.id}/reject`),
        ).expect(200);
        const row = await prisma.categoryRequest.findUniqueOrThrow({
          where: { id: r.id },
        });
        expect(row.status).toBe('REJECTED');
        expect(row.reviewedAt).not.toBeNull();
        expect(await prisma.category.count()).toBe(0);
        await asAdmin(
          http().post(
            '/admin/category-requests/00000000-0000-4000-8000-000000000000/reject',
          ),
        ).expect(404);
        await asAdmin(
          http().post('/admin/category-requests/not-a-uuid/reject'),
        ).expect(400);
      });
    });
  });

  describe('GET /cities', () => {
    it('counts only searchable drawings and merges case variants', async () => {
      const cat = await createCategory(prisma);
      const arch = await createArchitect(prisma);
      const pending = await createArchitect(prisma, {
        verificationStatus: 'PENDING',
      });
      const mk = (city: string, over: object = {}) =>
        createDrawing(prisma, {
          architectId: arch.id,
          categoryId: cat.id,
          city,
          ...over,
        });
      await mk('Pune');
      await mk('pune');
      await mk('Pune', { status: 'DRAFT' });
      await mk('Mumbai');
      await mk('Mumbai');
      await mk('Mumbai');
      await mk('Goa', { status: 'REMOVED' });
      await createDrawing(prisma, {
        architectId: pending.id,
        categoryId: cat.id,
        city: 'Delhi',
      });
      const res = await asUser(http().get('/cities')).expect(200);
      expect(res.body).toEqual([
        { city: 'Mumbai', count: 3 },
        { city: expect.stringMatching(/^[Pp]une$/) as string, count: 2 },
      ]);
    });

    it('returns an empty list when nothing is published', async () => {
      const res = await asUser(http().get('/cities')).expect(200);
      expect(res.body).toEqual([]);
    });
  });

  describe('architects', () => {
    it('top: needs >=3 ratings, APPROVED, sorted by rating, city filter', async () => {
      const cat = await createCategory(prisma);
      const best = await createArchitect(prisma, {
        fullName: 'Best',
        city: 'Pune',
        architectRating: 4.9,
        architectRatingCount: 10,
      });
      const good = await createArchitect(prisma, {
        fullName: 'Good',
        city: 'Mumbai',
        architectRating: 4.5,
        architectRatingCount: 3,
      });
      await createArchitect(prisma, {
        fullName: 'Few',
        architectRating: 5,
        architectRatingCount: 2,
      });
      await createArchitect(prisma, {
        fullName: 'Pending',
        architectRating: 5,
        architectRatingCount: 50,
        verificationStatus: 'PENDING',
      });
      await createDrawing(prisma, { architectId: best.id, categoryId: cat.id });
      await createDrawing(prisma, { architectId: best.id, categoryId: cat.id });
      await createDrawing(prisma, {
        architectId: best.id,
        categoryId: cat.id,
        status: 'DRAFT',
      });
      type Top = {
        fullName: string;
        drawingCount: number;
        ratingCount: number;
      };
      const all = (await asUser(http().get('/architects/top')).expect(200))
        .body as Top[];
      expect(all.map((a) => a.fullName)).toEqual(['Best', 'Good']);
      expect(all[0]).toMatchObject({ drawingCount: 2, ratingCount: 10 });
      expect(all[1].drawingCount).toBe(0);
      const mumbai = (
        await asUser(http().get('/architects/top?city=mumbai')).expect(200)
      ).body as Top[];
      expect(mumbai.map((a) => a.fullName)).toEqual(['Good']);
      expect(good.id).toBeDefined();
    });

    it('profile: summary plus newest-first first page, and paging endpoint', async () => {
      const cat = await createCategory(prisma);
      const arch = await createArchitect(prisma, { fullName: 'Ar Chi' });
      const other = await createArchitect(prisma);
      for (let i = 0; i < 5; i++) {
        await createDrawing(prisma, {
          architectId: arch.id,
          categoryId: cat.id,
          title: `D${i}`,
          createdAt: new Date(Date.UTC(2026, 0, 1 + i)),
        });
      }
      await createDrawing(prisma, {
        architectId: arch.id,
        categoryId: cat.id,
        title: 'Draft',
        status: 'DRAFT',
      });
      await createDrawing(prisma, {
        architectId: other.id,
        categoryId: cat.id,
        title: 'Other',
      });
      type P = { items: { title: string }[]; nextCursor: string | null };
      const res = await asUser(
        http().get(`/architects/${arch.id}?limit=2`),
      ).expect(200);
      const body = res.body as {
        architect: { id: string; fullName: string };
        drawings: P;
      };
      expect(body.architect).toMatchObject({ id: arch.id, fullName: 'Ar Chi' });
      expect(body.drawings.items.map((d) => d.title)).toEqual(['D4', 'D3']);
      const next = (
        await asUser(
          http().get(
            `/architects/${arch.id}/drawings?limit=2&cursor=${body.drawings.nextCursor}`,
          ),
        ).expect(200)
      ).body as P;
      expect(next.items.map((d) => d.title)).toEqual(['D2', 'D1']);
      const last = (
        await asUser(
          http().get(
            `/architects/${arch.id}/drawings?limit=2&cursor=${next.nextCursor}`,
          ),
        ).expect(200)
      ).body as P;
      expect(last.items.map((d) => d.title)).toEqual(['D0']);
      expect(last.nextCursor).toBeNull();
    });

    it('profile 404s for unknown, non-approved and non-uuid ids', async () => {
      const pending = await createArchitect(prisma, {
        verificationStatus: 'PENDING',
      });
      await asUser(
        http().get('/architects/00000000-0000-4000-8000-000000000000'),
      ).expect(404);
      await asUser(http().get(`/architects/${pending.id}`)).expect(404);
      await asUser(http().get(`/architects/${pending.id}/drawings`)).expect(
        404,
      );
      await asUser(http().get('/architects/nope')).expect(400);
    });
  });
});
