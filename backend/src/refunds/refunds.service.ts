import { HttpStatus, Inject, Injectable, Logger } from '@nestjs/common';
import { Prisma, PurchaseStatus, RefundProviderStatus } from '@prisma/client';
import { ApiException } from '../common/errors/api-exception';
import { decodeCursor, Page, toPage } from '../common/pagination';
import { lockUser } from '../commerce/shared/locks';
import { LedgerService } from '../ledger/ledger.service';
import { PrismaService } from '../prisma/prisma.service';
import { ListAdminPurchasesQueryDto } from './dto/admin-purchases.dto';
import { REFUND_PROVIDER, type RefundProvider } from './refund.provider';

/** A PENDING gateway call older than this is assumed lost (crash) and may be retried by an admin. */
const STALE_PENDING_MS = 60_000;

const purchaseInclude = {
  buyer: { select: { id: true, fullName: true, email: true } },
  drawing: {
    select: {
      id: true,
      title: true,
      architect: { select: { id: true, fullName: true, email: true } },
    },
  },
  refund: { include: { admin: { select: { id: true, fullName: true } } } },
} satisfies Prisma.PurchaseInclude;

type PurchaseRow = Prisma.PurchaseGetPayload<{
  include: typeof purchaseInclude;
}>;

export interface RefundView {
  id: string;
  reason: string;
  amountPaise: number;
  refundedAt: Date;
  refundedBy: { id: string; fullName: string };
  providerStatus: RefundProviderStatus;
  providerRefundId: string | null;
  providerError: string | null;
}

export interface AdminPurchaseView {
  id: string;
  status: PurchaseStatus;
  pricePaise: number;
  platformFeePaise: number;
  sellerNetPaise: number;
  razorpayOrderId: string | null;
  razorpayPaymentId: string | null;
  createdAt: Date;
  paidAt: Date | null;
  buyer: { id: string; fullName: string; email: string };
  seller: { id: string; fullName: string; email: string };
  drawing: { id: string; title: string };
  refund: RefundView | null;
}

export interface AdminPurchaseDetail extends AdminPurchaseView {
  /** Seller's current wallet balance; a refund larger than this makes it negative and blocks their withdrawals. */
  sellerBalancePaise: number;
}

export interface RefundResult {
  ok: true;
  /** True when the purchase had already been refunded (nothing was booked again). */
  alreadyRefunded: boolean;
  refund: RefundView;
}

interface KeysetCursor extends Record<string, unknown> {
  at: string;
  id: string;
}

const UUID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

@Injectable()
export class RefundsService {
  private readonly logger = new Logger(RefundsService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly ledger: LedgerService,
    @Inject(REFUND_PROVIDER) private readonly provider: RefundProvider,
  ) {}

  async list(q: ListAdminPurchasesQueryDto): Promise<Page<AdminPurchaseView>> {
    const cursor = decodeCursor<KeysetCursor>(q.cursor);
    const at = cursor ? parseCursorDate(cursor) : null;
    const and: Prisma.PurchaseWhereInput[] = [];
    if (q.status) and.push({ status: q.status });
    if (q.buyerId) and.push({ buyerId: q.buyerId });
    if (q.drawingId) and.push({ drawingId: q.drawingId });
    if (q.q) and.push({ OR: searchClauses(q.q) });
    if (cursor && at) {
      and.push({
        OR: [
          { createdAt: { lt: at } },
          { createdAt: at, id: { lt: String(cursor.id) } },
        ],
      });
    }
    const rows = await this.prisma.purchase.findMany({
      where: { AND: and },
      include: purchaseInclude,
      orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
      take: q.limit + 1,
    });
    const page = toPage(rows, q.limit, (r) => ({
      at: r.createdAt.toISOString(),
      id: r.id,
    }));
    return { items: page.items.map(toView), nextCursor: page.nextCursor };
  }

  async detail(id: string): Promise<AdminPurchaseDetail> {
    const row = await this.prisma.purchase.findUnique({
      where: { id },
      include: purchaseInclude,
    });
    if (!row) throw this.notFound();
    return {
      ...toView(row),
      sellerBalancePaise: await this.ledger.getWalletBalance(
        row.drawing.architect.id,
      ),
    };
  }

