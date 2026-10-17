import { Logger } from '@nestjs/common';
import { RefundProvider, RefundRequest } from './refund.provider';

const PAYMENTS_URL = 'https://api.razorpay.com/v1/payments';

export interface RazorpayRefundConfig {
  keyId: string;
  keySecret: string;
}

export class RazorpayRefundProvider implements RefundProvider {
  readonly isStub = false;
  private readonly logger = new Logger(RazorpayRefundProvider.name);

  constructor(
    private readonly cfg: RazorpayRefundConfig,
    private readonly fetchImpl: typeof fetch = fetch,
  ) {}

  async refund(input: RefundRequest): Promise<{ refundId: string }> {
    const auth = Buffer.from(
      `${this.cfg.keyId}:${this.cfg.keySecret}`,
    ).toString('base64');
    const res = await this.fetchImpl(
      `${PAYMENTS_URL}/${encodeURIComponent(input.paymentId)}/refund`,
      {
        method: 'POST',
        headers: {
          Authorization: `Basic ${auth}`,
          'Content-Type': 'application/json',
          'X-Refund-Idempotency': input.idempotencyKey,
        },
        body: JSON.stringify({
          amount: input.amountPaise,
          speed: 'normal',
          notes: input.notes ?? {},
        }),
        signal: AbortSignal.timeout(10_000),
      },
    );
    if (!res.ok) {
      this.logger.error(
        `Razorpay refund for ${input.paymentId} failed: HTTP ${res.status}`,
      );
      throw new Error(`Razorpay refund failed (HTTP ${res.status})`);
    }
    const body = (await res.json()) as { id?: string };
    if (!body.id) throw new Error('Razorpay refund response had no id');
    return { refundId: body.id };
  }
}
