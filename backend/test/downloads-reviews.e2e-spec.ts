/* eslint-disable @typescript-eslint/no-unsafe-member-access, @typescript-eslint/no-unsafe-assignment, @typescript-eslint/no-unsafe-argument -- supertest bodies are untyped */
import { INestApplication } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PDFDocument } from 'pdf-lib';
import request from 'supertest';
import { Env } from '../src/config/env.schema';
import { PrismaService } from '../src/prisma/prisma.service';
import { StorageService } from '../src/storage/storage.service';
import { bearer, createTestUser, TestUser } from './helpers/auth';
import { buildCommerceApp } from './helpers/commerce-app';
import { createDrawing } from './helpers/commerce-fixtures';
import { resetDb } from './helpers/db';

describe('Downloads, library and reviews (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let storage: StorageService;
  let limit: number;
  let seller: TestUser;
  let buyer: TestUser;
  let stranger: TestUser;
  let paid: Awaited<ReturnType<typeof createDrawing>>;

  const http = () => request(app.getHttpServer());
  const download = (u: TestUser, drawingId: string, sheetId?: string) =>
    http()
      .get(`/drawings/${drawingId}/download`)
      .query(sheetId ? { sheetId } : {})
      .set(...bearer(u));

  async function seedOriginals(drawingId: string) {
    const sheets = await prisma.drawingSheet.findMany({ where: { drawingId } });
    const doc = await PDFDocument.create();
    doc.addPage([400, 400]);
    const bytes = Buffer.from(await doc.save());
    for (const s of sheets) {
      await storage.putOriginal(s.originalKey, bytes, 'application/pdf');
    }
    return sheets;
  }

  const sheetOf = async (drawingId: string) =>
    (
      await prisma.drawingSheet.findFirstOrThrow({
        where: { drawingId },
        orderBy: { createdAt: 'asc' },
      })
    ).id;

  const makePaid = (u: TestUser, drawingId: string, pricePaise = 100000) =>
    prisma.purchase.create({
      data: {
        buyerId: u.user.id,
        drawingId,
        pricePaise,
        platformFeePaise: 0,
        status: 'PAID',
        paidAt: new Date(),
      },
    });

  beforeAll(async () => {
    ({ app, prisma } = await buildCommerceApp());
    storage = app.get(StorageService);
    limit = app
      .get<ConfigService<Env, true>>(ConfigService)
      .get('FREE_DOWNLOAD_LIMIT', { infer: true });
  });

  afterAll(async () => {
    await resetDb(prisma);
    await app.close();
  });

  beforeEach(async () => {
    await resetDb(prisma);
    seller = await createTestUser(app, { fullName: 'Seller' });
    buyer = await createTestUser(app, { fullName: 'Buyer Person' });
    stranger = await createTestUser(app, { fullName: 'Stranger' });
    paid = await createDrawing(prisma, seller.user.id, { pricePaise: 100000 });
  });

  describe('GET /drawings/:id/download', () => {
    it('requires authentication', async () => {
      await http().get(`/drawings/${paid.id}/download`).expect(401);
    });

    it('denies non-buyers, serves buyers a 5-minute licensed copy and owners the original', async () => {
      const sheets = await seedOriginals(paid.id);
      const sheetId = sheets[0].id;

      const denied = await download(stranger, paid.id, sheetId).expect(403);
      expect(denied.body.error.code).toBe('FORBIDDEN');

      const purchase = await makePaid(buyer, paid.id);
      const res = await download(buyer, paid.id, sheetId).expect(200);
      expect(res.body).toMatchObject({
        expiresInSeconds: 300,
        fileName: sheets[0].fileName,
      });
      expect(res.body.url).toContain(`licensed/${purchase.id}/${sheetId}/`);
      expect(res.body.url).toContain('X-Amz-Expires=300');
      expect(res.body.url).not.toContain(sheets[0].originalKey);
      const file = await fetch(res.body.url);
      expect(file.status).toBe(200);
      expect(file.headers.get('content-disposition')).toContain('attachment');
      const stamped = await PDFDocument.load(await file.arrayBuffer());
      expect(stamped.getPageCount()).toBe(1);

      const owner = await download(seller, paid.id, sheetId).expect(200);
      expect(owner.body.url).toContain(sheets[0].originalKey);
      expect((await fetch(owner.body.url)).status).toBe(200);
    });

    it('validates the sheet selection', async () => {
      await seedOriginals(paid.id);
      await makePaid(buyer, paid.id);
      await download(buyer, paid.id).expect(400);
      const other = await createDrawing(prisma, seller.user.id);
      await download(buyer, paid.id, await sheetOf(other.id)).expect(404);
      await download(buyer, paid.id, 'nope').expect(400);
      await http()
        .get('/drawings/3f2a1b7c-0000-4000-8000-000000000000/download')
        .set(...bearer(buyer))
        .expect(404);
    });

    it('a refunded or unpaid purchase does not entitle', async () => {
      await seedOriginals(paid.id);
      await prisma.purchase.create({
        data: {
          buyerId: buyer.user.id,
          drawingId: paid.id,
          pricePaise: 1,
          platformFeePaise: 0,
          status: 'CREATED',
        },
      });
      await download(buyer, paid.id, await sheetOf(paid.id)).expect(403);
    });

    it('past buyers keep access after the drawing is removed', async () => {
      await seedOriginals(paid.id);
      await makePaid(buyer, paid.id);
      await prisma.drawing.update({
        where: { id: paid.id },
        data: { status: 'REMOVED' },
      });
      await download(buyer, paid.id, await sheetOf(paid.id)).expect(200);
    });
  });

  describe('free downloads and quota', () => {
    const freeDrawing = async (status: 'PUBLISHED' | 'DRAFT' = 'PUBLISHED') => {
      const d = await createDrawing(prisma, seller.user.id, {
        pricePaise: 0,
        status,
      });
      await seedOriginals(d.id);
      return d;
    };
    const used = async (u: TestUser) =>
      (await prisma.user.findUniqueOrThrow({ where: { id: u.user.id } }))
        .freeDownloadsUsed;

    it('counts each distinct free drawing once; repeats are free', async () => {
      const d = await freeDrawing();
      const sheetId = await sheetOf(d.id);
      await download(buyer, d.id, sheetId).expect(200);
      await download(buyer, d.id, sheetId).expect(200);
      expect(await used(buyer)).toBe(1);
      expect(await prisma.freeDownload.count()).toBe(1);
    });

    it('does not let strangers claim an unpublished free drawing, and the owner is exempt', async () => {
      const d = await freeDrawing('DRAFT');
      const sheetId = await sheetOf(d.id);
      await download(buyer, d.id, sheetId).expect(404);
      expect(await prisma.freeDownload.count()).toBe(0);
      await download(seller, d.id, sheetId).expect(200);
      expect(await used(seller)).toBe(0);
    });

    it('rejects with FREE_LIMIT_REACHED at the quota and keeps access to already-claimed drawings', async () => {
      const first = await freeDrawing();
      await download(buyer, first.id, await sheetOf(first.id)).expect(200);
      await prisma.user.update({
        where: { id: buyer.user.id },
        data: { freeDownloadsUsed: limit },
      });
      const next = await freeDrawing();
      const res = await download(buyer, next.id, await sheetOf(next.id)).expect(
        403,
      );
      expect(res.body.error.code).toBe('FREE_LIMIT_REACHED');
      expect(await used(buyer)).toBe(limit);
      expect(
        await prisma.freeDownload.count({ where: { drawingId: next.id } }),
      ).toBe(0);
      await download(buyer, first.id, await sheetOf(first.id)).expect(200);
    });

    it('parallel claims at the boundary never exceed the limit', async () => {
      await prisma.user.update({
        where: { id: buyer.user.id },
        data: { freeDownloadsUsed: limit - 2 },
      });
      const drawings = await Promise.all(
        Array.from({ length: 6 }, () => freeDrawing()),
      );
      const results = await Promise.all(
        drawings.map(async (d) => download(buyer, d.id, await sheetOf(d.id))),
      );
      const ok = results.filter((r) => r.status === 200);
      const rejected = results.filter((r) => r.status === 403);
      expect(ok).toHaveLength(2);
      expect(rejected).toHaveLength(4);
      rejected.forEach((r) =>
        expect(r.body.error.code).toBe('FREE_LIMIT_REACHED'),
      );
      expect(await used(buyer)).toBe(limit);
      expect(await prisma.freeDownload.count()).toBe(2);
    });

    it('parallel downloads of the same free drawing consume one unit', async () => {
      const d = await freeDrawing();
      const sheetId = await sheetOf(d.id);
      const results = await Promise.all(
        Array.from({ length: 6 }, () => download(buyer, d.id, sheetId)),
      );
      results.forEach((r) => expect(r.status).toBe(200));
      expect(await used(buyer)).toBe(1);
    });
  });

  describe('GET /me/purchases', () => {
    it('lists paid and free items newest first with sheets, and paginates', async () => {
      const free = await createDrawing(prisma, seller.user.id, {
        pricePaise: 0,
      });
      const p1 = await makePaid(buyer, paid.id);
      await new Promise((r) => setTimeout(r, 20));
      await prisma.freeDownload.create({
        data: { userId: buyer.user.id, drawingId: free.id },
      });
      const other = await createDrawing(prisma, seller.user.id);
      await prisma.purchase.create({
        data: {
          buyerId: buyer.user.id,
          drawingId: other.id,
          pricePaise: 1,
          platformFeePaise: 0,
          status: 'CREATED',
        },
      });
      await makePaid(stranger, other.id);

      const page1 = await http()
        .get('/me/purchases')
        .query({ limit: 1 })
        .set(...bearer(buyer))
        .expect(200);
      expect(page1.body.items).toHaveLength(1);
      expect(page1.body.nextCursor).toEqual(expect.any(String));
      expect(page1.body.items[0]).toMatchObject({
        kind: 'FREE',
        pricePaise: 0,
        purchaseId: null,
      });
      expect(page1.body.items[0].drawing.sheets).toHaveLength(2);
      expect(page1.body.items[0].drawing.sheets[0]).not.toHaveProperty(
        'originalKey',
      );

      const page2 = await http()
        .get('/me/purchases')
        .query({ limit: 1, cursor: page1.body.nextCursor })
        .set(...bearer(buyer))
        .expect(200);
      expect(page2.body.nextCursor).toBeNull();
      expect(page2.body.items[0]).toMatchObject({
        kind: 'PAID',
        pricePaise: 100000,
        purchaseId: p1.id,
      });
      expect(page2.body.items[0].drawing.id).toBe(paid.id);
    });
  });

  describe('PUT /drawings/:id/review', () => {
    const put = (u: TestUser, drawingId: string, body: object) =>
      http()
        .put(`/drawings/${drawingId}/review`)
        .set(...bearer(u))
        .send(body);

    it('only buyers (paid or free) who are not the author may review', async () => {
      await put(stranger, paid.id, { rating: 5 }).expect(403);
      await put(seller, paid.id, { rating: 5 }).expect(403);
      await put(buyer, '3f2a1b7c-0000-4000-8000-000000000000', {
        rating: 5,
      }).expect(404);
      expect(await prisma.review.count()).toBe(0);

      await prisma.purchase.create({
        data: {
          buyerId: buyer.user.id,
          drawingId: paid.id,
          pricePaise: 1,
          platformFeePaise: 0,
          status: 'CREATED',
        },
      });
      await put(buyer, paid.id, { rating: 5 }).expect(403);

      const free = await createDrawing(prisma, seller.user.id, {
        pricePaise: 0,
      });
      await prisma.freeDownload.create({
        data: { userId: stranger.user.id, drawingId: free.id },
      });
      await put(stranger, free.id, { rating: 4 }).expect(200);
    });

    it('validates input', async () => {
      await makePaid(buyer, paid.id);
      await put(buyer, paid.id, { rating: 0 }).expect(400);
      await put(buyer, paid.id, { rating: 6 }).expect(400);
      await put(buyer, paid.id, { rating: 3.5 }).expect(400);
      await put(buyer, paid.id, {}).expect(400);
      await put(buyer, paid.id, {
        rating: 3,
        comment: 'x'.repeat(1001),
      }).expect(400);
    });

    it('creates then updates a single review per buyer and maintains aggregates', async () => {
      await makePaid(buyer, paid.id);
      await makePaid(stranger, paid.id);
      const second = await createDrawing(prisma, seller.user.id);
      await makePaid(buyer, second.id);

      const a = await put(buyer, paid.id, {
        rating: 5,
        comment: '  Great plan ',
      }).expect(200);
      expect(a.body).toMatchObject({
        rating: 5,
        comment: 'Great plan',
        reviewer: { id: buyer.user.id, fullName: 'Buyer Person' },
      });
      await put(stranger, paid.id, { rating: 2 }).expect(200);
      await put(buyer, second.id, { rating: 4 }).expect(200);

      let d = await prisma.drawing.findUniqueOrThrow({
        where: { id: paid.id },
      });
      expect([d.avgRating, d.ratingCount]).toEqual([3.5, 2]);
      let arch = await prisma.user.findUniqueOrThrow({
        where: { id: seller.user.id },
      });
      expect([arch.architectRating, arch.architectRatingCount]).toEqual([
        3.67, 3,
      ]);

      const b = await put(buyer, paid.id, { rating: 1, comment: null }).expect(
        200,
      );
      expect(b.body.id).toBe(a.body.id);
      expect(b.body.comment).toBeNull();
      expect(await prisma.review.count()).toBe(3);
      d = await prisma.drawing.findUniqueOrThrow({ where: { id: paid.id } });
      expect([d.avgRating, d.ratingCount]).toEqual([1.5, 2]);
      arch = await prisma.user.findUniqueOrThrow({
        where: { id: seller.user.id },
      });
      expect([arch.architectRating, arch.architectRatingCount]).toEqual([
        2.33, 3,
      ]);
    });

    it('concurrent reviews from many buyers leave consistent aggregates', async () => {
      const buyers = await Promise.all(
        Array.from({ length: 8 }, () => createTestUser(app)),
      );
      await Promise.all(buyers.map((b) => makePaid(b, paid.id)));
      const ratings = [1, 2, 3, 4, 5, 5, 4, 3];
      const results = await Promise.all(
        buyers.map((b, i) => put(b, paid.id, { rating: ratings[i] })),
      );
      results.forEach((r) => expect(r.status).toBe(200));
      const d = await prisma.drawing.findUniqueOrThrow({
        where: { id: paid.id },
      });
      expect(d.ratingCount).toBe(8);
      expect(d.avgRating).toBe(3.38);
      const arch = await prisma.user.findUniqueOrThrow({
        where: { id: seller.user.id },
      });
      expect([arch.architectRating, arch.architectRatingCount]).toEqual([
        3.38, 8,
      ]);
    });
  });
});
