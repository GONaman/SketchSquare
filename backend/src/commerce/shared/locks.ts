import { Prisma } from '@prisma/client';

/**
 * Row-locks a user for the rest of the transaction. FOR NO KEY UPDATE serialises writers of the same user
 * (checkout, withdrawal, quota, rating recompute) without blocking the foreign-key checks that ledger inserts
 * make on that row, which would otherwise allow lock cycles between two users paying each other.
 * Lock order used everywhere: User → Purchase/Withdrawal → Drawing.
 */
export async function lockUser(
  tx: Prisma.TransactionClient,
  userId: string,
): Promise<void> {
  await tx.$queryRaw`SELECT "id" FROM "User" WHERE "id" = ${userId}::uuid FOR NO KEY UPDATE`;
}
