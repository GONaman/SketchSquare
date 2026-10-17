import { LedgerService } from '../src/ledger/ledger.service';
import { PrismaService } from '../src/prisma/prisma.service';
import { resetDb } from './helpers/db';

describe('Ledger (DB-level guarantees)', () => {
  const prisma = new PrismaService();
  const ledger = new LedgerService(prisma);
  let userId: string;

  beforeEach(async () => {
    await resetDb(prisma);
    const user = await prisma.user.create({
      data: {
        email: 'seller@test.local',
        passwordHash: 'x',
        fullName: 'Seller',
        address: 'addr',
        phone: '1',
        city: 'Delhi',
      },
    });
    userId = user.id;
  });

  afterAll(async () => {
    await resetDb(prisma);
    await prisma.$disconnect();
  });

  const sale = () => [
    {
      accountType: 'PAYMENT_GATEWAY' as const,
      amountPaise: -1000,
      entryType: 'SALE' as const,
    },
    {
      accountType: 'USER_WALLET' as const,
      accountOwnerId: userId,
      amountPaise: 900,
      entryType: 'SALE' as const,
    },
    {
      accountType: 'PLATFORM_REVENUE' as const,
      amountPaise: 100,
      entryType: 'PLATFORM_FEE' as const,
    },
  ];

  it('commits a balanced transaction and computes the wallet balance', async () => {
    await ledger.postTransaction(sale());
    await ledger.postTransaction(sale());
    expect(await ledger.getWalletBalance(userId)).toBe(1800);
    const sums = await prisma.$queryRaw<{ s: bigint }[]>`
      SELECT SUM("amountPaise") AS s FROM "LedgerEntry" GROUP BY "txnId"`;
    expect(sums.map((r) => Number(r.s))).toEqual([0, 0]);
  });

  it('service rejects an unbalanced transaction and writes nothing', async () => {
    const entries = sale();
    entries[2].amountPaise = 99;
    await expect(ledger.postTransaction(entries)).rejects.toThrow(/unbalanced/);
    expect(await prisma.ledgerEntry.count()).toBe(0);
  });

  it('DB trigger rejects an unbalanced txn even when the service is bypassed', async () => {
    const txnId = '11111111-1111-4111-8111-111111111111';
    await expect(
      prisma.$transaction((tx) =>
        tx.ledgerEntry.createMany({
          data: [
            {
              txnId,
              accountType: 'PAYMENT_GATEWAY',
              amountPaise: -1000,
              entryType: 'SALE',
            },
            {
              txnId,
              accountType: 'USER_WALLET',
              accountOwnerId: userId,
              amountPaise: 999,
              entryType: 'SALE',
            },
          ],
        }),
      ),
    ).rejects.toThrow(/unbalanced/);
    expect(await prisma.ledgerEntry.count()).toBe(0);
  });

  it('balance is checked at commit, so entries may be inserted one by one inside a transaction', async () => {
    const txnId = '22222222-2222-4222-8222-222222222222';
    await prisma.$transaction(async (tx) => {
      await tx.ledgerEntry.create({
        data: {
          txnId,
          accountType: 'PAYMENT_GATEWAY',
          amountPaise: -500,
          entryType: 'SALE',
        },
      });
      await tx.ledgerEntry.create({
        data: {
          txnId,
          accountType: 'USER_WALLET',
          accountOwnerId: userId,
          amountPaise: 500,
          entryType: 'SALE',
        },
      });
    });
    expect(await prisma.ledgerEntry.count()).toBe(2);
  });

  it('ledger rows are append-only', async () => {
    await ledger.postTransaction(sale());
    await expect(
      prisma.ledgerEntry.updateMany({ data: { amountPaise: 1 } }),
    ).rejects.toThrow(/append-only/);
    await expect(prisma.ledgerEntry.deleteMany()).rejects.toThrow(
      /append-only/,
    );
  });

  it('rejects a USER_WALLET entry without an owner at the DB level', async () => {
    await expect(
      prisma.$executeRaw`INSERT INTO "LedgerEntry" ("txnId","accountType","amountPaise","entryType")
        VALUES (gen_random_uuid(), 'USER_WALLET', 10, 'SALE')`,
    ).rejects.toThrow(/LedgerEntry_wallet_owner_check/);
  });
});
