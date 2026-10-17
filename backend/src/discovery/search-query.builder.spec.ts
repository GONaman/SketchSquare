import { ApiException } from '../common/errors/api-exception';
import {
  SearchParams,
  SearchSort,
  buildSearchQuery,
} from './search-query.builder';

const base = (over: Partial<SearchParams> = {}): SearchParams => ({
  sort: 'newest',
  limit: 20,
  ...over,
});
const size = { lengthFt: 30, breadthFt: 40, tolerancePct: 10 };
const ID = '11111111-1111-4111-8111-111111111111';

describe('buildSearchQuery', () => {
  it('always restricts to PUBLISHED drawings of APPROVED architects', () => {
    const { sql } = buildSearchQuery(base());
    expect(sql.sql).toContain(`d."status" = 'PUBLISHED'`);
    expect(sql.sql).toContain(`u."verificationStatus" = 'APPROVED'`);
  });

  it('fetches limit + 1 rows and binds user values as parameters', () => {
    const { sql } = buildSearchQuery(base({ q: "x'; DROP TABLE", limit: 7 }));
    expect(sql.values).toContain(8);
    expect(sql.values).toContain("x'; DROP TABLE");
    expect(sql.sql).not.toContain('DROP TABLE');
  });

  it('adds both orientations for size search and exposes size_score', () => {
    const built = buildSearchQuery(base({ size }));
    expect(built.hasSize).toBe(true);
    expect(built.sql.sql.match(/BETWEEN/g)).toHaveLength(4);
    expect(built.sql.sql).toContain('size_score');
  });

  it('omits size_score without a size query', () => {
    const built = buildSearchQuery(base());
    expect(built.hasSize).toBe(false);
    expect(built.sql.sql).not.toContain('size_score');
  });

  it('size_match sort requires a size', () => {
    expect(() => buildSearchQuery(base({ sort: 'size_match' }))).toThrow(
      ApiException,
    );
    expect(() =>
      buildSearchQuery(base({ sort: 'size_match', size })),
    ).not.toThrow();
  });

  it('relevance falls back to newest when there is no q or size', () => {
    expect(buildSearchQuery(base({ sort: 'relevance' })).keyCount).toBe(2);
    expect(
      buildSearchQuery(base({ sort: 'relevance', q: 'villa' })).keyCount,
    ).toBe(3);
  });

  it('applies each filter', () => {
    const { sql } = buildSearchQuery(
      base({
        categoryId: ID,
        cities: ['Jaipur', 'Delhi'],
        minDrawingRating: 4,
        minArchitectRating: 3,
        priceType: 'paid',
        minPricePaise: 100,
        maxPricePaise: 900,
        floors: [2, 3],
        bedrooms: [2, 3],
        tags: ['Vastu', 'Corner'],
        facing: ['N'],
        architectId: ID,
      }),
    );
    for (const frag of [
      '"categoryId"',
      'lower(d."city") IN',
      '"avgRating" >=',
      '"architectRating" >=',
      '"pricePaise" > 0',
      '"pricePaise" >=',
      '"pricePaise" <=',
      '"floors" IN',
      '"bedrooms" IN',
      'unnest(d."tags")',
      '"facing"::text IN',
      '"architectId"',
    ]) {
      expect(sql.sql).toContain(frag);
    }
    expect(sql.values).toEqual(
      expect.arrayContaining(['jaipur', 'delhi', 'vastu', 'corner']),
    );
  });

  it('priceType=free filters to price 0', () => {
    expect(buildSearchQuery(base({ priceType: 'free' })).sql.sql).toContain(
      '"pricePaise" = 0',
    );
  });

  describe('cursor', () => {
    it('adds a keyset predicate with one branch per key', () => {
      const withCursor = buildSearchQuery(
        base({
          sort: 'price_asc',
          cursor: { s: 'price_asc', v: ['500', '2026-01-01 00:00:00', ID] },
        }),
      );
      const without = buildSearchQuery(base({ sort: 'price_asc' }));
      expect(withCursor.sql.sql.match(/ OR /g)).toHaveLength(2);
      expect(without.sql.sql).not.toContain(' OR ');
    });

    it.each<[string, SearchParams['cursor']]>([
      ['a different sort', { s: 'newest', v: ['x'] }],
      ['the wrong number of values', { s: 'price_asc', v: ['1'] }],
      [
        'malformed values',
        { s: 'price_asc', v: ['abc', '2026-01-01 00:00:00', ID] },
      ],
      [
        'injection attempts',
        { s: 'price_asc', v: ['1; DROP', '2026-01-01 00:00:00', ID] },
      ],
    ])('rejects %s', (_name, cursor) => {
      expect(() =>
        buildSearchQuery(base({ sort: 'price_asc', cursor })),
      ).toThrow(ApiException);
    });
  });

  it.each<SearchSort>([
    'relevance',
    'price_asc',
    'price_desc',
    'drawing_rating',
    'architect_rating',
    'newest',
    'popularity',
  ])('every sort ends with the unique id tiebreaker (%s)', (sort) => {
    const { sql } = buildSearchQuery(base({ sort, q: 'a' }));
    expect(sql.sql).toMatch(/ORDER BY .*d\."id" ASC\s+LIMIT/s);
  });
});
