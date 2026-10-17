import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { createHash } from 'node:crypto';
import request from 'supertest';
import sharp from 'sharp';
import { App } from 'supertest/types';
import { AppModule } from '../src/app.module';
import { configureApp } from '../src/app.setup';
import { PlagiarismCheckService } from '../src/plagiarism/plagiarism-check.service';
import { PrismaService } from '../src/prisma/prisma.service';
import { StorageService } from '../src/storage/storage.service';
import { hammingDistance } from '../src/watermark/phash';
import { bearer, createTestUser, TestUser } from './helpers/auth';
import { resetDb } from './helpers/db';
import { createCategory, createDrawing } from './helpers/fixtures';
import { waitForEmail } from './helpers/mailpit';

const rect = (x: number, y: number, w: number, h: number) =>
  `<rect x="${x}" y="${y}" width="${w}" height="${h}" fill="black"/>`;

/** A floor-plan-like drawing: white page, thick walls, rooms. `extra` adds small details (a near copy). */
function planPng(kind: 'plan' | 'plan-edited' | 'other'): Promise<Buffer> {
  const plan = [
    rect(50, 50, 700, 12),
    rect(50, 538, 700, 12),
    rect(50, 50, 12, 500),
    rect(738, 50, 12, 500),
    rect(400, 50, 10, 300),
    rect(50, 350, 400, 10),
  ];
  const shapes =
    kind === 'other'
      ? [
          `<circle cx="200" cy="200" r="120" fill="black"/>`,
          `<circle cx="600" cy="400" r="150" fill="black"/>`,
          rect(380, 20, 40, 560),
        ]
      : kind === 'plan-edited'
        ? [...plan, rect(600, 450, 20, 20)]
        : plan;
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="800" height="600"><rect width="800" height="600" fill="white"/>${shapes.join('')}</svg>`;
  return sharp(Buffer.from(svg)).png().toBuffer();
}

describe('Plagiarism check at publish time (e2e)', () => {
  let app: INestApplication<App>;
  let prisma: PrismaService;
  let storage: StorageService;
  let check: PlagiarismCheckService;
  let categoryId: string;
  let alice: TestUser;
  let bob: TestUser;
  const keys: string[] = [];
  const http = () => request(app.getHttpServer());
  let seq = 0;

  async function draft(
    owner: TestUser,
    png: Buffer,
    plot = { l: 40, b: 30 },
  ): Promise<string> {
    const d = await createDrawing(prisma, {
      architectId: owner.user.id,
      categoryId,
      plotLengthFt: plot.l,
      plotBreadthFt: plot.b,
      pricePaise: 0,
      status: 'DRAFT',
    });
    const key = `plagiarism-test/${d.id}-${++seq}.png`;
    keys.push(key);
    await storage.putOriginal(key, png, 'image/png');
    await prisma.drawingSheet.create({
      data: {
        drawingId: d.id,
        originalKey: key,
        originalMime: 'image/png',
        fileName: 'plan.png',
        sizeBytes: png.length,
        isPreview: true,
        sha256: createHash('sha256').update(png).digest('hex'),
      },
    });
    return d.id;
  }

  async function publishAndSettle(owner: TestUser, id: string) {
    await http()
      .post(`/drawings/${id}/publish`)
      .set(...bearer(owner))
      .expect(202);
    const start = Date.now();
    for (;;) {
      const d = await prisma.drawing.findUniqueOrThrow({ where: { id } });
      if (d.status !== 'PROCESSING') return d;
      if (Date.now() - start > 20000) throw new Error('stuck processing');
      await new Promise((r) => setTimeout(r, 150));
    }
  }

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();
    app = moduleRef.createNestApplication();
    configureApp(app);
    await app.init();
    prisma = app.get(PrismaService);
    storage = app.get(StorageService);
    check = app.get(PlagiarismCheckService);
  });

  beforeEach(async () => {
    await resetDb(prisma);
    categoryId = (await createCategory(prisma)).id;
    alice = await createTestUser(app, {
      fullName: 'Alice',
      email: `alice-${Date.now()}@example.com`,
    });
    bob = await createTestUser(app, {
      fullName: 'Bob',
      email: `bob-${Date.now()}@example.com`,
    });
  });

  afterAll(async () => {
    await Promise.all(keys.map((k) => storage.deleteOriginal(k)));
    await resetDb(prisma);
    await app.close();
  });

  it('hard-blocks a byte-identical file from another architect (FAILED, no flag)', async () => {
    const png = await planPng('plan');
    const original = await publishAndSettle(alice, await draft(alice, png));
    expect(original.status).toBe('PUBLISHED');

    const copy = await publishAndSettle(bob, await draft(bob, png));
    expect(copy.status).toBe('FAILED');
    expect(copy.failureReason).toContain('plan.png');
    expect(copy.failureReason).toContain('another architect');
    expect(await prisma.plagiarismFlag.count()).toBe(0);
    // The block is visible to the uploader via the normal detail endpoint.
    const detail = await http()
      .get(`/drawings/${copy.id}`)
      .set(...bearer(bob))
      .expect(200);
    expect((detail.body as { status: string }).status).toBe('FAILED');
  });

  it('never flags or blocks an architect against their own drawings, nor against another architect’s draft', async () => {
    const png = await planPng('plan');
    const a1 = await publishAndSettle(alice, await draft(alice, png));
    expect(a1.status).toBe('PUBLISHED');
    const a2 = await publishAndSettle(alice, await draft(alice, png));
    expect(a2.status).toBe('PUBLISHED');
    expect(await prisma.plagiarismFlag.count()).toBe(0);

    await resetDb(prisma);
    categoryId = (await createCategory(prisma)).id;
    alice = await createTestUser(app, {});
    bob = await createTestUser(app, {});
    await draft(alice, png); // another architect's DRAFT is not "on the platform"
    const b = await publishAndSettle(bob, await draft(bob, png));
    expect(b.status).toBe('PUBLISHED');
  });

  it('holds a near-identical preview for review, links both drawings and emails the uploader', async () => {
    const original = await publishAndSettle(
      alice,
      await draft(alice, await planPng('plan')),
    );
    expect(original.status).toBe('PUBLISHED');

    const copyId = await draft(bob, await planPng('plan-edited'));
    const copy = await publishAndSettle(bob, copyId);
    expect(copy.status).toBe('UNDER_REVIEW');
    expect(copy.failureReason).toBeNull();

    const flags = await prisma.plagiarismFlag.findMany();
    expect(flags).toHaveLength(1);
    const [flag] = flags;
    expect(flag).toMatchObject({
      drawingId: copyId,
      matchedDrawingId: original.id,
      status: 'PENDING',
    });
    expect(flag.hammingDistance).toBeLessThanOrEqual(8);
    const [mine, theirs] = await Promise.all([
      prisma.drawingSheet.findUniqueOrThrow({ where: { id: flag.sheetId } }),
      prisma.drawingSheet.findUniqueOrThrow({
        where: { id: flag.matchedSheetId },
      }),
    ]);
    expect(mine.drawingId).toBe(copyId);
    expect(theirs.drawingId).toBe(original.id);
    expect(hammingDistance(mine.pHash!, theirs.pHash!)).toBe(
      flag.hammingDistance,
    );
    expect(mine.previewKey).toBeTruthy(); // admins can see it side by side

    await waitForEmail(bob.user.email, 'under review');

    // Not publicly visible while under review, and the original is untouched.
    const carol = await createTestUser(app, {});
    await http()
      .get(`/drawings/${copyId}`)
      .set(...bearer(carol))
      .expect(404);
    await http()
      .get(`/drawings/${copyId}`)
      .set(...bearer(bob))
      .expect(200);
  });

  it('flags a rotated plot and ignores other plot sizes and other images', async () => {
    const original = await publishAndSettle(
      alice,
      await draft(alice, await planPng('plan'), { l: 40, b: 30 }),
    );
    const near = await planPng('plan-edited');

    const rotated = await publishAndSettle(
      bob,
      await draft(bob, near, { l: 30.5, b: 41 }),
    );
    expect(rotated.status).toBe('UNDER_REVIEW');

    const bigger = await publishAndSettle(
      bob,
      await draft(bob, near, { l: 60, b: 45 }),
    );
    expect(bigger.status).toBe('PUBLISHED');

    const different = await publishAndSettle(
      bob,
      await draft(bob, await planPng('other'), { l: 40, b: 30 }),
    );
    expect(different.status).toBe('PUBLISHED');

    const flags = await prisma.plagiarismFlag.findMany();
    expect(flags).toHaveLength(1);
    expect(flags[0]).toMatchObject({
      drawingId: rotated.id,
      matchedDrawingId: original.id,
    });
  });

  describe('findSimilarPreviews', () => {
    const base = '0000000000000000';
    const bits = (n: number) =>
      (2n ** BigInt(n) - 1n).toString(16).padStart(16, '0');

    async function liveSheet(owner: TestUser, pHash: string, l = 40, b = 30) {
      const d = await createDrawing(prisma, {
        architectId: owner.user.id,
        categoryId,
        plotLengthFt: l,
        plotBreadthFt: b,
        previewKeys: ['p.png'],
      });
      const sheet = await prisma.drawingSheet.findFirstOrThrow({
        where: { drawingId: d.id },
      });
      await prisma.drawingSheet.update({
        where: { id: sheet.id },
        data: { pHash },
      });
      return { drawingId: d.id, sheetId: sheet.id };
    }

    const subject = (architectId: string) => ({
      id: '11111111-1111-4111-8111-111111111111',
      architectId,
      plotLengthFt: 40,
      plotBreadthFt: 30,
    });
    const previews = [
      { sheetId: '22222222-2222-4222-8222-222222222222', pHash: base },
    ];

    it('uses an inclusive Hamming threshold of 8 and reports the exact distance', async () => {
      const at8 = await liveSheet(alice, bits(8));
      await liveSheet(alice, bits(9));
      const matches = await check.findSimilarPreviews(
        subject(bob.user.id),
        previews,
      );
      expect(matches).toHaveLength(1);
      expect(matches[0]).toMatchObject({
        matchedDrawingId: at8.drawingId,
        matchedSheetId: at8.sheetId,
        hammingDistance: 8,
      });
    });

    it('applies the ±5% plot window in both orientations (inclusive) and skips own drawings', async () => {
      const edge = await liveSheet(alice, base, 42, 28.5);
      const rotatedEdge = await liveSheet(alice, base, 28.5, 42);
      await liveSheet(alice, base, 42.1, 30);
      await liveSheet(bob, base);
      const matches = await check.findSimilarPreviews(
        subject(bob.user.id),
        previews,
      );
      expect(matches.map((m) => m.matchedDrawingId).sort()).toEqual(
        [edge.drawingId, rotatedEdge.drawingId].sort(),
      );
    });
  });
});
