import { ConfigService } from '@nestjs/config';
import type { IncomingMessage, ServerResponse } from 'node:http';
import type { Params } from 'nestjs-pino';
import { stdTimeFunctions } from 'pino';
import { Env } from '../config/env.schema';
import { REDACT_PATHS, sanitizeUrl } from './redact';

type Req = IncomingMessage & { id?: string; user?: { id?: string } };

const QUIET_PATHS = ['/health', '/metrics'];

/** Structured JSON logs on stdout with request ids and secret redaction (pino-http under nestjs-pino). */
export function buildLoggerParams(config: ConfigService<Env, true>): Params {
  return {
    pinoHttp: {
      level: config.get('LOG_LEVEL', { infer: true }),
      base: { service: 'sketchsquare-api' },
      timestamp: stdTimeFunctions.isoTime,
      formatters: { level: (label: string) => ({ level: label }) },
      redact: { paths: REDACT_PATHS, censor: '[Redacted]' },
      // The id is set by requestIdMiddleware (so it also covers errors raised before this middleware runs).
      genReqId: (req: IncomingMessage) => (req as Req).id ?? '-',
      serializers: {
        req: (req: Req) => ({
          id: req.id,
          method: req.method,
          url: sanitizeUrl(req.url),
        }),
        res: (res: ServerResponse) => ({ statusCode: res.statusCode }),
      },
      customProps: (req: IncomingMessage) => ({
        userId: (req as Req).user?.id,
      }),
      customLogLevel: (_req: IncomingMessage, res: ServerResponse, err) => {
        if (err || res.statusCode >= 500) return 'error';
        return res.statusCode >= 400 ? 'warn' : 'info';
      },
      autoLogging: {
        ignore: (req: IncomingMessage) =>
          QUIET_PATHS.some((p) => req.url?.startsWith(p)),
      },
    },
  };
}
