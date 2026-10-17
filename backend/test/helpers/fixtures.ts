import {
  DrawingStatus,
  Facing,
  PrismaClient,
  VerificationStatus,
} from '@prisma/client';

let seq = 0;
const next = () => ++seq;

export async function createCategory(
  prisma: PrismaClient,
  name = `Category ${next()}`,
) {
  return prisma.category.create({
    data: {
      name,
      slug: `${name.toLowerCase().replace(/\W+/g, '-')}-${next()}`,
    },
  });
}

export async function createArchitect(
  prisma: PrismaClient,
  over: Partial<{
    fullName: string;
    city: string;
    architectRating: number;
    architectRatingCount: number;
    verificationStatus: VerificationStatus;
    role: 'ARCHITECT' | 'ADMIN';
  }> = {},
) {
  const n = next();
  return prisma.user.create({
    data: {
      email: `architect${n}@example.test`,
      passwordHash: 'x',
      fullName: over.fullName ?? `Architect ${n}`,
      address: '1 Test Street',
      phone: '9999999999',
      city: over.city ?? 'Bengaluru',
      verificationStatus: over.verificationStatus ?? 'APPROVED',
      architectRating: over.architectRating ?? 0,
      architectRatingCount: over.architectRatingCount ?? 0,
      role: over.role ?? 'ARCHITECT',
    },
  });
}

export interface DrawingFixture {
  architectId: string;
  categoryId: string;
  title?: string;
  description?: string;
  city?: string;
  plotLengthFt?: number;
  plotBreadthFt?: number;
  floors?: number;
  facing?: Facing;
  bedrooms?: number;
  tags?: string[];
  failureReason?: string;
  pricePaise?: number;
  status?: DrawingStatus;
  avgRating?: number;
  ratingCount?: number;
  viewCount?: number;
  purchaseCount?: number;
  createdAt?: Date;
  previewKeys?: string[];
}

export async function createDrawing(prisma: PrismaClient, f: DrawingFixture) {
  const n = next();
  return prisma.drawing.create({
    data: {
      architectId: f.architectId,
      categoryId: f.categoryId,
      title: f.title ?? `Drawing ${n}`,
      description: f.description ?? `Description ${n}`,
      city: f.city ?? 'Bengaluru',
      plotLengthFt: f.plotLengthFt ?? 30,
      plotBreadthFt: f.plotBreadthFt ?? 40,
      floors: f.floors ?? 1,
      facing: f.facing,
      bedrooms: f.bedrooms,
      tags: f.tags,
      failureReason: f.failureReason,
      pricePaise: f.pricePaise ?? 0,
      status: f.status ?? 'PUBLISHED',
      avgRating: f.avgRating ?? 0,
      ratingCount: f.ratingCount ?? 0,
      viewCount: f.viewCount ?? 0,
      purchaseCount: f.purchaseCount ?? 0,
      createdAt: f.createdAt,
      sheets: f.previewKeys
        ? {
            create: f.previewKeys.map((key, i) => ({
              originalKey: `orig/${n}/${i}.pdf`,
              originalMime: 'application/pdf',
              fileName: `sheet${i}.pdf`,
              sizeBytes: 1000,
              isPreview: true,
              previewKey: key,
              createdAt: new Date(Date.now() + i * 1000),
            })),
          }
        : undefined,
    },
  });
}
