import { HttpStatus, Inject, Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Prisma } from '@prisma/client';
import { randomUUID } from 'node:crypto';
import { ApiException } from '../../common/errors/api-exception';
import { Env } from '../../config/env.schema';
import { PrismaService } from '../../prisma/prisma.service';
import { lockUser } from '../shared/locks';
import { computePlatformFeePaise } from '../shared/money';
import {
  PAYMENT_PROVIDER,
  type PaymentProvider,
} from '../payments/payment.provider';
import {
  OrderStatus,
  PaymentSettlementService,
} from '../payments/payment-settlement.service';

export interface CheckoutResult {
  orderId: string;
  razorpayKeyId: string;
  amountPaise: number;
  currency: 'INR';
  purchaseIds: string[];
}

@Injectable()
export class CheckoutService {
  private readonly logger = new Logger(CheckoutService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly settlement: PaymentSettlementService,
    private readonly config: ConfigService<Env, true>,
    @Inject(PAYMENT_PROVIDER) private readonly provider: PaymentProvider,
  ) {}

  /**
   * Creates (or re-uses) one Razorpay order for the whole cart. The user row lock serialises concurrent checkouts,
   * and an identical still-unpaid order is returned as-is, so double taps never create a second payable order.
   */
  async checkout(userId: string): Promise<CheckoutResult> {
    const feeBps = this.config.get('PLATFORM_FEE_BPS', { infer: true });

    const result = await this.prisma.$transaction(
      async (tx) => {
        await lockUser(tx, userId);
        const cart = await tx.cartItem.findMany({
          where: { userId },
          orderBy: { drawingId: 'asc' },
          include: {
            drawing: {
              select: {
                id: true,
                pricePaise: true,
                status: true,
                architectId: true,
              },
            },
          },
        });
        if (cart.length === 0) {
          throw new ApiException(
            HttpStatus.BAD_REQUEST,
            'VALIDATION_ERROR',
            'Your cart is empty',
          );
        }

        const owned = await tx.purchase.findMany({
          where: {
            buyerId: userId,
            status: 'PAID',
            drawingId: { in: cart.map((c) => c.drawingId) },
          },
          select: { drawingId: true },
        });
        const ownedIds = new Set(owned.map((o) => o.drawingId));
        const unavailable = cart.filter(
          (c) =>
            c.drawing.status !== 'PUBLISHED' ||
            c.drawing.pricePaise <= 0 ||
            c.drawing.architectId === userId ||
            ownedIds.has(c.drawingId),
        );
        if (unavailable.length > 0) {
          const ids = unavailable.map((c) => c.drawingId);
          await tx.cartItem.deleteMany({
            where: { userId, drawingId: { in: ids } },
          });
          return { unavailable: ids } as const;
        }

        const lines = cart.map((c) => ({
          drawingId: c.drawingId,
          pricePaise: c.drawing.pricePaise,
        }));
        const amountPaise = lines.reduce((s, l) => s + l.pricePaise, 0);

        const existing = await this.findReusableOrder(tx, userId, lines);
        if (existing) return { order: existing } as const;

        // Supersede stale unpaid purchases for the same drawings (a late payment can still settle them).
        await tx.purchase.updateMany({
          where: {
            buyerId: userId,
            status: 'CREATED',
            drawingId: { in: lines.map((l) => l.drawingId) },
          },
          data: { status: 'FAILED' },
        });

        const created = await Promise.all(
          lines.map((l) =>
            tx.purchase.create({
              data: {
                buyerId: userId,
                drawingId: l.drawingId,
                pricePaise: l.pricePaise,
                platformFeePaise: computePlatformFeePaise(l.pricePaise, feeBps),
              },
              select: { id: true },
            }),
          ),
        );
        const { orderId } = await this.provider.createOrder({
          amountPaise,
          receipt: `ck_${randomUUID().replace(/-/g, '')}`,
          notes: { buyerId: userId },
        });
        await tx.purchase.updateMany({
          where: { id: { in: created.map((p) => p.id) } },
          data: { razorpayOrderId: orderId },
        });
        return {
          order: {
            orderId,
            amountPaise,
            purchaseIds: created.map((p) => p.id),
          },
        } as const;
      },
      { timeout: 20_000 },
    );

    if ('unavailable' in result) {
      throw new ApiException(
        HttpStatus.BAD_REQUEST,
        'VALIDATION_ERROR',
        'Some drawings in your cart are no longer available and were removed',
        { unavailableDrawingIds: result.unavailable },
      );
    }
    return {
      orderId: result.order.orderId,
      razorpayKeyId: this.provider.keyId,
      amountPaise: result.order.amountPaise,
      currency: 'INR',
      purchaseIds: result.order.purchaseIds,
    };
  }

