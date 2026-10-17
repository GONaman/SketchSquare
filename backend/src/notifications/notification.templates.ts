import type {
  NotificationPayloads,
  NotificationType,
} from './notification.types';

export interface RenderedNotification {
  title: string;
  body: string;
  /** Idempotency key: one notification per (user, key); repeats are dropped. */
  dedupeKey: string;
  /** Flat string map for the push `data` field (deep-linking in the app). */
  data: Record<string, string>;
}

export function formatRupees(paise: number): string {
  const rupees = Math.floor(paise / 100);
  const rem = paise % 100;
  const grouped = rupees.toLocaleString('en-IN');
  return `₹${grouped}${rem === 0 ? '' : `.${String(rem).padStart(2, '0')}`}`;
}

type Renderer<T extends NotificationType> = (
  p: NotificationPayloads[T],
) => Omit<RenderedNotification, 'data'> & { data?: Record<string, string> };

const RENDERERS: { [T in NotificationType]: Renderer<T> } = {
  VERIFICATION_RESULT: (p) => ({
    title:
      p.status === 'APPROVED'
        ? 'Welcome to SketchSquare'
        : 'Verification needs attention',
    body:
      p.status === 'APPROVED'
        ? 'Your architect verification was approved. You can now browse, buy and sell drawings.'
        : `Your verification was rejected${p.note ? `: ${p.note}` : '.'} You can resubmit your details.`,
    dedupeKey: `verification:${p.requestId}:${p.status}`,
    data: { status: p.status },
  }),
  SALE_MADE: (p) => ({
    title: 'You made a sale',
    body: `"${p.drawingTitle}" was purchased. ${formatRupees(p.amountPaise)} was added to your wallet.`,
    dedupeKey: `sale:${p.purchaseId}`,
    data: { drawingId: p.drawingId, purchaseId: p.purchaseId },
  }),
  WITHDRAWAL_STATUS: (p) => ({
    title: p.status === 'PAID' ? 'Withdrawal completed' : 'Withdrawal failed',
    body:
      p.status === 'PAID'
        ? `${formatRupees(p.amountPaise)} was sent to your bank account.`
        : `Your withdrawal of ${formatRupees(p.amountPaise)} failed${p.reason ? ` (${p.reason})` : ''}. The amount is back in your wallet.`,
    dedupeKey: `withdrawal:${p.withdrawalId}:${p.status}`,
    data: { withdrawalId: p.withdrawalId, status: p.status },
  }),
  NEW_REVIEW: (p) => ({
    title: 'New review',
    body: `${p.reviewerName} rated "${p.drawingTitle}" ${p.rating}/5.`,
    dedupeKey: `review:${p.reviewId}`,
    data: { drawingId: p.drawingId, reviewId: p.reviewId },
  }),
  INTEREST_RECEIVED: (p) => ({
    title: 'Someone is interested',
    body: `${p.userName} is interested in "${p.drawingTitle}".`,
    dedupeKey: `interest:${p.drawingId}:${p.userId}`,
    data: { drawingId: p.drawingId },
  }),
};

export function renderNotification<T extends NotificationType>(
  type: T,
  payload: NotificationPayloads[T],
): RenderedNotification {
  const { data, ...rest } = (RENDERERS[type] as Renderer<T>)(payload);
  return { ...rest, data: { type, ...data } };
}
