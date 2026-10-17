/**
 * Seeds synthetic drawings into the e2e database and prints EXPLAIN ANALYZE for the hot read queries.
 *   TEST_DATABASE_URL=... npx ts-node test/perf/search-explain.ts [rows=50000]
 * It TRUNCATES every table first, so it only ever connects to TEST_DATABASE_URL (never DATABASE_URL).
 * The data generator is shared with `npm run seed:bulk`.
 */
import { Prisma, PrismaClient } from '@prisma/client';
import { insertBulk } from '../../scripts/bulk-data';
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

async function explain(name: string, query: Prisma.Sql) {
  const plan = await prisma.$queryRaw<{ 'QUERY PLAN': string }[]>(
    Prisma.sql`EXPLAIN (ANALYZE, BUFFERS, COSTS OFF) ${query}`,
  );
  console.log(`\n=== ${name}`);
  console.log(plan.map((r) => r['QUERY PLAN']).join('\n'));
}

async function main() {
  console.log(
    `Seeding ${rows} drawings into ${new URL(TEST_DATABASE_URL).pathname}`,
  );
  await resetDb(prisma);
  await insertBulk(prisma, { drawings: rows });
  const cat = await prisma.category.findFirstOrThrow();
  const architect = await prisma.user.findFirstOrThrow({
    where: { verificationStatus: 'APPROVED' },
  });

  for (const [name, over] of Object.entries(scenarios)) {
    const params: SearchParams = {
      sort: 'newest',
      limit: 20,
      ...over,
      ...(name.startsWith('category') ? { categoryId: cat.id } : {}),
    };
    await explain(name, buildSearchQuery(params).sql);
  }

  // Other hot reads: filter sheet (/cities), top architects, an architect's catalogue and "my drawings".
  await explain(
    'GET /cities',
    Prisma.sql`SELECT min(d."city") AS "city", count(*)::int AS "count"
      FROM "Drawing" d JOIN "User" u ON u."id" = d."architectId"
      WHERE d."status" = 'PUBLISHED' AND u."verificationStatus" = 'APPROVED'
      GROUP BY lower(d."city") ORDER BY count(*) DESC, lower(d."city") ASC`,
  );
  await explain(
    'GET /architects/top',
    Prisma.sql`SELECT u."id" FROM "User" u
      WHERE u."role" = 'ARCHITECT' AND u."verificationStatus" = 'APPROVED' AND u."architectRatingCount" >= 3
      ORDER BY u."architectRating" DESC, u."architectRatingCount" DESC, u."id" ASC LIMIT 20`,
  );
  await explain(
    'GET /architects/:id/drawings and /me/drawings (first page)',
    Prisma.sql`SELECT d."id" FROM "Drawing" d
      WHERE d."architectId" = ${architect.id}::uuid AND d."status" = 'PUBLISHED'
      ORDER BY d."createdAt" DESC, d."id" DESC LIMIT 21`,
  );
}

void main().finally(() => prisma.$disconnect());
