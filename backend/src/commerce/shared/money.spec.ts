import { computePlatformFeePaise } from './money';

describe('computePlatformFeePaise', () => {
  it('rounds down using integer math', () => {
    expect(computePlatformFeePaise(100000, 1000)).toBe(10000);
    expect(computePlatformFeePaise(33333, 1000)).toBe(3333);
    expect(computePlatformFeePaise(5, 1000)).toBe(0);
    expect(computePlatformFeePaise(0, 1000)).toBe(0);
  });

  it('fee plus net always equals price', () => {
    for (const price of [1, 7, 99, 12345, 999999]) {
      const fee = computePlatformFeePaise(price, 1250);
      expect(fee).toBeGreaterThanOrEqual(0);
      expect(fee).toBeLessThanOrEqual(price);
    }
  });

  it('rejects fractional or negative prices', () => {
    expect(() => computePlatformFeePaise(1.5, 1000)).toThrow(RangeError);
    expect(() => computePlatformFeePaise(-1, 1000)).toThrow(RangeError);
  });
});