  /**
   * Refunds a PAID purchase. The books change in ONE transaction (status → REFUNDED, reversing ledger txn, counters,
   * audit row) under row locks, so repeats and races book it exactly once. The gateway call happens afterwards,
   * outside the locks, keyed by the purchase id; if it fails the refund stays recorded (the buyer is owed the money)
   * with `providerStatus=FAILED` and calling this again retries only the gateway call.
   */
  async refund(
    purchaseId: string,
    adminId: string,
    reason: string,
  ): Promise<RefundResult> {
    const head = await this.prisma.purchase.findUnique({
      where: { id: purchaseId },
      select: { drawing: { select: { architectId: true } } },
    });
    if (!head) throw this.notFound();

    const booked = await this.prisma.$transaction(
      (tx) =>
        this.bookRefund(
          tx,
          purchaseId,
          head.drawing.architectId,
          adminId,
          reason,
        ),
      { timeout: 20_000 },
    );

    const owner = booked.created || (await this.claimRetry(booked.refundId));
    if (owner) await this.callProvider(purchaseId, booked.refundId);

    const view = await this.prisma.refund.findUniqueOrThrow({
      where: { id: booked.refundId },
      include: { admin: { select: { id: true, fullName: true } } },
    });
    return {
      ok: true,
      alreadyRefunded: !booked.created,
      refund: toRefundView(view),
    };
  }

  private async bookRefund(
    tx: Prisma.TransactionClient,
    purchaseId: string,
    sellerId: string,
    adminId: string,
    reason: string,
  ): Promise<{ refundId: string; created: boolean }> {
    // Lock order (see lockUser): seller → purchase → drawing.
    await lockUser(tx, sellerId);
    await tx.$queryRaw`SELECT "id" FROM "Purchase" WHERE "id" = ${purchaseId}::uuid FOR UPDATE`;
    const p = await tx.purchase.findUniqueOrThrow({
      where: { id: purchaseId },
      include: { refund: { select: { id: true } } },
    });

    if (p.status === 'REFUNDED' && p.refund) {
      return { refundId: p.refund.id, created: false };
    }
    if (p.status !== 'PAID') {
      throw new ApiException(
        HttpStatus.CONFLICT,
        'CONFLICT',
        'Only paid purchases can be refunded',
        { status: p.status },
      );
    }

    const moved = await tx.purchase.updateMany({
      where: { id: p.id, status: 'PAID' },
      data: { status: 'REFUNDED' },
    });
    if (moved.count !== 1) {
      throw new ApiException(
        HttpStatus.CONFLICT,
        'CONFLICT',
        'Purchase changed while refunding, please retry',
      );
    }

    // Exact mirror of the sale posting (see PaymentSettlementService): signs flipped, zero legs skipped.
    const net = p.pricePaise - p.platformFeePaise;
    const ledgerTxnId = await this.ledger.postTransaction(
      [
        {
          accountType: 'PAYMENT_GATEWAY',
          amountPaise: p.pricePaise,
          entryType: 'REFUND',
          referenceId: p.id,
        },
        ...(net > 0
          ? [
              {
                accountType: 'USER_WALLET' as const,
                accountOwnerId: sellerId,
                amountPaise: -net,
                entryType: 'REFUND' as const,
                referenceId: p.id,
              },
            ]
          : []),
        ...(p.platformFeePaise > 0
          ? [
              {
                accountType: 'PLATFORM_REVENUE' as const,
                amountPaise: -p.platformFeePaise,
                entryType: 'REFUND' as const,
                referenceId: p.id,
              },
            ]
          : []),
      ],
      tx,
    );

    await tx.$executeRaw`UPDATE "Drawing" SET "purchaseCount" = GREATEST("purchaseCount" - 1, 0) WHERE "id" = ${p.drawingId}::uuid`;

    const refund = await tx.refund.create({
      data: {
        purchaseId: p.id,
        adminId,
        reason,
        amountPaise: p.pricePaise,
        ledgerTxnId,
      },
    });
    await tx.auditLog.create({
      data: {
        actorId: adminId,
        action: 'purchase.refund',
        entityType: 'Purchase',
        entityId: p.id,
        metadata: {
          reason,
          amountPaise: p.pricePaise,
          sellerId,
          buyerId: p.buyerId,
          ledgerTxnId,
        },
      },
    });
    return { refundId: refund.id, created: true };
  }

