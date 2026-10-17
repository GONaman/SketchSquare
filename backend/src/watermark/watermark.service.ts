import { Injectable } from '@nestjs/common';
import { execFile } from 'node:child_process';
import { mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { promisify } from 'node:util';
import { PDFDocument, StandardFonts, rgb } from 'pdf-lib';
import sharp from 'sharp';
import { StorageService } from '../storage/storage.service';

const execFileAsync = promisify(execFile);

export const PREVIEW_MAX_EDGE_PX = 1600;
const PREVIEW_WATERMARK_OPACITY = 0.15;
const PDF_RENDER_TIMEOUT_MS = 60_000;

export const MIME_PDF = 'application/pdf';
export const MIME_PNG = 'image/png';
export const MIME_JPEG = 'image/jpeg';

export interface BuyerCopyInput {
  /** Stable reference used for the cache key and printed in the footer (purchase id, or a free-download reference). */
  licenseRef: string;
  buyerName: string;
  sheetId: string;
  originalKey: string;
  originalMime: string;
  fileName: string;
}

export interface BuyerCopy {
  key: string;
  fileName: string;
  contentType: string;
}

export interface PreviewResult {
  /** Downscaled but un-watermarked PNG; only used to compute the perceptual hash, never stored. */
  base: Buffer;
  /** Watermarked, downscaled PNG that is safe to expose publicly. */
  watermarked: Buffer;
}

export function escapeXml(text: string): string {
  return text
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&apos;');
}

/** pdf-lib's standard fonts only encode WinAnsi (Latin-1 + a few symbols such as the bullet). */
export function toWinAnsi(text: string): string {
  return Array.from(text.normalize('NFC'))
    .map((ch) => {
      const cp = ch.codePointAt(0) ?? 63;
      return cp === 0x2022 ||
        (cp >= 32 && cp <= 126) ||
        (cp >= 161 && cp <= 255)
        ? ch
        : '?';
    })
    .join('');
}

export function previewWatermarkText(architectName: string): string {
  return `SketchSquare • ${architectName} • PREVIEW`;
}

export function licenseFooterText(
  buyerName: string,
  licenseRef: string,
): string {
  return `Licensed to ${buyerName} • ${licenseRef} • SketchSquare`;
}

/** Transparent SVG with the text tiled on a -30° diagonal grid, sized exactly to the target image. */
function tiledWatermarkSvg(
  width: number,
  height: number,
  text: string,
): Buffer {
  const fontSize = Math.max(14, Math.round(Math.min(width, height) / 38));
  const tileW = Math.round(text.length * fontSize * 0.62 + fontSize * 3);
  const tileH = Math.round(fontSize * 5);
  const label = escapeXml(text);
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}">
  <defs>
    <pattern id="wm" width="${tileW}" height="${tileH}" patternUnits="userSpaceOnUse" patternTransform="rotate(-30)">
      <text x="0" y="${fontSize * 2}" font-family="DejaVu Sans, Helvetica, Arial, sans-serif" font-size="${fontSize}" font-weight="bold"
        fill="#ffffff" stroke="#ffffff" stroke-width="2" opacity="${PREVIEW_WATERMARK_OPACITY}">${label}</text>
      <text x="0" y="${fontSize * 2}" font-family="DejaVu Sans, Helvetica, Arial, sans-serif" font-size="${fontSize}" font-weight="bold"
        fill="#000000" opacity="${PREVIEW_WATERMARK_OPACITY + 0.05}">${label}</text>
    </pattern>
  </defs>
  <rect width="100%" height="100%" fill="url(#wm)"/>
</svg>`;
  return Buffer.from(svg);
}

@Injectable()
export class WatermarkService {
  constructor(private readonly storage: StorageService) {}

  /** Image preview: downscale to 1600px long edge, flatten alpha, tile the diagonal watermark. */
  async renderImagePreview(
    image: Buffer,
    architectName: string,
  ): Promise<PreviewResult> {
    const base = await sharp(image)
      .rotate()
      .flatten({ background: '#ffffff' })
      .resize(PREVIEW_MAX_EDGE_PX, PREVIEW_MAX_EDGE_PX, {
        fit: 'inside',
        withoutEnlargement: true,
      })
      .png()
      .toBuffer();
    const { width, height } = await sharp(base).metadata();
    const watermarked = await sharp(base)
      .composite([
        {
          input: tiledWatermarkSvg(
            width,
            height,
            previewWatermarkText(architectName),
          ),
          top: 0,
          left: 0,
        },
      ])
      .removeAlpha()
      .png()
      .toBuffer();
    return { base, watermarked };
  }

  /** PDF preview: poppler renders page 1 (already scaled to fit 1600px), then the image pipeline applies the watermark. */
  async renderPdfPreview(
    pdf: Buffer,
    architectName: string,
  ): Promise<PreviewResult> {
    const page = await this.renderPdfFirstPage(pdf);
    return this.renderImagePreview(page, architectName);
  }

  async renderPdfFirstPage(pdf: Buffer): Promise<Buffer> {
    const dir = await mkdtemp(join(tmpdir(), 'sketchsquare-pdf-'));
    try {
      const input = join(dir, 'in.pdf');
      const outPrefix = join(dir, 'page');
      await writeFile(input, pdf);
      await execFileAsync(
        'pdftoppm',
        [
          '-png',
          '-singlefile',
          '-f',
          '1',
          '-l',
          '1',
          '-scale-to',
          String(PREVIEW_MAX_EDGE_PX),
          input,
          outPrefix,
        ],
        { timeout: PDF_RENDER_TIMEOUT_MS },
      );
      return await readFile(`${outPrefix}.png`);
    } catch (err) {
      const e = err as NodeJS.ErrnoException;
      if (e.code === 'ENOENT') {
        throw new Error(
          'PDF rendering is unavailable on the server (pdftoppm / poppler-utils is not installed)',
        );
      }
      throw new Error('The PDF could not be rendered (corrupt or encrypted?)');
    } finally {
      await rm(dir, { recursive: true, force: true });
    }
  }

  /** PDF: footer on every page. Images: footer strip. DWG/DXF and anything else pass through unchanged. */
  async applyBuyerWatermark(
    original: Buffer,
    mime: string,
    buyerName: string,
    licenseRef: string,
  ): Promise<{ buffer: Buffer; contentType: string }> {
    const footer = licenseFooterText(buyerName, licenseRef);
    if (mime === MIME_PDF) {
      return {
        buffer: await this.footerPdf(original, footer),
        contentType: mime,
      };
    }
    if (mime === MIME_PNG || mime === MIME_JPEG) {
      return {
        buffer: await this.footerImage(original, mime, footer),
        contentType: mime,
      };
    }
    return { buffer: original, contentType: mime };
  }

  private async footerPdf(pdf: Buffer, footer: string): Promise<Buffer> {
    const doc = await PDFDocument.load(pdf);
    const font = await doc.embedFont(StandardFonts.Helvetica);
    const text = toWinAnsi(footer);
    for (const page of doc.getPages()) {
      const { width } = page.getSize();
      const size = Math.min(9, Math.max(5, width / 90));
      page.drawText(text, {
        x: Math.max(8, (width - font.widthOfTextAtSize(text, size)) / 2),
        y: 8,
        size,
        font,
        color: rgb(0.35, 0.35, 0.35),
      });
    }
    return Buffer.from(await doc.save());
  }

  private async footerImage(
    image: Buffer,
    mime: string,
    footer: string,
  ): Promise<Buffer> {
    const rotated = await sharp(image).rotate().toBuffer();
    const { width, height } = await sharp(rotated).metadata();
    const stripH = Math.max(28, Math.round(width * 0.03));
    const fontSize = Math.round(stripH * 0.55);
    const svg = Buffer.from(
      `<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${stripH}">
  <rect width="100%" height="100%" fill="#ffffff"/>
  <text x="${width / 2}" y="${Math.round(stripH * 0.68)}" text-anchor="middle" font-family="DejaVu Sans, Helvetica, Arial, sans-serif"
    font-size="${fontSize}" fill="#444444">${escapeXml(footer)}</text>
</svg>`,
    );
    const out = sharp(rotated)
      .flatten({ background: '#ffffff' })
      .extend({ bottom: stripH, background: '#ffffff' })
      .composite([{ input: svg, top: height, left: 0 }]);
    return mime === MIME_JPEG
      ? out.jpeg({ quality: 92 }).toBuffer()
      : out.png().toBuffer();
  }

  /**
   * Returns the key (in the private originals bucket) of the buyer-specific copy, generating it on first use
   * and reusing the cached object afterwards. Callers presign the returned key for the 5-minute download link.
   */
  async ensureBuyerCopy(input: BuyerCopyInput): Promise<BuyerCopy> {
    if (!/^[A-Za-z0-9_-]{1,80}$/.test(input.licenseRef)) {
      throw new Error('licenseRef must be URL-safe');
    }
    const safeName = input.fileName.replace(/[^A-Za-z0-9._-]/g, '_');
    const key = `licensed/${input.licenseRef}/${input.sheetId}/${safeName}`;
    const contentType = input.originalMime;
    if (await this.storage.originalsObjectExists(key)) {
      return { key, fileName: input.fileName, contentType };
    }
    const original = await this.storage.getOriginalBuffer(input.originalKey);
    const copy = await this.applyBuyerWatermark(
      original,
      input.originalMime,
      input.buyerName,
      input.licenseRef,
    );
    await this.storage.putOriginal(key, copy.buffer, copy.contentType);
    return { key, fileName: input.fileName, contentType };
  }
}
