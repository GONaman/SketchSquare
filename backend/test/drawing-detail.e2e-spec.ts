import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { Category } from '@prisma/client';
import request from 'supertest';
import { App } from 'supertest/types';
import { AppModule } from '../src/app.module';
import { configureApp } from '../src/app.setup';
import { PrismaService } from '../src/prisma/prisma.service';
import { TestUser, bearer, createTestUser } from './helpers/auth';
import { resetDb } from './helpers/db';
import { createCategory, createDrawing } from './helpers/fixtures';

interface Sheet {
  id: string;
  isPreview: boolean;
  previewUrl: string | null;
}
interface Detail {
  id: string;
  status: string;
  title: string;
  description: string;
  bedrooms: number | null;
  tags: string[];
  viewCount: number;
  purchaseCount: number;
  failureReason: string | null;
  previewUrl: string | null;
  isFree: boolean;
  sheets: Sheet[];
  reviews: {
    items: { rating: number; reviewer: { fullName: string } }[];
    nextCursor: string | null;
  };
  viewer: {
    isOwner: boolean;
    isPurchased: boolean;
    inCart: boolean;
    canDownload: boolean;
    freeDownloadsRemaining: number | null;
    myReview: { rating: number } | null;
  };
}
interface ErrBody {
  error: { code: string };
}