  /** Takes ownership of re-sending a FAILED (or abandoned PENDING) gateway refund; true for exactly one caller. */
  private async claimRetry(refundId: string): Promise<boolean> {
    const claimed = await this.prisma.refund.updateMany({
      where: {
        id: refundId,
        OR: [
          { providerStatus: 'FAILED' },
          {
            providerStatus: 'PENDING',
            updatedAt: { lt: new Date(Date.now() - STALE_PENDING_MS) },
          },
        ],
      },
      data: { providerStatus: 'PENDING', providerError: null },
    });
    return claimed.count === 1;
  }

  private async callProvider(
    purchaseId: string,
    refundId: string,
  ): Promise<void> {
    const p = await this.prisma.purchase.findUniqueOrThrow({
      where: { id: purchaseId },
      select: { razorpayPaymentId: true, pricePaise: true },
    });
    try {
      if (!p.razorpayPaymentId) {
        throw new Error('Purchase has no gateway payment id to refund');
      }
      const res = await this.provider.refund({
        paymentId: p.razorpayPaymentId,
        amountPaise: p.pricePaise,
        idempotencyKey: purchaseId,
        notes: { purchaseId },
      });
      await this.prisma.refund.update({
        where: { id: refundId },
        data: {
          providerStatus: 'SUCCEEDED',
          providerRefundId: res.refundId,
          providerError: null,
        },
      });
    } catch (err) {
      const message = err instanceof Error ? err.message : String(err);
      this.logger.error(
        `Gateway refund failed for purchase ${purchaseId} (refund ${refundId}): ${message}`,
      );
      await this.prisma.refund.update({
        where: { id: refundId },
        data: {
          providerStatus: 'FAILED',
          providerError: message.slice(0, 500),
        },
      });
    }
  }

  private notFound(): ApiException {
    return new ApiException(
      HttpStatus.NOT_FOUND,
      'NOT_FOUND',
      'Purchase not found',
    );
  }
}

function searchClauses(q: string): Prisma.PurchaseWhereInput[] {
  const contains = { contains: q, mode: 'insensitive' as const };
  return [
    ...(UUID_RE.test(q) ? [{ id: q.toLowerCase() }] : []),
    { razorpayOrderId: contains },
    { razorpayPaymentId: contains },
    { buyer: { OR: [{ fullName: contains }, { email: contains }] } },
    {
      drawing: {
        OR: [
          { title: contains },
          {
            architect: { OR: [{ fullName: contains }, { email: contains }] },
          },
        ],
      },
    },
  ];
}

function toRefundView(r: NonNullable<PurchaseRow['refund']>): RefundView {
  return {
    id: r.id,
    reason: r.reason,
    amountPaise: r.amountPaise,
    refundedAt: r.createdAt,
    refundedBy: { id: r.admin.id, fullName: r.admin.fullName },
    providerStatus: r.providerStatus,
    providerRefundId: r.providerRefundId,
    providerError: r.providerError,
  };
}

function toView(p: PurchaseRow): AdminPurchaseView {
  return {
    id: p.id,
    status: p.status,
    pricePaise: p.pricePaise,
    platformFeePaise: p.platformFeePaise,
    sellerNetPaise: p.pricePaise - p.platformFeePaise,
    razorpayOrderId: p.razorpayOrderId,
    razorpayPaymentId: p.razorpayPaymentId,
    createdAt: p.createdAt,
    paidAt: p.paidAt,
    buyer: p.buyer,
    seller: p.drawing.architect,
    drawing: { id: p.drawing.id, title: p.drawing.title },
    refund: p.refund ? toRefundView(p.refund) : null,
  };
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
