import { createHash } from 'node:crypto';
import { RefundProvider, RefundRequest } from './refund.provider';

/** Local no-account refunds: succeeds instantly with a deterministic fake id. */
export class StubRefundProvider implements RefundProvider {
  readonly isStub = true;

  /** `enabled=false` (production without Razorpay keys) refuses, so no refund is ever faked as sent. */
  constructor(private readonly enabled: boolean) {}

  refund(input: RefundRequest): Promise<{ refundId: string }> {
    if (!this.enabled) {
      return Promise.reject(new Error('Refunds are not configured'));
    }
    const id = createHash('sha256')
      .update(input.idempotencyKey)
      .digest('hex')
      .slice(0, 14);
    return Promise.resolve({ refundId: `rfnd_stub_${id}` });
  }
}
