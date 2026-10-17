export const PAYOUT_PROVIDER = Symbol('PAYOUT_PROVIDER');

export interface FundAccountInput {
  userId: string;
  holderName: string;
  ifsc: string;
  accountNumber: string;
}

export interface CreatePayoutInput {
  /** Also the provider idempotency key: calling again with the same id must not pay twice. */
  withdrawalId: string;
  amountPaise: number;
  fundAccountId: string;
}

export interface CreatePayoutResult {
  providerRef: string;
  /** PAID: money is already out (stub). PROCESSING: the provider confirms later via webhook. */
  status: 'PAID' | 'PROCESSING';
}

/** The provider definitively refused the payout (nothing was or will be sent): safe to reverse the ledger. */
export class PayoutRejectedError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'PayoutRejectedError';
  }
}

export interface PayoutProvider {
  readonly isStub: boolean;
  /** Registers the bank account with the provider; the raw account number is never stored by us. */
  createFundAccount(
    input: FundAccountInput,
  ): Promise<{ fundAccountId: string }>;
  /** Throws PayoutRejectedError for a definitive refusal; any other error means "unknown, retry". */
  createPayout(input: CreatePayoutInput): Promise<CreatePayoutResult>;
  verifyWebhookSignature(
    rawBody: Buffer | string,
    signature: string | undefined,
  ): boolean;
}
