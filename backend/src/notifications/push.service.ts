export const PUSH_SERVICE = Symbol('PUSH_SERVICE');

export interface PushTarget {
  token: string;
  platform: string;
}

export interface PushMessage {
  title: string;
  body: string;
  /** String-only map, as required by FCM. */
  data: Record<string, string>;
}

export interface PushResult {
  sent: number;
  /** Tokens the provider says are dead (uninstalled/expired); the caller deletes them. */
  invalidTokens: string[];
}

/** Delivery channel for push notifications. `FcmPushService` is real; `StubPushService` is the no-credentials default. */
export interface PushService {
  send(targets: PushTarget[], message: PushMessage): Promise<PushResult>;
}
