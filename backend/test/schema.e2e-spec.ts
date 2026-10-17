import { PrismaClient } from '@prisma/client';
import { resetDb } from './helpers/db';

describe('Schema constraints', () => {
  const prisma = new PrismaClient();
  let buyerId: string;
  let drawingId: string;
  let categoryId: string;
  let architectId: string;

  const newUser = (email: string) =>
    prisma.user.create({
      data: {
        email,
        passwordHash: 'x',
        fullName: email,
        address: 'a',
        phone: '1',
        city: 'Jaipur',
      },
    });

  const newDrawing = (over: Record<string, unknown> = {}) =>
    prisma.drawing.create({
      data: {
        architectId,
        categoryId,
        title: 'Courtyard villa',
        description: 'A spacious villa with an inner courtyard',
        city: 'Jaipur',
        plotLengthFt: 30,
        plotBreadthFt: 40,
        pricePaise: 49900,
        ...over,
      },
    });

  beforeEach(async () => {
    await resetDb(prisma);
    architectId = (await newUser('arch@test.local')).id;
    buyerId = (await newUser('buyer@test.local')).id;
    categoryId = (
      await prisma.category.create({ data: { name: 'Villas', slug: 'villas' } })
    ).id;
    drawingId = (await newDrawing()).id;
  });

  afterAll(async () => {
    await resetDb(prisma);
    await prisma.$disconnect();
  });

  const purchase = (status: 'CREATED' | 'PAID' | 'FAILED' | 'REFUNDED') =>
    prisma.purchase.create({
      data: {
        buyerId,
        drawingId,
        pricePaise: 49900,
        platformFeePaise: 4990,
        status,
      },
    });

  describe('Purchase partial unique index', () => {
    it('allows only one PAID purchase per buyer and drawing', async () => {
      await purchase('PAID');
      await expect(purchase('PAID')).rejects.toMatchObject({ code: 'P2002' });
    });

    it('allows other statuses to coexist with a PAID one', async () => {
      await purchase('PAID');
      await purchase('CREATED');
      await purchase('FAILED');
      await purchase('REFUNDED');
      expect(await prisma.purchase.count()).toBe(4);
    });

    it('allows a new PAID purchase after the previous one is refunded', async () => {
      const first = await purchase('PAID');
      await prisma.purchase.update({
        where: { id: first.id },
        data: { status: 'REFUNDED' },
      });
      await expect(purchase('PAID')).resolves.toBeDefined();
    });
  });

  describe('CHECK constraints', () => {
    it('rejects negative prices and non-positive plot sizes', async () => {
      await expect(newDrawing({ pricePaise: -1 })).rejects.toThrow(
        /Drawing_pricePaise_check/,
      );
      await expect(newDrawing({ plotLengthFt: 0 })).rejects.toThrow(
        /Drawing_plotLengthFt_check/,
      );
      await expect(newDrawing({ floors: 0 })).rejects.toThrow(
        /Drawing_floors_check/,
      );
    });

    it('rejects ratings outside 1..5', async () => {
      for (const rating of [0, 6]) {
        await expect(
          prisma.review.create({ data: { buyerId, drawingId, rating } }),
        ).rejects.toThrow(/Review_rating_check/);
      }
      await expect(
        prisma.review.create({ data: { buyerId, drawingId, rating: 5 } }),
      ).resolves.toBeDefined();
    });

    it('allows one review per buyer per drawing', async () => {
      await prisma.review.create({ data: { buyerId, drawingId, rating: 4 } });
      await expect(
        prisma.review.create({ data: { buyerId, drawingId, rating: 3 } }),
      ).rejects.toMatchObject({ code: 'P2002' });
    });

    it('rejects a platform fee above the price', async () => {
      await expect(
        prisma.purchase.create({
          data: { buyerId, drawingId, pricePaise: 100, platformFeePaise: 101 },
        }),
      ).rejects.toThrow(/Purchase_platformFeePaise_check/);
    });
  });

  describe('Drawing derived columns', () => {
    it('maintains plotAreaSqft via trigger, including on update', async () => {
      const d = await newDrawing({ plotLengthFt: 30, plotBreadthFt: 40.5 });
      expect(d.plotAreaSqft).toBe(1215);
      const updated = await prisma.drawing.update({
        where: { id: d.id },
        data: { plotLengthFt: 20 },
      });
      expect(updated.plotAreaSqft).toBe(810);
    });

    it('full-text search vector matches title and description', async () => {
      const hits = (q: string) =>
        prisma.$queryRaw<{ id: string }[]>`
          SELECT id FROM "Drawing" WHERE "searchVector" @@ plainto_tsquery('english', ${q})`;
      expect((await hits('courtyard')).map((r) => r.id)).toContain(drawingId);
      expect((await hits('spacious villas')).map((r) => r.id)).toContain(
        drawingId,
      );
      expect(await hits('skyscraper')).toHaveLength(0);

      await prisma.drawing.update({
        where: { id: drawingId },
        data: { title: 'Bungalow' },
      });
      expect(await hits('courtyard')).toHaveLength(1); // still in description
      expect(await hits('bungalow')).toHaveLength(1);
    });

    it('has a GIN index on the search vector', async () => {
      const idx = await prisma.$queryRaw<{ indexdef: string }[]>`
        SELECT indexdef FROM pg_indexes WHERE indexname = 'Drawing_searchVector_idx'`;
      expect(idx[0].indexdef).toMatch(/USING gin/i);
    });
  });

  it('ProcessedWebhookEvent enforces idempotency by (provider, eventId)', async () => {
    const data = {
      provider: 'razorpay',
      eventId: 'evt_1',
      eventType: 'payment.captured',
    };
    await prisma.processedWebhookEvent.create({ data });
    await expect(
      prisma.processedWebhookEvent.create({ data }),
    ).rejects.toMatchObject({
      code: 'P2002',
    });
  });
});
