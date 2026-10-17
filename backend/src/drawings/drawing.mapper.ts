import { Category, Drawing, DrawingSheet, User } from '@prisma/client';

export type DrawingWithRelations = Drawing & {
  category: Category;
  architect: User;
  sheets: DrawingSheet[];
};

type PreviewUrl = (key: string | null | undefined) => string | null;

export function toSheetResponse(sheet: DrawingSheet, previewUrl: PreviewUrl) {
  return {
    id: sheet.id,
    type: sheet.type,
    isPreview: sheet.isPreview,
    previewUrl: sheet.isPreview ? previewUrl(sheet.previewKey) : null,
    originalMime: sheet.originalMime,
    fileName: sheet.fileName,
    sizeBytes: sheet.sizeBytes,
  };
}

export function toArchitectSummary(a: User) {
  return {
    id: a.id,
    fullName: a.fullName,
    city: a.city,
    architectRating: a.architectRating,
    ratingCount: a.architectRatingCount,
    avatarUrl: a.avatarUrl,
  };
}

/** Contract DrawingSummary. Never exposes original keys; only watermarked preview URLs. */
export function toDrawingSummary(
  d: DrawingWithRelations,
  previewUrl: PreviewUrl,
) {
  const cover = d.sheets
    .filter((s) => s.isPreview && s.previewKey)
    .sort((a, b) => a.createdAt.getTime() - b.createdAt.getTime())[0];
  return {
    id: d.id,
    title: d.title,
    category: {
      id: d.category.id,
      name: d.category.name,
      slug: d.category.slug,
    },
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
    previewUrl: previewUrl(cover?.previewKey),
    architect: toArchitectSummary(d.architect),
    status: d.status,
    createdAt: d.createdAt,
  };
}

/** Owner-view DrawingDetail returned by the seller endpoints (no viewer/reviews block). */
export function toOwnerDrawingDetail(
  d: DrawingWithRelations,
  previewUrl: PreviewUrl,
) {
  return {
    ...toDrawingSummary(d, previewUrl),
    description: d.description,
    bedrooms: d.bedrooms,
    tags: d.tags,
    viewCount: d.viewCount,
    purchaseCount: d.purchaseCount,
    failureReason: d.failureReason,
    sheets: [...d.sheets]
      .sort((a, b) => a.createdAt.getTime() - b.createdAt.getTime())
      .map((s) => toSheetResponse(s, previewUrl)),
  };
}
