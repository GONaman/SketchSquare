import { HttpStatus } from '@nestjs/common';
import { createHash } from 'node:crypto';
import { ApiException } from '../../common/errors/api-exception';
import { hmacSha256Hex, safeEqualHex } from '../payments/signature';
import {
  CreatePayoutInput,
  CreatePayoutResult,
  FundAccountInput,
  PayoutProvider,
  PayoutRejectedError,
} from './payout.provider';

/** Fixed non-secret key for the stub payout webhook; the stub is disabled in production. */
export const STUB_PAYOUT_WEBHOOK_SECRET = 'sketchsquare-stub-payout-secret';

/** Bank accounts whose number ends with this make the stub reject payouts, to exercise the failure path. */
export const STUB_FAIL_ACCOUNT_SUFFIX = '0000';

/** Local payouts without a bank: every payout "succeeds" immediately unless the account number ends in 0000. */
export class StubPayoutProvider implements PayoutProvider {
  readonly isStub = true;

  /** `enabled=false` (production without RazorpayX) refuses everything so no withdrawal is ever faked as paid. */
  constructor(private readonly enabled: boolean) {}

  createFundAccount(
    input: FundAccountInput,
  ): Promise<{ fundAccountId: string }> {
    // Rejects (rather than throws) when disabled, like a real provider call would.
    return Promise.resolve().then(() => {
      this.assertEnabled();
      const digest = createHash('sha256')
        .update(`${input.userId}:${input.ifsc}:${input.accountNumber}`)
        .digest('hex')
        .slice(0, 16);
      const fail = input.accountNumber.endsWith(STUB_FAIL_ACCOUNT_SUFFIX);
      return { fundAccountId: `fa_stub_${fail ? 'fail_' : ''}${digest}` };
    });
  }

  createPayout(input: CreatePayoutInput): Promise<CreatePayoutResult> {
    return Promise.resolve().then((): CreatePayoutResult => {
      this.assertEnabled();
      if (input.fundAccountId.startsWith('fa_stub_fail_')) {
        throw new PayoutRejectedError('Stub bank rejected the payout');
      }
      return { providerRef: `pout_stub_${input.withdrawalId}`, status: 'PAID' };
    });
  }

  verifyWebhookSignature(
    rawBody: Buffer | string,
    signature: string | undefined,
  ): boolean {
    return (
      this.enabled &&
      safeEqualHex(
        hmacSha256Hex(STUB_PAYOUT_WEBHOOK_SECRET, rawBody),
        signature,
      )
    );
  }

  private assertEnabled(): void {
    if (!this.enabled) {
      throw new ApiException(
        HttpStatus.INTERNAL_SERVER_ERROR,
        'INTERNAL',
        'Payouts are not configured',
      );
    }
  }
}
