import { HttpStatus, Injectable, Logger } from '@nestjs/common';
import { Prisma, PurchaseStatus } from '@prisma/client';
import { ApiException } from '../../common/errors/api-exception';
import { LedgerService } from '../../ledger/ledger.service';
import { NotificationsService } from '../../notifications/notifications.service';
import { PrismaService } from '../../prisma/prisma.service';
import { lockUser } from '../shared/locks';

export type OrderOutcome =
  | 'PAID'
  | 'DUPLICATE_PAYMENT'
  | 'AMOUNT_MISMATCH'
  | 'UNKNOWN_ORDER'
  | 'NOTHING_TO_DO';

export interface CaptureResult {
  outcome: OrderOutcome;
  /** Purchases that moved to PAID in this call (empty on replays). */
  newlyPaid: string[];
}

export type OrderStatus = 'CREATED' | 'PAID' | 'FAILED';

export const WEBHOOK_PROVIDER = 'razorpay';

/**
 * Turns a captured payment into PAID purchases + ledger postings, all in the caller's DB transaction.
 * Safe to run any number of times for the same order (webhook, client verify, stub completion): a purchase only
 * leaves CREATED/FAILED once, and the ledger is only written on that single transition.
 */
@Injectable()
export class PaymentSettlementService {
  private readonly logger = new Logger(PaymentSettlementService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly ledger: LedgerService,
    private readonly notifications: NotificationsService,
  ) {}

  async captureOrder(
    orderId: string,
    paymentId: string,
    paidAmountPaise?: number,
  ): Promise<CaptureResult> {
    return this.prisma.$transaction(
      (tx) => this.captureOrderInTx(tx, orderId, paymentId, paidAmountPaise),
      { timeout: 20_000 },
    );
  }

  async captureOrderInTx(
    tx: Prisma.TransactionClient,
    orderId: string,
    paymentId: string,
    paidAmountPaise?: number,
  ): Promise<CaptureResult> {
    const head = await tx.purchase.findFirst({
      where: { razorpayOrderId: orderId },
      select: { buyerId: true },
    });
    if (!head) {
      this.logger.warn(`Payment ${paymentId} for unknown order ${orderId}`);
      return { outcome: 'UNKNOWN_ORDER', newlyPaid: [] };
    }

    // Lock order: buyer → purchases (by drawing id, so drawing counters are also bumped in a stable order).
    await lockUser(tx, head.buyerId);
    const purchases = await tx.purchase.findMany({
      where: { razorpayOrderId: orderId },
      orderBy: [{ drawingId: 'asc' }, { id: 'asc' }],
      include: { drawing: { select: { architectId: true, title: true } } },
    });
    await tx.$queryRaw`SELECT "id" FROM "Purchase" WHERE "razorpayOrderId" = ${orderId} ORDER BY "drawingId", "id" FOR UPDATE`;
    // Re-read under the lock: statuses may have changed while we waited for it.
    const fresh = await tx.purchase.findMany({
      where: { id: { in: purchases.map((p) => p.id) } },
      select: { id: true, status: true },
    });
    const statusById = new Map(fresh.map((p) => [p.id, p.status]));

    const total = purchases.reduce((s, p) => s + p.pricePaise, 0);
    if (paidAmountPaise !== undefined && paidAmountPaise !== total) {
      this.logger.error(
        `Order ${orderId}: captured ${paidAmountPaise} paise but purchases total ${total}; not settling`,
      );
      return { outcome: 'AMOUNT_MISMATCH', newlyPaid: [] };
    }

    const newlyPaid: string[] = [];
    let duplicate = false;
    for (const p of purchases) {
      const status = statusById.get(p.id);
      if (status === 'PAID' || status === 'REFUNDED') continue;

      const alreadyOwned = await tx.purchase.findFirst({
        where: {
          buyerId: p.buyerId,
          drawingId: p.drawingId,
          status: 'PAID',
          id: { not: p.id },
        },
        select: { id: true },
      });
      if (alreadyOwned) {
        // Two orders for the same drawing were both paid; the second payment needs a manual refund.
        duplicate = true;
        this.logger.error(
          `Duplicate payment ${paymentId} for drawing ${p.drawingId} (purchase ${p.id}) needs a manual refund`,
        );
        await tx.purchase.updateMany({
          where: { id: p.id, status: 'CREATED' },
          data: { status: 'FAILED' },
        });
        continue;
      }

      const moved = await tx.purchase.updateMany({
        where: { id: p.id, status: { in: ['CREATED', 'FAILED'] } },
        data: {
          status: 'PAID',
          razorpayPaymentId: paymentId,
          paidAt: new Date(),
        },
      });
      if (moved.count !== 1) continue;

      const net = p.pricePaise - p.platformFeePaise;
      await this.ledger.postTransaction(
        [
          {
            accountType: 'PAYMENT_GATEWAY',
            amountPaise: -p.pricePaise,
            entryType: 'SALE',
            referenceId: p.id,
          },
          ...(net > 0
            ? [
                {
                  accountType: 'USER_WALLET' as const,
                  accountOwnerId: p.drawing.architectId,
                  amountPaise: net,
                  entryType: 'SALE' as const,
                  referenceId: p.id,
                },
              ]
            : []),
          ...(p.platformFeePaise > 0
            ? [
                {
                  accountType: 'PLATFORM_REVENUE' as const,
                  amountPaise: p.platformFeePaise,
                  entryType: 'PLATFORM_FEE' as const,
                  referenceId: p.id,
                },
              ]
            : []),
        ],
        tx,
      );
      await tx.drawing.update({
        where: { id: p.drawingId },
        data: { purchaseCount: { increment: 1 } },
      });
      await tx.cartItem.deleteMany({
        where: { userId: p.buyerId, drawingId: p.drawingId },
      });
      await this.notifications.notify(
        p.drawing.architectId,
        'SALE_MADE',
        {
          purchaseId: p.id,
          drawingId: p.drawingId,
          drawingTitle: p.drawing.title,
          amountPaise: net,
        },
        tx,
      );
      newlyPaid.push(p.id);
    }

    const outcome: OrderOutcome =
      newlyPaid.length > 0
        ? 'PAID'
        : duplicate
          ? 'DUPLICATE_PAYMENT'
          : 'NOTHING_TO_DO';
    return { outcome, newlyPaid };
  }

  /** payment.failed: only still-unpaid purchases fail; a later successful retry on the same order can still settle. */
  async failOrderInTx(
    tx: Prisma.TransactionClient,
    orderId: string,
  ): Promise<number> {
    const res = await tx.purchase.updateMany({
      where: { razorpayOrderId: orderId, status: 'CREATED' },
      data: { status: 'FAILED' },
    });
    return res.count;
  }

  /** Aggregate status of an order, scoped to its buyer. */
  async getOrderStatus(userId: string, orderId: string): Promise<OrderStatus> {
    const purchases = await this.prisma.purchase.findMany({
      where: { razorpayOrderId: orderId, buyerId: userId },
      select: { status: true },
    });
    if (purchases.length === 0) {
      throw new ApiException(
        HttpStatus.NOT_FOUND,
        'NOT_FOUND',
        'Order not found',
      );
    }
    return aggregateStatus(purchases.map((p) => p.status));
  }
}

export function aggregateStatus(statuses: PurchaseStatus[]): OrderStatus {
  if (statuses.some((s) => s === 'CREATED')) return 'CREATED';
  if (statuses.some((s) => s === 'PAID' || s === 'REFUNDED')) return 'PAID';
  return 'FAILED';
}
