import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { spawnSync } from 'node:child_process';
import { PDFDocument } from 'pdf-lib';
import request from 'supertest';
import sharp from 'sharp';
import { App } from 'supertest/types';
import { AppModule } from '../src/app.module';
import { configureApp } from '../src/app.setup';
import { PrismaService } from '../src/prisma/prisma.service';
import { StorageService } from '../src/storage/storage.service';
import { bearer, createTestUser, TestUser } from './helpers/auth';
import { resetDb } from './helpers/db';

const hasPdftoppm = spawnSync('pdftoppm', ['-v']).error === undefined;

interface ErrBody {
  error: { code: string; message: string };
}

async function waitForStatus(
  prisma: PrismaService,
  id: string,
  status: string,
  timeoutMs = 20000,
) {
  const start = Date.now();
  for (;;) {
    const d = await prisma.drawing.findUniqueOrThrow({ where: { id } });
    if (d.status === status) return d;
    if (Date.now() - start > timeoutMs) {
      throw new Error(`Drawing stuck in ${d.status} (${d.failureReason})`);
    }
    await new Promise((r) => setTimeout(r, 200));
  }
}

describe('Publish flow + processing worker (e2e)', () => {
  let app: INestApplication<App>;
  let prisma: PrismaService;
  let storage: StorageService;
  let owner: TestUser;
  let categoryId: string;
  const http = () => request(app.getHttpServer());
  const keys: string[] = [];

  async function newDrawing(user = owner): Promise<string> {
    const res = await http()
      .post('/drawings')
      .set(...bearer(user))
      .send({
        title: 'Publish test',
        description: 'd',
        categoryId,
        city: 'Pune',
        plotLength: 40,
        plotBreadth: 30,
        unit: 'ft',
        floors: 1,
        pricePaise: 100,
      })
      .expect(201);
    return (res.body as { id: string }).id;
  }

  async function addSheet(
    drawingId: string,
    fileName: string,
    contentType: string,
    content: Buffer,
    isPreview: boolean,
  ): Promise<string> {
    const up = (
      await http()
        .post(`/drawings/${drawingId}/sheets/upload-url`)
        .set(...bearer(owner))
        .send({ fileName, contentType, sizeBytes: content.length })
        .expect(200)
    ).body as { uploadUrl: string; objectKey: string; headers: HeadersInit };
    keys.push(up.objectKey);
    const put = await fetch(up.uploadUrl, {
      method: 'PUT',
      headers: up.headers,
      body: new Uint8Array(content),
    });
    expect(put.ok).toBe(true);
    const sheet = (
      await http()
        .post(`/drawings/${drawingId}/sheets`)
        .set(...bearer(owner))
        .send({
          type: 'ARCHITECTURAL',
          objectKey: up.objectKey,
          isPreview,
          fileName,
          sizeBytes: content.length,
        })
        .expect(201)
    ).body as { id: string };
    return sheet.id;
  }

  const publish = (id: string, user = owner) =>
    http()
      .post(`/drawings/${id}/publish`)
      .set(...bearer(user));

  const png = (color: string) =>
    sharp({
      create: { width: 800, height: 600, channels: 3, background: color },
    })
      .png()
      .toBuffer();

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();
    app = moduleRef.createNestApplication();
    configureApp(app);
    await app.init();
    prisma = app.get(PrismaService);
    storage = app.get(StorageService);
  });

  beforeEach(async () => {
    await resetDb(prisma);
    categoryId = (
      await prisma.category.create({
        data: { name: 'Residential', slug: 'residential' },
      })
    ).id;
    owner = await createTestUser(app, { fullName: 'Asha Rao' });
  });

  afterAll(async () => {
    await Promise.all(keys.map((k) => storage.deleteOriginal(k)));
    await resetDb(prisma);
    await app.close();
  });

  it('validates sheets before publishing and enforces ownership', async () => {
    const id = await newDrawing();
    const none = await publish(id).expect(400);
    expect((none.body as ErrBody).error.code).toBe('VALIDATION_ERROR');

    await addSheet(id, 'a.png', 'image/png', await png('#336699'), false);
    const noPreview = await publish(id).expect(400);
    expect((noPreview.body as ErrBody).error.message).toContain('preview');

    for (const name of ['p1.png', 'p2.png', 'p3.png']) {
      await addSheet(id, name, 'image/png', await png('#996633'), true);
    }
    await publish(id).expect(400); // 3 previews > 2

    const other = await createTestUser(app);
    await publish(id, other).expect(403);
    await http().post(`/drawings/${id}/publish`).expect(401);
    await publish('11111111-1111-4111-8111-111111111111').expect(404);
    expect(
      (await prisma.drawing.findUniqueOrThrow({ where: { id } })).status,
    ).toBe('DRAFT');
  });

  it('publishes a PNG drawing: PROCESSING → PUBLISHED with a watermarked preview and pHash', async () => {
    const id = await newDrawing();
    await addSheet(id, 'plan.png', 'image/png', await png('#336699'), true);
    await addSheet(
      id,
      'structure.png',
      'image/png',
      await png('#aabbcc'),
      false,
    );

    const res = await publish(id).expect(202);
    expect(res.body).toEqual({ status: 'PROCESSING' });
    // A second publish while processing is accepted but does not enqueue again.
    await publish(id).expect(202);

    const done = await waitForStatus(prisma, id, 'PUBLISHED');
    expect(done.failureReason).toBeNull();

    const sheets = await prisma.drawingSheet.findMany({
      where: { drawingId: id },
      orderBy: { createdAt: 'asc' },
    });
    const preview = sheets.find((s) => s.isPreview)!;
    expect(preview.previewKey).toMatch(new RegExp(`^drawings/${id}/`));
    expect(preview.pHash).toMatch(/^[0-9a-f]{16}$/);
    expect(sheets.find((s) => !s.isPreview)!.previewKey).toBeNull();

    // The public preview is served from the previews bucket and is not the original.
    const url = storage.previewUrl(preview.previewKey)!;
    const img = await fetch(url);
    expect(img.status).toBe(200);
    const bytes = Buffer.from(await img.arrayBuffer());
    const original = await storage.getOriginalBuffer(preview.originalKey);
    expect(bytes.equals(original)).toBe(false);
    expect((await sharp(bytes).metadata()).format).toBe('png');

    // Owner response exposes only the watermarked preview URL, never original keys.
    const patched = await http()
      .patch(`/drawings/${id}`)
      .set(...bearer(owner))
      .send({ pricePaise: 500 })
      .expect(200);
    const text = JSON.stringify(patched.body);
    expect(text).toContain(url);
    expect(text).not.toContain(preview.originalKey);
    expect((patched.body as { previewUrl: string }).previewUrl).toBe(url);

    await publish(id).expect(409);
  });

  (hasPdftoppm ? it : it.skip)(
    'renders PDF previews',
    async () => {
      const doc = await PDFDocument.create();
      doc.addPage([600, 400]).drawText('Ground floor plan', { x: 50, y: 200 });
      const pdf = Buffer.from(await doc.save());
      const id = await newDrawing();
      await addSheet(id, 'plan.pdf', 'application/pdf', pdf, true);
      await publish(id).expect(202);
      await waitForStatus(prisma, id, 'PUBLISHED');
      const sheet = await prisma.drawingSheet.findFirstOrThrow({
        where: { drawingId: id },
      });
      expect(sheet.pHash).toMatch(/^[0-9a-f]{16}$/);
      const img = await fetch(storage.previewUrl(sheet.previewKey)!);
      expect(
        (await sharp(Buffer.from(await img.arrayBuffer())).metadata()).format,
      ).toBe('png');
    },
    30000,
  );

  it('allows re-publishing a FAILED drawing', async () => {
    const id = await newDrawing();
    await addSheet(id, 'plan.png', 'image/png', await png('#336699'), true);
    await prisma.drawing.update({
      where: { id },
      data: { status: 'FAILED', failureReason: 'boom' },
    });
    await publish(id).expect(202);
    const done = await waitForStatus(prisma, id, 'PUBLISHED');
    expect(done.failureReason).toBeNull();
  });

  it('a removed drawing cannot be published (404)', async () => {
    const id = await newDrawing();
    await addSheet(id, 'plan.png', 'image/png', await png('#336699'), true);
    await prisma.drawing.update({ where: { id }, data: { status: 'REMOVED' } });
    await publish(id).expect(404);
  });
});
