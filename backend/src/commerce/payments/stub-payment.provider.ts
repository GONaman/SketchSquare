import { HttpStatus } from '@nestjs/common';
import { randomBytes } from 'node:crypto';
import { ApiException } from '../../common/errors/api-exception';
import { PaymentProvider } from './payment.provider';
import { hmacSha256Hex, safeEqualHex } from './signature';

/** Shared secret for the stub provider; only usable outside production, so it protects nothing real. */
export const STUB_PAYMENT_SECRET = 'sketchsquare-stub-payment-secret';

/** Local no-account checkout: orders are fake ids, "payment" is simulated via /checkout/stub-complete. */
export class StubPaymentProvider implements PaymentProvider {
  readonly keyId = 'stub';
  readonly isStub = true;

  /** `enabled=false` (production without Razorpay keys) refuses to create orders or accept signatures. */
  constructor(private readonly enabled: boolean) {}

  createOrder(): Promise<{ orderId: string }> {
    if (!this.enabled) {
      throw new ApiException(
        HttpStatus.INTERNAL_SERVER_ERROR,
        'INTERNAL',
        'Payments are not configured',
      );
    }
    return Promise.resolve({
      orderId: `order_stub_${randomBytes(9).toString('hex')}`,
    });
  }

  verifyPaymentSignature(
    orderId: string,
    paymentId: string,
    signature: string,
  ): boolean {
    return (
      this.enabled &&
      safeEqualHex(
        hmacSha256Hex(STUB_PAYMENT_SECRET, `${orderId}|${paymentId}`),
        signature,
      )
    );
  }

  verifyWebhookSignature(
    rawBody: Buffer | string,
    signature: string | undefined,
  ): boolean {
    return (
      this.enabled &&
      safeEqualHex(hmacSha256Hex(STUB_PAYMENT_SECRET, rawBody), signature)
    );
  }
}
