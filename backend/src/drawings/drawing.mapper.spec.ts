import { Drawing, DrawingSheet, User } from '@prisma/client';
import {
  toDrawingSummary,
  toOwnerDrawingDetail,
  DrawingWithRelations,
} from './drawing.mapper';
import { toFeet } from './drawings.service';

const user = {
  id: 'u1',
  fullName: 'Asha',
  city: 'Pune',
  architectRating: 4.5,
  architectRatingCount: 7,
  avatarUrl: null,
  passwordHash: 'secret',
} as unknown as User;

const sheet = (over: Partial<DrawingSheet>): DrawingSheet =>
  ({
    id: 's',
    type: 'ARCHITECTURAL',
    isPreview: false,
    originalKey: 'drawings/d1/x/orig.pdf',
    originalMime: 'application/pdf',
    fileName: 'orig.pdf',
    sizeBytes: 10,
    previewKey: null,
    createdAt: new Date(1),
    ...over,
  }) as DrawingSheet;

const drawing = (sheets: DrawingSheet[]): DrawingWithRelations =>
  ({
    id: 'd1',
    title: 'T',
    description: 'D',
    city: 'Pune',
    plotLengthFt: 40,
    plotBreadthFt: 30,
    plotAreaSqft: 1200,
    floors: 2,
    facing: 'N',
    bedrooms: null,
    tags: [],
    pricePaise: 0,
    status: 'PUBLISHED',
    failureReason: null,
    avgRating: 0,
    ratingCount: 0,
    viewCount: 1,
    purchaseCount: 2,
    createdAt: new Date(0),
    category: { id: 'c', name: 'Res', slug: 'res', isActive: true },
    architect: user,
    sheets,
  }) as unknown as DrawingWithRelations & Drawing;

const url = (k: string | null | undefined) =>
  k ? `http://previews/${k}` : null;

describe('drawing mapper', () => {
  it('never leaks original keys or architect secrets and picks the first preview as cover', () => {
    const d = drawing([
      sheet({
        id: 'a',
        isPreview: true,
        previewKey: 'p/a.png',
        createdAt: new Date(5),
      }),
      sheet({
        id: 'b',
        isPreview: true,
        previewKey: 'p/b.png',
        createdAt: new Date(2),
      }),
      sheet({ id: 'c' }),
    ]);
    const detail = toOwnerDrawingDetail(d, url);
    const json = JSON.stringify(detail);
    expect(json).not.toContain('originalKey');
    expect(json).not.toContain('drawings/d1/x');
    expect(json).not.toContain('passwordHash');
    expect(detail.previewUrl).toBe('http://previews/p/b.png');
    expect(detail.isFree).toBe(true);
    expect(detail.sheets.map((s) => s.id)).toEqual(['c', 'b', 'a']);
    expect(detail.sheets.find((s) => s.id === 'c')?.previewUrl).toBeNull();
    expect(toDrawingSummary(d, url).architect.ratingCount).toBe(7);
  });

  it('has no previewUrl without processed preview sheets', () => {
    expect(
      toDrawingSummary(drawing([sheet({ isPreview: true })]), url).previewUrl,
    ).toBeNull();
  });
});

describe('toFeet', () => {
  it('passes feet through and converts metres to 2 decimals', () => {
    expect(toFeet(40, 'ft')).toBe(40);
    expect(toFeet(10, 'm')).toBe(32.81);
    expect(toFeet(0.5, 'm')).toBe(1.64);
  });
});
