import { hmacSha256Hex } from '../payments/signature';
import { PayoutRejectedError } from './payout.provider';
import { RazorpayXPayoutProvider } from './razorpayx.provider';
import {
  STUB_PAYOUT_WEBHOOK_SECRET,
  StubPayoutProvider,
} from './stub-payout.provider';

const cfg = {
  keyId: 'rzp_key',
  keySecret: 'secret',
  accountNumber: '2323230000000001',
  webhookSecret: 'whsec',
};

function mockFetch(...responses: Partial<Response>[]) {
  const fn = jest.fn();
  for (const r of responses) fn.mockResolvedValueOnce(r);
  return fn;
}
const json = (status: number, body: unknown): Partial<Response> => ({
  status,
  ok: status >= 200 && status < 300,
  json: () => Promise.resolve(body),
  text: () => Promise.resolve(JSON.stringify(body)),
});

describe('StubPayoutProvider', () => {
  const stub = new StubPayoutProvider(true);

  it('pays immediately with a deterministic reference', async () => {
    const { fundAccountId } = await stub.createFundAccount({
      userId: 'u1',
      holderName: 'A B',
      ifsc: 'HDFC0001234',
      accountNumber: '123456789012',
    });
    expect(fundAccountId).toMatch(/^fa_stub_[0-9a-f]{16}$/);
    await expect(
      stub.createPayout({ withdrawalId: 'w1', amountPaise: 5, fundAccountId }),
    ).resolves.toEqual({ providerRef: 'pout_stub_w1', status: 'PAID' });
  });

  it('rejects payouts for accounts ending 0000', async () => {
    const { fundAccountId } = await stub.createFundAccount({
      userId: 'u1',
      holderName: 'A B',
      ifsc: 'HDFC0001234',
      accountNumber: '123456780000',
    });
    await expect(
      stub.createPayout({ withdrawalId: 'w1', amountPaise: 5, fundAccountId }),
    ).rejects.toBeInstanceOf(PayoutRejectedError);
  });

  it('verifies webhook signatures with its fixed key', () => {
    const body = '{"a":1}';
    expect(
      stub.verifyWebhookSignature(
        body,
        hmacSha256Hex(STUB_PAYOUT_WEBHOOK_SECRET, body),
      ),
    ).toBe(true);
    expect(stub.verifyWebhookSignature(body, 'nope')).toBe(false);
    expect(stub.verifyWebhookSignature(body, undefined)).toBe(false);
  });

  it('refuses everything when disabled (production without RazorpayX)', async () => {
    const off = new StubPayoutProvider(false);
    await expect(
      off.createFundAccount({
        userId: 'u',
        holderName: 'x',
        ifsc: 'HDFC0001234',
        accountNumber: '123456789',
      }),
    ).rejects.toMatchObject({ status: 500 });
    await expect(
      off.createPayout({
        withdrawalId: 'w',
        amountPaise: 1,
        fundAccountId: 'f',
      }),
    ).rejects.toMatchObject({ status: 500 });
    const body = 'x';
    expect(
      off.verifyWebhookSignature(
        body,
        hmacSha256Hex(STUB_PAYOUT_WEBHOOK_SECRET, body),
      ),
    ).toBe(false);
  });
});

describe('RazorpayXPayoutProvider', () => {
  it('creates a contact then a fund account', async () => {
    const f = mockFetch(json(200, { id: 'cont_1' }), json(200, { id: 'fa_1' }));
    const p = new RazorpayXPayoutProvider(cfg, f);
    await expect(
      p.createFundAccount({
        userId: 'u1',
        holderName: 'A B',
        ifsc: 'HDFC0001234',
        accountNumber: '123456789012',
      }),
    ).resolves.toEqual({ fundAccountId: 'fa_1' });
    expect(f).toHaveBeenCalledTimes(2);
    const [, second] = f.mock.calls[1] as [string, RequestInit];
    expect(JSON.parse(second.body as string)).toMatchObject({
      contact_id: 'cont_1',
      bank_account: { account_number: '123456789012' },
    });
  });

  it('maps a 400 on fund accounts to a validation error and 5xx to bad gateway', async () => {
    const input = {
      userId: 'u',
      holderName: 'A B',
      ifsc: 'HDFC0001234',
      accountNumber: '123456789012',
    };
    await expect(
      new RazorpayXPayoutProvider(
        cfg,
        mockFetch(json(400, {})),
      ).createFundAccount(input),
    ).rejects.toMatchObject({ status: 400 });
    await expect(
      new RazorpayXPayoutProvider(
        cfg,
        mockFetch(json(503, {})),
      ).createFundAccount(input),
    ).rejects.toMatchObject({ status: 502 });
  });

  it('sends the withdrawal id as idempotency key and reference', async () => {
    const f = mockFetch(json(200, { id: 'pout_1', status: 'processing' }));
    const res = await new RazorpayXPayoutProvider(cfg, f).createPayout({
      withdrawalId: 'w1',
      amountPaise: 123400,
      fundAccountId: 'fa_1',
    });
    expect(res).toEqual({ providerRef: 'pout_1', status: 'PROCESSING' });
    const [url, init] = f.mock.calls[0] as [string, RequestInit];
    expect(url).toBe('https://api.razorpay.com/v1/payouts');
    expect(
      (init.headers as Record<string, string>)['X-Payout-Idempotency'],
    ).toBe('w1');
    expect(JSON.parse(init.body as string)).toMatchObject({
      amount: 123400,
      reference_id: 'w1',
      fund_account_id: 'fa_1',
      account_number: cfg.accountNumber,
    });
  });

  it('reports an immediately processed payout as PAID', async () => {
    const f = mockFetch(json(200, { id: 'pout_1', status: 'processed' }));
    await expect(
      new RazorpayXPayoutProvider(cfg, f).createPayout({
        withdrawalId: 'w1',
        amountPaise: 1,
        fundAccountId: 'fa',
      }),
    ).resolves.toMatchObject({ status: 'PAID' });
  });

  it('treats a 400 as a definitive rejection but 5xx/network errors as retryable', async () => {
    const input = { withdrawalId: 'w1', amountPaise: 1, fundAccountId: 'fa' };
    await expect(
      new RazorpayXPayoutProvider(
        cfg,
        mockFetch(json(400, { error: { description: 'bad account' } })),
      ).createPayout(input),
    ).rejects.toBeInstanceOf(PayoutRejectedError);

    const retryable = [
      new RazorpayXPayoutProvider(cfg, mockFetch(json(500, {}))),
      new RazorpayXPayoutProvider(cfg, mockFetch(json(429, {}))),
      new RazorpayXPayoutProvider(
        cfg,
        jest.fn().mockRejectedValue(new Error('timeout')),
      ),
    ];
    for (const p of retryable) {
      const err: unknown = await p.createPayout(input).catch((e: unknown) => e);
      expect(err).toBeInstanceOf(Error);
      expect(err).not.toBeInstanceOf(PayoutRejectedError);
    }
  });

  it('verifies webhooks with the configured secret only', () => {
    const body = '{"event":"payout.processed"}';
    const p = new RazorpayXPayoutProvider(cfg, jest.fn());
    expect(p.verifyWebhookSignature(body, hmacSha256Hex('whsec', body))).toBe(
      true,
    );
    expect(p.verifyWebhookSignature(body, hmacSha256Hex('other', body))).toBe(
      false,
    );
    expect(
      new RazorpayXPayoutProvider(
        { ...cfg, webhookSecret: undefined },
        jest.fn(),
      ).verifyWebhookSignature(body, hmacSha256Hex('', body)),
    ).toBe(false);
  });
});
