import { Role } from '@prisma/client';

export type { AuthUser } from '../common/decorators/current-user.decorator';

export interface AccessTokenPayload {
  sub: string;
  role: Role;
}

export interface Tokens {
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
}
