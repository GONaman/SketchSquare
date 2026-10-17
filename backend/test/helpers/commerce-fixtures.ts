import { PrismaClient } from '@prisma/client';

export async function createCategory(prisma: PrismaClient) {
  return prisma.category.upsert({
    where: { slug: 'houses' },
    update: {},
    create: { name: 'Houses', slug: 'houses' },
  });
}

export async function createDrawing(
  prisma: PrismaClient,
  architectId: string,
  opts: {
    pricePaise?: number;
    status?: 'PUBLISHED' | 'DRAFT' | 'REMOVED';
    title?: string;
    withSheets?: boolean;
  } = {},
) {
  const category = await createCategory(prisma);
  const drawing = await prisma.drawing.create({
    data: {
      architectId,
      categoryId: category.id,
      title: opts.title ?? 'Test drawing',
      description: 'A drawing used in tests',
      city: 'Bengaluru',
      plotLengthFt: 30,
      plotBreadthFt: 40,
      pricePaise: opts.pricePaise ?? 100000,
      status: opts.status ?? 'PUBLISHED',
    },
  });
  if (opts.withSheets !== false) {
    await prisma.drawingSheet.createMany({
      data: [
        {
          drawingId: drawing.id,
          type: 'ARCHITECTURAL',
          originalKey: `drawings/${drawing.id}/plan.pdf`,
          originalMime: 'application/pdf',
          fileName: 'plan.pdf',
          sizeBytes: 1234,
          isPreview: true,
          previewKey: `drawings/${drawing.id}/plan-preview.png`,
        },
        {
          drawingId: drawing.id,
          type: 'STRUCTURAL',
          originalKey: `drawings/${drawing.id}/structure.pdf`,
          originalMime: 'application/pdf',
          fileName: 'structure.pdf',
          sizeBytes: 4321,
        },
      ],
    });
  }
  return drawing;
}
