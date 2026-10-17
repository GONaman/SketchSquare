import { RazorpayRefundProvider } from './razorpay-refund.provider';
import { StubRefundProvider } from './stub-refund.provider';

const req = {
  paymentId: 'pay_123',
  amountPaise: 49900,
  idempotencyKey: 'purchase-1',
};

describe('RazorpayRefundProvider', () => {
  it('posts the refund with auth and idempotency header', async () => {
    const fetchMock = jest.fn().mockResolvedValue({
      ok: true,
      status: 200,
      json: () => Promise.resolve({ id: 'rfnd_1' }),
    });
    const provider = new RazorpayRefundProvider(
      { keyId: 'k', keySecret: 's' },
      fetchMock,
    );
    await expect(provider.refund(req)).resolves.toEqual({ refundId: 'rfnd_1' });
    const [url, init] = fetchMock.mock.calls[0] as [string, RequestInit];
    expect(url).toBe('https://api.razorpay.com/v1/payments/pay_123/refund');
    const headers = init.headers as Record<string, string>;
    expect(headers['X-Refund-Idempotency']).toBe('purchase-1');
    expect(headers.Authorization).toBe(
      `Basic ${Buffer.from('k:s').toString('base64')}`,
    );
    expect(JSON.parse(init.body as string)).toMatchObject({ amount: 49900 });
  });

  it('throws on HTTP errors', async () => {
    const fetchMock = jest.fn().mockResolvedValue({ ok: false, status: 400 });
    const provider = new RazorpayRefundProvider(
      { keyId: 'k', keySecret: 's' },
      fetchMock,
    );
    await expect(provider.refund(req)).rejects.toThrow('HTTP 400');
  });

  it('throws when the response has no id', async () => {
    const fetchMock = jest.fn().mockResolvedValue({
      ok: true,
      status: 200,
      json: () => Promise.resolve({}),
    });
    const provider = new RazorpayRefundProvider(
      { keyId: 'k', keySecret: 's' },
      fetchMock,
    );
    await expect(provider.refund(req)).rejects.toThrow('no id');
  });
});

describe('StubRefundProvider', () => {
  it('returns a deterministic id per idempotency key', async () => {
    const provider = new StubRefundProvider(true);
    const a = await provider.refund(req);
    const b = await provider.refund(req);
    expect(a.refundId).toMatch(/^rfnd_stub_/);
    expect(a).toEqual(b);
  });

  it('refuses to run when disabled', async () => {
    const provider = new StubRefundProvider(false);
    await expect(provider.refund(req)).rejects.toThrow();
  });
});
