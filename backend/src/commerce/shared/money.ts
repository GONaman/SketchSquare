/** Platform fee in paise, rounded down (the seller keeps the remainder). Integer math only. */
export function computePlatformFeePaise(
  pricePaise: number,
  feeBps: number,
): number {
  if (!Number.isSafeInteger(pricePaise) || pricePaise < 0) {
    throw new RangeError('pricePaise must be a non-negative integer');
  }
  return Math.floor((pricePaise * feeBps) / 10000);
}
