import { hammingDistance } from '../watermark/phash';
import { dimensionBounds, isSimilarPlot } from './similarity';

describe('isSimilarPlot', () => {
  const plot = { lengthFt: 40, breadthFt: 30 };

  it('matches identical, near and boundary sizes', () => {
    expect(isSimilarPlot(plot, plot, 5)).toBe(true);
    expect(isSimilarPlot(plot, { lengthFt: 41.5, breadthFt: 29 }, 5)).toBe(
      true,
    );
    expect(isSimilarPlot(plot, { lengthFt: 38, breadthFt: 31.5 }, 5)).toBe(
      true,
    );
    expect(isSimilarPlot(plot, { lengthFt: 42, breadthFt: 28.5 }, 5)).toBe(
      true,
    );
  });

  it('rejects a size outside the tolerance on either dimension', () => {
    expect(isSimilarPlot(plot, { lengthFt: 42.1, breadthFt: 30 }, 5)).toBe(
      false,
    );
    expect(isSimilarPlot(plot, { lengthFt: 40, breadthFt: 28.4 }, 5)).toBe(
      false,
    );
    expect(isSimilarPlot(plot, { lengthFt: 60, breadthFt: 50 }, 5)).toBe(false);
  });

  it('matches the rotated plot', () => {
    expect(isSimilarPlot(plot, { lengthFt: 30, breadthFt: 40 }, 5)).toBe(true);
    expect(isSimilarPlot(plot, { lengthFt: 31, breadthFt: 41 }, 5)).toBe(true);
    expect(isSimilarPlot(plot, { lengthFt: 30, breadthFt: 45 }, 5)).toBe(false);
  });

  it('does not mix orientations across dimensions', () => {
    // 40x40 matches the length in one orientation and the breadth in neither
    expect(isSimilarPlot(plot, { lengthFt: 40, breadthFt: 40 }, 5)).toBe(false);
  });

  it('honours the configured tolerance', () => {
    const near = { lengthFt: 44, breadthFt: 33 };
    expect(isSimilarPlot(plot, near, 5)).toBe(false);
    expect(isSimilarPlot(plot, near, 10)).toBe(true);
    expect(isSimilarPlot(plot, near, 0)).toBe(false);
    expect(isSimilarPlot(plot, plot, 0)).toBe(true);
  });
});

describe('dimensionBounds', () => {
  it('is symmetric around the value', () => {
    const [min, max] = dimensionBounds(100, 5);
    expect(min).toBeCloseTo(95, 6);
    expect(max).toBeCloseTo(105, 6);
  });
});

describe('hammingDistance threshold semantics', () => {
  it('counts differing bits', () => {
    expect(hammingDistance('0000000000000000', '0000000000000000')).toBe(0);
    expect(hammingDistance('0000000000000000', '00000000000000ff')).toBe(8);
    expect(hammingDistance('ffffffffffffffff', '0000000000000000')).toBe(64);
  });
});
