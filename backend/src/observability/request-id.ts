import { randomUUID } from 'node:crypto';
import type { NextFunction, Request, Response } from 'express';

export const REQUEST_ID_HEADER = 'X-Request-Id';

// Client-supplied ids are echoed into logs and headers, so only a conservative charset/length is accepted.
const SAFE_ID = /^[A-Za-z0-9._-]{1,64}$/;

export function resolveRequestId(incoming: string | string[] | undefined) {
  const candidate = Array.isArray(incoming) ? incoming[0] : incoming;
  return candidate && SAFE_ID.test(candidate) ? candidate : randomUUID();
}

/** First middleware: every response (including body-parser/validation/5xx errors) carries `X-Request-Id`. */
export function requestIdMiddleware(
  req: Request,
  res: Response,
  next: NextFunction,
): void {
  const id = resolveRequestId(req.headers['x-request-id']);
  (req as Request & { id?: string }).id = id;
  res.setHeader(REQUEST_ID_HEADER, id);
  next();
}
