import { SetMetadata } from '@nestjs/common';

export const IS_PUBLIC_KEY = 'isPublic';
export const ALLOW_UNVERIFIED_KEY = 'allowUnverified';
export const ROLES_KEY = 'roles';

/** No token needed (contract `[public]`). */
export const Public = () => SetMetadata(IS_PUBLIC_KEY, true);

/** Valid token required but verificationStatus may be anything (contract `[auth]`). */
export const AllowUnverified = () => SetMetadata(ALLOW_UNVERIFIED_KEY, true);

/** Restrict to roles, e.g. `@Roles('ADMIN')` (contract `[admin]`). */
export const Roles = (...roles: string[]) => SetMetadata(ROLES_KEY, roles);
