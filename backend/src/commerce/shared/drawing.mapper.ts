import { DrawingStatus, Facing, Prisma } from '@prisma/client';

export const drawingSummaryInclude = {
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
  sheets: {
    where: { isPreview: true, previewKey: { not: null } },
    orderBy: [{ createdAt: 'asc' }, { id: 'asc' }],
    take: 1,
    select: { previewKey: true },
  },
} satisfies Prisma.DrawingInclude;

export const drawingWithSheetsInclude = {
  ...drawingSummaryInclude,
  sheets: { orderBy: [{ createdAt: 'asc' }, { id: 'asc' }] },
} satisfies Prisma.DrawingInclude;

export type DrawingSummaryRow = Prisma.DrawingGetPayload<{
  include: typeof drawingSummaryInclude;
}>;
export type DrawingWithSheetsRow = Prisma.DrawingGetPayload<{
  include: typeof drawingWithSheetsInclude;
}>;

export interface ArchitectSummaryView {
  id: string;
  fullName: string;
  city: string;
  architectRating: number;
  ratingCount: number;
  avatarUrl: string | null;
}

export interface DrawingSummaryView {
  id: string;
  title: string;
  category: { id: string; name: string; slug: string };
  city: string;
  plotLengthFt: number;
  plotBreadthFt: number;
  plotAreaSqft: number;
  floors: number;
  facing: Facing | null;
  pricePaise: number;
  isFree: boolean;
  avgRating: number;
  ratingCount: number;
  previewUrl: string | null;
  architect: ArchitectSummaryView;
  status: DrawingStatus;
  createdAt: Date;
  sizeMatch: number | null;
}

export interface SheetView {
  id: string;
  type: string;
  isPreview: boolean;
  previewUrl: string | null;
  originalMime: string;
  fileName: string;
  sizeBytes: number;
}

export function previewUrl(
  previewsBaseUrl: string,
  key: string | null | undefined,
): string | null {
  return key ? `${previewsBaseUrl.replace(/\/$/, '')}/${key}` : null;
}

export function toDrawingSummary(
  d: DrawingSummaryRow,
  previewsBaseUrl: string,
): DrawingSummaryView {
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
    previewUrl: previewUrl(previewsBaseUrl, d.sheets[0]?.previewKey),
    architect: {
      id: d.architect.id,
      fullName: d.architect.fullName,
      city: d.architect.city,
      architectRating: d.architect.architectRating,
      ratingCount: d.architect.architectRatingCount,
      avatarUrl: d.architect.avatarUrl,
    },
    status: d.status,
    createdAt: d.createdAt,
    sizeMatch: null,
  };
}

/** Sheets as exposed to clients: never original keys; preview URL only for preview sheets. */
export function toSheetViews(
  sheets: DrawingWithSheetsRow['sheets'],
  previewsBaseUrl: string,
): SheetView[] {
  return sheets.map((s) => ({
    id: s.id,
    type: s.type,
    isPreview: s.isPreview,
    previewUrl: s.isPreview ? previewUrl(previewsBaseUrl, s.previewKey) : null,
    originalMime: s.originalMime,
    fileName: s.fileName,
    sizeBytes: s.sizeBytes,
  }));
}
