import { Injectable, Logger } from '@nestjs/common';
import type { INestApplication } from '@nestjs/common';

/** Flipped as soon as a shutdown signal arrives so `/health` reports 503 and load balancers stop routing here. */
@Injectable()
export class ShutdownState {
  private shuttingDown = false;

  get active(): boolean {
    return this.shuttingDown;
  }

  begin(): void {
    this.shuttingDown = true;
  }
}

export interface GracefulShutdownOptions {
  /** Time between flipping /health to 503 and closing the listener, so the load balancer notices. */
  drainMs: number;
  /** Hard cap for the whole shutdown; afterwards connections are cut and the process exits 1. */
  timeoutMs: number;
  exit?: (code: number) => void;
  signals?: NodeJS.Signals[];
}

const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));

/**
 * SIGTERM/SIGINT handling in a deliberate order (Nest's own hooks would disconnect Prisma before the HTTP server has
 * finished in-flight requests): 503 on /health → drain → stop accepting and wait for in-flight requests →
 * `app.close()` (BullMQ workers, Redis, Prisma) → exit. A second signal or the timeout forces the exit.
 */
export function installGracefulShutdown(
  app: INestApplication,
  opts: GracefulShutdownOptions,
): (signal: string) => Promise<void> {
  const logger = new Logger('Shutdown');
  const exit = opts.exit ?? ((code: number) => process.exit(code));
  const state = app.get(ShutdownState);
  let started = false;

  const run = async (signal: string): Promise<void> => {
    if (started) {
      logger.warn(`Second ${signal}, exiting immediately`);
      exit(1);
      return;
    }
    started = true;
    logger.log(`${signal} received, draining (${opts.drainMs} ms)`);
    state.begin();

    const server = app.getHttpServer() as import('node:http').Server;
    const timer = setTimeout(() => {
      logger.error(`Shutdown exceeded ${opts.timeoutMs} ms, forcing exit`);
      server.closeAllConnections?.();
      exit(1);
    }, opts.timeoutMs);
    timer.unref();

    try {
      await sleep(opts.drainMs);
      const closed = new Promise<void>((resolve) => {
        server.close(() => resolve());
      });
      server.closeIdleConnections?.();
      await closed;
      await app.close();
      clearTimeout(timer);
      logger.log('Shutdown complete');
      exit(0);
    } catch (err) {
      logger.error(`Shutdown failed: ${String(err)}`);
      exit(1);
    }
  };

  for (const s of opts.signals ?? ['SIGTERM', 'SIGINT']) {
    process.on(s, () => void run(s));
  }
  return run;
}
