export const PAYMENT_PROVIDER = 'PAYMENT_PROVIDER';

export interface CreateOrderInput {
  amountPaise: number;
  receipt: string;
  notes?: Record<string, string>;
}

/** Abstraction over Razorpay Orders so checkout works with a local stub when no keys are configured. */
export interface PaymentProvider {
  /** `"stub"` when running without real keys (the contract's stub mode). */
  readonly keyId: string;
  readonly isStub: boolean;
  createOrder(input: CreateOrderInput): Promise<{ orderId: string }>;
  /** Checkout signature: HMAC-SHA256(`${orderId}|${paymentId}`, key secret), hex. */
  verifyPaymentSignature(
    orderId: string,
    paymentId: string,
    signature: string,
  ): boolean;
  /** Webhook signature: HMAC-SHA256(raw body, webhook secret), hex. */
  verifyWebhookSignature(
    rawBody: Buffer | string,
    signature: string | undefined,
  ): boolean;
}
