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
interface Interested {
  user: { id: string; fullName: string; city: string };
  createdAt: string;
}

describe('Express interest (e2e)', () => {
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
  const interest = (u: TestUser, id: string) =>
    http()
      .put(`/drawings/${id}/interest`)
      .set(...bearer(u));
  const uninterest = (u: TestUser, id: string) =>
    http()
      .delete(`/drawings/${id}/interest`)
      .set(...bearer(u));
  const interested = (u: TestUser, id: string, qs = '', path = 'interests') =>
    http()
      .get(`/drawings/${id}/${path}${qs}`)
      .set(...bearer(u));
  const code = (res: { body: unknown }) => (res.body as ErrBody).error.code;

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
    me = await createTestUser(app, { fullName: 'Me', city: 'Delhi' });
  });

  afterAll(async () => {
    await resetDb(prisma);
    await app.close();
  });

  it('requires authentication and an approved account', async () => {
    const d = await drawing();
    await http().put(`/drawings/${d.id}/interest`).expect(401);
    await http().get(`/drawings/${d.id}/interests`).expect(401);
    const pending = await createTestUser(app, {
      verificationStatus: 'PENDING',
    });
    expect(code(await interest(pending, d.id).expect(403))).toBe(
      'VERIFICATION_REQUIRED',
    );
    await interested(pending, d.id).expect(403);
  });

  it('PUT is idempotent (also under concurrency) and DELETE is idempotent', async () => {
    const d = await drawing();
    await uninterest(me, d.id).expect(204);
    const results = await Promise.all(
      Array.from({ length: 4 }, () => interest(me, d.id)),
    );
    expect(results.map((r) => r.status)).toEqual([204, 204, 204, 204]);
    expect(await prisma.interest.count()).toBe(1);
    await uninterest(me, d.id).expect(204);
    await uninterest(me, d.id).expect(204);
    expect(await prisma.interest.count()).toBe(0);
  });

  it('rejects free drawings (400), own drawings (403) and non-listable drawings (404)', async () => {
    const free = await drawing({ pricePaise: 0 });
    expect(code(await interest(me, free.id).expect(400))).toBe(
      'VALIDATION_ERROR',
    );
    const own = await drawing();
    expect(code(await interest(seller, own.id).expect(403))).toBe('FORBIDDEN');

    const draft = await drawing({ status: 'DRAFT' });
    const removed = await drawing({ status: 'REMOVED' });
    const rejected = await createTestUser(app, {
      verificationStatus: 'REJECTED',
    });
    const unapproved = await drawing({ architectId: rejected.user.id });
    for (const id of [
      draft.id,
      removed.id,
      unapproved.id,
      '00000000-0000-4000-8000-000000000000',
    ]) {
      expect(code(await interest(me, id).expect(404))).toBe('NOT_FOUND');
    }
    await http()
      .put('/drawings/nope/interest')
      .set(...bearer(me))
      .expect(400);
    expect(await prisma.interest.count()).toBe(0);
  });

  it('only the owner can list interested users; others get 403, missing drawings 404', async () => {
    const d = await drawing();
    await interest(me, d.id).expect(204);
    expect(code(await interested(me, d.id).expect(403))).toBe('FORBIDDEN');
    const admin = await createTestUser(app, { role: 'ADMIN' });
    await interested(admin, d.id).expect(403);
    expect(
      code(
        await interested(seller, '00000000-0000-4000-8000-000000000000').expect(
          404,
        ),
      ),
    ).toBe('NOT_FOUND');
  });

  it('lists name, city and date newest-first with pagination and no private fields', async () => {
    const d = await drawing();
    const others = [me, await createTestUser(app, { fullName: 'Third' })];
    const third = await createTestUser(app, { fullName: 'Fourth' });
    others.push(third);
    for (const u of others) {
      await interest(u, d.id).expect(204);
      await new Promise((r) => setTimeout(r, 5));
    }
    const all = (await interested(seller, d.id).expect(200))
      .body as Page<Interested>;
    expect(all.items.map((i) => i.user.id)).toEqual([
      third.user.id,
      others[1].user.id,
      me.user.id,
    ]);
    expect(all.items[2]).toEqual({
      user: { id: me.user.id, fullName: 'Me', city: 'Delhi' },
      createdAt: expect.any(String) as string,
    });
    expect(JSON.stringify(all)).not.toMatch(/email|phone|passwordHash/);

    const p1 = (await interested(seller, d.id, '?limit=2').expect(200))
      .body as Page<Interested>;
    expect(p1.items).toHaveLength(2);
    const p2 = (
      await interested(seller, d.id, `?limit=2&cursor=${p1.nextCursor}`).expect(
        200,
      )
    ).body as Page<Interested>;
    expect(p2.items.map((i) => i.user.id)).toEqual([me.user.id]);
    expect(p2.nextCursor).toBeNull();
    await interested(seller, d.id, '?cursor=bad').expect(400);

    const alias = (await interested(seller, d.id, '', 'interested').expect(200))
      .body as Page<Interested>;
    expect(alias.items).toHaveLength(3);
  });

  it('the owner still sees interested users after the drawing is removed', async () => {
    const d = await drawing();
    await interest(me, d.id).expect(204);
    await prisma.drawing.update({
      where: { id: d.id },
      data: { status: 'REMOVED' },
    });
    const res = (await interested(seller, d.id).expect(200))
      .body as Page<Interested>;
    expect(res.items).toHaveLength(1);
    await uninterest(me, d.id).expect(204);
  });

  it('exposes viewer.isInterested for the caller only', async () => {
    const other = await createTestUser(app);
    const d = await drawing();
    const get = async (u: TestUser) =>
      (
        await http()
          .get(`/drawings/${d.id}`)
          .set(...bearer(u))
          .expect(200)
      ).body as { viewer: { isInterested: boolean } };
    expect((await get(me)).viewer.isInterested).toBe(false);
    await interest(me, d.id).expect(204);
    expect((await get(me)).viewer.isInterested).toBe(true);
    expect((await get(other)).viewer.isInterested).toBe(false);
    await uninterest(me, d.id).expect(204);
    expect((await get(me)).viewer.isInterested).toBe(false);
  });
});
