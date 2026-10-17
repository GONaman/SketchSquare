export interface PlotSize {
  lengthFt: number;
  breadthFt: number;
}

// Plot sizes are stored with 2 decimals; the slack keeps exact boundary values (e.g. 38 vs 40 at 5%) inside the tolerance.
const EPSILON = 1e-9;

/** Inclusive `[min, max]` that a dimension may take to be within `tolerancePct` of `value`. */
export function dimensionBounds(
  value: number,
  tolerancePct: number,
): [number, number] {
  const delta = (value * tolerancePct) / 100;
  return [value - delta - EPSILON, value + delta + EPSILON];
}

const within = (value: number, target: number, tolerancePct: number) => {
  const [min, max] = dimensionBounds(target, tolerancePct);
  return value >= min && value <= max;
};

/**
 * True when `candidate` is within ±`tolerancePct` of `plot` on both dimensions, in the same orientation or rotated
 * (length↔breadth). The tolerance is relative to `plot` (the drawing being checked).
 */
export function isSimilarPlot(
  plot: PlotSize,
  candidate: PlotSize,
  tolerancePct: number,
): boolean {
  const straight =
    within(candidate.lengthFt, plot.lengthFt, tolerancePct) &&
    within(candidate.breadthFt, plot.breadthFt, tolerancePct);
  const rotated =
    within(candidate.lengthFt, plot.breadthFt, tolerancePct) &&
    within(candidate.breadthFt, plot.lengthFt, tolerancePct);
  return straight || rotated;
}
