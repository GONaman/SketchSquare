import { formatRupees, renderNotification } from './notification.templates';

describe('formatRupees', () => {
  it.each([
    [0, '₹0'],
    [50, '₹0.50'],
    [100, '₹1'],
    [123456, '₹1,234.56'],
    [10000000, '₹1,00,000'],
  ])('formats %d paise as %s', (paise, expected) => {
    expect(formatRupees(paise)).toBe(expected);
  });
});

describe('renderNotification', () => {
  it('renders a verification result with a per-request, per-status key', () => {
    const approved = renderNotification('VERIFICATION_RESULT', {
      requestId: 'r1',
      status: 'APPROVED',
    });
    expect(approved.dedupeKey).toBe('verification:r1:APPROVED');
    expect(approved.data).toEqual({
      type: 'VERIFICATION_RESULT',
      status: 'APPROVED',
    });

    const rejected = renderNotification('VERIFICATION_RESULT', {
      requestId: 'r1',
      status: 'REJECTED',
      note: 'Blurry document',
    });
    expect(rejected.body).toContain('Blurry document');
    expect(rejected.dedupeKey).not.toBe(approved.dedupeKey);
  });

  it('renders a sale with the net amount and purchase key', () => {
    const n = renderNotification('SALE_MADE', {
      purchaseId: 'p1',
      drawingId: 'd1',
      drawingTitle: 'Villa',
      amountPaise: 90000,
    });
    expect(n.body).toContain('"Villa"');
    expect(n.body).toContain('₹900');
    expect(n.dedupeKey).toBe('sale:p1');
    expect(n.data).toMatchObject({ drawingId: 'd1', purchaseId: 'p1' });
  });

  it('renders paid and failed withdrawals', () => {
    const paid = renderNotification('WITHDRAWAL_STATUS', {
      withdrawalId: 'w1',
      status: 'PAID',
      amountPaise: 50000,
    });
    expect(paid.title).toBe('Withdrawal completed');
    const failed = renderNotification('WITHDRAWAL_STATUS', {
      withdrawalId: 'w1',
      status: 'FAILED',
      amountPaise: 50000,
      reason: 'Bank rejected',
    });
    expect(failed.body).toContain('Bank rejected');
    expect(failed.dedupeKey).toBe('withdrawal:w1:FAILED');
  });

  it('keys reviews by review id so edits do not re-notify', () => {
    const n = renderNotification('NEW_REVIEW', {
      reviewId: 'rv1',
      drawingId: 'd1',
      drawingTitle: 'Villa',
      rating: 4,
      reviewerName: 'Asha',
    });
    expect(n.body).toBe('Asha rated "Villa" 4/5.');
    expect(n.dedupeKey).toBe('review:rv1');
  });

  it('keys interest by drawing and user so toggling cannot spam', () => {
    const n = renderNotification('INTEREST_RECEIVED', {
      drawingId: 'd1',
      drawingTitle: 'Villa',
      userId: 'u1',
      userName: 'Asha',
    });
    expect(n.dedupeKey).toBe('interest:d1:u1');
  });
});
