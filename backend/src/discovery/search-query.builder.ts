import { Prisma } from '@prisma/client';
import { HttpStatus } from '@nestjs/common';
import { ApiException } from '../common/errors/api-exception';
import { SizeQuery, sizeBounds } from './size-match';

export const SEARCH_SORTS = [
  'relevance',
  'price_asc',
  'price_desc',
  'drawing_rating',
  'architect_rating',
  'newest',
  'popularity',
  'size_match',
] as const;
export type SearchSort = (typeof SEARCH_SORTS)[number];

export const PRICE_TYPES = ['free', 'paid', 'all'] as const;
export type PriceType = (typeof PRICE_TYPES)[number];

export interface SearchParams {
  q?: string;
  categoryId?: string;
  size?: SizeQuery;
  cities?: string[];
  minDrawingRating?: number;
  minArchitectRating?: number;
  priceType?: PriceType;
  minPricePaise?: number;
  maxPricePaise?: number;
  floors?: number[];
  facing?: string[];
  architectId?: string;
  sort: SearchSort;
  limit: number;
  cursor?: { s: string; v: string[] } | null;
}

type KeyType = 'numeric' | 'float' | 'timestamp' | 'uuid' | 'int';

interface SortKey {
  expr: Prisma.Sql;
  type: KeyType;
  dir: 'asc' | 'desc';
}

const KEY_PATTERNS: Record<KeyType, RegExp> = {
  numeric: /^-?\d+(\.\d+)?$/,
  float: /^-?\d+(\.\d+)?(e[+-]?\d+)?$/i,
  int: /^-?\d+$/,
  timestamp: /^\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}:\d{2}(\.\d{1,6})?$/,
  uuid: /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i,
};

const col = (name: string) => Prisma.raw(`d."${name}"`);
const round6 = (e: Prisma.Sql) => Prisma.sql`round((${e})::numeric, 6)`;

export interface BuiltSearch {
  sql: Prisma.Sql;
  keyCount: number;
  hasSize: boolean;
}

/**
 * Builds the single SQL statement behind GET /drawings/search. Rows carry `id`, `k0..kN` (sort keys as text, the
 * stable keyset used for the cursor) and `size_score` when a size was requested. Every user value is a bound
 * parameter; only fixed identifiers are inlined.
 */
export function buildSearchQuery(p: SearchParams): BuiltSearch {
  const where: Prisma.Sql[] = [
    Prisma.sql`d."status" = 'PUBLISHED'`,
    Prisma.sql`u."verificationStatus" = 'APPROVED'`,
  ];

  const tsQuery = p.q
    ? Prisma.sql`plainto_tsquery('english', ${p.q})`
    : undefined;
  if (tsQuery) where.push(Prisma.sql`d."searchVector" @@ ${tsQuery}`);
  if (p.categoryId)
    where.push(Prisma.sql`d."categoryId" = ${p.categoryId}::uuid`);
  if (p.architectId)
    where.push(Prisma.sql`d."architectId" = ${p.architectId}::uuid`);
  if (p.cities?.length)
    where.push(
      Prisma.sql`lower(d."city") IN (${Prisma.join(p.cities.map((c) => c.toLowerCase()))})`,
    );
  if (p.minDrawingRating !== undefined)
    where.push(Prisma.sql`d."avgRating" >= ${p.minDrawingRating}`);
  if (p.minArchitectRating !== undefined)
    where.push(Prisma.sql`u."architectRating" >= ${p.minArchitectRating}`);
  if (p.priceType === 'free') where.push(Prisma.sql`d."pricePaise" = 0`);
  if (p.priceType === 'paid') where.push(Prisma.sql`d."pricePaise" > 0`);
  if (p.minPricePaise !== undefined)
    where.push(Prisma.sql`d."pricePaise" >= ${p.minPricePaise}`);
  if (p.maxPricePaise !== undefined)
    where.push(Prisma.sql`d."pricePaise" <= ${p.maxPricePaise}`);
  if (p.floors?.length)
    where.push(Prisma.sql`d."floors" IN (${Prisma.join(p.floors)})`);
  if (p.facing?.length)
    where.push(Prisma.sql`d."facing"::text IN (${Prisma.join(p.facing)})`);

  let sizeScore: Prisma.Sql | undefined;
  if (p.size) {
    const { lengthFt: L, breadthFt: B, tolerancePct } = p.size;
    const b = sizeBounds(p.size);
    where.push(Prisma.sql`(
      (d."plotLengthFt" BETWEEN ${b.lMin} AND ${b.lMax} AND d."plotBreadthFt" BETWEEN ${b.bMin} AND ${b.bMax})
      OR (d."plotLengthFt" BETWEEN ${b.bMin} AND ${b.bMax} AND d."plotBreadthFt" BETWEEN ${b.lMin} AND ${b.lMax})
    )`);
    if (tolerancePct === 0) {
      sizeScore = Prisma.sql`1::numeric`;
    } else {
      const t = tolerancePct / 100;
      sizeScore = round6(Prisma.sql`GREATEST(0, 1 - LEAST(
        GREATEST(abs(d."plotLengthFt" - ${L}::float8) / ${L}::float8, abs(d."plotBreadthFt" - ${B}::float8) / ${B}::float8),
        GREATEST(abs(d."plotLengthFt" - ${B}::float8) / ${B}::float8, abs(d."plotBreadthFt" - ${L}::float8) / ${L}::float8)
      ) / ${t}::float8)`);
    }
  }

  const keys = sortKeys(p, tsQuery, sizeScore);
  const cursor = readCursor(p, keys);
  if (cursor) where.push(keysetCondition(keys, cursor));

  const keyColumns = keys.map(
    (k, i) => Prisma.sql`(${k.expr})::text AS ${Prisma.raw(`k${i}`)}`,
  );
  const orderBy = keys.map(
    (k) => Prisma.sql`${k.expr} ${Prisma.raw(k.dir.toUpperCase())}`,
  );

  const sql = Prisma.sql`
    SELECT d."id"::text AS id, ${Prisma.join(keyColumns)}${
      sizeScore
        ? Prisma.sql`, (${sizeScore})::float8 AS size_score`
        : Prisma.empty
    }
    FROM "Drawing" d
    JOIN "User" u ON u."id" = d."architectId"
    WHERE ${Prisma.join(where, ' AND ')}
    ORDER BY ${Prisma.join(orderBy)}
    LIMIT ${p.limit + 1}`;

  return { sql, keyCount: keys.length, hasSize: !!sizeScore };
}

