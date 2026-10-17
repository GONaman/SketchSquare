import { HttpStatus, Inject, Injectable, Logger } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { createHash } from 'node:crypto';
import { ApiException } from '../../common/errors/api-exception';
import { PrismaService } from '../../prisma/prisma.service';
import { PAYOUT_PROVIDER, type PayoutProvider } from './payout.provider';
import { PayoutService } from './payout.service';

export const PAYOUT_WEBHOOK_PROVIDER = 'razorpayx';

interface PayoutEvent {
  event?: string;
  payload?: {
    payout?: {
      entity?: {
        id?: string;
        reference_id?: string;
        failure_reason?: string | null;
        status_details?: { description?: string | null } | null;
      };
    };
  };
}

export interface PayoutWebhookResult {
  ok: true;
  duplicate: boolean;
}

const UUID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

@Injectable()
export class RazorpayXWebhookService {
  private readonly logger = new Logger(RazorpayXWebhookService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly payouts: PayoutService,
    @Inject(PAYOUT_PROVIDER) private readonly provider: PayoutProvider,
  ) {}

  async handle(
    rawBody: Buffer | undefined,
    signature: string | undefined,
    eventIdHeader: string | undefined,
  ): Promise<PayoutWebhookResult> {
    if (!rawBody || !this.provider.verifyWebhookSignature(rawBody, signature)) {
      throw new ApiException(
        HttpStatus.UNAUTHORIZED,
        'UNAUTHORIZED',
        'Invalid webhook signature',
      );
    }
    let event: PayoutEvent;
    try {
      event = JSON.parse(rawBody.toString('utf8')) as PayoutEvent;
    } catch {
      throw new ApiException(
        HttpStatus.BAD_REQUEST,
        'VALIDATION_ERROR',
        'Malformed webhook body',
      );
    }
    const type = event.event ?? 'unknown';
    const eventId =
      eventIdHeader?.trim() ||
      `sha256:${createHash('sha256').update(rawBody).digest('hex')}`;

    return this.prisma.$transaction(
      async (tx) => {
        const inserted = await tx.processedWebhookEvent.createMany({
          data: [
            { provider: PAYOUT_WEBHOOK_PROVIDER, eventId, eventType: type },
          ],
          skipDuplicates: true,
        });
        if (inserted.count === 0) return { ok: true as const, duplicate: true };

        const entity = event.payload?.payout?.entity;
        if (!type.startsWith('payout.') || !entity) {
          return { ok: true as const, duplicate: false };
        }
        const withdrawalId = await this.findWithdrawalId(tx, entity);
        if (!withdrawalId) {
          this.logger.warn(`${type} for unknown payout ${entity.id ?? '?'}`);
          return { ok: true as const, duplicate: false };
        }
        const reason =
          entity.failure_reason ??
          entity.status_details?.description ??
          `Payout ${type.slice('payout.'.length)}`;

        let applied = true;
        if (type === 'payout.processed') {
          applied = await this.payouts.markPaidInTx(tx, withdrawalId);
        } else if (
          type === 'payout.failed' ||
          type === 'payout.rejected' ||
          type === 'payout.cancelled'
        ) {
          applied = await this.payouts.failInTx(tx, withdrawalId, reason);
        } else if (type === 'payout.reversed') {
          // The bank returned money after reporting success, so a PAID withdrawal can be reversed too.
          applied = await this.payouts.failInTx(tx, withdrawalId, reason, [
            'REQUESTED',
            'PROCESSING',
            'PAID',
          ]);
        }
        if (!applied) {
          this.logger.warn(
            `${type} for withdrawal ${withdrawalId} ignored: not in a state that allows it (manual review if unexpected)`,
          );
        }
        return { ok: true as const, duplicate: false };
      },
      { timeout: 20_000 },
    );
  }

  private async findWithdrawalId(
    tx: Prisma.TransactionClient,
    entity: { id?: string; reference_id?: string },
  ): Promise<string | null> {
    if (entity.reference_id && UUID_RE.test(entity.reference_id)) {
      const w = await tx.withdrawal.findUnique({
        where: { id: entity.reference_id },
        select: { id: true },
      });
      if (w) return w.id;
    }
    if (entity.id) {
      const w = await tx.withdrawal.findFirst({
        where: { providerRef: entity.id },
        select: { id: true },
      });
      if (w) return w.id;
    }
    return null;
  }
}
