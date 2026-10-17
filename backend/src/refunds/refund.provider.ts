export const REFUND_PROVIDER = 'REFUND_PROVIDER';

export interface RefundRequest {
  /** Gateway payment id (`razorpayPaymentId`) the refund is issued against. */
  paymentId: string;
  amountPaise: number;
  /** Stable per purchase, so retrying a refund never pays the buyer twice. */
  idempotencyKey: string;
  notes?: Record<string, string>;
}

/** Abstraction over the gateway refund API so refunds work with a local stub when no Razorpay keys are configured. */
export interface RefundProvider {
  readonly isStub: boolean;
  /** Throws on failure; a thrown error is recorded on the refund and the call can be retried. */
  refund(input: RefundRequest): Promise<{ refundId: string }>;
}
