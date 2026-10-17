import { PrismaService } from '../prisma/prisma.service';
import {
  LedgerEntryInput,
  LedgerImbalanceError,
  LedgerService,
} from './ledger.service';

const wallet = (id: string, amountPaise: number): LedgerEntryInput => ({
  accountType: 'USER_WALLET',
  accountOwnerId: id,
  amountPaise,
  entryType: 'SALE',
});

describe('LedgerService.postTransaction (unit)', () => {
  const createMany = jest.fn().mockResolvedValue({ count: 3 });
  const tx = { ledgerEntry: { createMany } };
  const transaction = jest.fn((fn: (t: typeof tx) => Promise<unknown>) =>
    fn(tx),
  );
  const prisma = { $transaction: transaction } as unknown as PrismaService;
  const service = new LedgerService(prisma);

  beforeEach(() => jest.clearAllMocks());

  it('writes balanced entries under one txnId inside a transaction', async () => {
    const txnId = await service.postTransaction([
      { accountType: 'PAYMENT_GATEWAY', amountPaise: -1000, entryType: 'SALE' },
      wallet('u1', 900),
      {
        accountType: 'PLATFORM_REVENUE',
        amountPaise: 100,
        entryType: 'PLATFORM_FEE',
      },
    ]);
    expect(transaction).toHaveBeenCalledTimes(1);
    const arg = createMany.mock.calls[0] as [{ data: { txnId: string }[] }];
    expect(arg[0].data).toHaveLength(3);
    expect(new Set(arg[0].data.map((d) => d.txnId))).toEqual(new Set([txnId]));
  });

  it('joins the caller transaction when given', async () => {
    await service.postTransaction(
      [
        wallet('u1', 500),
        {
          accountType: 'PAYOUT_CLEARING',
          amountPaise: -500,
          entryType: 'SALE',
        },
      ],
      tx as never,
    );
    expect(transaction).not.toHaveBeenCalled();
    expect(createMany).toHaveBeenCalledTimes(1);
  });

  it('rejects unbalanced entries without touching the DB', async () => {
    await expect(
      service.postTransaction([
        {
          accountType: 'PAYMENT_GATEWAY',
          amountPaise: -1000,
          entryType: 'SALE',
        },
        wallet('u1', 901),
      ]),
    ).rejects.toBeInstanceOf(LedgerImbalanceError);
    expect(transaction).not.toHaveBeenCalled();
    expect(createMany).not.toHaveBeenCalled();
  });

  it.each([
    ['a single entry', [wallet('u1', 5)]],
    ['zero amounts', [wallet('u1', 0), wallet('u2', 0)]],
    ['fractional paise', [wallet('u1', 0.5), wallet('u2', -0.5)]],
    [
      'a wallet entry without owner',
      [
        { accountType: 'USER_WALLET', amountPaise: 5, entryType: 'SALE' },
        { accountType: 'PAYMENT_GATEWAY', amountPaise: -5, entryType: 'SALE' },
      ],
    ],
  ] as [string, LedgerEntryInput[]][])('rejects %s', async (_n, entries) => {
    await expect(service.postTransaction(entries)).rejects.toThrow();
    expect(createMany).not.toHaveBeenCalled();
  });
});
