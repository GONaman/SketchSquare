import { Injectable } from '@nestjs/common';
import {
  LedgerAccountType,
  LedgerEntryType,
  Prisma,
  PrismaClient,
} from '@prisma/client';
import { randomUUID } from 'node:crypto';
import { PrismaService } from '../prisma/prisma.service';

export interface LedgerEntryInput {
  accountType: LedgerAccountType;
  /** Required for USER_WALLET. */
  accountOwnerId?: string | null;
  /** Signed integer paise; credits positive, debits negative. */
  amountPaise: number;
  entryType: LedgerEntryType;
  referenceId?: string | null;
}

export class LedgerImbalanceError extends Error {
  constructor(public readonly sumPaise: number) {
    super(`Ledger transaction is unbalanced: entries sum to ${sumPaise} paise`);
    this.name = 'LedgerImbalanceError';
  }
}

export class LedgerValidationError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'LedgerValidationError';
  }
}

type Db = Prisma.TransactionClient | PrismaClient;

@Injectable()
export class LedgerService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Appends a balanced group of entries sharing one txnId and returns that id.
   * Pass `tx` to join a caller's DB transaction (so the ledger write commits atomically with, e.g., a purchase update);
   * otherwise a new transaction is opened. Unbalanced input is rejected before touching the DB, and the
   * deferred constraint trigger enforces the same rule at commit as a backstop.
   */
  async postTransaction(
    entries: LedgerEntryInput[],
    tx?: Prisma.TransactionClient,
  ): Promise<string> {
    this.assertValid(entries);
    const txnId = randomUUID();
    const write = (db: Db) =>
      db.ledgerEntry.createMany({
        data: entries.map((e) => ({
          txnId,
          accountType: e.accountType,
          accountOwnerId: e.accountOwnerId ?? null,
          amountPaise: e.amountPaise,
          entryType: e.entryType,
          referenceId: e.referenceId ?? null,
        })),
      });

    if (tx) await write(tx);
    else await this.prisma.$transaction((t) => write(t));
    return txnId;
  }

  /** Wallet balance = SUM of the user's USER_WALLET entries (paise). */
  async getWalletBalance(userId: string, tx?: Db): Promise<number> {
    const db = tx ?? this.prisma;
    const res = await db.ledgerEntry.aggregate({
      where: { accountType: 'USER_WALLET', accountOwnerId: userId },
      _sum: { amountPaise: true },
    });
    return res._sum.amountPaise ?? 0;
  }

  private assertValid(entries: LedgerEntryInput[]): void {
    if (entries.length < 2) {
      throw new LedgerValidationError(
        'A ledger transaction needs at least two entries',
      );
    }
    let sum = 0;
    for (const e of entries) {
      if (!Number.isSafeInteger(e.amountPaise) || e.amountPaise === 0) {
        throw new LedgerValidationError(
          'Ledger amounts must be non-zero integer paise',
        );
      }
      if (e.accountType === 'USER_WALLET' && !e.accountOwnerId) {
        throw new LedgerValidationError(
          'USER_WALLET entries require accountOwnerId',
        );
      }
      sum += e.amountPaise;
    }
    if (sum !== 0) throw new LedgerImbalanceError(sum);
  }
}
