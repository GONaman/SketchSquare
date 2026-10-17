import * as Sentry from '@sentry/node';

export interface SentryOptions {
  dsn?: string;
  environment?: string;
  tracesSampleRate?: number;
}

/** Error reporting is opt-in: nothing is initialised (and `captureException` stays a no-op) without a DSN. */
export function initSentry(opts: SentryOptions): boolean {
  if (!opts.dsn) return false;
  Sentry.init({
    dsn: opts.dsn,
    environment: opts.environment,
    tracesSampleRate: opts.tracesSampleRate ?? 0,
    beforeSend(event) {
      if (event.request) {
        delete event.request.headers;
        delete event.request.cookies;
        delete event.request.data;
      }
      return event;
    },
  });
  return true;
}

export function reportException(exception: unknown, requestId?: string): void {
  Sentry.captureException(exception, {
    tags: requestId ? { requestId } : undefined,
  });
}