describe('GET /drawings/:id (e2e)', () => {
  let app: INestApplication<App>;
  let prisma: PrismaService;
  let owner: TestUser;
  let viewer: TestUser;
  let admin: TestUser;
  let category: Category;
  const http = () => request(app.getHttpServer());
  const get = (id: string, as: TestUser = viewer) =>
    http()
      .get(`/drawings/${id}`)
      .set(...bearer(as));
  const detail = async (id: string, as: TestUser = viewer): Promise<Detail> =>
    (await get(id, as).expect(200)).body as Detail;

  const mk = (over: Partial<Parameters<typeof createDrawing>[1]> = {}) =>
    createDrawing(prisma, {
      architectId: owner.user.id,
      categoryId: category.id,
      previewKeys: ['d/p1.png'],
      ...over,
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
    owner = await createTestUser(app);
    viewer = await createTestUser(app);
    admin = await createTestUser(app, { role: 'ADMIN' });
    category = await createCategory(prisma);
  });

  afterAll(async () => {
    await resetDb(prisma);
    await app.close();
  });

  it('requires a token and an approved viewer', async () => {
    const d = await mk();
    await http().get(`/drawings/${d.id}`).expect(401);
    const pending = await createTestUser(app, {
      verificationStatus: 'PENDING',
    });
    await get(d.id, pending).expect(403);
  });

  it('returns the full public shape with watermarked previews only', async () => {
    const d = await mk({
      title: 'Villa',
      description: 'Nice villa',
      bedrooms: 3,
      tags: ['vastu', 'modern'],
    });
    await prisma.drawingSheet.create({
      data: {
        drawingId: d.id,
        type: 'STRUCTURAL',
        originalKey: 'secret/orig/structural.pdf',
        originalMime: 'application/pdf',
        fileName: 'structural.pdf',
        sizeBytes: 123,
        isPreview: false,
        previewKey: 'd/should-not-leak.png',
        createdAt: new Date(Date.now() + 60_000),
      },
    });
    const res = await get(d.id).expect(200);
    const body = res.body as Detail;
    expect(body).toMatchObject({
      id: d.id,
      title: 'Villa',
      description: 'Nice villa',
      bedrooms: 3,
      tags: ['vastu', 'modern'],
      status: 'PUBLISHED',
      failureReason: null,
      purchaseCount: 0,
    });
    expect(body.previewUrl).toMatch(/\/d\/p1\.png$/);
    expect(body.sheets).toHaveLength(2);
    expect(body.sheets[0]).toMatchObject({ isPreview: true });
    expect(body.sheets[0].previewUrl).toMatch(/\/d\/p1\.png$/);
    expect(body.sheets[1]).toMatchObject({
      isPreview: false,
      previewUrl: null,
    });
    const raw = JSON.stringify(res.body);
    expect(raw).not.toContain('originalKey');
    expect(raw).not.toContain('secret/orig');
    expect(raw).not.toContain('should-not-leak');
    expect(body.reviews).toEqual({ items: [], nextCursor: null });
  });

  it('hides non-published drawings from everyone but owner and admin', async () => {
    for (const status of [
      'DRAFT',
      'PROCESSING',
      'FAILED',
      'UNDER_REVIEW',
      'REMOVED',
    ] as const) {
      const d = await mk({ status, failureReason: 'boom' });
      const res = await get(d.id).expect(404);
      expect((res.body as ErrBody).error.code).toBe('NOT_FOUND');
      const own = await detail(d.id, owner);
      expect(own.status).toBe(status);
      expect(own.failureReason).toBe('boom');
      expect(own.sheets).toHaveLength(1);
      expect((await detail(d.id, admin)).status).toBe(status);
    }
  });

  it('hides published drawings of non-approved architects from other viewers', async () => {
    const d = await mk();
    await prisma.user.update({
      where: { id: owner.user.id },
      data: { verificationStatus: 'REJECTED' },
    });
    await get(d.id).expect(404);
  });

  it('404s for unknown ids and 400s for malformed ones; search is not shadowed', async () => {
    await get('00000000-0000-4000-8000-000000000000').expect(404);
    await get('not-a-uuid').expect(400);
    await http()
      .get('/drawings/search')
      .set(...bearer(viewer))
      .expect(200);
  });

  describe('viewer flags', () => {
    it('owner: isOwner and may download, no free quota info', async () => {
      const d = await mk({ pricePaise: 50000 });
      const own = await detail(d.id, owner);
      expect(own.viewer).toMatchObject({
        isOwner: true,
        isPurchased: false,
        canDownload: true,
        freeDownloadsRemaining: null,
      });
    });

    it('paid drawing: cannot download until a PAID purchase exists', async () => {
      const d = await mk({ pricePaise: 50000 });
      expect((await detail(d.id)).viewer).toMatchObject({
        isOwner: false,
        isPurchased: false,
        canDownload: false,
        freeDownloadsRemaining: null,
      });
      await prisma.purchase.create({
        data: {
          buyerId: viewer.user.id,
          drawingId: d.id,
          pricePaise: 50000,
          platformFeePaise: 5000,
          status: 'CREATED',
        },
      });
      expect((await detail(d.id)).viewer.isPurchased).toBe(false);
      await prisma.purchase.updateMany({
        data: { status: 'PAID', paidAt: new Date() },
      });
      expect((await detail(d.id)).viewer).toMatchObject({
        isPurchased: true,
        canDownload: true,
      });
    });

    it('free drawing: quota remaining, exhausted quota, and prior claims', async () => {
      const d = await mk({ pricePaise: 0 });
      const first = await detail(d.id);
      expect(first.isFree).toBe(true);
      expect(first.viewer.canDownload).toBe(true);
      const limit = first.viewer.freeDownloadsRemaining as number;
      expect(limit).toBeGreaterThan(0);

      await prisma.user.update({
        where: { id: viewer.user.id },
        data: { freeDownloadsUsed: limit },
      });
      const exhausted = await detail(d.id);
      expect(exhausted.viewer).toMatchObject({
        canDownload: false,
        freeDownloadsRemaining: 0,
      });

      await prisma.freeDownload.create({
        data: { userId: viewer.user.id, drawingId: d.id },
      });
      expect((await detail(d.id)).viewer.canDownload).toBe(true);
    });

    it('inCart and myReview reflect the caller only', async () => {
      const d = await mk({ pricePaise: 1000, ratingCount: 1, avgRating: 4 });
      await prisma.cartItem.create({
        data: { userId: viewer.user.id, drawingId: d.id },
      });
      await prisma.review.create({
        data: {
          buyerId: viewer.user.id,
          drawingId: d.id,
          rating: 4,
          comment: 'ok',
        },
      });
      const mine = await detail(d.id);
      expect(mine.viewer.inCart).toBe(true);
      expect(mine.viewer.myReview).toMatchObject({ rating: 4 });
      const other = await createTestUser(app);
      const theirs = await detail(d.id, other);
      expect(theirs.viewer.inCart).toBe(false);
      expect(theirs.viewer.myReview).toBeNull();
      expect(theirs.reviews.items).toHaveLength(1);
    });
  });

  describe('reviews first page', () => {
    it('returns the newest 10 with a cursor', async () => {
      const d = await mk({ pricePaise: 1000 });
      for (let i = 0; i < 12; i++) {
        const buyer = await createTestUser(app, { fullName: `Buyer ${i}` });
        await prisma.review.create({
          data: {
            buyerId: buyer.user.id,
            drawingId: d.id,
            rating: (i % 5) + 1,
            createdAt: new Date(Date.UTC(2026, 0, 1, 0, 0, i)),
          },
        });
      }
      const body = await detail(d.id);
      expect(body.reviews.items).toHaveLength(10);
      expect(body.reviews.items[0].reviewer.fullName).toBe('Buyer 11');
      expect(body.reviews.nextCursor).not.toBeNull();
    });
  });

  describe('GET /drawings/:id/reviews', () => {
    it('pages newest-first without gaps or repeats and enforces visibility', async () => {
      const d = await mk({ pricePaise: 1000 });
      const at = new Date(Date.UTC(2026, 0, 1));
      for (let i = 0; i < 5; i++) {
        const buyer = await createTestUser(app, { fullName: `B${i}` });
        await prisma.review.create({
          data: {
            buyerId: buyer.user.id,
            drawingId: d.id,
            rating: 5,
            createdAt: at, // identical timestamps: the id tiebreak must keep pages stable
          },
        });
      }
      type P = { items: { id: string }[]; nextCursor: string | null };
      const seen: string[] = [];
      let cursor: string | null = null;
      for (let guard = 0; guard < 5; guard++) {
        const q = `limit=2${cursor ? `&cursor=${cursor}` : ''}`;
        const page = (
          await http()
            .get(`/drawings/${d.id}/reviews?${q}`)
            .set(...bearer(viewer))
            .expect(200)
        ).body as P;
        seen.push(...page.items.map((r) => r.id));
        cursor = page.nextCursor;
        if (!cursor) break;
      }
      expect(seen).toHaveLength(5);
      expect(new Set(seen).size).toBe(5);

      await http()
        .get(`/drawings/${d.id}/reviews?cursor=garbage`)
        .set(...bearer(viewer))
        .expect(400);
      const draft = await mk({ status: 'DRAFT' });
      await http()
        .get(`/drawings/${draft.id}/reviews`)
        .set(...bearer(viewer))
        .expect(404);
      await http()
        .get(`/drawings/${draft.id}/reviews`)
        .set(...bearer(owner))
        .expect(200);
    });
  });

  describe('view recording', () => {
    const views = (id: string) =>
      prisma.drawingView.count({ where: { drawingId: id } });
    const stored = async (id: string) =>
      (await prisma.drawing.findUniqueOrThrow({ where: { id } })).viewCount;

    it('counts once per viewer per 24h and returns the updated count', async () => {
      const d = await mk();
      expect((await detail(d.id)).viewCount).toBe(1);
      expect((await detail(d.id)).viewCount).toBe(1);
      expect(await views(d.id)).toBe(1);

      await prisma.drawingView.updateMany({
        data: { viewedAt: new Date(Date.now() - 25 * 3_600_000) },
      });
      expect((await detail(d.id)).viewCount).toBe(2);
      expect(await views(d.id)).toBe(2);

      const other = await createTestUser(app);
      expect((await detail(d.id, other)).viewCount).toBe(3);
      expect(await stored(d.id)).toBe(3);
    });

    it('does not count the owner, admins, or non-published drawings', async () => {
      const d = await mk();
      await detail(d.id, owner);
      await detail(d.id, admin);
      expect(await views(d.id)).toBe(0);
      const draft = await mk({ status: 'DRAFT' });
      await detail(draft.id, owner);
      expect(await views(draft.id)).toBe(0);
    });

    it('parallel opens by one viewer record a single view', async () => {
      const d = await mk();
      const results = await Promise.all(
        Array.from({ length: 6 }, () => get(d.id)),
      );
      results.forEach((r) => expect(r.status).toBe(200));
      expect(await views(d.id)).toBe(1);
      expect(await stored(d.id)).toBe(1);
    });
  });
});
