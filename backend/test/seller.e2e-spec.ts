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

describe('Seller manage endpoints (e2e)', () => {
  let app: INestApplication<App>;
  let prisma: PrismaService;
  let categoryId: string;
  let seller: TestUser;
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
        ...over,
      },
    });

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
  });

  afterAll(async () => {
    await resetDb(prisma);
    await app.close();
  });

  describe('GET /me/drawings', () => {
    it('lists only my drawings, hides REMOVED by default, filters by status, paginates and returns stats', async () => {
      const other = await createTestUser(app);
      await prisma.drawing.create({
        data: {
          architectId: other.user.id,
          title: 'Not mine',
          description: 'x',
          categoryId,
          city: 'Pune',
          plotLengthFt: 1,
          plotBreadthFt: 1,
        },
      });
      const a = await drawing({
        title: 'A',
        status: 'PUBLISHED',
        viewCount: 7,
        purchaseCount: 2,
        avgRating: 4.5,
        ratingCount: 2,
      });
      await new Promise((r) => setTimeout(r, 5));
      const b = await drawing({ title: 'B', status: 'DRAFT' });
      await new Promise((r) => setTimeout(r, 5));
      const c = await drawing({ title: 'C', status: 'PUBLISHED' });
      await drawing({ title: 'Gone', status: 'REMOVED' });

      type Item = {
        drawing: { id: string; title: string; status: string };
        stats: Record<string, number>;
      };
      const all = (
        await http()
          .get('/me/drawings')
          .set(...bearer(seller))
          .expect(200)
      ).body as Page<Item>;
      expect(all.items.map((i) => i.drawing.id)).toEqual([c.id, b.id, a.id]);
      expect(all.items[2].stats).toEqual({
        viewCount: 7,
        purchaseCount: 2,
        avgRating: 4.5,
        ratingCount: 2,
      });
      expect(JSON.stringify(all)).not.toContain('originalKey');

      const published = (
        await http()
          .get('/me/drawings?status=PUBLISHED')
          .set(...bearer(seller))
          .expect(200)
      ).body as Page<Item>;
      expect(published.items.map((i) => i.drawing.id)).toEqual([c.id, a.id]);

      const removed = (
        await http()
          .get('/me/drawings?status=REMOVED')
          .set(...bearer(seller))
          .expect(200)
      ).body as Page<Item>;
      expect(removed.items.map((i) => i.drawing.title)).toEqual(['Gone']);

      const p1 = (
        await http()
          .get('/me/drawings?limit=2')
          .set(...bearer(seller))
          .expect(200)
      ).body as Page<Item>;
      expect(p1.items).toHaveLength(2);
      expect(p1.nextCursor).not.toBeNull();
      const p2 = (
        await http()
          .get(`/me/drawings?limit=2&cursor=${p1.nextCursor}`)
          .set(...bearer(seller))
          .expect(200)
      ).body as Page<Item>;
      expect(p2.items.map((i) => i.drawing.id)).toEqual([a.id]);
      expect(p2.nextCursor).toBeNull();

      await http()
        .get('/me/drawings?status=NOPE')
        .set(...bearer(seller))
        .expect(400);
      await http()
        .get('/me/drawings?cursor=garbage')
        .set(...bearer(seller))
        .expect(400);
      await http().get('/me/drawings').expect(401);
    });
  });

  describe('GET /drawings/:id/buyers and /viewers', () => {
    it('is owner-only and returns paid purchases + free claims, then deduped recent viewers', async () => {
      const d = await drawing({ status: 'PUBLISHED' });
      const buyer1 = await createTestUser(app, {
        fullName: 'Buyer One',
        city: 'Delhi',
      });
      const buyer2 = await createTestUser(app, { fullName: 'Buyer Two' });
      const buyer3 = await createTestUser(app, { fullName: 'Buyer Three' });
      await prisma.purchase.create({
        data: {
          buyerId: buyer1.user.id,
          drawingId: d.id,
          pricePaise: 1000,
          platformFeePaise: 100,
          status: 'PAID',
          paidAt: new Date('2026-01-02T10:00:00Z'),
        },
      });
      await prisma.purchase.create({
        data: {
          buyerId: buyer3.user.id,
          drawingId: d.id,
          pricePaise: 1000,
          platformFeePaise: 100,
          status: 'CREATED',
        },
      });
      await prisma.freeDownload.create({
        data: {
          userId: buyer2.user.id,
          drawingId: d.id,
          createdAt: new Date('2026-01-03T10:00:00Z'),
        },
      });

      type Row = {
        buyer: { id: string; fullName: string; city: string };
        pricePaise: number;
        purchasedAt: string;
      };
      const res = (
        await http()
          .get(`/drawings/${d.id}/buyers`)
          .set(...bearer(seller))
          .expect(200)
      ).body as Page<Row>;
      expect(res.items.map((r) => r.buyer.fullName)).toEqual([
        'Buyer Two',
        'Buyer One',
      ]);
      expect(res.items[0].pricePaise).toBe(0);
      expect(res.items[1]).toMatchObject({
        pricePaise: 1000,
        purchasedAt: '2026-01-02T10:00:00.000Z',
        buyer: { id: buyer1.user.id, city: 'Delhi' },
      });
      expect(Object.keys(res.items[1].buyer).sort()).toEqual([
        'city',
        'fullName',
        'id',
      ]);

      const p1 = (
        await http()
          .get(`/drawings/${d.id}/buyers?limit=1`)
          .set(...bearer(seller))
          .expect(200)
      ).body as Page<Row>;
      const p2 = (
        await http()
          .get(`/drawings/${d.id}/buyers?limit=1&cursor=${p1.nextCursor}`)
          .set(...bearer(seller))
          .expect(200)
      ).body as Page<Row>;
      expect(p1.items[0].buyer.fullName).toBe('Buyer Two');
      expect(p2.items[0].buyer.fullName).toBe('Buyer One');
      expect(p2.nextCursor).toBeNull();

      await http()
        .get(`/drawings/${d.id}/buyers`)
        .set(...bearer(buyer1))
        .expect(403);
      await http().get(`/drawings/${d.id}/buyers`).expect(401);
      await http()
        .get('/drawings/11111111-1111-4111-8111-111111111111/buyers')
        .set(...bearer(seller))
        .expect(404);

      // viewers: deduped per viewer, last 30 days only
      const day = 86_400_000;
      await prisma.drawingView.createMany({
        data: [
          {
            drawingId: d.id,
            viewerId: buyer1.user.id,
            viewedAt: new Date(Date.now() - 3 * day),
          },
          {
            drawingId: d.id,
            viewerId: buyer1.user.id,
            viewedAt: new Date(Date.now() - 1 * day),
          },
          {
            drawingId: d.id,
            viewerId: buyer2.user.id,
            viewedAt: new Date(Date.now() - 2 * day),
          },
          {
            drawingId: d.id,
            viewerId: buyer3.user.id,
            viewedAt: new Date(Date.now() - 45 * day),
          },
        ],
      });
      type V = {
        viewer: { id: string; fullName: string };
        lastViewedAt: string;
      };
      const viewers = (
        await http()
          .get(`/drawings/${d.id}/viewers`)
          .set(...bearer(seller))
          .expect(200)
      ).body as Page<V>;
      expect(viewers.items.map((v) => v.viewer.fullName)).toEqual([
        'Buyer One',
        'Buyer Two',
      ]);
      const v1 = (
        await http()
          .get(`/drawings/${d.id}/viewers?limit=1`)
          .set(...bearer(seller))
          .expect(200)
      ).body as Page<V>;
      const v2 = (
        await http()
          .get(`/drawings/${d.id}/viewers?limit=1&cursor=${v1.nextCursor}`)
          .set(...bearer(seller))
          .expect(200)
      ).body as Page<V>;
      expect([v1.items[0], v2.items[0]].map((v) => v.viewer.fullName)).toEqual([
        'Buyer One',
        'Buyer Two',
      ]);
      expect(v2.nextCursor).toBeNull();
      await http()
        .get(`/drawings/${d.id}/viewers`)
        .set(...bearer(buyer2))
        .expect(403);
    });

    it('lets sellers read buyers of a REMOVED drawing', async () => {
      const d = await drawing({ status: 'REMOVED' });
      await http()
        .get(`/drawings/${d.id}/buyers`)
        .set(...bearer(seller))
        .expect(200);
    });
  });

  describe('GET /drawings/:id/reviews', () => {
    it('pages reviews newest first; non-published drawings are visible only to owner/admin', async () => {
      const d = await drawing({ status: 'PUBLISHED' });
      const reviewers = await Promise.all(
        ['Ann', 'Bob', 'Cy'].map((fullName) =>
          createTestUser(app, { fullName }),
        ),
      );
      for (const [i, r] of reviewers.entries()) {
        await prisma.review.create({
          data: {
            buyerId: r.user.id,
            drawingId: d.id,
            rating: 3 + (i % 3),
            comment: i === 0 ? null : `c${i}`,
            createdAt: new Date(2026, 0, 1 + i),
          },
        });
      }
      type R = {
        id: string;
        rating: number;
        comment: string | null;
        reviewer: { id: string; fullName: string };
      };
      const viewer = reviewers[0];
      const p1 = (
        await http()
          .get(`/drawings/${d.id}/reviews?limit=2`)
          .set(...bearer(viewer))
          .expect(200)
      ).body as Page<R>;
      expect(p1.items.map((r) => r.reviewer.fullName)).toEqual(['Cy', 'Bob']);
      expect(Object.keys(p1.items[0].reviewer).sort()).toEqual([
        'fullName',
        'id',
      ]);
      const p2 = (
        await http()
          .get(`/drawings/${d.id}/reviews?limit=2&cursor=${p1.nextCursor}`)
          .set(...bearer(viewer))
          .expect(200)
      ).body as Page<R>;
      expect(p2.items.map((r) => r.reviewer.fullName)).toEqual(['Ann']);
      expect(p2.items[0].comment).toBeNull();
      expect(p2.nextCursor).toBeNull();

      const draft = await drawing({ status: 'DRAFT' });
      const hidden = await http()
        .get(`/drawings/${draft.id}/reviews`)
        .set(...bearer(viewer))
        .expect(404);
      expect((hidden.body as ErrBody).error.code).toBe('NOT_FOUND');
      await http()
        .get(`/drawings/${draft.id}/reviews`)
        .set(...bearer(seller))
        .expect(200);
      const admin = await createTestUser(app, { role: 'ADMIN' });
      await http()
        .get(`/drawings/${draft.id}/reviews`)
        .set(...bearer(admin))
        .expect(200);
      await http().get(`/drawings/${d.id}/reviews`).expect(401);
    });
  });
});
