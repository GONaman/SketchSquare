import { slugify } from './categories.service';

describe('slugify', () => {
  it('lowercases and hyphenates', () => {
    expect(slugify('Row House')).toBe('row-house');
    expect(slugify('  Vastu / Compliant!! ')).toBe('vastu-compliant');
  });

  it('never returns an empty slug', () => {
    expect(slugify('???')).toBe('category');
  });
});
