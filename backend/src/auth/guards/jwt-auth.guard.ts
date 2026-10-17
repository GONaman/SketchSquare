import { ExecutionContext, HttpStatus, Injectable } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { AuthGuard } from '@nestjs/passport';
import { ApiException } from '../../common/errors/api-exception';
import { IS_PUBLIC_KEY } from '../../common/decorators/access.decorators';
import { AuthUser } from '../../common/decorators/current-user.decorator';

/** Global guard: every route needs a valid access token unless it is `@Public()`. */
@Injectable()
export class JwtAuthGuard extends AuthGuard('jwt') {
  constructor(private readonly reflector: Reflector) {
    super();
  }

  canActivate(context: ExecutionContext) {
    const isPublic = this.reflector.getAllAndOverride<boolean>(IS_PUBLIC_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);
    return isPublic ? true : super.canActivate(context);
  }

  handleRequest<T = AuthUser>(err: unknown, user: T | false): T {
    if (err || !user) {
      throw new ApiException(
        HttpStatus.UNAUTHORIZED,
        'UNAUTHORIZED',
        'Missing or invalid access token',
      );
    }
    return user;
  }
}
