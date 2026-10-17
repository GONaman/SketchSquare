import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { App } from 'supertest/types';
import { AppModule } from '../src/app.module';
import { configureApp } from '../src/app.setup';
import { PrismaService } from '../src/prisma/prisma.service';
import { bearer, createTestUser, TestUser } from './helpers/auth';
import { resetDb } from './helpers/db';

interface Page<T> {
  items: T[];
  nextCursor: string | null;
}
interface ErrBody {
  error: { code: string };
}

describe('Favorites (e2e)', () => {
  let app: INestApplication<App>;
  let prisma: PrismaService;
  let categoryId: string;
  let seller: TestUser;
  let me: TestUser;
  const http = () => request(app.getHttpServer());

  const drawing = (over: Record<string, unknown> = {}) =>
    prisma.drawing.create({
      data: {
        architectId: seller.user.id,
        title: 'D',
        description: 'd',
        categoryId,
        city: 'Pune',
        plotLengthFt: 40,
        plotBreadthFt: 30,
        pricePaise: 1000,
        status: 'PUBLISHED',
        ...over,
      },
    });
  const fav = (u: TestUser, id: string) =>
    http()
      .put(`/drawings/${id}/favorite`)
      .set(...bearer(u));
  const unfav = (u: TestUser, id: string) =>
    http()
      .delete(`/drawings/${id}/favorite`)
      .set(...bearer(u));
  const list = async (u: TestUser, qs = '') =>
    (
      await http()
        .get(`/me/favorites${qs}`)
        .set(...bearer(u))
        .expect(200)
    ).body as Page<{ id: string }>;

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
    categoryId = (
      await prisma.category.create({ data: { name: 'Res', slug: 'res' } })
    ).id;
    seller = await createTestUser(app, { fullName: 'Seller One' });
    me = await createTestUser(app, { fullName: 'Me' });
  });

  afterAll(async () => {
    await resetDb(prisma);
    await app.close();
  });

  it('requires authentication and an approved account', async () => {
    const d = await drawing();
    await http().put(`/drawings/${d.id}/favorite`).expect(401);
    await http().get('/me/favorites').expect(401);
    const pending = await createTestUser(app, {
      verificationStatus: 'PENDING',
    });
    const res = await fav(pending, d.id).expect(403);
    expect((res.body as ErrBody).error.code).toBe('VERIFICATION_REQUIRED');
    await http()
      .get('/me/favorites')
      .set(...bearer(pending))
      .expect(403);
  });

  it('PUT is idempotent and keeps a single row with the original timestamp', async () => {
    const d = await drawing();
    await fav(me, d.id).expect(204);
    const first = await prisma.favorite.findMany();
    await fav(me, d.id).expect(204);
    await fav(me, d.id).expect(204);
    const rows = await prisma.favorite.findMany();
    expect(rows).toHaveLength(1);
    expect(rows[0].createdAt).toEqual(first[0].createdAt);
  });

  it('concurrent PUTs do not fail or duplicate', async () => {
    const d = await drawing();
    const results = await Promise.all(
      Array.from({ length: 5 }, () => fav(me, d.id)),
    );
    expect(results.map((r) => r.status)).toEqual([204, 204, 204, 204, 204]);
    expect(await prisma.favorite.count()).toBe(1);
  });

  it('DELETE is idempotent, also for drawings that never were favourites', async () => {
    const d = await drawing();
    await unfav(me, d.id).expect(204);
    await fav(me, d.id).expect(204);
    await unfav(me, d.id).expect(204);
    await unfav(me, d.id).expect(204);
    expect(await prisma.favorite.count()).toBe(0);
  });

  it('is per user: one user cannot see or remove another user’s favourite', async () => {
    const other = await createTestUser(app);
    const d = await drawing();
    await fav(me, d.id).expect(204);
    expect((await list(other)).items).toEqual([]);
    await unfav(other, d.id).expect(204);
    expect((await list(me)).items.map((i) => i.id)).toEqual([d.id]);
  });

  it('404s for unknown, draft, removed and unapproved-architect drawings', async () => {
    const draft = await drawing({ status: 'DRAFT' });
    const removed = await drawing({ status: 'REMOVED' });
    const rejected = await createTestUser(app, {
      verificationStatus: 'REJECTED',
    });
    const theirs = await drawing({ architectId: rejected.user.id });
    for (const id of [
      draft.id,
      removed.id,
      theirs.id,
      '00000000-0000-4000-8000-000000000000',
    ]) {
      const res = await fav(me, id).expect(404);
      expect((res.body as ErrBody).error.code).toBe('NOT_FOUND');
    }
    await http()
      .put('/drawings/not-a-uuid/favorite')
      .set(...bearer(me))
      .expect(400);
    expect(await prisma.favorite.count()).toBe(0);
  });

  it('lists favourites newest-first with DrawingSummary shape and cursor pagination', async () => {
    const a = await drawing({ title: 'A' });
    const b = await drawing({ title: 'B', pricePaise: 0 });
    const c = await drawing({ title: 'C' });
    for (const d of [a, b, c]) {
      await fav(me, d.id).expect(204);
      await new Promise((r) => setTimeout(r, 5));
    }
    const all = await list(me);
    expect(all.items.map((i) => i.id)).toEqual([c.id, b.id, a.id]);
    expect(all.nextCursor).toBeNull();
    expect(all.items[1]).toMatchObject({
      id: b.id,
      title: 'B',
      isFree: true,
      category: { slug: 'res' },
      architect: { id: seller.user.id },
    });
    expect(JSON.stringify(all)).not.toContain('originalKey');

    const p1 = await list(me, '?limit=2');
    expect(p1.items.map((i) => i.id)).toEqual([c.id, b.id]);
    expect(p1.nextCursor).not.toBeNull();
    const p2 = await list(me, `?limit=2&cursor=${p1.nextCursor}`);
    expect(p2.items.map((i) => i.id)).toEqual([a.id]);
    expect(p2.nextCursor).toBeNull();

    await http()
      .get('/me/favorites?cursor=garbage')
      .set(...bearer(me))
      .expect(400);
  });

  it('hides favourites whose drawing is no longer listable, and shows them again if restored', async () => {
    const a = await drawing({ title: 'A' });
    const b = await drawing({ title: 'B' });
    await fav(me, a.id).expect(204);
    await fav(me, b.id).expect(204);
    await prisma.drawing.update({
      where: { id: a.id },
      data: { status: 'REMOVED' },
    });
    expect((await list(me)).items.map((i) => i.id)).toEqual([b.id]);
    await unfav(me, a.id).expect(204);
    expect(await prisma.favorite.count()).toBe(1);
  });

  it('exposes viewer.isFavorite on the drawing detail for the caller only', async () => {
    const other = await createTestUser(app);
    const d = await drawing();
    type Detail = { viewer: { isFavorite: boolean } };
    const get = async (u: TestUser) =>
      (
        await http()
          .get(`/drawings/${d.id}`)
          .set(...bearer(u))
          .expect(200)
      ).body as Detail;
    expect((await get(me)).viewer.isFavorite).toBe(false);
    await fav(me, d.id).expect(204);
    expect((await get(me)).viewer.isFavorite).toBe(true);
    expect((await get(other)).viewer.isFavorite).toBe(false);
    await unfav(me, d.id).expect(204);
    expect((await get(me)).viewer.isFavorite).toBe(false);
  });
});
