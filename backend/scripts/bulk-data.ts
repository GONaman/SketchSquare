/* eslint-disable no-console */
import { Prisma, PrismaClient } from '@prisma/client';

export interface BulkOptions {
  drawings: number;
  architects?: number;
  categories?: number;
  /** Namespaces the generated rows (emails / category slugs) so they can be topped up or removed again. */
  tag?: string;
}

const emailDomain = '@seed.sketchsquare.test';

/**
 * Synthetic catalogue for performance work: ~90 % PUBLISHED drawings across 10 cities / 7 plot-size bands / 8 sort-relevant
 * ratings, ~10 % of architects PENDING. Idempotent: only the missing difference to `drawings` is inserted.
 */
export async function insertBulk(
  prisma: PrismaClient,
  opts: BulkOptions,
): Promise<{ existing: number; inserted: number }> {
  const tag = opts.tag ?? 'bulk';
  const architects = opts.architects ?? 500;
  const categories = opts.categories ?? 8;
  const emailLike = `${tag}-%${emailDomain}`;

  await prisma.$executeRaw`
    INSERT INTO "Category" ("name","slug")
    SELECT ${`Bulk ${tag} `} || g, ${`bulk-${tag}-`} || g FROM generate_series(1, ${categories}::int) g
    ON CONFLICT DO NOTHING`;
  await prisma.$executeRaw`
    INSERT INTO "User" ("email","passwordHash","fullName","address","phone","city","verificationStatus","architectRating","architectRatingCount","updatedAt")
    SELECT ${`${tag}-`} || g || ${emailDomain}, 'x', 'Bulk Architect ' || g, 'addr', '999',
      (ARRAY['Bengaluru','Delhi','Jaipur','Mumbai','Pune','Chennai','Hyderabad','Kolkata'])[1 + g % 8],
      CASE WHEN g % 10 = 0 THEN 'PENDING' ELSE 'APPROVED' END::"VerificationStatus",
      round((random()*5)::numeric, 1), (random()*30)::int, now()
    FROM generate_series(1, ${architects}::int) g
    ON CONFLICT DO NOTHING`;

  const [{ n }] = await prisma.$queryRaw<{ n: number }[]>`
    SELECT count(*)::int AS n FROM "Drawing" d
    JOIN "User" u ON u."id" = d."architectId" WHERE u."email" LIKE ${emailLike}`;
  const missing = Math.max(0, opts.drawings - n);
  if (missing > 0) {
    // Batches keep each statement (and the WAL burst) small for 50k+ rows.
    const batch = 10000;
    for (let from = n + 1; from <= n + missing; from += batch) {
      const to = Math.min(from + batch - 1, n + missing);
      await prisma.$executeRaw`
        WITH u AS (SELECT array_agg("id" ORDER BY "id") a FROM "User" WHERE "email" LIKE ${emailLike}),
             c AS (SELECT array_agg("id" ORDER BY "id") a FROM "Category" WHERE "slug" LIKE ${`bulk-${tag}-%`})
        INSERT INTO "Drawing" ("architectId","categoryId","title","description","city","plotLengthFt","plotBreadthFt","floors","facing","pricePaise","status","avgRating","ratingCount","viewCount","purchaseCount","createdAt","updatedAt")
        SELECT (SELECT a[1 + g % cardinality(a)] FROM u),
          (SELECT a[1 + g % cardinality(a)] FROM c),
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
        FROM generate_series(${from}::int, ${to}::int) g`;
      console.log(`  inserted drawings ${from}..${to}`);
    }
  }
  await prisma.$executeRaw(Prisma.sql`ANALYZE "Drawing"`);
  await prisma.$executeRaw(Prisma.sql`ANALYZE "User"`);
  return { existing: n, inserted: missing };
}

/** Removes everything `insertBulk` created for the tag (drawings first: Drawing → User is RESTRICT). */
export async function cleanBulk(
  prisma: PrismaClient,
  tag = 'bulk',
): Promise<number> {
  const emailLike = `${tag}-%${emailDomain}`;
  const removed = await prisma.$executeRaw`
    DELETE FROM "Drawing" WHERE "architectId" IN (SELECT "id" FROM "User" WHERE "email" LIKE ${emailLike})`;
  await prisma.$executeRaw`DELETE FROM "User" WHERE "email" LIKE ${emailLike}`;
  await prisma.$executeRaw`DELETE FROM "Category" WHERE "slug" LIKE ${`bulk-${tag}-%`}`;
  return removed;
}
