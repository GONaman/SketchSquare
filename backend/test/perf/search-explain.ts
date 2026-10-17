/**
 * Seeds synthetic drawings into the e2e database and prints EXPLAIN ANALYZE for representative search queries.
 *   TEST_DATABASE_URL=... npx ts-node test/perf/search-explain.ts [rows=50000]
 * It TRUNCATES every table first, so it only ever connects to TEST_DATABASE_URL (never DATABASE_URL).
 */
import { Prisma, PrismaClient } from '@prisma/client';
import { resetDb } from '../helpers/db';
import { TEST_DATABASE_URL } from '../helpers/test-db-url';
import {
  SearchParams,
  buildSearchQuery,
} from '../../src/discovery/search-query.builder';

const rows = Number(process.argv[2] ?? 50000);
const prisma = new PrismaClient({
  datasources: { db: { url: TEST_DATABASE_URL } },
});

async function seed() {
  await resetDb(prisma);
  await prisma.$executeRawUnsafe(`
    INSERT INTO "Category" ("name","slug") SELECT 'Cat ' || g, 'cat-' || g FROM generate_series(1,8) g`);
  await prisma.$executeRawUnsafe(`
    INSERT INTO "User" ("email","passwordHash","fullName","address","phone","city","verificationStatus","architectRating","architectRatingCount","updatedAt")
    SELECT 'u' || g || '@x.test','x','Arch ' || g,'addr','999',
      (ARRAY['Bengaluru','Delhi','Jaipur','Mumbai','Pune','Chennai','Hyderabad','Kolkata'])[1 + g % 8],
      CASE WHEN g % 10 = 0 THEN 'PENDING' ELSE 'APPROVED' END::"VerificationStatus",
      round((random()*5)::numeric, 1), (random()*30)::int, now()
    FROM generate_series(1,500) g`);
  await prisma.$executeRawUnsafe(`
    WITH u AS (SELECT array_agg("id" ORDER BY "id") a FROM "User"), c AS (SELECT array_agg("id" ORDER BY "id") a FROM "Category")
    INSERT INTO "Drawing" ("architectId","categoryId","title","description","city","plotLengthFt","plotBreadthFt","floors","facing","pricePaise","status","avgRating","ratingCount","viewCount","purchaseCount","createdAt","updatedAt")
    SELECT (SELECT a[1 + g % 500] FROM u),
      (SELECT a[1 + g % 8] FROM c),
      (ARRAY['Modern','Classic','Compact','Luxury','Duplex','Courtyard','Eco'])[1 + g % 7] || ' ' ||
        (ARRAY['villa','house','bungalow','hotel','bank','mall','office'])[1 + g % 7] || ' ' || g,
      'Plan with ' || (ARRAY['garden','parking','terrace','pool','vastu'])[1 + g % 5] || ' and ' || (ARRAY['solar','atrium','balcony'])[1 + g % 3],
      (ARRAY['Bengaluru','Delhi','Jaipur','Mumbai','Pune','Chennai','Hyderabad','Kolkata','Indore','Surat'])[1 + g % 10],
      15 + (g::bigint * 7919 % 650) / 10.0, 15 + (g::bigint * 104729 % 650) / 10.0, 1 + g % 4,
      (ARRAY['N','NE','E','SE','S','SW','W','NW'])[1 + g % 8]::"Facing",
      CASE WHEN g % 4 = 0 THEN 0 ELSE (g % 200 + 1) * 500 END,
      CASE WHEN g % 20 = 0 THEN 'DRAFT' WHEN g % 33 = 0 THEN 'REMOVED' ELSE 'PUBLISHED' END::"DrawingStatus",
      round((random()*5)::numeric,1), (random()*40)::int, (random()*1000)::int, (random()*50)::int,
      now() - (g || ' minutes')::interval, now()
    FROM generate_series(1, ${rows}) g`);
  await prisma.$executeRawUnsafe('ANALYZE "Drawing"');
  await prisma.$executeRawUnsafe('ANALYZE "User"');
}

const scenarios: Record<string, Partial<SearchParams>> = {
  'browse newest': { sort: 'newest' },
  'browse newest, page 2 cursor': {
    sort: 'newest',
    cursor: {
      s: 'newest',
      v: ['2026-10-01 00:00:00', '11111111-1111-4111-8111-111111111111'],
    },
  },
  'size 30x40 +-10% relevance': {
    size: { lengthFt: 30, breadthFt: 40, tolerancePct: 10 },
    sort: 'relevance',
  },
  'size 30x40 +-10% + city': {
    size: { lengthFt: 30, breadthFt: 40, tolerancePct: 10 },
    cities: ['Jaipur'],
    sort: 'size_match',
  },
  'full-text "villa"': { q: 'villa', sort: 'relevance' },
  'category + price_asc': { categoryId: '', sort: 'price_asc' },
  'free + drawing_rating': { priceType: 'free', sort: 'drawing_rating' },
  architect_rating: { sort: 'architect_rating' },
  popularity: { sort: 'popularity' },
};

async function main() {
  console.log(
    `Seeding ${rows} drawings into ${new URL(TEST_DATABASE_URL).pathname}`,
  );
  await seed();
  const cat = await prisma.category.findFirstOrThrow();
  for (const [name, over] of Object.entries(scenarios)) {
    const params: SearchParams = {
      sort: 'newest',
      limit: 20,
      ...over,
      ...(name.startsWith('category') ? { categoryId: cat.id } : {}),
    };
    const { sql } = buildSearchQuery(params);
    const plan = await prisma.$queryRaw<{ 'QUERY PLAN': string }[]>(
      Prisma.sql`EXPLAIN (ANALYZE, BUFFERS, COSTS OFF) ${sql}`,
    );
    console.log(`\n=== ${name}`);
    console.log(plan.map((r) => r['QUERY PLAN']).join('\n'));
  }
}

void main().finally(() => prisma.$disconnect());
