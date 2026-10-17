import { Inject, Injectable, Logger } from '@nestjs/common';
import { Prisma, WithdrawalStatus } from '@prisma/client';
import { LedgerService } from '../../ledger/ledger.service';
import { NotificationsService } from '../../notifications/notifications.service';
import { PrismaService } from '../../prisma/prisma.service';
import { lockUser } from '../shared/locks';
import {
  PAYOUT_PROVIDER,
  type PayoutProvider,
  PayoutRejectedError,
} from './payout.provider';

export type PayoutOutcome = 'PAID' | 'PROCESSING' | 'FAILED' | 'SKIPPED';

const OPEN: WithdrawalStatus[] = ['REQUESTED', 'PROCESSING'];

/**
 * Money movement of a withdrawal after the request: the wallet debit (wallet → PAYOUT_CLEARING) happened when it was
 * requested. Success needs no ledger entry (PAYOUT_CLEARING keeps the paid-out total); failure posts the exact reverse,
 * guarded by the status transition so it can happen at most once however many workers/webhooks race.
 */
@Injectable()
export class PayoutService {
  private readonly logger = new Logger(PayoutService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly ledger: LedgerService,
    private readonly notifications: NotificationsService,
    @Inject(PAYOUT_PROVIDER) private readonly provider: PayoutProvider,
  ) {}

  /** Worker entry point. Safe to call repeatedly: a retry after a crash resumes, a finished payout is skipped. */
  async process(withdrawalId: string): Promise<PayoutOutcome> {
    const claimed = await this.prisma.withdrawal.updateMany({
      where: { id: withdrawalId, status: 'REQUESTED' },
      data: { status: 'PROCESSING' },
    });
    const w = await this.prisma.withdrawal.findUnique({
      where: { id: withdrawalId },
      include: { bankAccount: true },
    });
    if (!w) return 'SKIPPED';
    const resumable = w.status === 'PROCESSING' && !w.providerRef;
    if (claimed.count === 0 && !resumable) return 'SKIPPED';

    if (!w.bankAccount) {
      await this.fail(w.id, 'Bank account is missing');
      return 'FAILED';
    }

    let result;
    try {
      result = await this.provider.createPayout({
        withdrawalId: w.id,
        amountPaise: w.amountPaise,
        fundAccountId: w.bankAccount.providerFundAccountId,
      });
    } catch (err) {
      if (err instanceof PayoutRejectedError) {
        await this.fail(w.id, err.message);
        return 'FAILED';
      }
      // Unknown outcome: leave it PROCESSING and let the queue retry with the same idempotency key.
      this.logger.error(
        `Payout ${w.id} attempt failed: ${err instanceof Error ? err.message : String(err)}`,
      );
      throw err;
    }

    await this.prisma.withdrawal.updateMany({
      where: { id: w.id, providerRef: null },
      data: { providerRef: result.providerRef },
    });
    if (result.status === 'PAID') {
      await this.markPaid(w.id);
      return 'PAID';
    }
    return 'PROCESSING';
  }

  async markPaid(withdrawalId: string): Promise<boolean> {
    return this.prisma.$transaction((tx) =>
      this.markPaidInTx(tx, withdrawalId),
    );
  }

  async markPaidInTx(
    tx: Prisma.TransactionClient,
    withdrawalId: string,
  ): Promise<boolean> {
    const res = await tx.withdrawal.updateMany({
      where: { id: withdrawalId, status: { in: OPEN } },
      data: { status: 'PAID', failureReason: null },
    });
    if (res.count !== 1) return false;
    const w = await tx.withdrawal.findUnique({
      where: { id: withdrawalId },
      select: { userId: true, amountPaise: true },
    });
    if (w) {
      await this.notifications.notify(
        w.userId,
        'WITHDRAWAL_STATUS',
        {
          withdrawalId,
          status: 'PAID',
          amountPaise: w.amountPaise,
        },
        tx,
      );
    }
    return true;
  }

  async fail(
    withdrawalId: string,
    reason: string,
    from: WithdrawalStatus[] = OPEN,
  ): Promise<boolean> {
    return this.prisma.$transaction((tx) =>
      this.failInTx(tx, withdrawalId, reason, from),
    );
  }

  /** Marks the withdrawal FAILED and returns the money to the wallet; false if it was not in a failable state. */
  async failInTx(
    tx: Prisma.TransactionClient,
    withdrawalId: string,
    reason: string,
    from: WithdrawalStatus[] = OPEN,
  ): Promise<boolean> {
    const w = await tx.withdrawal.findUnique({
      where: { id: withdrawalId },
      select: { userId: true, amountPaise: true },
    });
    if (!w) return false;
    await lockUser(tx, w.userId);
    const res = await tx.withdrawal.updateMany({
      where: { id: withdrawalId, status: { in: from } },
      data: { status: 'FAILED', failureReason: reason.slice(0, 500) },
    });
    if (res.count !== 1) return false;
    await this.ledger.postTransaction(
      [
        {
          accountType: 'PAYOUT_CLEARING',
          amountPaise: -w.amountPaise,
          entryType: 'WITHDRAWAL_REVERSAL',
          referenceId: withdrawalId,
        },
        {
          accountType: 'USER_WALLET',
          accountOwnerId: w.userId,
          amountPaise: w.amountPaise,
          entryType: 'WITHDRAWAL_REVERSAL',
          referenceId: withdrawalId,
        },
      ],
      tx,
    );
    await this.notifications.notify(
      w.userId,
      'WITHDRAWAL_STATUS',
      {
        withdrawalId,
        status: 'FAILED',
        amountPaise: w.amountPaise,
        reason,
      },
      tx,
    );
    this.logger.warn(
      `Withdrawal ${withdrawalId} failed and was reversed: ${reason}`,
    );
    return true;
  }

  /** Withdrawals that never got handed to the provider (e.g. Redis was down at request time or the worker crashed). */
  async findUnstarted(olderThanMs: number): Promise<string[]> {
    const before = new Date(Date.now() - olderThanMs);
    const rows = await this.prisma.withdrawal.findMany({
      where: {
        updatedAt: { lt: before },
        OR: [
          { status: 'REQUESTED' },
          { status: 'PROCESSING', providerRef: null },
        ],
      },
      select: { id: true },
      take: 500,
    });
    return rows.map((r) => r.id);
  }
}
