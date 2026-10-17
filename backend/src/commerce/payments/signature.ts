import { createHmac, timingSafeEqual } from 'node:crypto';

export function hmacSha256Hex(
  secret: string,
  payload: Buffer | string,
): string {
  return createHmac('sha256', secret).update(payload).digest('hex');
}

/** Constant-time comparison of two hex signatures (false for anything malformed or of a different length). */
export function safeEqualHex(a: string, b: string | undefined): boolean {
  if (!b) return false;
  const ab = Buffer.from(a, 'utf8');
  const bb = Buffer.from(b, 'utf8');
  return ab.length === bb.length && timingSafeEqual(ab, bb);
}