  /** `{status:"PAID"}` once the signature is valid; the webhook may already have settled it (idempotent). */
  async verify(
    userId: string,
    input: {
      razorpayOrderId: string;
      razorpayPaymentId: string;
      razorpaySignature: string;
    },
  ): Promise<{ status: 'PAID' | 'FAILED' }> {
    await this.assertOwnsOrder(userId, input.razorpayOrderId);
    const valid = this.provider.verifyPaymentSignature(
      input.razorpayOrderId,
      input.razorpayPaymentId,
      input.razorpaySignature,
    );
    if (!valid) {
      throw new ApiException(
        HttpStatus.BAD_REQUEST,
        'VALIDATION_ERROR',
        'Invalid payment signature',
      );
    }
    await this.settlement.captureOrder(
      input.razorpayOrderId,
      input.razorpayPaymentId,
    );
    const status = await this.settlement.getOrderStatus(
      userId,
      input.razorpayOrderId,
    );
    return { status: status === 'PAID' ? 'PAID' : 'FAILED' };
  }

  /** Stub mode only: simulates the captured-payment webhook for the user's own order. */
  async stubComplete(
    userId: string,
    orderId: string,
  ): Promise<{ status: 'PAID' }> {
    if (
      !this.provider.isStub ||
      this.config.get('NODE_ENV', { infer: true }) === 'production'
    ) {
      throw new ApiException(
        HttpStatus.NOT_FOUND,
        'NOT_FOUND',
        'Not available outside stub mode',
      );
    }
    await this.assertOwnsOrder(userId, orderId);
    await this.settlement.captureOrder(orderId, `pay_stub_${orderId}`);
    const status = await this.settlement.getOrderStatus(userId, orderId);
    if (status !== 'PAID') {
      throw new ApiException(
        HttpStatus.CONFLICT,
        'CONFLICT',
        'Order could not be completed',
      );
    }
    return { status: 'PAID' };
  }

  getStatus(userId: string, orderId: string): Promise<{ status: OrderStatus }> {
    return this.settlement
      .getOrderStatus(userId, orderId)
      .then((status) => ({ status }));
  }

  private async assertOwnsOrder(
    userId: string,
    orderId: string,
  ): Promise<void> {
    const found = await this.prisma.purchase.findFirst({
      where: { razorpayOrderId: orderId, buyerId: userId },
      select: { id: true },
    });
    if (!found) {
      throw new ApiException(
        HttpStatus.NOT_FOUND,
        'NOT_FOUND',
        'Order not found',
      );
    }
  }

  private async findReusableOrder(
    tx: Prisma.TransactionClient,
    userId: string,
    lines: { drawingId: string; pricePaise: number }[],
  ): Promise<{
    orderId: string;
    amountPaise: number;
    purchaseIds: string[];
  } | null> {
    const pending = await tx.purchase.findMany({
      where: {
        buyerId: userId,
        status: 'CREATED',
        razorpayOrderId: { not: null },
      },
      orderBy: { drawingId: 'asc' },
    });
    const byOrder = new Map<string, typeof pending>();
    for (const p of pending) {
      const list = byOrder.get(p.razorpayOrderId!) ?? [];
      list.push(p);
      byOrder.set(p.razorpayOrderId!, list);
    }
    for (const [orderId, list] of byOrder) {
      const same =
        list.length === lines.length &&
        list.every(
          (p, i) =>
            p.drawingId === lines[i].drawingId &&
            p.pricePaise === lines[i].pricePaise,
        );
      if (same) {
        return {
          orderId,
          amountPaise: list.reduce((s, p) => s + p.pricePaise, 0),
          purchaseIds: list.map((p) => p.id),
        };
      }
    }
    return null;
  }
}
