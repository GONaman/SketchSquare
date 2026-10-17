import { aggregateStatus } from './payment-settlement.service';
import { hmacSha256Hex, safeEqualHex } from './signature';
import {
  STUB_PAYMENT_SECRET,
  StubPaymentProvider,
} from './stub-payment.provider';

describe('signature helpers', () => {
  it('hmacSha256Hex matches a known vector', () => {
    expect(
      hmacSha256Hex('key', 'The quick brown fox jumps over the lazy dog'),
    ).toBe('f7bc83f430538424b13298e6aa6fb143ef4d59a14946175997479dbc2d1a3cd8');
  });

  it('safeEqualHex handles mismatches, lengths and missing values', () => {
    expect(safeEqualHex('abc', 'abc')).toBe(true);
    expect(safeEqualHex('abc', 'abd')).toBe(false);
    expect(safeEqualHex('abc', 'abcd')).toBe(false);
    expect(safeEqualHex('abc', undefined)).toBe(false);
    expect(safeEqualHex('abc', '')).toBe(false);
  });
});

describe('StubPaymentProvider', () => {
  const on = new StubPaymentProvider(true);
  const off = new StubPaymentProvider(false);

  it('creates unique fake orders when enabled', async () => {
    const a = await on.createOrder();
    const b = await on.createOrder();
    expect(a.orderId).toMatch(/^order_stub_[0-9a-f]{18}$/);
    expect(a.orderId).not.toBe(b.orderId);
    expect(on.isStub).toBe(true);
    expect(on.keyId).toBe('stub');
  });

  it('verifies payment and webhook signatures', () => {
    const sig = hmacSha256Hex(STUB_PAYMENT_SECRET, 'order_1|pay_1');
    expect(on.verifyPaymentSignature('order_1', 'pay_1', sig)).toBe(true);
    expect(on.verifyPaymentSignature('order_1', 'pay_2', sig)).toBe(false);
    const body = Buffer.from('{"a":1}');
    const wsig = hmacSha256Hex(STUB_PAYMENT_SECRET, body);
    expect(on.verifyWebhookSignature(body, wsig)).toBe(true);
    expect(on.verifyWebhookSignature(body, undefined)).toBe(false);
    expect(on.verifyWebhookSignature(Buffer.from('{"a":2}'), wsig)).toBe(false);
  });

  it('refuses everything when disabled (production without keys)', () => {
    expect(() => off.createOrder()).toThrow();
    const sig = hmacSha256Hex(STUB_PAYMENT_SECRET, 'o|p');
    expect(off.verifyPaymentSignature('o', 'p', sig)).toBe(false);
    expect(
      off.verifyWebhookSignature('x', hmacSha256Hex(STUB_PAYMENT_SECRET, 'x')),
    ).toBe(false);
  });
});

describe('aggregateStatus', () => {
  it('is CREATED while any purchase is unpaid', () => {
    expect(aggregateStatus(['PAID', 'CREATED'])).toBe('CREATED');
  });
  it('is PAID when settled', () => {
    expect(aggregateStatus(['PAID', 'PAID'])).toBe('PAID');
    expect(aggregateStatus(['REFUNDED'])).toBe('PAID');
  });
  it('is FAILED when nothing was paid', () => {
    expect(aggregateStatus(['FAILED', 'FAILED'])).toBe('FAILED');
  });
});
