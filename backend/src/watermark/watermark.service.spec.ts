import { spawnSync } from 'node:child_process';
import { inflateSync } from 'node:zlib';
import { PDFDocument } from 'pdf-lib';
import sharp from 'sharp';
import { StorageService } from '../storage/storage.service';
import {
  WatermarkService,
  licenseFooterText,
  previewWatermarkText,
  toWinAnsi,
} from './watermark.service';

const hasPdftoppm = spawnSync('pdftoppm', ['-v']).error === undefined;

async function solidPng(width: number, height: number): Promise<Buffer> {
  return sharp({
    create: { width, height, channels: 3, background: '#e8eef8' },
  })
    .png()
    .toBuffer();
}

async function makePdf(pages: number): Promise<Buffer> {
  const doc = await PDFDocument.create();
  for (let i = 0; i < pages; i++) {
    const page = doc.addPage([600, 400]);
    page.drawText(`Sheet ${i + 1}`, { x: 50, y: 200, size: 30 });
  }
  return Buffer.from(await doc.save());
}

function inflatedStreams(pdf: Buffer): string {
  const raw = pdf.toString('latin1');
  const parts: string[] = [];
  for (const m of raw.matchAll(/stream\r?\n([\s\S]*?)\r?\nendstream/g)) {
    try {
      parts.push(inflateSync(Buffer.from(m[1], 'latin1')).toString('latin1'));
    } catch {
      parts.push(m[1]);
    }
  }
  return parts.join('\n');
}

function hex(text: string): string {
  return Buffer.from(text, 'latin1').toString('hex').toUpperCase();
}

function makeService(storage: Partial<StorageService> = {}): WatermarkService {
  return new WatermarkService(storage as StorageService);
}

