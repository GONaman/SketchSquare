import { Prisma } from '@prisma/client';

/** Prisma select shared by every endpoint that returns a contract `DrawingSummary`. */
export const DRAWING_SUMMARY_SELECT = {
  id: true,
  title: true,
  city: true,
  plotLengthFt: true,
  plotBreadthFt: true,
  plotAreaSqft: true,
  floors: true,
  facing: true,
  pricePaise: true,
  avgRating: true,
  ratingCount: true,
  status: true,
  createdAt: true,
  category: { select: { id: true, name: true, slug: true } },
  architect: {
    select: {
      id: true,
      fullName: true,
      city: true,
      architectRating: true,
      architectRatingCount: true,
      avatarUrl: true,
    },
  },
  // Only watermarked previews are ever exposed; the first preview sheet is the tile image.
  sheets: {
    where: { isPreview: true, previewKey: { not: null } },
    orderBy: [{ createdAt: 'asc' }, { id: 'asc' }],
    take: 1,
    select: { previewKey: true },
  },
} satisfies Prisma.DrawingSelect;

export type DrawingSummaryRow = Prisma.DrawingGetPayload<{
  select: typeof DRAWING_SUMMARY_SELECT;
}>;

export interface ArchitectSummary {
  id: string;
  fullName: string;
  city: string;
  architectRating: number;
  ratingCount: number;
  avatarUrl: string | null;
}

export interface DrawingSummary {
  id: string;
  title: string;
  category: { id: string; name: string; slug: string };
  city: string;
  plotLengthFt: number;
  plotBreadthFt: number;
  plotAreaSqft: number;
  floors: number;
  facing: string | null;
  pricePaise: number;
  isFree: boolean;
  avgRating: number;
  ratingCount: number;
  previewUrl: string | null;
  architect: ArchitectSummary;
  status: string;
  createdAt: Date;
  sizeMatch?: number;
}

export type PreviewUrlFn = (key: string) => string | null;

export function toArchitectSummary(
  a: DrawingSummaryRow['architect'],
): ArchitectSummary {
  return {
    id: a.id,
    fullName: a.fullName,
    city: a.city,
    architectRating: a.architectRating,
    ratingCount: a.architectRatingCount,
    avatarUrl: a.avatarUrl,
  };
}

export function toDrawingSummary(
  d: DrawingSummaryRow,
  previewUrl: PreviewUrlFn,
  sizeMatch?: number,
): DrawingSummary {
  const key = d.sheets[0]?.previewKey;
  return {
    id: d.id,
    title: d.title,
    category: d.category,
    city: d.city,
    plotLengthFt: d.plotLengthFt,
    plotBreadthFt: d.plotBreadthFt,
    plotAreaSqft: d.plotAreaSqft,
    floors: d.floors,
    facing: d.facing,
    pricePaise: d.pricePaise,
    isFree: d.pricePaise === 0,
    avgRating: d.avgRating,
    ratingCount: d.ratingCount,
    previewUrl: key ? previewUrl(key) : null,
    architect: toArchitectSummary(d.architect),
    status: d.status,
    createdAt: d.createdAt,
    ...(sizeMatch === undefined
      ? {}
      : { sizeMatch: Math.round(sizeMatch * 10000) / 10000 }),
  };
}
