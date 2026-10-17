import { evaluateContribution } from './contribution.service';

describe('evaluateContribution', () => {
  it('always allows the first paid drawing', () => {
    const r = evaluateContribution(0, 0, 0, 1);
    expect(r.canPublishPaid).toBe(true);
    expect(r.freeNeeded).toBe(0);
  });

  it('requires one free drawing before the 2nd paid drawing (default ratio)', () => {
    const blocked = evaluateContribution(0, 1, 0, 1);
    expect(blocked.canPublishPaid).toBe(false);
    expect(blocked.freeNeeded).toBe(1);
    expect(blocked.guidance).toContain('1 more free drawing');
    expect(evaluateContribution(1, 1, 0, 1).canPublishPaid).toBe(true);
  });

  it('scales with the ratio and with the number of paid drawings', () => {
    expect(evaluateContribution(1, 1, 0, 2)).toMatchObject({
      canPublishPaid: false,
      freeNeeded: 1,
    });
    expect(evaluateContribution(2, 1, 0, 2).canPublishPaid).toBe(true);
    expect(evaluateContribution(1, 2, 0, 1)).toMatchObject({
      canPublishPaid: false,
      freeNeeded: 1,
    });
  });

  it('counts paid drawings that are still pending', () => {
    expect(evaluateContribution(0, 0, 1, 1).canPublishPaid).toBe(false);
  });

  it('is disabled with a ratio of 0', () => {
    expect(evaluateContribution(0, 10, 3, 0)).toMatchObject({
      canPublishPaid: true,
      freeNeeded: 0,
    });
  });
});
