export type LengthUnit = 'ft' | 'm';

export const FEET_PER_METRE = 1 / 0.3048;
export const DEFAULT_TOLERANCE_PCT = 10;
export const MAX_TOLERANCE_PCT = 50;

// Absorbs float noise (e.g. 9.144 m / 0.3048 = 30.000000000000004 ft) so boundary plots still match.
const EPSILON_FT = 1e-6;

/** Converts a user-entered length to feet, rounded to 1e-6 ft to drop unit-conversion noise. */
export function toFeet(value: number, unit: LengthUnit): number {
  const ft = unit === 'm' ? value * FEET_PER_METRE : value;
  return Math.round(ft * 1e6) / 1e6;
}

export interface SizeQuery {
  lengthFt: number;
  breadthFt: number;
  /** 0..MAX_TOLERANCE_PCT; applied to each requested dimension separately. */
  tolerancePct: number;
}

export interface SizeBounds {
  lMin: number;
  lMax: number;
  bMin: number;
  bMax: number;
}

export function sizeBounds(q: SizeQuery): SizeBounds {
  const t = q.tolerancePct / 100;
  return {
    lMin: q.lengthFt * (1 - t) - EPSILON_FT,
    lMax: q.lengthFt * (1 + t) + EPSILON_FT,
    bMin: q.breadthFt * (1 - t) - EPSILON_FT,
    bMax: q.breadthFt * (1 + t) + EPSILON_FT,
  };
}

const within = (v: number, lo: number, hi: number) => v >= lo && v <= hi;

/** True when the plot matches as asked (L x B) or rotated (B x L), both dimensions inside tolerance (inclusive). */
export function matchesSize(
  q: SizeQuery,
  plotLengthFt: number,
  plotBreadthFt: number,
): boolean {
  const b = sizeBounds(q);
  const direct =
    within(plotLengthFt, b.lMin, b.lMax) &&
    within(plotBreadthFt, b.bMin, b.bMax);
  const rotated =
    within(plotLengthFt, b.bMin, b.bMax) &&
    within(plotBreadthFt, b.lMin, b.lMax);
  return direct || rotated;
}

/**
 * Score in 0..1, 1 = exact (either orientation). It is `1 - worstRelativeDeviation / tolerance` for the better
 * orientation, so a plot exactly on the tolerance edge scores 0 but still matches. Returns null if it does not match.
 */
export function sizeMatchScore(
  q: SizeQuery,
  plotLengthFt: number,
  plotBreadthFt: number,
): number | null {
  if (!matchesSize(q, plotLengthFt, plotBreadthFt)) return null;
  const dev = (a: number, ref: number) => Math.abs(a - ref) / ref;
  const direct = Math.max(
    dev(plotLengthFt, q.lengthFt),
    dev(plotBreadthFt, q.breadthFt),
  );
  const rotated = Math.max(
    dev(plotLengthFt, q.breadthFt),
    dev(plotBreadthFt, q.lengthFt),
  );
  const t = q.tolerancePct / 100;
  if (t === 0) return 1;
  return Math.max(0, 1 - Math.min(direct, rotated) / t);
}
