import { ExecutionContext } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import {
  ALLOW_UNVERIFIED_KEY,
  IS_PUBLIC_KEY,
  ROLES_KEY,
} from '../../common/decorators/access.decorators';
import { ApprovedGuard } from './approved.guard';
import { RolesGuard } from './roles.guard';

function ctx(
  user: unknown,
  meta: Record<string, unknown>,
): { context: ExecutionContext; reflector: Reflector } {
  const reflector = {
    getAllAndOverride: (key: string) => meta[key],
  } as unknown as Reflector;
  const context = {
    getHandler: () => undefined,
    getClass: () => undefined,
    switchToHttp: () => ({ getRequest: () => ({ user }) }),
  } as unknown as ExecutionContext;
  return { context, reflector };
}

describe('ApprovedGuard', () => {
  const run = (user: unknown, meta: Record<string, unknown> = {}) => {
    const { context, reflector } = ctx(user, meta);
    return new ApprovedGuard(reflector).canActivate(context);
  };

  it('allows APPROVED users and admins', () => {
    expect(run({ role: 'ARCHITECT', verificationStatus: 'APPROVED' })).toBe(
      true,
    );
    expect(run({ role: 'ADMIN', verificationStatus: 'PENDING' })).toBe(true);
  });

  it('blocks PENDING / REJECTED with VERIFICATION_REQUIRED', () => {
    for (const verificationStatus of ['PENDING', 'REJECTED']) {
      expect(() => run({ role: 'ARCHITECT', verificationStatus })).toThrow(
        expect.objectContaining({ code: 'VERIFICATION_REQUIRED' }) as Error,
      );
    }
  });

  it('skips @Public and @AllowUnverified routes', () => {
    const pending = { role: 'ARCHITECT', verificationStatus: 'PENDING' };
    expect(run(undefined, { [IS_PUBLIC_KEY]: true })).toBe(true);
    expect(run(pending, { [ALLOW_UNVERIFIED_KEY]: true })).toBe(true);
  });
});

describe('RolesGuard', () => {
  const run = (user: unknown, meta: Record<string, unknown>) => {
    const { context, reflector } = ctx(user, meta);
    return new RolesGuard(reflector).canActivate(context);
  };

  it('ignores routes without @Roles', () => {
    expect(run({ role: 'ARCHITECT' }, {})).toBe(true);
  });

  it('allows a matching role and rejects others with FORBIDDEN', () => {
    expect(run({ role: 'ADMIN' }, { [ROLES_KEY]: ['ADMIN'] })).toBe(true);
    expect(() =>
      run({ role: 'ARCHITECT' }, { [ROLES_KEY]: ['ADMIN'] }),
    ).toThrow(expect.objectContaining({ code: 'FORBIDDEN' }) as Error);
  });
});
