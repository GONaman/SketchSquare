import { ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsInt, IsOptional, IsString, Max, Min } from 'class-validator';
import { HttpStatus } from '@nestjs/common';
import { ApiException } from './errors/api-exception';

export const DEFAULT_PAGE_LIMIT = 20;
export const MAX_PAGE_LIMIT = 50;

/** Extend (or use directly) for any paginated endpoint: `?cursor=<opaque>&limit=20`. */
export class PageQueryDto {
  @ApiPropertyOptional({ description: 'Opaque cursor from a previous page' })
  @IsOptional()
  @IsString()
  cursor?: string;

  @ApiPropertyOptional({
    minimum: 1,
    maximum: MAX_PAGE_LIMIT,
    default: DEFAULT_PAGE_LIMIT,
  })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(MAX_PAGE_LIMIT)
  limit: number = DEFAULT_PAGE_LIMIT;
}

export interface Page<T> {
  items: T[];
  nextCursor: string | null;
}

export function encodeCursor(payload: Record<string, unknown>): string {
  return Buffer.from(JSON.stringify(payload)).toString('base64url');
}

export function decodeCursor<T extends Record<string, unknown>>(
  cursor: string | undefined,
): T | null {
  if (!cursor) return null;
  try {
    return JSON.parse(Buffer.from(cursor, 'base64url').toString('utf8')) as T;
  } catch {
    throw new ApiException(
      HttpStatus.BAD_REQUEST,
      'VALIDATION_ERROR',
      'Invalid cursor',
    );
  }
}

/**
 * Build a page from `limit + 1` fetched rows: the extra row only signals that another page exists.
 * `cursorOf` derives the cursor payload from the last returned item.
 */
export function toPage<T>(
  rows: T[],
  limit: number,
  cursorOf: (last: T) => Record<string, unknown>,
): Page<T> {
  const hasMore = rows.length > limit;
  const items = hasMore ? rows.slice(0, limit) : rows;
  return {
    items,
    nextCursor: hasMore
      ? encodeCursor(cursorOf(items[items.length - 1]))
      : null,
  };
}
