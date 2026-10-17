import * as Sentry from '@sentry/node';
import { initSentry, reportException } from './sentry';

jest.mock('@sentry/node', () => ({
  init: jest.fn(),
  captureException: jest.fn(),
}));

describe('sentry', () => {
  beforeEach(() => jest.clearAllMocks());

  it('stays inactive without a DSN', () => {
    expect(initSentry({})).toBe(false);
    expect(Sentry.init).not.toHaveBeenCalled();
  });

  it('initialises with a DSN and strips request data before sending', () => {
    expect(
      initSentry({ dsn: 'https://k@sentry.example/1', environment: 'prod' }),
    ).toBe(true);
    const options = (
      (Sentry.init as jest.Mock).mock.calls as unknown[][]
    )[0][0] as {
      environment: string;
      tracesSampleRate: number;
      beforeSend: (e: unknown) => {
        request: Record<string, unknown>;
      };
    };
    expect(options.environment).toBe('prod');
    expect(options.tracesSampleRate).toBe(0);
    const event = options.beforeSend({
      request: {
        headers: { authorization: 'x' },
        cookies: {},
        data: 'p',
        url: '/a',
      },
    });
    expect(event.request).toEqual({ url: '/a' });
  });

  it('tags exceptions with the request id', () => {
    const err = new Error('boom');
    reportException(err, 'req-1');
    expect(Sentry.captureException).toHaveBeenCalledWith(err, {
      tags: { requestId: 'req-1' },
    });
  });
});
