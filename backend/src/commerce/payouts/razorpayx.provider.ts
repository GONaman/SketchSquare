import { HttpStatus, Logger } from '@nestjs/common';
import { ApiException } from '../../common/errors/api-exception';
import { hmacSha256Hex, safeEqualHex } from '../payments/signature';
import {
  CreatePayoutInput,
  CreatePayoutResult,
  FundAccountInput,
  PayoutProvider,
  PayoutRejectedError,
} from './payout.provider';

const BASE_URL = 'https://api.razorpay.com/v1';

export interface RazorpayXConfig {
  keyId: string;
  keySecret: string;
  /** The RazorpayX current account the payouts are debited from. */
  accountNumber: string;
  webhookSecret?: string;
}

interface RazorpayXPayout {
  id?: string;
  status?: string;
}

/** Real payouts via RazorpayX (contact → fund account → payout). Retried calls are made safe by `X-Payout-Idempotency`. */
export class RazorpayXPayoutProvider implements PayoutProvider {
  readonly isStub = false;
  private readonly logger = new Logger(RazorpayXPayoutProvider.name);

  constructor(
    private readonly cfg: RazorpayXConfig,
    private readonly fetchImpl: typeof fetch = fetch,
  ) {}

  async createFundAccount(
    input: FundAccountInput,
  ): Promise<{ fundAccountId: string }> {
    const contact = await this.post<{ id?: string }>('/contacts', {
      name: input.holderName,
      type: 'vendor',
      reference_id: input.userId,
    });
    const fund = await this.post<{ id?: string }>('/fund_accounts', {
      contact_id: contact.id,
      account_type: 'bank_account',
      bank_account: {
        name: input.holderName,
        ifsc: input.ifsc,
        account_number: input.accountNumber,
      },
    });
    if (!contact.id || !fund.id) throw this.unavailable();
    return { fundAccountId: fund.id };
  }

  async createPayout(input: CreatePayoutInput): Promise<CreatePayoutResult> {
    let res: Response;
    try {
      res = await this.fetchImpl(`${BASE_URL}/payouts`, {
        method: 'POST',
        headers: {
          ...this.headers(),
          'X-Payout-Idempotency': input.withdrawalId,
        },
        body: JSON.stringify({
          account_number: this.cfg.accountNumber,
          fund_account_id: input.fundAccountId,
          amount: input.amountPaise,
          currency: 'INR',
          mode: 'IMPS',
          purpose: 'payout',
          queue_if_low_balance: true,
          reference_id: input.withdrawalId,
          narration: 'SketchSquare payout',
        }),
        signal: AbortSignal.timeout(15_000),
      });
    } catch (err) {
      // Unknown outcome (timeout/network): the caller retries with the same idempotency key.
      throw new Error(`RazorpayX payout request failed: ${String(err)}`);
    }
    if (res.status === 400) {
      const detail = await res.text();
      this.logger.warn(`RazorpayX rejected payout ${input.withdrawalId}`);
      throw new PayoutRejectedError(
        `RazorpayX rejected the payout: ${detail.slice(0, 300)}`,
      );
    }
    if (!res.ok) {
      throw new Error(`RazorpayX payout failed: HTTP ${res.status}`);
    }
    const body = (await res.json()) as RazorpayXPayout;
    if (!body.id) throw new Error('RazorpayX payout response had no id');
    return {
      providerRef: body.id,
      status: body.status === 'processed' ? 'PAID' : 'PROCESSING',
    };
  }

  verifyWebhookSignature(
    rawBody: Buffer | string,
    signature: string | undefined,
  ): boolean {
    const secret = this.cfg.webhookSecret;
    if (!secret) return false;
    return safeEqualHex(hmacSha256Hex(secret, rawBody), signature);
  }

  private headers(): Record<string, string> {
    const auth = Buffer.from(
      `${this.cfg.keyId}:${this.cfg.keySecret}`,
    ).toString('base64');
    return {
      Authorization: `Basic ${auth}`,
      'Content-Type': 'application/json',
    };
  }

  private async post<T>(path: string, body: unknown): Promise<T> {
    let res: Response;
    try {
      res = await this.fetchImpl(`${BASE_URL}${path}`, {
        method: 'POST',
        headers: this.headers(),
        body: JSON.stringify(body),
        signal: AbortSignal.timeout(15_000),
      });
    } catch (err) {
      this.logger.error(`RazorpayX ${path} failed: ${String(err)}`);
      throw this.unavailable();
    }
    if (res.status === 400) {
      throw new ApiException(
        HttpStatus.BAD_REQUEST,
        'VALIDATION_ERROR',
        'The bank details were rejected by the payout provider',
      );
    }
    if (!res.ok) {
      this.logger.error(`RazorpayX ${path} failed: HTTP ${res.status}`);
      throw this.unavailable();
    }
    return (await res.json()) as T;
  }

  private unavailable(): ApiException {
    return new ApiException(
      HttpStatus.BAD_GATEWAY,
      'INTERNAL',
      'Payout provider is unavailable, please try again',
    );
  }
}
