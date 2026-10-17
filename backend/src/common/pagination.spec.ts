import { decodeCursor, encodeCursor, toPage } from './pagination';

describe('pagination helpers', () => {
  it('round-trips cursors', () => {
    const c = encodeCursor({ id: 'abc', n: 3 });
    expect(decodeCursor(c)).toEqual({ id: 'abc', n: 3 });
    expect(decodeCursor(undefined)).toBeNull();
  });

  it('rejects garbage cursors with VALIDATION_ERROR', () => {
    expect(() => decodeCursor('%%%not-json')).toThrow('Invalid cursor');
  });

  it('returns nextCursor only when an extra row was fetched', () => {
    const rows = [{ id: 1 }, { id: 2 }, { id: 3 }];
    const page = toPage(rows, 2, (r) => ({ id: r.id }));
    expect(page.items).toHaveLength(2);
    expect(decodeCursor(page.nextCursor!)).toEqual({ id: 2 });
    expect(
      toPage(rows.slice(0, 2), 2, (r) => ({ id: r.id })).nextCursor,
    ).toBeNull();
  });
});
