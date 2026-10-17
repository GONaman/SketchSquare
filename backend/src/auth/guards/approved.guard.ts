import {
  CanActivate,
  ExecutionContext,
  HttpStatus,
  Injectable,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import type { Request } from 'express';
import {
  ALLOW_UNVERIFIED_KEY,
  IS_PUBLIC_KEY,
} from '../../common/decorators/access.decorators';
import { ApiException } from '../../common/errors/api-exception';
import { AuthUser } from '../../common/decorators/current-user.decorator';

/**
 * Global guard: only APPROVED architects (or ADMINs, who are not verified) may use a route
 * unless it is `@Public()` or `@AllowUnverified()`. Otherwise 403 VERIFICATION_REQUIRED.
 */
@Injectable()
export class ApprovedGuard implements CanActivate {
  constructor(private readonly reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const targets = [context.getHandler(), context.getClass()];
    if (
      this.reflector.getAllAndOverride<boolean>(IS_PUBLIC_KEY, targets) ||
      this.reflector.getAllAndOverride<boolean>(ALLOW_UNVERIFIED_KEY, targets)
    ) {
      return true;
    }
    const user = context.switchToHttp().getRequest<Request>().user as
      AuthUser | undefined;
    if (user?.role === 'ADMIN' || user?.verificationStatus === 'APPROVED') {
      return true;
    }
    throw new ApiException(
      HttpStatus.FORBIDDEN,
      'VERIFICATION_REQUIRED',
      'Your architect account is not verified yet',
      { verificationStatus: user?.verificationStatus },
    );
  }
}
