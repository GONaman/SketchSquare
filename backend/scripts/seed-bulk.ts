/* eslint-disable no-console */
/**
 * Seeds a synthetic catalogue into the DEV database for performance work.
 *
 *   npm run seed:bulk                 # tops up to 50 000 drawings (idempotent)
 *   npm run seed:bulk -- 100000       # other target
 *   npm run seed:bulk -- --clean      # removes exactly what this script created
 *
 * Rows are tagged (`bulk-*@seed.sketchsquare.test` users, `bulk-bulk-*` categories), never touch other data, and the script
 * refuses to run with NODE_ENV=production. Typical runtime for 50k rows: a few seconds.
 */
import { PrismaClient } from '@prisma/client';
import { cleanBulk, insertBulk } from './bulk-data';

async function main() {
  if (process.env.NODE_ENV === 'production') {
    throw new Error('seed:bulk refuses to run with NODE_ENV=production');
  }
  const args = process.argv.slice(2);
  const prisma = new PrismaClient();
  try {
    const target = process.env.DATABASE_URL
      ? new URL(process.env.DATABASE_URL).pathname.slice(1)
      : '(default from .env)';
    if (args.includes('--clean')) {
      const n = await cleanBulk(prisma);
      console.log(`Removed ${n} bulk drawings from ${target}`);
      return;
    }
    const drawings = Number(args.find((a) => /^\d+$/.test(a)) ?? 50000);
    console.log(`Seeding up to ${drawings} drawings into ${target}`);
    const { existing, inserted } = await insertBulk(prisma, { drawings });
    console.log(
      `Done: ${existing} already present, ${inserted} inserted (total ${existing + inserted}).`,
    );
  } finally {
    await prisma.$disconnect();
  }
}

main().catch((err) => {
  console.error(err instanceof Error ? err.message : err);
  process.exitCode = 1;
});
