import { createHash, timingSafeEqual } from 'node:crypto';
import { isIP } from 'node:net';

const digest = (v: string) => createHash('sha256').update(v).digest();

export function tokenMatches(provided: string, expected: string): boolean {
  return timingSafeEqual(digest(provided), digest(expected));
}

export function bearerToken(header: string | undefined): string {
  const m = /^Bearer\s+(.+)$/i.exec(header ?? '');
  return m ? m[1].trim() : '';
}

/** Loopback, RFC1918 and unique-local IPv6 — i.e. not reachable from the public internet. */
export function isPrivateAddress(addr: string | undefined): boolean {
  if (!addr) return false;
  const ip = addr.startsWith('::ffff:') ? addr.slice(7) : addr;
  const kind = isIP(ip);
  if (kind === 4) {
    const [a, b] = ip.split('.').map(Number);
    return (
      a === 127 ||
      a === 10 ||
      (a === 172 && b >= 16 && b <= 31) ||
      (a === 192 && b === 168)
    );
  }
  if (kind === 6) {
    const lower = ip.toLowerCase();
    return lower === '::1' || lower.startsWith('fc') || lower.startsWith('fd');
  }
  return false;
}

/**
 * Without METRICS_TOKEN the endpoint is internal-only: the TCP peer must be a private address and the request must
 * not have been forwarded by a proxy (a public request through an in-VPC load balancer carries X-Forwarded-For).
 */
export function isInternalRequest(
  remoteAddress: string | undefined,
  forwardedFor: string | string[] | undefined,
): boolean {
  return !forwardedFor && isPrivateAddress(remoteAddress);
}
