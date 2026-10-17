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

interface Item {
  id: string;
  title: string;
  pricePaise: number;
  isFree: boolean;
  sizeMatch?: number;
  previewUrl: string | null;
  city: string;
  architect: { id: string; ratingCount: number };
  category: { id: string };
}
interface PageBody {
  items: Item[];
  nextCursor: string | null;
}
interface ErrBody {
  error: { code: string };
}

describe('GET /drawings/search (e2e)', () => {
  let app: INestApplication<App>;
  let prisma: PrismaService;
  let viewer: TestUser;
  const search = (qs: string) =>
    request(app.getHttpServer())
      .get(`/drawings/search?${qs}`)
      .set(...bearer(viewer));
  const ok = async (qs: string): Promise<PageBody> =>
    (await search(qs).expect(200)).body as PageBody;
  const titles = (b: PageBody) => b.items.map((i) => i.title);

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();
    app = moduleRef.createNestApplication();
    configureApp(app);
    await app.init();
    prisma = app.get(PrismaService);
  });
  afterAll(async () => {
    await resetDb(prisma);
    await app.close();
  });
  beforeEach(async () => {
    await resetDb(prisma);
    viewer = await createTestUser(app);
  });

  describe('access', () => {
    it('requires a token and an APPROVED viewer', async () => {
      const http = request(app.getHttpServer());
      await http.get('/drawings/search').expect(401);
      const pending = await createTestUser(app, {
        verificationStatus: 'PENDING',
      });
      const res = await http
        .get('/drawings/search')
        .set(...bearer(pending))
        .expect(403);
      expect((res.body as ErrBody).error.code).toBe('VERIFICATION_REQUIRED');
    });
  });

  describe('visibility', () => {
    it('only returns PUBLISHED drawings of APPROVED architects', async () => {
      const cat = await createCategory(prisma);
      const ok1 = await createArchitect(prisma);
      const pending = await createArchitect(prisma, {
        verificationStatus: 'PENDING',
      });
      const rejected = await createArchitect(prisma, {
        verificationStatus: 'REJECTED',
      });
      const base = { categoryId: cat.id };
      await createDrawing(prisma, {
        ...base,
        architectId: ok1.id,
        title: 'visible',
      });
      for (const status of [
        'DRAFT',
        'PROCESSING',
        'UNDER_REVIEW',
        'REMOVED',
        'FAILED',
      ] as const) {
        await createDrawing(prisma, {
          ...base,
          architectId: ok1.id,
          title: status,
          status,
        });
      }
      await createDrawing(prisma, {
        ...base,
        architectId: pending.id,
        title: 'pending architect',
      });
      await createDrawing(prisma, {
        ...base,
        architectId: rejected.id,
        title: 'rejected architect',
      });

      expect(titles(await ok(''))).toEqual(['visible']);
    });

    it('returns the summary shape with watermarked preview url only', async () => {
      const cat = await createCategory(prisma, 'Villas');
      const a = await createArchitect(prisma, {
        fullName: 'Ar One',
        architectRating: 4.2,
        architectRatingCount: 5,
      });
      const d = await createDrawing(prisma, {
        architectId: a.id,
        categoryId: cat.id,
        pricePaise: 49900,
        previewKeys: ['x/1.png', 'x/2.png'],
      });
      const body = await ok('');
      const item = body.items[0] as Item & Record<string, unknown>;
      expect(item.id).toBe(d.id);
      expect(item.previewUrl).toMatch(/\/x\/1\.png$/);
      expect(item.isFree).toBe(false);
      expect(item.sizeMatch).toBeUndefined();
      expect(item.architect).toMatchObject({
        fullName: 'Ar One',
        architectRating: 4.2,
        ratingCount: 5,
      });
      expect(item.category).toMatchObject({ name: 'Villas' });
      expect(JSON.stringify(item)).not.toContain('orig/');
    });

    it('previewUrl is null when there are no preview sheets', async () => {
      const cat = await createCategory(prisma);
      const a = await createArchitect(prisma);
      await createDrawing(prisma, { architectId: a.id, categoryId: cat.id });
      expect((await ok('')).items[0].previewUrl).toBeNull();
    });
  });

  describe('plot size search', () => {
    let cat: { id: string };
    let arch: { id: string };
    const plot = (title: string, l: number, b: number, extra: object = {}) =>
      createDrawing(prisma, {
        architectId: arch.id,
        categoryId: cat.id,
        title,
        plotLengthFt: l,
        plotBreadthFt: b,
        ...extra,
      });

    beforeEach(async () => {
      cat = await createCategory(prisma);
      arch = await createArchitect(prisma);
      await plot('exact 30x40', 30, 40);
      await plot('rotated 40x30', 40, 30);
      await plot('near 31x41', 31, 41);
      await plot('edge low 27x36', 27, 36);
      await plot('edge high 33x44', 33, 44);
      await plot('just outside 26.9x40', 26.9, 40);
      await plot('one dim off 30x50', 30, 50);
      await plot('mixed 30x30', 30, 30);
      await plot('far 60x80', 60, 80);
    });

    it('matches both dimensions within default 10% tolerance, including the rotated plot', async () => {
      const body = await ok('length=30&breadth=40&limit=50');
      expect(new Set(titles(body))).toEqual(
        new Set([
          'exact 30x40',
          'rotated 40x30',
          'near 31x41',
          'edge low 27x36',
          'edge high 33x44',
        ]),
      );
    });

    it('is symmetric: asking 40x30 returns the same set', async () => {
      const a = await ok('length=30&breadth=40&limit=50');
      const b = await ok('length=40&breadth=30&limit=50');
      expect(new Set(titles(b))).toEqual(new Set(titles(a)));
    });

    it('returns sizeMatch with exact (and exact rotated) first under relevance', async () => {
      const body = await ok('length=30&breadth=40&limit=50');
      expect(body.items.every((i) => typeof i.sizeMatch === 'number')).toBe(
        true,
      );
      expect(new Set(titles(body).slice(0, 2))).toEqual(
        new Set(['exact 30x40', 'rotated 40x30']),
      );
      expect(body.items[0].sizeMatch).toBe(1);
      expect(body.items[1].sizeMatch).toBe(1);
      expect(titles(body)[2]).toBe('near 31x41');
      const scores = body.items.map((i) => i.sizeMatch as number);
      expect([...scores].sort((x, y) => y - x)).toEqual(scores);
      // Plots exactly on the tolerance edge score 0 but still match.
      expect(body.items.at(-1)?.sizeMatch).toBeCloseTo(0, 4);
    });

    it('tolerancePct=0 returns exact matches only (either orientation)', async () => {
      const body = await ok('length=30&breadth=40&tolerancePct=0');
      expect(new Set(titles(body))).toEqual(
        new Set(['exact 30x40', 'rotated 40x30']),
      );
      expect(body.items.every((i) => i.sizeMatch === 1)).toBe(true);
    });

    it('widening the tolerance widens the result', async () => {
      const body = await ok('length=30&breadth=40&tolerancePct=15&limit=50');
      expect(titles(body)).toContain('just outside 26.9x40');
      expect(titles(body)).not.toContain('one dim off 30x50');
      const wide = await ok('length=30&breadth=40&tolerancePct=50&limit=50');
      expect(titles(wide)).toContain('one dim off 30x50');
      expect(titles(wide)).not.toContain('far 60x80');
    });

    it('a small tolerance excludes the edge plots', async () => {
      const body = await ok('length=30&breadth=40&tolerancePct=5&limit=50');
      expect(new Set(titles(body))).toEqual(
        new Set(['exact 30x40', 'rotated 40x30', 'near 31x41']),
      );
    });

    it('converts metres to feet (9.144m x 12.192m == 30ft x 40ft)', async () => {
      const body = await ok(
        'length=9.144&breadth=12.192&unit=m&tolerancePct=0',
      );
      expect(new Set(titles(body))).toEqual(
        new Set(['exact 30x40', 'rotated 40x30']),
      );
    });

    it('sort=size_match orders by closeness, breaking ties by newest', async () => {
      const body = await ok('length=30&breadth=40&sort=size_match&limit=50');
      const scores = body.items.map((i) => i.sizeMatch as number);
      expect([...scores].sort((x, y) => y - x)).toEqual(scores);
    });

    it('combines with other filters', async () => {
      await plot('paid exact', 30, 40, { pricePaise: 10000 });
      const body = await ok('length=30&breadth=40&priceType=paid');
      expect(titles(body)).toEqual(['paid exact']);
    });

    it('rejects a lone dimension, bad numbers and size_match without a size', async () => {
      for (const qs of [
        'length=30',
        'breadth=40',
        'length=-5&breadth=40',
        'length=abc&breadth=40',
        'length=30&breadth=40&unit=cm',
        'length=30&breadth=40&tolerancePct=51',
        'length=30&breadth=40&tolerancePct=-1',
        'sort=size_match',
      ]) {
        const res = await search(qs).expect(400);
        expect((res.body as ErrBody).error.code).toBe('VALIDATION_ERROR');
      }
    });
  });

  describe('filters', () => {
    let villas: { id: string };
    let houses: { id: string };
    let delhi: { id: string };
    let blr: { id: string };

    beforeEach(async () => {
      villas = await createCategory(prisma, 'Villas');
      houses = await createCategory(prisma, 'Houses');
      blr = await createArchitect(prisma, {
        city: 'Bengaluru',
        architectRating: 4.6,
        architectRatingCount: 9,
      });
      delhi = await createArchitect(prisma, {
        city: 'Delhi',
        architectRating: 3.1,
        architectRatingCount: 4,
      });
      const d = (title: string, over: object) =>
        createDrawing(prisma, {
          architectId: blr.id,
          categoryId: houses.id,
          title,
          ...over,
        });
      await d('free blr house', {
        pricePaise: 0,
        city: 'Bengaluru',
        avgRating: 4.8,
        floors: 2,
        facing: 'N',
        bedrooms: 3,
        tags: ['Vastu', 'Corner plot'],
      });
      await d('cheap jaipur house', {
        pricePaise: 20000,
        city: 'Jaipur',
        avgRating: 3.0,
        floors: 1,
        facing: 'E',
        bedrooms: 2,
        tags: ['vastu'],
      });
      await createDrawing(prisma, {
        architectId: delhi.id,
        categoryId: villas.id,
        title: 'premium delhi villa',
        pricePaise: 900000,
        city: 'Delhi',
        avgRating: 4.2,
        floors: 3,
        facing: 'NE',
        bedrooms: 5,
        description: 'Spacious courtyard with garden',
      });
    });

    it('categoryId', async () => {
      expect(titles(await ok(`categoryId=${villas.id}`))).toEqual([
        'premium delhi villa',
      ]);
      expect(
        await ok(`categoryId=${houses.id}&limit=50`).then((b) => b.items),
      ).toHaveLength(2);
    });

    it('city (repeatable and case-insensitive)', async () => {
      expect(titles(await ok('city=delhi'))).toEqual(['premium delhi villa']);
      expect(new Set(titles(await ok('city=DELHI&city=jaipur')))).toEqual(
        new Set(['premium delhi villa', 'cheap jaipur house']),
      );
      expect(await ok('city=Mumbai').then((b) => b.items)).toHaveLength(0);
    });

    it('minDrawingRating', async () => {
      expect(new Set(titles(await ok('minDrawingRating=4')))).toEqual(
        new Set(['free blr house', 'premium delhi villa']),
      );
      expect(titles(await ok('minDrawingRating=4.5'))).toEqual([
        'free blr house',
      ]);
    });

    it('minArchitectRating', async () => {
      expect(new Set(titles(await ok('minArchitectRating=4')))).toEqual(
        new Set(['free blr house', 'cheap jaipur house']),
      );
    });

    it('priceType free / paid / all', async () => {
      expect(titles(await ok('priceType=free'))).toEqual(['free blr house']);
      expect((await ok('priceType=free')).items[0].isFree).toBe(true);
      expect(
        await ok('priceType=paid&limit=50').then((b) => b.items),
      ).toHaveLength(2);
      expect(
        await ok('priceType=all&limit=50').then((b) => b.items),
      ).toHaveLength(3);
    });

    it('price range is inclusive and composes with priceType', async () => {
      expect(
        titles(await ok('minPricePaise=20000&maxPricePaise=20000')),
      ).toEqual(['cheap jaipur house']);
      expect(titles(await ok('maxPricePaise=100000&priceType=paid'))).toEqual([
        'cheap jaipur house',
      ]);
      expect(titles(await ok('minPricePaise=500000'))).toEqual([
        'premium delhi villa',
      ]);
      await search('minPricePaise=10&maxPricePaise=5').expect(400);
    });

    it('bedrooms (repeatable) and tag (all must match, case-insensitive)', async () => {
      expect(titles(await ok('bedrooms=3'))).toEqual(['free blr house']);
      expect(new Set(titles(await ok('bedrooms=2&bedrooms=5')))).toEqual(
        new Set(['cheap jaipur house', 'premium delhi villa']),
      );
      expect(new Set(titles(await ok('tag=VASTU')))).toEqual(
        new Set(['free blr house', 'cheap jaipur house']),
      );
      expect(titles(await ok('tag=vastu&tag=corner%20plot'))).toEqual([
        'free blr house',
      ]);
      expect(titles(await ok('tag=nope'))).toEqual([]);
      await search('bedrooms=21').expect(400);
      await search('bedrooms=x').expect(400);
      await search('tag=1&tag=2&tag=3&tag=4&tag=5&tag=6').expect(400);
    });

    it('floors (repeatable) and facing (repeatable)', async () => {
      expect(titles(await ok('floors=2'))).toEqual(['free blr house']);
      expect(new Set(titles(await ok('floors=1&floors=3')))).toEqual(
        new Set(['cheap jaipur house', 'premium delhi villa']),
      );
      expect(new Set(titles(await ok('facing=N&facing=NE')))).toEqual(
        new Set(['free blr house', 'premium delhi villa']),
      );
      await search('facing=UP').expect(400);
    });

    it('architectId', async () => {
      expect(titles(await ok(`architectId=${delhi.id}`))).toEqual([
        'premium delhi villa',
      ]);
    });

    it('full-text q matches title and description, ranks title above description', async () => {
      await createDrawing(prisma, {
        architectId: blr.id,
        categoryId: houses.id,
        title: 'Courtyard house',
        description: 'Plain description',
      });
      const body = await ok('q=courtyard');
      expect(titles(body)).toEqual(['Courtyard house', 'premium delhi villa']);
      expect(titles(await ok('q=villa'))).toEqual(['premium delhi villa']);
      expect(titles(await ok('q=nonexistentword'))).toEqual([]);
    });

    it('q is safe against SQL and tsquery syntax characters', async () => {
      for (const q of ['\'; DROP TABLE "Drawing"; --', '&|!()<->:*', '   ']) {
        await search(`q=${encodeURIComponent(q)}`).expect(200);
      }
      expect(await prisma.drawing.count()).toBe(3);
    });

    it('combines filters (AND)', async () => {
      expect(titles(await ok('city=Bengaluru&priceType=paid'))).toEqual([]);
      expect(
        titles(await ok('city=Bengaluru&priceType=free&floors=2&facing=N')),
      ).toEqual(['free blr house']);
    });
  });

  describe('sorting', () => {
    beforeEach(async () => {
      const cat = await createCategory(prisma);
      const lo = await createArchitect(prisma, { architectRating: 2 });
      const hi = await createArchitect(prisma, { architectRating: 4.9 });
      const day = (n: number) => new Date(Date.UTC(2026, 0, n));
      const d = (title: string, architectId: string, over: object) =>
        createDrawing(prisma, {
          architectId,
          categoryId: cat.id,
          title,
          ...over,
        });
      await d('A', lo.id, {
        pricePaise: 300,
        avgRating: 3,
        ratingCount: 2,
        createdAt: day(1),
        purchaseCount: 1,
        viewCount: 50,
      });
      await d('B', hi.id, {
        pricePaise: 100,
        avgRating: 5,
        ratingCount: 1,
        createdAt: day(3),
        purchaseCount: 9,
        viewCount: 5,
      });
      await d('C', hi.id, {
        pricePaise: 200,
        avgRating: 5,
        ratingCount: 7,
        createdAt: day(2),
        purchaseCount: 9,
        viewCount: 80,
      });
      await d('D', lo.id, {
        pricePaise: 0,
        avgRating: 0,
        ratingCount: 0,
        createdAt: day(4),
        purchaseCount: 0,
        viewCount: 0,
      });
    });

    it.each([
      ['newest', ['D', 'B', 'C', 'A']],
      ['price_asc', ['D', 'B', 'C', 'A']],
      ['price_desc', ['A', 'C', 'B', 'D']],
      ['drawing_rating', ['C', 'B', 'A', 'D']],
      ['architect_rating', ['B', 'C', 'A', 'D']],
      ['popularity', ['C', 'B', 'A', 'D']],
      ['relevance', ['D', 'B', 'C', 'A']],
    ])('sort=%s', async (sort, expected) => {
      expect(titles(await ok(`sort=${sort}`))).toEqual(expected);
    });

    it('rejects an unknown sort', async () => {
      await search('sort=cheapest').expect(400);
    });
  });

  describe('cursor pagination', () => {
    const TOTAL = 31;
    beforeEach(async () => {
      const cat = await createCategory(prisma);
      const archs = [
        await createArchitect(prisma, { architectRating: 4 }),
        await createArchitect(prisma, { architectRating: 4 }),
        await createArchitect(prisma, { architectRating: 3.5 }),
      ];
      const sameInstant = new Date(Date.UTC(2026, 0, 1));
      for (let i = 0; i < TOTAL; i++) {
        // Heavy ties on every sort key (price, rating, popularity, createdAt) so only the id tiebreaker orders them.
        await createDrawing(prisma, {
          architectId: archs[i % 3].id,
          categoryId: cat.id,
          title: `Tie villa ${i}`,
          pricePaise: (i % 3) * 1000,
          avgRating: [4, 4.5, 4][i % 3],
          ratingCount: i % 2,
          purchaseCount: i % 4,
          viewCount: i % 5,
          plotLengthFt: 30 + (i % 4),
          plotBreadthFt: 40,
          createdAt: i % 2 === 0 ? sameInstant : new Date(Date.UTC(2026, 0, 2)),
        });
      }
    });

    async function walk(qs: string, limit: number): Promise<string[]> {
      const ids: string[] = [];
      let cursor: string | null = null;
      for (let guard = 0; guard < 50; guard++) {
        const page: PageBody = await ok(
          `${qs}&limit=${limit}${cursor ? `&cursor=${cursor}` : ''}`,
        );
        expect(page.items.length).toBeLessThanOrEqual(limit);
        ids.push(...page.items.map((i) => i.id));
        cursor = page.nextCursor;
        if (!cursor) return ids;
      }
      throw new Error('pagination did not terminate');
    }

    const sorts = [
      'relevance',
      'newest',
      'price_asc',
      'price_desc',
      'drawing_rating',
      'architect_rating',
      'popularity',
    ];
    const sizeQs = 'length=31&breadth=40&tolerancePct=15';

    it.each(sorts)(
      'sort=%s pages without gaps or duplicates and matches the unpaged order',
      async (sort) => {
        const full = (await ok(`sort=${sort}&limit=50`)).items.map((i) => i.id);
        expect(full).toHaveLength(TOTAL);
        for (const limit of [1, 7, 10, 30]) {
          const paged = await walk(`sort=${sort}`, limit);
          expect(new Set(paged).size).toBe(paged.length);
          expect(paged).toEqual(full);
        }
      },
    );

    it.each(['relevance', 'size_match', 'price_asc'])(
      'size search sort=%s is stable across pages',
      async (sort) => {
        const full = (await ok(`${sizeQs}&sort=${sort}&limit=50`)).items.map(
          (i) => i.id,
        );
        expect(full.length).toBeGreaterThan(10);
        expect(await walk(`${sizeQs}&sort=${sort}`, 4)).toEqual(full);
      },
    );

    it('text search relevance is stable across pages', async () => {
      const full = (await ok('q=villa&limit=50')).items.map((i) => i.id);
      expect(full).toHaveLength(TOTAL);
      expect(await walk('q=villa', 6)).toEqual(full);
    });

    it('nextCursor is null on the last page and defaults to 20 items', async () => {
      const first = await ok('');
      expect(first.items).toHaveLength(20);
      expect(first.nextCursor).not.toBeNull();
      const exact = await ok(`limit=${TOTAL}`);
      expect(exact.items).toHaveLength(TOTAL);
      expect(exact.nextCursor).toBeNull();
    });

    it('rows inserted mid-pagination do not duplicate or skip earlier items', async () => {
      const full = (await ok('sort=newest&limit=50')).items.map((i) => i.id);
      const page1 = await ok('sort=newest&limit=10');
      const cat = await createCategory(prisma);
      const a = await createArchitect(prisma);
      await createDrawing(prisma, {
        architectId: a.id,
        categoryId: cat.id,
        title: 'new arrival',
      });
      const page2 = await ok(`sort=newest&limit=50&cursor=${page1.nextCursor}`);
      const seen = [...page1.items, ...page2.items].map((i) => i.id);
      expect(seen).toEqual(full);
    });

    it('rejects malformed cursors, cursors from another sort, and bad limits', async () => {
      const page = await ok('sort=price_asc&limit=5');
      for (const qs of [
        'cursor=not-base64-json',
        `sort=newest&cursor=${page.nextCursor}`,
        `cursor=${Buffer.from(JSON.stringify({ s: 'relevance', v: ['x'] })).toString('base64url')}`,
        'limit=0',
        'limit=51',
        'limit=abc',
      ]) {
        const res = await search(qs).expect(400);
        expect((res.body as ErrBody).error.code).toBe('VALIDATION_ERROR');
      }
    });
  });

  it('rejects unknown query params', async () => {
    await search('bogus=1').expect(400);
  });
});
