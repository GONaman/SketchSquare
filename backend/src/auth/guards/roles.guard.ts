import {
  CanActivate,
  ExecutionContext,
  HttpStatus,
  Injectable,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import type { Request } from 'express';
import {
  IS_PUBLIC_KEY,
  ROLES_KEY,
} from '../../common/decorators/access.decorators';
import { ApiException } from '../../common/errors/api-exception';
import { AuthUser } from '../../common/decorators/current-user.decorator';

/** Enforces `@Roles(...)`. Routes without the decorator are not role-restricted. */
@Injectable()
export class RolesGuard implements CanActivate {
  constructor(private readonly reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const targets = [context.getHandler(), context.getClass()];
    if (this.reflector.getAllAndOverride<boolean>(IS_PUBLIC_KEY, targets)) {
      return true;
    }
    const roles = this.reflector.getAllAndOverride<string[] | undefined>(
      ROLES_KEY,
      targets,
    );
    if (!roles || roles.length === 0) return true;
    const user = context.switchToHttp().getRequest<Request>().user as
      AuthUser | undefined;
    if (!user || !roles.includes(user.role)) {
      throw new ApiException(
        HttpStatus.FORBIDDEN,
        'FORBIDDEN',
        'You do not have permission to access this resource',
      );
    }
    return true;
  }
}
