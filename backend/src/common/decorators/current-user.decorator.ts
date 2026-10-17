import { createParamDecorator, ExecutionContext } from '@nestjs/common';
import { Role, VerificationStatus } from '@prisma/client';
import type { Request } from 'express';

/** What `@CurrentUser()` returns; loaded fresh from the DB on every authenticated request. */
export interface AuthUser {
  id: string;
  email: string;
  fullName: string;
  role: Role;
  verificationStatus: VerificationStatus;
}

/**
 * Injects the authenticated user. `@CurrentUser() user: AuthUser` or `@CurrentUser('id') userId: string`.
 * Undefined on `@Public()` routes.
 */
export const CurrentUser = createParamDecorator(
  (field: keyof AuthUser | undefined, ctx: ExecutionContext) => {
    const user = ctx.switchToHttp().getRequest<Request>().user as
      AuthUser | undefined;
    return field ? user?.[field] : user;
  },
);
