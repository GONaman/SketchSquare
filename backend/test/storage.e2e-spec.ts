import { Test } from '@nestjs/testing';
import { randomUUID } from 'node:crypto';
import { AppConfigModule } from '../src/config/config.module';
import { StorageModule } from '../src/storage/storage.module';
import { StorageService } from '../src/storage/storage.service';

describe('StorageService against MinIO (e2e)', () => {
  let storage: StorageService;
  const prefix = `e2e-${randomUUID()}`;
  const keys: string[] = [];

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({
      imports: [AppConfigModule, StorageModule],
    }).compile();
    storage = moduleRef.get(StorageService);
  });

  afterAll(async () => {
    await Promise.all(keys.map((k) => storage.deleteOriginal(k)));
  });

  it('presigned upload enforces content type + length, and the object can be inspected', async () => {
    const key = `${prefix}/plan.pdf`;
    keys.push(key);
    const body = Buffer.from('%PDF-1.7\nhello world');
    const { uploadUrl, headers } = await storage.presignOriginalUpload({
      key,
      contentType: 'application/pdf',
      sizeBytes: body.length,
    });

    expect(await storage.headOriginal(key)).toBeNull();

    const bad = await fetch(uploadUrl, {
      method: 'PUT',
      headers: { 'Content-Type': 'image/png' },
      body,
    });
    expect(bad.status).toBeGreaterThanOrEqual(400);

    const oversized = await fetch(uploadUrl, {
      method: 'PUT',
      headers,
      body: Buffer.concat([body, Buffer.alloc(1024)]),
    });
    expect(oversized.status).toBeGreaterThanOrEqual(400);
    expect(await storage.headOriginal(key)).toBeNull();

    const ok = await fetch(uploadUrl, { method: 'PUT', headers, body });
    expect(ok.status).toBe(200);

    expect(await storage.headOriginal(key)).toEqual({
      sizeBytes: body.length,
      contentType: 'application/pdf',
    });
    expect((await storage.readOriginalHead(key, 5)).toString()).toBe('%PDF-');
    expect((await storage.getOriginalBuffer(key)).equals(body)).toBe(true);
    expect(await storage.sha256Original(key)).toMatch(/^[0-9a-f]{64}$/);

    const link = await storage.presignOriginalDownload(key, 'plan.pdf');
    const dl = await fetch(link);
    expect(dl.status).toBe(200);
    expect(Buffer.from(await dl.arrayBuffer()).equals(body)).toBe(true);
    expect(dl.headers.get('content-disposition')).toContain('plan.pdf');
  });

  it('originals are not publicly readable without a signature', async () => {
    const key = `${prefix}/private.bin`;
    keys.push(key);
    await storage.putOriginal(key, Buffer.from('secret'), 'text/plain');
    const res = await fetch(
      `${process.env.S3_ENDPOINT ?? 'http://localhost:9000'}/originals/${key}`,
    );
    expect(res.status).toBeGreaterThanOrEqual(400);
  });

  it('stores previews and builds their public URL', async () => {
    const key = `${prefix}/preview.png`;
    await storage.putPreview(key, Buffer.from('png-bytes'));
    const url = storage.previewUrl(key)!;
    expect(url).toContain(`/previews/${key}`);
    expect(storage.previewUrl(null)).toBeNull();
  });
});
