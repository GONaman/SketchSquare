import { HttpStatus, Logger } from '@nestjs/common';
import { ApiException } from '../../common/errors/api-exception';
import { CreateOrderInput, PaymentProvider } from './payment.provider';
import { hmacSha256Hex, safeEqualHex } from './signature';

const ORDERS_URL = 'https://api.razorpay.com/v1/orders';

export interface RazorpayConfig {
  keyId: string;
  keySecret: string;
  webhookSecret?: string;
}

export class RazorpayPaymentProvider implements PaymentProvider {
  readonly isStub = false;
  private readonly logger = new Logger(RazorpayPaymentProvider.name);

  constructor(
    private readonly cfg: RazorpayConfig,
    private readonly fetchImpl: typeof fetch = fetch,
  ) {}

  get keyId(): string {
    return this.cfg.keyId;
  }

  async createOrder(input: CreateOrderInput): Promise<{ orderId: string }> {
    const auth = Buffer.from(
      `${this.cfg.keyId}:${this.cfg.keySecret}`,
    ).toString('base64');
    let res: Response;
    try {
      res = await this.fetchImpl(ORDERS_URL, {
        method: 'POST',
        headers: {
          Authorization: `Basic ${auth}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          amount: input.amountPaise,
          currency: 'INR',
          receipt: input.receipt,
          notes: input.notes ?? {},
        }),
        signal: AbortSignal.timeout(10_000),
      });
    } catch (err) {
      this.logger.error(`Razorpay order request failed: ${String(err)}`);
      throw this.unavailable();
    }
    if (!res.ok) {
      this.logger.error(`Razorpay order creation failed: HTTP ${res.status}`);
      throw this.unavailable();
    }
    const body = (await res.json()) as { id?: string };
    if (!body.id) throw this.unavailable();
    return { orderId: body.id };
  }

  verifyPaymentSignature(
    orderId: string,
    paymentId: string,
    signature: string,
  ): boolean {
    return safeEqualHex(
      hmacSha256Hex(this.cfg.keySecret, `${orderId}|${paymentId}`),
      signature,
    );
  }

  verifyWebhookSignature(
    rawBody: Buffer | string,
    signature: string | undefined,
  ): boolean {
    if (!this.cfg.webhookSecret) return false;
    return safeEqualHex(
      hmacSha256Hex(this.cfg.webhookSecret, rawBody),
      signature,
    );
  }

  private unavailable(): ApiException {
    return new ApiException(
      HttpStatus.INTERNAL_SERVER_ERROR,
      'INTERNAL',
      'Could not create the payment order, please try again',
    );
  }
}
