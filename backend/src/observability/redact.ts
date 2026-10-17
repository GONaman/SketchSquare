const SECRET_KEYS = [
  'password',
  'passwordHash',
  'currentPassword',
  'newPassword',
  'token',
  'accessToken',
  'refreshToken',
  'resetToken',
  'idToken',
  'secret',
  'clientSecret',
  'apiKey',
  'authorization',
  'cookie',
  'accountNumber',
  'ifsc',
  'signature',
];

/** pino `redact` paths: the secret keys at the top level and up to two levels deep, plus well-known header locations. */
export const REDACT_PATHS: string[] = [
  ...SECRET_KEYS.flatMap((k) => [k, `*.${k}`, `*.*.${k}`]),
  'req.headers.authorization',
  'req.headers.cookie',
  'req.headers["x-razorpay-signature"]',
  'res.headers["set-cookie"]',
];

const SENSITIVE_QUERY = /(token|secret|password|signature|key)/i;

/** Masks sensitive query-string values (e.g. `?token=…`) so URLs are safe to log. */
export function sanitizeUrl(url: string | undefined): string {
  if (!url) return '';
  const i = url.indexOf('?');
  if (i < 0) return url;
  const query = url
    .slice(i + 1)
    .split('&')
    .map((pair) => {
      const [k] = pair.split('=');
      return SENSITIVE_QUERY.test(k) ? `${k}=[Redacted]` : pair;
    })
    .join('&');
  return `${url.slice(0, i)}?${query}`;
}
