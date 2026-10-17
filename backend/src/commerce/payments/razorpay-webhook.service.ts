import { HttpStatus, Inject, Injectable, Logger } from '@nestjs/common';
import { createHash } from 'node:crypto';
import { ApiException } from '../../common/errors/api-exception';
import { PrismaService } from '../../prisma/prisma.service';
import { PAYMENT_PROVIDER, type PaymentProvider } from './payment.provider';
import {
  PaymentSettlementService,
  WEBHOOK_PROVIDER,
} from './payment-settlement.service';

interface RazorpayEvent {
  event?: string;
  payload?: {
    payment?: {
      entity?: { id?: string; order_id?: string; amount?: number };
    };
    order?: { entity?: { id?: string; amount_paid?: number } };
  };
}

export interface WebhookResult {
  ok: true;
  duplicate: boolean;
}

@Injectable()
export class RazorpayWebhookService {
  private readonly logger = new Logger(RazorpayWebhookService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly settlement: PaymentSettlementService,
    @Inject(PAYMENT_PROVIDER) private readonly provider: PaymentProvider,
  ) {}

  async handle(
    rawBody: Buffer | undefined,
    signature: string | undefined,
    eventIdHeader: string | undefined,
  ): Promise<WebhookResult> {
    if (!rawBody || !this.provider.verifyWebhookSignature(rawBody, signature)) {
      throw new ApiException(
        HttpStatus.UNAUTHORIZED,
        'UNAUTHORIZED',
        'Invalid webhook signature',
      );
    }
    let event: RazorpayEvent;
    try {
      event = JSON.parse(rawBody.toString('utf8')) as RazorpayEvent;
    } catch {
      throw new ApiException(
        HttpStatus.BAD_REQUEST,
        'VALIDATION_ERROR',
        'Malformed webhook body',
      );
    }
    const type = event.event ?? 'unknown';
    // Razorpay retries re-send the same event id; the body hash is a stable fallback.
    const eventId =
      eventIdHeader?.trim() ||
      `sha256:${createHash('sha256').update(rawBody).digest('hex')}`;

    return this.prisma.$transaction(
      async (tx) => {
        // The id is recorded in the same transaction as its effects: a failure rolls both back so the retry reprocesses,
        // and a concurrent duplicate waits on the unique key, then sees it already processed.
        const inserted = await tx.processedWebhookEvent.createMany({
          data: [{ provider: WEBHOOK_PROVIDER, eventId, eventType: type }],
          skipDuplicates: true,
        });
        if (inserted.count === 0) return { ok: true as const, duplicate: true };

        const payment = event.payload?.payment?.entity;
        const orderId = payment?.order_id ?? event.payload?.order?.entity?.id;
        if (type === 'payment.captured' || type === 'order.paid') {
          if (orderId && payment?.id) {
            await this.settlement.captureOrderInTx(
              tx,
              orderId,
              payment.id,
              payment.amount,
            );
          } else {
            this.logger.warn(`Ignoring ${type} without order/payment ids`);
          }
        } else if (type === 'payment.failed') {
          if (orderId) await this.settlement.failOrderInTx(tx, orderId);
        }
        return { ok: true as const, duplicate: false };
      },
      { timeout: 20_000 },
    );
  }
}
