import sharp from 'sharp';
import { hammingDistance, perceptualHash } from './phash';

async function pattern(
  width: number,
  height: number,
  kind: 'a' | 'b',
): Promise<Buffer> {
  const shapes =
    kind === 'a'
      ? `<rect x="${width * 0.1}" y="${height * 0.1}" width="${width * 0.5}" height="${height * 0.3}" fill="#000"/>
         <circle cx="${width * 0.75}" cy="${height * 0.7}" r="${height * 0.2}" fill="#444"/>`
      : `<rect x="${width * 0.5}" y="${height * 0.55}" width="${width * 0.4}" height="${height * 0.35}" fill="#000"/>
         <rect x="${width * 0.05}" y="${height * 0.05}" width="${width * 0.2}" height="${height * 0.6}" fill="#888"/>`;
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}">
    <rect width="100%" height="100%" fill="#fff"/>${shapes}</svg>`;
  return sharp(Buffer.from(svg)).png().toBuffer();
}

describe('perceptualHash', () => {
  it('returns 16 hex chars and is deterministic', async () => {
    const img = await pattern(400, 300, 'a');
    const h = await perceptualHash(img);
    expect(h).toMatch(/^[0-9a-f]{16}$/);
    expect(await perceptualHash(img)).toBe(h);
  });

  it('is stable under rescaling and re-encoding', async () => {
    const big = await pattern(1200, 900, 'a');
    const small = await sharp(big)
      .resize(300, 225)
      .jpeg({ quality: 60 })
      .toBuffer();
    const d = hammingDistance(
      await perceptualHash(big),
      await perceptualHash(small),
    );
    expect(d).toBeLessThanOrEqual(6);
  });

  it('differs substantially for unrelated drawings', async () => {
    const d = hammingDistance(
      await perceptualHash(await pattern(400, 300, 'a')),
      await perceptualHash(await pattern(400, 300, 'b')),
    );
    expect(d).toBeGreaterThan(8);
  });
});

describe('hammingDistance', () => {
  it('counts differing bits', () => {
    expect(hammingDistance('0000000000000000', '0000000000000000')).toBe(0);
    expect(hammingDistance('0000000000000000', 'ffffffffffffffff')).toBe(64);
    expect(hammingDistance('0000000000000001', '0000000000000003')).toBe(1);
  });
});
