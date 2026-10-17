import sharp from 'sharp';

const HASH_SIDE = 32;
const LOW_FREQ = 8;

// Precomputed DCT-II basis: COS[u][x] = cos((2x + 1) * u * PI / (2N))
const COS: number[][] = Array.from({ length: LOW_FREQ }, (_, u) =>
  Array.from({ length: HASH_SIDE }, (_, x) =>
    Math.cos(((2 * x + 1) * u * Math.PI) / (2 * HASH_SIDE)),
  ),
);

/**
 * 64-bit perceptual hash (DCT pHash) of an image as 16 lowercase hex chars.
 * Greyscale 32x32 -> 2D DCT -> top-left 8x8 low frequencies -> bit = coefficient > median (DC excluded from the median).
 */
export async function perceptualHash(image: Buffer): Promise<string> {
  const { data } = await sharp(image)
    .rotate()
    .flatten({ background: '#ffffff' })
    .greyscale()
    .resize(HASH_SIDE, HASH_SIDE, { fit: 'fill' })
    .raw()
    .toBuffer({ resolveWithObject: true });

  // Separable DCT: rows first, then columns, keeping only the 8x8 low-frequency block.
  const rows: number[][] = Array.from({ length: HASH_SIDE }, () =>
    new Array<number>(LOW_FREQ).fill(0),
  );
  for (let y = 0; y < HASH_SIDE; y++) {
    for (let u = 0; u < LOW_FREQ; u++) {
      let sum = 0;
      for (let x = 0; x < HASH_SIDE; x++)
        sum += data[y * HASH_SIDE + x] * COS[u][x];
      rows[y][u] = sum;
    }
  }
  const coeffs: number[] = [];
  for (let v = 0; v < LOW_FREQ; v++) {
    for (let u = 0; u < LOW_FREQ; u++) {
      let sum = 0;
      for (let y = 0; y < HASH_SIDE; y++) sum += rows[y][u] * COS[v][y];
      coeffs.push(sum);
    }
  }

  const sorted = coeffs.slice(1).sort((a, b) => a - b);
  const median = (sorted[31] + sorted[32]) / 2;
  let bits = 0n;
  for (const c of coeffs) bits = (bits << 1n) | (c > median ? 1n : 0n);
  return bits.toString(16).padStart(16, '0');
}

export function hammingDistance(a: string, b: string): number {
  let x = BigInt(`0x${a}`) ^ BigInt(`0x${b}`);
  let count = 0;
  while (x > 0n) {
    count += Number(x & 1n);
    x >>= 1n;
  }
  return count;
}
