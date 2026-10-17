import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { App } from 'supertest/types';
import { AppModule } from '../src/app.module';
import { configureApp } from '../src/app.setup';
import { PrismaService } from '../src/prisma/prisma.service';
import { StorageService } from '../src/storage/storage.service';
import { bearer, createTestUser, TestUser } from './helpers/auth';
import { resetDb } from './helpers/db';

interface ErrBody {
  error: { code: string; message: string };
}
interface UploadBody {
  uploadUrl: string;
  objectKey: string;
  headers: Record<string, string>;
}
interface SheetBody {
  id: string;
  type: string;
  isPreview: boolean;
  previewUrl: string | null;
  originalMime: string;
  fileName: string;
  sizeBytes: number;
}

const PDF = Buffer.from('%PDF-1.7\n1 0 obj\n<<>>\nendobj\n%%EOF\n');
const PNG = Buffer.concat([
  Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
  Buffer.alloc(32),
]);

describe('Drawing sheets (e2e)', () => {
  let app: INestApplication<App>;
  let prisma: PrismaService;
  let storage: StorageService;
  let owner: TestUser;
  let drawingId: string;
  const http = () => request(app.getHttpServer());
  const keys: string[] = [];

  async function uploadFile(
    as: TestUser,
    id: string,
    fileName: string,
    contentType: string,
    content: Buffer,
  ): Promise<string> {
    const res = await http()
      .post(`/drawings/${id}/sheets/upload-url`)
      .set(...bearer(as))
      .send({ fileName, contentType, sizeBytes: content.length })
      .expect(200);
    const u = res.body as UploadBody;
    keys.push(u.objectKey);
    const put = await fetch(u.uploadUrl, {
      method: 'PUT',
      headers: u.headers,
      body: new Uint8Array(content),
    });
    expect(put.ok).toBe(true);
    return u.objectKey;
  }

  const register = (
    as: TestUser,
    objectKey: string,
    over: Record<string, unknown> = {},
    id = drawingId,
  ) =>
    http()
      .post(`/drawings/${id}/sheets`)
      .set(...bearer(as))
      .send({
        type: 'ARCHITECTURAL',
        objectKey,
        isPreview: false,
        fileName: 'plan.pdf',
        sizeBytes: 10,
        ...over,
      });

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
    const category = await prisma.category.create({
      data: { name: 'Residential', slug: 'residential' },
    });
    owner = await createTestUser(app);
    const res = await http()
      .post('/drawings')
      .set(...bearer(owner))
      .send({
        title: 'Sheet test',
        description: 'd',
        categoryId: category.id,
        city: 'Pune',
        plotLength: 40,
        plotBreadth: 30,
        unit: 'ft',
        floors: 1,
        pricePaise: 100,
      })
      .expect(201);
    drawingId = (res.body as { id: string }).id;
  });

  afterAll(async () => {
    await Promise.all(keys.map((k) => storage.deleteOriginal(k)));
    await resetDb(prisma);
    await app.close();
  });

  it('upload-url validates type, declared content type and size', async () => {
    const post = (body: Record<string, unknown>) =>
      http()
        .post(`/drawings/${drawingId}/sheets/upload-url`)
        .set(...bearer(owner))
        .send(body);
    for (const body of [
      { fileName: 'a.exe', contentType: 'application/pdf', sizeBytes: 5 },
      { fileName: 'a.pdf', contentType: 'image/png', sizeBytes: 5 },
      {
        fileName: 'a.pdf',
        contentType: 'application/pdf',
        sizeBytes: 50 * 1024 * 1024 + 1,
      },
    ]) {
      const res = await post(body).expect(400);
      expect((res.body as ErrBody).error.code).toBe('UPLOAD_INVALID');
    }
    await post({ fileName: 'a.pdf', contentType: 'application/pdf' }).expect(
      400,
    );
  });

  it('uploads via presigned URL then registers a sheet (idempotently)', async () => {
    const key = await uploadFile(
      owner,
      drawingId,
      'My Plan.pdf',
      'application/pdf',
      PDF,
    );
    expect(key).toMatch(
      new RegExp(`^drawings/${drawingId}/[0-9a-f-]{36}/My_Plan\\.pdf$`),
    );
    const res = await register(owner, key, { fileName: 'My Plan.pdf' }).expect(
      201,
    );
    const sheet = res.body as SheetBody;
    expect(sheet).toMatchObject({
      type: 'ARCHITECTURAL',
      isPreview: false,
      previewUrl: null,
      originalMime: 'application/pdf',
      fileName: 'My_Plan.pdf',
      sizeBytes: PDF.length,
    });
    expect(JSON.stringify(res.body)).not.toContain(key);

    const again = await register(owner, key, {
      fileName: 'My Plan.pdf',
    }).expect(201);
    expect((again.body as SheetBody).id).toBe(sheet.id);
    expect(await prisma.drawingSheet.count({ where: { drawingId } })).toBe(1);
    const row = await prisma.drawingSheet.findFirstOrThrow({
      where: { drawingId },
    });
    expect(row.sha256).toMatch(/^[0-9a-f]{64}$/);
  });

  it('rejects registration when nothing was uploaded', async () => {
    const res = await register(
      owner,
      `drawings/${drawingId}/${'1'.repeat(8)}-1111-4111-8111-111111111111/plan.pdf`,
    ).expect(400);
    expect((res.body as ErrBody).error.code).toBe('UPLOAD_INVALID');
  });

  it('rejects wrong magic bytes (and deletes the object)', async () => {
    const key = await uploadFile(
      owner,
      drawingId,
      'fake.pdf',
      'application/pdf',
      Buffer.from('MZ not a pdf at all'),
    );
    const res = await register(owner, key, { fileName: 'fake.pdf' }).expect(
      400,
    );
    expect((res.body as ErrBody).error.code).toBe('UPLOAD_INVALID');
    expect(await storage.originalsObjectExists(key)).toBe(false);
    expect(await prisma.drawingSheet.count()).toBe(0);
  });

  it('rejects an extension that does not match the detected type', async () => {
    const key = await uploadFile(owner, drawingId, 'pic.png', 'image/png', PDF);
    await register(owner, key, { fileName: 'pic.png' }).expect(400);
  });

  it('rejects keys from another drawing and path tricks', async () => {
    for (const objectKey of [
      'drawings/11111111-1111-4111-8111-111111111111/x/plan.pdf',
      `drawings/${drawingId}/../other/plan.pdf`,
      'licensed/abc/plan.pdf',
    ]) {
      const res = await register(owner, objectKey).expect(400);
      expect((res.body as ErrBody).error.code).toBe('UPLOAD_INVALID');
    }
  });

  it('only previewable kinds can be previews', async () => {
    const dwg = Buffer.concat([Buffer.from('AC1032'), Buffer.alloc(40)]);
    const key = await uploadFile(
      owner,
      drawingId,
      'plan.dwg',
      'application/octet-stream',
      dwg,
    );
    const bad = await register(owner, key, {
      fileName: 'plan.dwg',
      isPreview: true,
    }).expect(400);
    expect((bad.body as ErrBody).error.code).toBe('VALIDATION_ERROR');
    const ok = await register(owner, key, { fileName: 'plan.dwg' }).expect(201);
    expect((ok.body as SheetBody).originalMime).toBe('application/acad');
    await http()
      .patch(`/drawings/${drawingId}/sheets/${(ok.body as SheetBody).id}`)
      .set(...bearer(owner))
      .send({ isPreview: true })
      .expect(400);
  });

  it('patches and deletes sheets (delete is idempotent and removes the object)', async () => {
    const key = await uploadFile(owner, drawingId, 'p.png', 'image/png', PNG);
    const created = (
      await register(owner, key, { fileName: 'p.png' }).expect(201)
    ).body as SheetBody;
    const patched = await http()
      .patch(`/drawings/${drawingId}/sheets/${created.id}`)
      .set(...bearer(owner))
      .send({ type: 'STRUCTURAL', isPreview: true })
      .expect(200);
    expect(patched.body).toMatchObject({ type: 'STRUCTURAL', isPreview: true });

    await http()
      .patch(
        `/drawings/${drawingId}/sheets/11111111-1111-4111-8111-111111111111`,
      )
      .set(...bearer(owner))
      .send({ type: 'HVAC' })
      .expect(404);

    for (let i = 0; i < 2; i++) {
      await http()
        .delete(`/drawings/${drawingId}/sheets/${created.id}`)
        .set(...bearer(owner))
        .expect(204);
    }
    expect(await storage.originalsObjectExists(key)).toBe(false);
  });

  it('enforces ownership and draft-only editing', async () => {
    const other = await createTestUser(app);
    await http()
      .post(`/drawings/${drawingId}/sheets/upload-url`)
      .set(...bearer(other))
      .send({ fileName: 'a.pdf', contentType: 'application/pdf', sizeBytes: 5 })
      .expect(403);
    await http()
      .post(`/drawings/${drawingId}/sheets/upload-url`)
      .send({ fileName: 'a.pdf', contentType: 'application/pdf', sizeBytes: 5 })
      .expect(401);
    await register(other, `drawings/${drawingId}/x/a.pdf`).expect(403);

    await prisma.drawing.update({
      where: { id: drawingId },
      data: { status: 'PUBLISHED' },
    });
    await http()
      .post(`/drawings/${drawingId}/sheets/upload-url`)
      .set(...bearer(owner))
      .send({ fileName: 'a.pdf', contentType: 'application/pdf', sizeBytes: 5 })
      .expect(409);
  });
});