function sortKeys(
  p: SearchParams,
  tsQuery: Prisma.Sql | undefined,
  sizeScore: Prisma.Sql | undefined,
): SortKey[] {
  const newest: SortKey = {
    expr: col('createdAt'),
    type: 'timestamp',
    dir: 'desc',
  };
  const id: SortKey = { expr: col('id'), type: 'uuid', dir: 'asc' };
  const num = (e: Prisma.Sql, dir: 'asc' | 'desc'): SortKey => ({
    expr: e,
    type: 'numeric',
    dir,
  });
  // Plain float8 columns stay unwrapped so composite partial indexes can serve the ORDER BY.
  const flt = (e: Prisma.Sql, dir: 'asc' | 'desc'): SortKey => ({
    expr: e,
    type: 'float',
    dir,
  });
  const int = (name: string, dir: 'asc' | 'desc'): SortKey => ({
    expr: col(name),
    type: 'int',
    dir,
  });

  switch (p.sort) {
    case 'price_asc':
      return [int('pricePaise', 'asc'), newest, id];
    case 'price_desc':
      return [int('pricePaise', 'desc'), newest, id];
    case 'drawing_rating':
      return [
        flt(col('avgRating'), 'desc'),
        int('ratingCount', 'desc'),
        newest,
        id,
      ];
    case 'architect_rating':
      return [
        flt(Prisma.sql`u."architectRating"`, 'desc'),
        flt(col('avgRating'), 'desc'),
        newest,
        id,
      ];
    case 'popularity':
      return [
        int('purchaseCount', 'desc'),
        int('viewCount', 'desc'),
        newest,
        id,
      ];
    case 'size_match':
      if (!sizeScore)
        throw new ApiException(
          HttpStatus.BAD_REQUEST,
          'VALIDATION_ERROR',
          'sort=size_match requires length and breadth',
        );
      return [num(sizeScore, 'desc'), newest, id];
    case 'relevance': {
      const parts: Prisma.Sql[] = [];
      if (tsQuery)
        parts.push(Prisma.sql`ts_rank(d."searchVector", ${tsQuery}, 32)`);
      if (sizeScore) parts.push(Prisma.sql`(${sizeScore})`);
      // Without q or a size there is nothing to rank by, so relevance degrades to newest.
      if (parts.length === 0) return [newest, id];
      return [num(round6(Prisma.join(parts, ' + ')), 'desc'), newest, id];
    }
    case 'newest':
    default:
      return [newest, id];
  }
}

function readCursor(p: SearchParams, keys: SortKey[]): string[] | null {
  if (!p.cursor) return null;
  const bad = () =>
    new ApiException(
      HttpStatus.BAD_REQUEST,
      'VALIDATION_ERROR',
      'Invalid cursor',
    );
  const { s, v } = p.cursor;
  if (s !== p.sort || !Array.isArray(v) || v.length !== keys.length)
    throw bad();
  v.forEach((value, i) => {
    if (typeof value !== 'string' || !KEY_PATTERNS[keys[i].type].test(value))
      throw bad();
  });
  return v;
}

/** Lexicographic "after this row" predicate for mixed asc/desc keys: (k0 op c0) OR (k0 = c0 AND k1 op c1) OR ... */
function keysetCondition(keys: SortKey[], values: string[]): Prisma.Sql {
  const cast = (k: SortKey, v: string) =>
    k.type === 'numeric'
      ? Prisma.sql`${v}::numeric`
      : k.type === 'float'
        ? Prisma.sql`${v}::float8`
        : k.type === 'int'
          ? Prisma.sql`${v}::int`
          : k.type === 'timestamp'
            ? Prisma.sql`${v}::timestamp`
            : Prisma.sql`${v}::uuid`;

  const branches = keys.map((k, i) => {
    const eqs = keys
      .slice(0, i)
      .map((e, j) => Prisma.sql`${e.expr} = ${cast(e, values[j])}`);
    const op = Prisma.raw(k.dir === 'desc' ? '<' : '>');
    return Prisma.sql`(${Prisma.join(
      [...eqs, Prisma.sql`${k.expr} ${op} ${cast(k, values[i])}`],
      ' AND ',
    )})`;
  });
  // Redundant inclusive bound on the leading key: lets the planner start the index scan at the cursor.
  const lead = keys[0];
  const bound = Prisma.sql`${lead.expr} ${Prisma.raw(lead.dir === 'desc' ? '<=' : '>=')} ${cast(lead, values[0])}`;
  return Prisma.sql`(${bound} AND (${Prisma.join(branches, ' OR ')}))`;
}
