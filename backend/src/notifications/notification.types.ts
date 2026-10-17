/** Events a user can be notified about. Stored as text so new types never need a migration. */
export type NotificationPayloads = {
  VERIFICATION_RESULT: {
    requestId: string;
    status: 'APPROVED' | 'REJECTED';
    note?: string | null;
  };
  SALE_MADE: {
    purchaseId: string;
    drawingId: string;
    drawingTitle: string;
    /** What the seller earns (after platform fee), in paise. */
    amountPaise: number;
  };
  WITHDRAWAL_STATUS: {
    withdrawalId: string;
    status: 'PAID' | 'FAILED';
    amountPaise: number;
    reason?: string | null;
  };
  NEW_REVIEW: {
    reviewId: string;
    drawingId: string;
    drawingTitle: string;
    rating: number;
    reviewerName: string;
  };
  INTEREST_RECEIVED: {
    drawingId: string;
    drawingTitle: string;
    userId: string;
    userName: string;
  };
};

export type NotificationType = keyof NotificationPayloads;

export const NOTIFICATION_TYPES: readonly NotificationType[] = [
  'VERIFICATION_RESULT',
  'SALE_MADE',
  'WITHDRAWAL_STATUS',
  'NEW_REVIEW',
  'INTEREST_RECEIVED',
];

export const PUSH_QUEUE = 'push';

export interface PushJob {
  notificationId: string;
}
