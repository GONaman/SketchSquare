import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import { Prisma } from '@prisma/client';
import type { Response } from 'express';
import { ApiErrorCode, ApiException } from '../errors/api-exception';

interface ErrorBody {
  error: { code: ApiErrorCode; message: string; details?: unknown };
}

const CODE_BY_STATUS: Record<number, ApiErrorCode> = {
  400: 'VALIDATION_ERROR',
  401: 'UNAUTHORIZED',
  403: 'FORBIDDEN',
  404: 'NOT_FOUND',
  409: 'CONFLICT',
  413: 'UPLOAD_INVALID',
  422: 'VALIDATION_ERROR',
  429: 'RATE_LIMITED',
};

@Catch()
export class AllExceptionsFilter implements ExceptionFilter {
  private readonly logger = new Logger(AllExceptionsFilter.name);

  catch(exception: unknown, host: ArgumentsHost): void {
    const res = host.switchToHttp().getResponse<Response>();
    const { status, body } = this.toResponse(exception);
    if (status >= 500) {
      this.logger.error(
        exception instanceof Error
          ? (exception.stack ?? exception.message)
          : String(exception),
      );
    }
    res.status(status).json(body);
  }

  private toResponse(exception: unknown): { status: number; body: ErrorBody } {
    if (exception instanceof ApiException) {
      return {
        status: exception.getStatus(),
        body: {
          error: {
            code: exception.code,
            message: exception.message,
            ...(exception.details && { details: exception.details }),
          },
        },
      };
    }

    if (exception instanceof HttpException) {
      const status = exception.getStatus();
      const raw = exception.getResponse();
      const message =
        typeof raw === 'string'
          ? raw
          : Array.isArray((raw as { message?: unknown }).message)
            ? ((raw as { message: string[] }).message[0] ?? exception.message)
            : ((raw as { message?: string }).message ?? exception.message);
      const code =
        CODE_BY_STATUS[status] ??
        (status >= 500 ? 'INTERNAL' : 'VALIDATION_ERROR');
      return { status, body: { error: { code, message } } };
    }

    if (exception instanceof Prisma.PrismaClientKnownRequestError) {
      if (exception.code === 'P2002') {
        return this.simple(
          HttpStatus.CONFLICT,
          'CONFLICT',
          'Resource already exists',
        );
      }
      if (exception.code === 'P2025') {
        return this.simple(
          HttpStatus.NOT_FOUND,
          'NOT_FOUND',
          'Resource not found',
        );
      }
    }

    return this.simple(
      HttpStatus.INTERNAL_SERVER_ERROR,
      'INTERNAL',
      'Internal server error',
    );
  }

  private simple(status: number, code: ApiErrorCode, message: string) {
    return { status, body: { error: { code, message } } };
  }
}
