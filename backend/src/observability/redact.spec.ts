import pino from 'pino';
import { REDACT_PATHS, sanitizeUrl } from './redact';
import { resolveRequestId } from './request-id';

function logged(obj: Record<string, unknown>): Record<string, unknown> {
  const lines: string[] = [];
  const logger = pino(
    { redact: { paths: REDACT_PATHS, censor: '[Redacted]' } },
    { write: (l: string) => void lines.push(l) },
  );
  logger.info(obj, 'event');
  return JSON.parse(lines[0]) as Record<string, unknown>;
}

describe('log redaction', () => {
  it('masks secrets at the top level and nested', () => {
    const out = logged({
      password: 'hunter2',
      user: { email: 'a@b.c', passwordHash: 'hash', refreshToken: 'rt' },
      body: { dto: { newPassword: 'np' } },
      req: {
        headers: {
          authorization: 'Bearer abc.def.ghi',
          cookie: 'sid=1',
          accept: 'application/json',
        },
      },
      accountNumber: '1234567890',
    });
    const text = JSON.stringify(out);
    for (const secret of [
      'hunter2',
      'hash',
      'rt',
      'np',
      'abc.def.ghi',
      'sid=1',
      '1234567890',
    ]) {
      expect(text).not.toContain(secret);
    }
    expect(out).toMatchObject({
      password: '[Redacted]',
      user: { email: 'a@b.c', refreshToken: '[Redacted]' },
      req: { headers: { accept: 'application/json' } },
    });
  });
});

describe('sanitizeUrl', () => {
  it('masks sensitive query values only', () => {
    expect(sanitizeUrl('/auth/reset?token=abc&next=/home')).toBe(
      '/auth/reset?token=[Redacted]&next=/home',
    );
    expect(sanitizeUrl('/drawings?city=Pune')).toBe('/drawings?city=Pune');
    expect(sanitizeUrl(undefined)).toBe('');
  });
});

describe('resolveRequestId', () => {
  it('echoes safe ids and replaces unsafe or missing ones', () => {
    expect(resolveRequestId('req-1.a_b')).toBe('req-1.a_b');
    expect(resolveRequestId(['first', 'second'])).toBe('first');
    for (const bad of [
      '',
      'has space',
      'x'.repeat(65),
      '<script>',
      undefined,
    ]) {
      expect(resolveRequestId(bad)).toMatch(/^[0-9a-f-]{36}$/);
    }
  });
});