describe('WatermarkService', () => {
  describe('text helpers', () => {
    it('builds the contract strings', () => {
      expect(previewWatermarkText('Asha Rao')).toBe(
        'SketchSquare • Asha Rao • PREVIEW',
      );
      expect(licenseFooterText('Ravi', 'abc')).toBe(
        'Licensed to Ravi • abc • SketchSquare',
      );
    });

    it('keeps WinAnsi text and replaces unsupported characters', () => {
      expect(toWinAnsi('José • Nuñez')).toBe('José • Nuñez');
      expect(toWinAnsi('राहुल')).toBe('?????');
    });
  });

  describe('renderImagePreview', () => {
    it('downscales to 1600px on the long edge and adds a visible watermark', async () => {
      const svc = makeService();
      const input = await solidPng(3200, 2000);
      const { base, watermarked } = await svc.renderImagePreview(
        input,
        'Asha Rao',
      );
      const meta = await sharp(watermarked).metadata();
      expect(meta.format).toBe('png');
      expect(meta.width).toBe(1600);
      expect(meta.height).toBe(1000);
      expect(Buffer.compare(base, watermarked)).not.toBe(0);
      const a = await sharp(base).raw().toBuffer();
      const b = await sharp(watermarked).raw().toBuffer();
      let changed = 0;
      for (let i = 0; i < a.length; i += 3) if (a[i] !== b[i]) changed++;
      expect(changed).toBeGreaterThan(500);
    });

    it('never upscales small images and flattens transparency', async () => {
      const svc = makeService();
      const input = await sharp({
        create: {
          width: 300,
          height: 200,
          channels: 4,
          background: { r: 0, g: 0, b: 0, alpha: 0 },
        },
      })
        .png()
        .toBuffer();
      const { watermarked } = await svc.renderImagePreview(input, 'A');
      const meta = await sharp(watermarked).metadata();
      expect([meta.width, meta.height]).toEqual([300, 200]);
      expect(meta.hasAlpha).toBe(false);
    });
  });

  (hasPdftoppm ? describe : describe.skip)('renderPdfPreview', () => {
    it('renders page 1 of a PDF as a watermarked PNG within 1600px', async () => {
      const svc = makeService();
      const { watermarked } = await svc.renderPdfPreview(
        await makePdf(2),
        'Asha Rao',
      );
      const meta = await sharp(watermarked).metadata();
      expect(meta.format).toBe('png');
      expect(Math.max(meta.width, meta.height)).toBeLessThanOrEqual(1600);
    });

    it('fails clearly for a corrupt PDF', async () => {
      await expect(
        makeService().renderPdfPreview(Buffer.from('not a pdf'), 'A'),
      ).rejects.toThrow(/could not be rendered/);
    });
  });

  describe('applyBuyerWatermark', () => {
    it('stamps the license footer on every PDF page', async () => {
      const svc = makeService();
      const pdf = await makePdf(3);
      const { buffer, contentType } = await svc.applyBuyerWatermark(
        pdf,
        'application/pdf',
        'Ravi Kumar',
        'purchase-123',
      );
      expect(contentType).toBe('application/pdf');
      const reloaded = await PDFDocument.load(buffer);
      expect(reloaded.getPageCount()).toBe(3);
      const content = inflatedStreams(buffer);
      const occurrences =
        content.split(hex('Licensed to Ravi Kumar')).length - 1;
      expect(occurrences).toBeGreaterThanOrEqual(3);
      expect(buffer.length).toBeGreaterThan(pdf.length);
    });

    it('adds a footer strip below PNG and keeps JPEG as JPEG', async () => {
      const svc = makeService();
      const png = await solidPng(1000, 600);
      const out = await svc.applyBuyerWatermark(
        png,
        'image/png',
        'Ravi',
        'p-1',
      );
      const meta = await sharp(out.buffer).metadata();
      expect(meta.format).toBe('png');
      expect(meta.width).toBe(1000);
      expect(meta.height).toBeGreaterThan(600);

      const jpg = await sharp(png).jpeg().toBuffer();
      const outJpg = await svc.applyBuyerWatermark(
        jpg,
        'image/jpeg',
        'Ravi',
        'p-1',
      );
      expect((await sharp(outJpg.buffer).metadata()).format).toBe('jpeg');
    });

    it('passes DWG/DXF through untouched', async () => {
      const svc = makeService();
      const dwg = Buffer.from('AC1027binary');
      const out = await svc.applyBuyerWatermark(dwg, 'image/vnd.dwg', 'R', 'p');
      expect(out.buffer).toBe(dwg);
      expect(out.contentType).toBe('image/vnd.dwg');
    });
  });

  describe('ensureBuyerCopy', () => {
    const input = {
      licenseRef: 'purchase-1',
      buyerName: 'Ravi',
      sheetId: 'sheet-1',
      originalKey: 'drawings/d1/s1/plan.png',
      originalMime: 'image/png',
      fileName: 'plan 1.png',
    };

    it('generates once, then serves the cached object', async () => {
      const stored = new Map<string, Buffer>();
      const original = await solidPng(400, 300);
      const storage = {
        originalsObjectExists: jest.fn((k: string) =>
          Promise.resolve(stored.has(k)),
        ),
        getOriginalBuffer: jest.fn(() => Promise.resolve(original)),
        putOriginal: jest.fn((k: string, b: Buffer) => {
          stored.set(k, b);
          return Promise.resolve();
        }),
      };
      const svc = makeService(storage);

      const first = await svc.ensureBuyerCopy(input);
      const second = await svc.ensureBuyerCopy(input);

      expect(first.key).toBe('licensed/purchase-1/sheet-1/plan_1.png');
      expect(second).toEqual(first);
      expect(storage.getOriginalBuffer).toHaveBeenCalledTimes(1);
      expect(storage.putOriginal).toHaveBeenCalledTimes(1);
      expect(stored.get(first.key)!.equals(original)).toBe(false);
    });

    it('rejects unsafe license references', async () => {
      await expect(
        makeService().ensureBuyerCopy({ ...input, licenseRef: '../x' }),
      ).rejects.toThrow(/URL-safe/);
    });
  });
});
