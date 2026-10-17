import { HttpStatus, ValidationError, ValidationPipe } from '@nestjs/common';
import { ApiException } from '../errors/api-exception';

function flatten(
  errors: ValidationError[],
  parent = '',
  out: Record<string, string[]> = {},
): Record<string, string[]> {
  for (const e of errors) {
    const path = parent ? `${parent}.${e.property}` : e.property;
    if (e.constraints) out[path] = Object.values(e.constraints);
    if (e.children?.length) flatten(e.children, path, out);
  }
  return out;
}

export function createValidationPipe(): ValidationPipe {
  return new ValidationPipe({
    whitelist: true,
    forbidNonWhitelisted: true,
    transform: true,
    transformOptions: { enableImplicitConversion: false },
    exceptionFactory: (errors) => {
      const fields = flatten(errors);
      const first = Object.entries(fields)[0];
      const message = first
        ? `${first[0]}: ${first[1][0]}`
        : 'Validation failed';
      return new ApiException(
        HttpStatus.BAD_REQUEST,
        'VALIDATION_ERROR',
        message,
        { fields },
      );
    },
  });
}
