import { HttpStatus, Inject, Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { LedgerEntryType, Prisma, WithdrawalStatus } from '@prisma/client';
import { ApiException } from '../../common/errors/api-exception';
import { decodeCursor, Page, toPage } from '../../common/pagination';
import { Env } from '../../config/env.schema';
import { LedgerService } from '../../ledger/ledger.service';
import { PrismaService } from '../../prisma/prisma.service';
import {
  PAYOUT_PROVIDER,
  type PayoutProvider,
} from '../payouts/payout.provider';
import { PAYOUT_QUEUE, type PayoutQueue } from '../payouts/payout.queue';
import { lockUser } from '../shared/locks';
import type { BankAccountDto } from './dto/wallet.dto';

export interface BankAccountView {
  holderName: string;
  ifsc: string;
  accountNumberLast4: string;
}

export interface WalletView {
  balancePaise: number;
  pendingWithdrawalPaise: number;
  minWithdrawalPaise: number;
  withdrawalBlocked: boolean;
  bankAccount: BankAccountView | null;
}

export interface LedgerItem {
  id: string;
  entryType: LedgerEntryType;
  amountPaise: number;
  description: string;
  referenceId: string | null;
  createdAt: Date;
}

export interface WithdrawalView {
  id: string;
  amountPaise: number;
  status: WithdrawalStatus;
  failureReason: string | null;
  createdAt: Date;
  updatedAt: Date;
}

const IN_FLIGHT: WithdrawalStatus[] = ['REQUESTED', 'PROCESSING'];

interface KeysetCursor extends Record<string, unknown> {
  at: string;
  id: string;
}

@Injectable()
export class WalletService {
  private readonly logger = new Logger(WalletService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly ledger: LedgerService,
    private readonly config: ConfigService<Env, true>,
    @Inject(PAYOUT_PROVIDER) private readonly provider: PayoutProvider,
    @Inject(PAYOUT_QUEUE) private readonly queue: PayoutQueue,
  ) {}

  async getWallet(userId: string): Promise<WalletView> {
    const [balancePaise, pending, bank] = await Promise.all([
      this.ledger.getWalletBalance(userId),
      this.prisma.withdrawal.aggregate({
        where: { userId, status: { in: IN_FLIGHT } },
        _sum: { amountPaise: true },
      }),
      this.prisma.bankAccount.findUnique({ where: { userId } }),
    ]);
    return {
      balancePaise,
      pendingWithdrawalPaise: pending._sum.amountPaise ?? 0,
      minWithdrawalPaise: this.config.get('MIN_WITHDRAWAL_PAISE', {
        infer: true,
      }),
      withdrawalBlocked: balancePaise < 0,
      bankAccount: bank ? toBankView(bank) : null,
    };
  }

  async listLedger(
    userId: string,
    cursor: string | undefined,
    limit: number,
  ): Promise<Page<LedgerItem>> {
    const c = decodeCursor<KeysetCursor>(cursor);
    const at = c ? parseCursorDate(c) : null;
    const rows = await this.prisma.ledgerEntry.findMany({
      where: {
        accountType: 'USER_WALLET',
        accountOwnerId: userId,
        ...(c && at
          ? {
              OR: [
                { createdAt: { lt: at } },
                { createdAt: at, id: { lt: String(c.id) } },
              ],
            }
          : {}),
      },
      orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
      take: limit + 1,
    });
    const page = toPage(rows, limit, (r) => ({
      at: r.createdAt.toISOString(),
      id: r.id,
    }));
    const descriptions = await this.describe(userId, page.items);
    return {
      items: page.items.map((e) => ({
        id: e.id,
        entryType: e.entryType,
        amountPaise: e.amountPaise,
        description: descriptions.get(e.id) ?? e.entryType,
        referenceId: e.referenceId,
        createdAt: e.createdAt,
      })),
      nextCursor: page.nextCursor,
    };
  }

  async upsertBankAccount(
    userId: string,
    dto: BankAccountDto,
  ): Promise<BankAccountView> {
    await this.assertNoWithdrawalInFlight(this.prisma, userId);
    // Remote call outside any DB lock/transaction.
    const { fundAccountId } = await this.provider.createFundAccount({
      userId,
      holderName: dto.holderName,
      ifsc: dto.ifsc,
      accountNumber: dto.accountNumber,
    });
    const data = {
      holderName: dto.holderName,
      ifsc: dto.ifsc,
      // Only the last four digits are ever stored.
      accountNumberLast4: dto.accountNumber.slice(-4),
      providerFundAccountId: fundAccountId,
    };
    const bank = await this.prisma.$transaction(async (tx) => {
      await lockUser(tx, userId);
      // A payout in flight uses the current bank account, so it may not change underneath it.
      await this.assertNoWithdrawalInFlight(tx, userId);
      return tx.bankAccount.upsert({
        where: { userId },
        create: { userId, ...data },
        update: data,
      });
    });
    return toBankView(bank);
  }

  async requestWithdrawal(
    userId: string,
    amountPaise: number,
  ): Promise<WithdrawalView> {
    const min = this.config.get('MIN_WITHDRAWAL_PAISE', { infer: true });
    const withdrawal = await this.prisma.$transaction(async (tx) => {
      // The user lock serialises every balance-changing operation for this user, so the balance read below is exact
      // and two concurrent withdrawals can never both spend the same money.
      await lockUser(tx, userId);
      const bank = await tx.bankAccount.findUnique({ where: { userId } });
      if (!bank) {
        throw new ApiException(
          HttpStatus.BAD_REQUEST,
          'VALIDATION_ERROR',
          'Add a bank account before withdrawing',
        );
      }
      await this.assertNoWithdrawalInFlight(tx, userId);
      const balance = await this.ledger.getWalletBalance(userId, tx);
      if (balance < 0) {
        throw new ApiException(
          HttpStatus.FORBIDDEN,
          'WITHDRAWAL_BLOCKED',
          'Withdrawals are blocked while your balance is negative',
        );
      }
      if (amountPaise < min) {
        throw new ApiException(
          HttpStatus.BAD_REQUEST,
          'BELOW_MIN_WITHDRAWAL',
          `Minimum withdrawal is ${min} paise`,
        );
      }
      if (amountPaise > balance) {
        throw new ApiException(
          HttpStatus.BAD_REQUEST,
          'INSUFFICIENT_BALANCE',
          'Withdrawal amount exceeds your wallet balance',
        );
      }
      const w = await tx.withdrawal.create({
        data: { userId, bankAccountId: bank.id, amountPaise },
      });
      await this.ledger.postTransaction(
        [
          {
            accountType: 'USER_WALLET',
            accountOwnerId: userId,
            amountPaise: -amountPaise,
            entryType: 'WITHDRAWAL',
            referenceId: w.id,
          },
          {
            accountType: 'PAYOUT_CLEARING',
            amountPaise,
            entryType: 'WITHDRAWAL',
            referenceId: w.id,
          },
        ],
        tx,
      );
      return w;
    });

    try {
      await this.queue.enqueue(withdrawal.id);
    } catch (err) {
      // The withdrawal is committed; the recovery sweep will pick it up.
      this.logger.error(
        `Could not enqueue payout ${withdrawal.id}: ${err instanceof Error ? err.message : String(err)}`,
      );
    }
    return toWithdrawalView(withdrawal);
  }

  async listWithdrawals(
    userId: string,
    cursor: string | undefined,
    limit: number,
  ): Promise<Page<WithdrawalView>> {
    const c = decodeCursor<KeysetCursor>(cursor);
    const at = c ? parseCursorDate(c) : null;
    const rows = await this.prisma.withdrawal.findMany({
      where: {
        userId,
        ...(c && at
          ? {
              OR: [
                { createdAt: { lt: at } },
                { createdAt: at, id: { lt: String(c.id) } },
              ],
            }
          : {}),
      },
      orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
      take: limit + 1,
    });
    const page = toPage(rows, limit, (r) => ({
      at: r.createdAt.toISOString(),
      id: r.id,
    }));
    return {
      items: page.items.map(toWithdrawalView),
      nextCursor: page.nextCursor,
    };
  }

  private async assertNoWithdrawalInFlight(
    db: Pick<Prisma.TransactionClient, 'withdrawal'>,
    userId: string,
  ): Promise<void> {
    const open = await db.withdrawal.findFirst({
      where: { userId, status: { in: IN_FLIGHT } },
      select: { id: true },
    });
    if (open) {
      throw new ApiException(
        HttpStatus.CONFLICT,
        'CONFLICT',
        'A withdrawal is already in progress',
      );
    }
  }

  private async describe(
    userId: string,
    entries: {
      id: string;
      entryType: LedgerEntryType;
      referenceId: string | null;
    }[],
  ): Promise<Map<string, string>> {
    const saleRefs = entries
      .filter(
        (e) =>
          (e.entryType === 'SALE' || e.entryType === 'REFUND') && e.referenceId,
      )
      .map((e) => e.referenceId as string);
    const purchases = saleRefs.length
      ? await this.prisma.purchase.findMany({
          where: { id: { in: saleRefs }, drawing: { architectId: userId } },
          select: { id: true, drawing: { select: { title: true } } },
        })
      : [];
    const titles = new Map(purchases.map((p) => [p.id, p.drawing.title]));
    const bank = await this.prisma.bankAccount.findUnique({
      where: { userId },
      select: { accountNumberLast4: true },
    });
    const out = new Map<string, string>();
    for (const e of entries) {
      switch (e.entryType) {
        case 'SALE': {
          const title = e.referenceId ? titles.get(e.referenceId) : undefined;
          out.set(e.id, title ? `Sale of "${title}"` : 'Sale');
          break;
        }
        case 'WITHDRAWAL':
          out.set(
            e.id,
            bank
              ? `Withdrawal to bank ••••${bank.accountNumberLast4}`
              : 'Withdrawal to bank',
          );
          break;
        case 'WITHDRAWAL_REVERSAL':
          out.set(e.id, 'Withdrawal failed – amount returned');
          break;
        case 'REFUND': {
          const title = e.referenceId ? titles.get(e.referenceId) : undefined;
          out.set(e.id, title ? `Refund of "${title}"` : 'Refund');
          break;
        }
        default:
          out.set(e.id, e.entryType);
      }
    }
    return out;
  }
}

function parseCursorDate(c: KeysetCursor): Date {
  const d = new Date(String(c.at));
  if (Number.isNaN(d.getTime()) || typeof c.id !== 'string') {
    throw new ApiException(
      HttpStatus.BAD_REQUEST,
      'VALIDATION_ERROR',
      'Invalid cursor',
    );
  }
  return d;
}

function toBankView(b: {
  holderName: string;
  ifsc: string;
  accountNumberLast4: string;
}): BankAccountView {
  return {
    holderName: b.holderName,
    ifsc: b.ifsc,
    accountNumberLast4: b.accountNumberLast4,
  };
}

function toWithdrawalView(w: {
  id: string;
  amountPaise: number;
  status: WithdrawalStatus;
  failureReason: string | null;
  createdAt: Date;
  updatedAt: Date;
}): WithdrawalView {
  return {
    id: w.id,
    amountPaise: w.amountPaise,
    status: w.status,
    failureReason: w.failureReason,
    createdAt: w.createdAt,
    updatedAt: w.updatedAt,
  };
}
