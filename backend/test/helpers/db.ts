import { PrismaClient } from '@prisma/client';

/** Empties every table (TRUNCATE bypasses the append-only ledger trigger). Call in `beforeEach`/`afterAll` of DB e2e tests. */
export async function resetDb(prisma: PrismaClient): Promise<void> {
  const tables = await prisma.$queryRaw<{ tablename: string }[]>`
    SELECT tablename FROM pg_tables
    WHERE schemaname = 'public' AND tablename <> '_prisma_migrations'`;
  if (tables.length === 0) return;
  const list = tables.map((t) => `"public"."${t.tablename}"`).join(', ');
  // A previous test's fire-and-forget job (e.g. a publish pipeline run) can still hold locks; Postgres then aborts one side as a deadlock victim, so retry.
  for (let attempt = 1; ; attempt++) {
    try {
      await prisma.$executeRawUnsafe(
        `TRUNCATE ${list} RESTART IDENTITY CASCADE`,
      );
      return;
    } catch (err) {
      if (attempt >= 5 || !String(err).includes('40P01')) throw err;
      await new Promise((resolve) => setTimeout(resolve, 100 * attempt));
    }
  }
}
