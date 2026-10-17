import { matchesSize, sizeBounds, sizeMatchScore, toFeet } from './size-match';

const q = (lengthFt: number, breadthFt: number, tolerancePct = 10) => ({
  lengthFt,
  breadthFt,
  tolerancePct,
});

describe('toFeet', () => {
  it('keeps feet unchanged', () => expect(toFeet(30, 'ft')).toBe(30));
  it('converts metres without float noise', () => {
    expect(toFeet(9.144, 'm')).toBe(30);
    expect(toFeet(12.192, 'm')).toBe(40);
    expect(toFeet(10, 'm')).toBeCloseTo(32.8084, 4);
  });
});

describe('matchesSize', () => {
  it('matches the exact plot', () =>
    expect(matchesSize(q(30, 40), 30, 40)).toBe(true));

  it('matches the rotated plot (40x30 when asking 30x40)', () => {
    expect(matchesSize(q(30, 40), 40, 30)).toBe(true);
  });

  it('is inclusive at both tolerance edges for each dimension', () => {
    expect(matchesSize(q(30, 40), 27, 36)).toBe(true);
    expect(matchesSize(q(30, 40), 33, 44)).toBe(true);
    expect(matchesSize(q(30, 40), 36, 27)).toBe(true);
    expect(matchesSize(q(30, 40), 44, 33)).toBe(true);
  });

  it('rejects plots just outside tolerance on either dimension', () => {
    expect(matchesSize(q(30, 40), 26.9, 40)).toBe(false);
    expect(matchesSize(q(30, 40), 30, 44.1)).toBe(false);
    expect(matchesSize(q(30, 40), 33.1, 40)).toBe(false);
  });

  it('requires BOTH dimensions to be within tolerance', () => {
    expect(matchesSize(q(30, 40), 30, 60)).toBe(false);
    expect(matchesSize(q(30, 40), 60, 40)).toBe(false);
  });

  it('does not mix orientations (length from one, breadth from the other)', () => {
    // 30 matches length, 30 would need to match breadth 40±10%: it does not.
    expect(matchesSize(q(30, 40), 30, 30)).toBe(false);
  });

  it('with zero tolerance only exact (either orientation) matches', () => {
    expect(matchesSize(q(30, 40, 0), 30, 40)).toBe(true);
    expect(matchesSize(q(30, 40, 0), 40, 30)).toBe(true);
    expect(matchesSize(q(30, 40, 0), 30.01, 40)).toBe(false);
  });

  it('handles a square plot', () => {
    expect(matchesSize(q(30, 30), 31, 29)).toBe(true);
    expect(matchesSize(q(30, 30), 34, 30)).toBe(false);
  });

  it('matches a metre query against the equivalent feet drawing', () => {
    const ft = {
      lengthFt: toFeet(9.144, 'm'),
      breadthFt: toFeet(12.192, 'm'),
      tolerancePct: 0,
    };
    expect(matchesSize(ft, 30, 40)).toBe(true);
  });
});

describe('sizeBounds', () => {
  it('is symmetric around the requested size', () => {
    const b = sizeBounds(q(30, 40, 10));
    expect(b.lMin).toBeCloseTo(27, 5);
    expect(b.lMax).toBeCloseTo(33, 5);
    expect(b.bMin).toBeCloseTo(36, 5);
    expect(b.bMax).toBeCloseTo(44, 5);
  });
});

describe('sizeMatchScore', () => {
  it('is 1 for exact and for exact rotated', () => {
    expect(sizeMatchScore(q(30, 40), 30, 40)).toBe(1);
    expect(sizeMatchScore(q(30, 40), 40, 30)).toBe(1);
  });

  it('is null when not matching', () => {
    expect(sizeMatchScore(q(30, 40), 60, 80)).toBeNull();
  });

  it('is 0 exactly on the tolerance edge and between 0 and 1 inside', () => {
    expect(sizeMatchScore(q(30, 40), 33, 40)).toBeCloseTo(0, 6);
    const mid = sizeMatchScore(q(30, 40), 31.5, 40);
    expect(mid).toBeCloseTo(0.5, 6);
  });

  it('ranks closer plots higher, using the worst dimension', () => {
    const near = sizeMatchScore(q(30, 40), 30, 41) as number;
    const far = sizeMatchScore(q(30, 40), 31, 42) as number;
    expect(near).toBeGreaterThan(far);
  });

  it('uses the better orientation', () => {
    const s = sizeMatchScore(q(30, 40), 40.4, 30.3) as number;
    expect(s).toBeCloseTo(1 - 0.01 / 0.1, 6);
  });

  it('is 1 for any match when tolerance is 0', () => {
    expect(sizeMatchScore(q(30, 40, 0), 40, 30)).toBe(1);
  });
});
