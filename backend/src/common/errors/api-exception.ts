import { HttpException, HttpStatus } from '@nestjs/common';

export type ApiErrorCode =
  | 'VALIDATION_ERROR'
  | 'UNAUTHORIZED'
  | 'FORBIDDEN'
  | 'VERIFICATION_REQUIRED'
  | 'NOT_FOUND'
  | 'CONFLICT'
  | 'FREE_LIMIT_REACHED'
  | 'CONTRIBUTION_REQUIRED'
  | 'INSUFFICIENT_BALANCE'
  | 'BELOW_MIN_WITHDRAWAL'
  | 'WITHDRAWAL_BLOCKED'
  | 'UPLOAD_INVALID'
  | 'RATE_LIMITED'
  | 'INTERNAL';

/**
 * Throw this for any domain error that needs a specific contract code, e.g.
 * `throw new ApiException(HttpStatus.FORBIDDEN, 'FREE_LIMIT_REACHED', 'Free download limit reached')`.
 */
export class ApiException extends HttpException {
  constructor(
    status: HttpStatus,
    public readonly code: ApiErrorCode,
    message: string,
    public readonly details?: Record<string, unknown>,
  ) {
    super({ code, message, details }, status);
  }
}
