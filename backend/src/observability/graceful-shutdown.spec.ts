import type { INestApplication } from '@nestjs/common';
import { EventEmitter } from 'node:events';
import { installGracefulShutdown, ShutdownState } from './graceful-shutdown';

function fakeApp() {
  const order: string[] = [];
  const server = Object.assign(new EventEmitter(), {
    close: jest.fn((cb: () => void) => {
      order.push('server.close');
      setImmediate(cb);
    }),
    closeIdleConnections: jest.fn(),
    closeAllConnections: jest.fn(),
  });
  const state = new ShutdownState();
  const app = {
    get: () => state,
    getHttpServer: () => server,
    close: jest.fn(() => {
      order.push('app.close');
      return Promise.resolve();
    }),
  } as unknown as INestApplication;
  return { app, state, server, order };
}

describe('installGracefulShutdown', () => {
  it('flips health first, then stops the listener, then closes the app, then exits 0', async () => {
    const { app, state, order, server } = fakeApp();
    const exit = jest.fn();
    const run = installGracefulShutdown(app, {
      drainMs: 5,
      timeoutMs: 1000,
      exit,
      signals: [],
    });
    const p = run('SIGTERM');
    expect(state.active).toBe(true);
    expect(order).toEqual([]);
    await p;
    expect(server.closeIdleConnections).toHaveBeenCalled();
    expect(order).toEqual(['server.close', 'app.close']);
    expect(exit).toHaveBeenCalledWith(0);
  });

  it('a second signal exits immediately', async () => {
    const { app } = fakeApp();
    const exit = jest.fn();
    const run = installGracefulShutdown(app, {
      drainMs: 50,
      timeoutMs: 1000,
      exit,
      signals: [],
    });
    const first = run('SIGTERM');
    await run('SIGTERM');
    expect(exit).toHaveBeenCalledWith(1);
    await first;
  });

  it('forces the exit when shutdown exceeds the timeout', async () => {
    const { app, server } = fakeApp();
    (server.close as jest.Mock).mockImplementation(() => undefined);
    const exit = jest.fn();
    const run = installGracefulShutdown(app, {
      drainMs: 0,
      timeoutMs: 20,
      exit,
      signals: [],
    });
    void run('SIGTERM');
    await new Promise((r) => setTimeout(r, 60));
    expect(server.closeAllConnections).toHaveBeenCalled();
    expect(exit).toHaveBeenCalledWith(1);
  });
});
