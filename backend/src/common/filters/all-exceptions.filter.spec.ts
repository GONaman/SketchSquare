import {
  ArgumentsHost,
  BadRequestException,
  HttpStatus,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { ApiException } from '../errors/api-exception';
import { AllExceptionsFilter } from './all-exceptions.filter';

function run(
  exception: unknown,
  headers: Record<string, string> = {},
  setHeader: jest.Mock = jest.fn(),
): { status: number; body: unknown } {
  const json = jest.fn<void, [unknown]>();
  const status = jest.fn<{ json: typeof json }, [number]>().mockReturnValue({
    json,
  });
  const host = {
    switchToHttp: () => ({
      getResponse: () => ({ status, setHeader, getHeader: () => undefined }),
      getRequest: () => ({ headers }),
    }),
  } as unknown as ArgumentsHost;
  new AllExceptionsFilter().catch(exception, host);
  return {
    status: status.mock.calls[0][0],
    body: json.mock.calls[0][0],
  };
}

describe('AllExceptionsFilter', () => {
  beforeAll(() => {
    jest.spyOn(Logger.prototype, 'error').mockImplementation();
  });

  it('sets X-Request-Id on error responses (echoing a safe client id, else generating one)', () => {
    const echoed = jest.fn();
    run(new NotFoundException(), { 'x-request-id': 'abc-123' }, echoed);
    expect(echoed).toHaveBeenCalledWith('X-Request-Id', 'abc-123');
    const generated = jest.fn();
    run(
      new NotFoundException(),
      { 'x-request-id': 'bad id with spaces' },
      generated,
    );
    expect((generated.mock.calls[0] as string[])[1]).toMatch(/^[0-9a-f-]{36}$/);
  });

  it('keeps ApiException code and details', () => {
    const { status, body } = run(
      new ApiException(HttpStatus.FORBIDDEN, 'FREE_LIMIT_REACHED', 'limit', {
        limit: 20,
      }),
    );
    expect(status).toBe(403);
    expect(body).toEqual({
      error: {
        code: 'FREE_LIMIT_REACHED',
        message: 'limit',
        details: { limit: 20 },
      },
    });
  });

  it('maps stock HttpExceptions by status', () => {
    expect(run(new NotFoundException('nope')).body).toEqual({
      error: { code: 'NOT_FOUND', message: 'nope' },
    });
    expect(run(new BadRequestException(['a must be x', 'b']))).toMatchObject({
      status: 400,
      body: { error: { code: 'VALIDATION_ERROR', message: 'a must be x' } },
    });
  });

  it('maps body-parser client errors (oversized / malformed body) instead of 500', () => {
    const tooLarge = Object.assign(new Error('request entity too large'), {
      status: 413,
      expose: true,
    });
    expect(run(tooLarge)).toEqual({
      status: 413,
      body: {
        error: { code: 'UPLOAD_INVALID', message: 'Request body is too large' },
      },
    });
    const malformed = Object.assign(new SyntaxError('Unexpected token'), {
      status: 400,
      expose: true,
    });
    expect(run(malformed)).toMatchObject({
      status: 400,
      body: { error: { code: 'VALIDATION_ERROR' } },
    });
  });

  it('maps Prisma unique violations to 409 CONFLICT', () => {
    const err = new Prisma.PrismaClientKnownRequestError('dup', {
      code: 'P2002',
      clientVersion: 'x',
    });
    expect(run(err)).toMatchObject({
      status: 409,
      body: { error: { code: 'CONFLICT' } },
    });
  });

  it('hides unknown errors behind INTERNAL', () => {
    const { status, body } = run(new Error('db password leaked'));
    expect(status).toBe(500);
    expect(body).toEqual({
      error: { code: 'INTERNAL', message: 'Internal server error' },
    });
  });
});
