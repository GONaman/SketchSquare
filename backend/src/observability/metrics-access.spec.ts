import {
  bearerToken,
  isInternalRequest,
  isPrivateAddress,
  tokenMatches,
} from './metrics-access';

describe('metrics access', () => {
  it('treats loopback and private ranges as internal', () => {
    for (const ip of [
      '127.0.0.1',
      '::1',
      '::ffff:127.0.0.1',
      '10.1.2.3',
      '172.16.0.9',
      '172.31.255.1',
      '192.168.1.5',
      'fd12::1',
    ]) {
      expect(isPrivateAddress(ip)).toBe(true);
    }
  });

  it('treats public and malformed addresses as external', () => {
    for (const ip of [
      '8.8.8.8',
      '172.32.0.1',
      '192.169.0.1',
      '2001:db8::1',
      'not-an-ip',
      '',
      undefined,
    ]) {
      expect(isPrivateAddress(ip)).toBe(false);
    }
  });

  it('refuses forwarded requests even from a private peer', () => {
    expect(isInternalRequest('10.0.0.5', undefined)).toBe(true);
    expect(isInternalRequest('10.0.0.5', '203.0.113.9')).toBe(false);
  });

  it('parses bearer tokens and compares in constant time', () => {
    expect(bearerToken('Bearer abc')).toBe('abc');
    expect(bearerToken('bearer  abc ')).toBe('abc');
    expect(bearerToken('Basic abc')).toBe('');
    expect(bearerToken(undefined)).toBe('');
    expect(tokenMatches('abc', 'abc')).toBe(true);
    expect(tokenMatches('abd', 'abc')).toBe(false);
    expect(tokenMatches('', 'abc')).toBe(false);
  });
});
