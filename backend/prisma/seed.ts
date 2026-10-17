import 'dotenv/config';
import { PutObjectCommand, S3Client } from '@aws-sdk/client-s3';
import { DrawingStatus, Facing, PrismaClient, SheetType } from '@prisma/client';
import * as argon2 from 'argon2';
import { createHash } from 'node:crypto';
import sharp from 'sharp';
import { validateEnv } from '../src/config/env.schema';

/**
 * Idempotent dev seed: safe to re-run (everything is keyed by deterministic ids / unique fields).
 * Credentials are documented in prisma/README-seed.md.
 */

const env = validateEnv(process.env);
const prisma = new PrismaClient();
const s3 = new S3Client({
  endpoint: env.S3_ENDPOINT,
  region: env.S3_REGION,
  forcePathStyle: env.S3_FORCE_PATH_STYLE,
  credentials: {
    accessKeyId: env.S3_ACCESS_KEY_ID,
    secretAccessKey: env.S3_SECRET_ACCESS_KEY,
  },
});

export const SEED_ADMIN = {
  email: 'admin@sketchsquare.local',
  password: 'Admin@12345',
};
export const SEED_ARCHITECT_PASSWORD = 'Architect@123';

/** Stable UUID derived from a label so re-runs update rows instead of duplicating them. */
function uid(label: string): string {
  const h = createHash('sha1').update(`sketchsquare-seed:${label}`).digest();
  h[6] = (h[6] & 0x0f) | 0x50;
  h[8] = (h[8] & 0x3f) | 0x80;
  const x = h.subarray(0, 16).toString('hex');
  return `${x.slice(0, 8)}-${x.slice(8, 12)}-${x.slice(12, 16)}-${x.slice(16, 20)}-${x.slice(20)}`;
}

const CATEGORIES = [
  'Houses',
  'Villas',
  'Hotels',
  'Shopping Complex',
  'Banks',
  'Government Buildings',
];
const slugify = (s: string) => s.toLowerCase().replace(/[^a-z0-9]+/g, '-');

const ARCHITECTS = [
  {
    key: 'arch-bengaluru',
    email: 'anita.rao@sketchsquare.local',
    fullName: 'Anita Rao',
    city: 'Bengaluru',
    phone: '+919800000001',
    address: '12 MG Road, Bengaluru 560001',
    coa: 'CA/2012/10001',
  },
  {
    key: 'arch-delhi',
    email: 'vikram.malhotra@sketchsquare.local',
    fullName: 'Vikram Malhotra',
    city: 'Delhi',
    phone: '+919800000002',
    address: '48 Connaught Place, New Delhi 110001',
    coa: 'CA/2009/20002',
  },
  {
    key: 'arch-jaipur',
    email: 'meera.shekhawat@sketchsquare.local',
    fullName: 'Meera Shekhawat',
    city: 'Jaipur',
    phone: '+919800000003',
    address: '7 C-Scheme, Jaipur 302001',
    coa: 'CA/2015/30003',
  },
];

interface DrawingSeed {
  key: string;
  architect: number;
  category: string;
  title: string;
  description: string;
  length: number;
  breadth: number;
  floors: number;
  facing: Facing;
  priceRupees: number;
  sheets: { type: SheetType; preview: boolean }[];
}

const A = SheetType.ARCHITECTURAL;
const S = SheetType.STRUCTURAL;
const E = SheetType.ELECTRICAL;
const P = SheetType.PLUMBING;
const SAN = SheetType.SANITARY;

const DRAWINGS: DrawingSeed[] = [
  {
    key: 'house-20x30',
    architect: 0,
    category: 'Houses',
    title: 'Compact 2BHK Family Home',
    description:
      'Efficient two-bedroom home on a 20x30 ft site with a ground-floor parking bay, open kitchen and a terrace garden.',
    length: 20,
    breadth: 30,
    floors: 2,
    facing: Facing.E,
    priceRupees: 999,
    sheets: [
      { type: A, preview: true },
      { type: S, preview: false },
    ],
  },
  {
    key: 'house-30x40',
    architect: 0,
    category: 'Houses',
    title: 'Vastu 3BHK East Facing House',
    description:
      'Vastu-compliant 3BHK plan for a 30x40 ft plot with pooja room, double-height living area and a sit-out.',
    length: 30,
    breadth: 40,
    floors: 2,
    facing: Facing.E,
    priceRupees: 1999,
    sheets: [
      { type: A, preview: true },
      { type: S, preview: false },
      { type: E, preview: false },
    ],
  },
  {
    key: 'house-30x50-free',
    architect: 1,
    category: 'Houses',
    title: 'Starter Home Plan (Free)',
    description:
      'Free starter plan for a 30x50 ft plot: three bedrooms, spacious living room and a rear courtyard.',
    length: 30,
    breadth: 50,
    floors: 1,
    facing: Facing.N,
    priceRupees: 0,
    sheets: [{ type: A, preview: true }],
  },
  {
    key: 'house-40x60',
    architect: 1,
    category: 'Houses',
    title: 'Modern 4BHK Duplex',
    description:
      'Contemporary duplex on a 40x60 ft plot with a double-height foyer, home office and a rooftop deck.',
    length: 40,
    breadth: 60,
    floors: 3,
    facing: Facing.N,
    priceRupees: 4999,
    sheets: [
      { type: A, preview: true },
      { type: S, preview: true },
      { type: E, preview: false },
      { type: P, preview: false },
    ],
  },
  {
    key: 'house-25x45-free',
    architect: 2,
    category: 'Houses',
    title: 'Courtyard House Concept (Free)',
    description:
      'Free concept sheet for a narrow 25x45 ft plot built around a central courtyard for light and ventilation.',
    length: 25,
    breadth: 45,
    floors: 2,
    facing: Facing.S,
    priceRupees: 0,
    sheets: [{ type: A, preview: true }],
  },
  {
    key: 'villa-50x80',
    architect: 2,
    category: 'Villas',
    title: 'Rajasthani Heritage Villa',
    description:
      'Jaali screens, an inner courtyard and a sandstone facade define this 50x80 ft villa with a private pool.',
    length: 50,
    breadth: 80,
    floors: 2,
    facing: Facing.W,
    priceRupees: 14999,
    sheets: [
      { type: A, preview: true },
      { type: S, preview: false },
      { type: E, preview: false },
      { type: SAN, preview: false },
    ],
  },
  {
    key: 'villa-60x90',
    architect: 0,
    category: 'Villas',
    title: 'Tropical Luxury Villa with Pool',
    description:
      'Five-bedroom tropical villa on 60x90 ft with a infinity pool, outdoor kitchen and landscaped deck.',
    length: 60,
    breadth: 90,
    floors: 2,
    facing: Facing.SE,
    priceRupees: 24999,
    sheets: [
      { type: A, preview: true },
      { type: S, preview: true },
      { type: E, preview: false },
    ],
  },
  {
    key: 'villa-40x60-free',
    architect: 1,
    category: 'Villas',
    title: 'Weekend Villa Sketch (Free)',
    description:
      'Free sketch of a relaxed weekend villa on a 40x60 ft plot with verandah and open-plan living.',
    length: 40,
    breadth: 60,
    floors: 1,
    facing: Facing.NE,
    priceRupees: 0,
    sheets: [{ type: A, preview: true }],
  },
  {
    key: 'hotel-100x150',
    architect: 1,
    category: 'Hotels',
    title: '3-Star Business Hotel, 60 Rooms',
    description:
      'Complete schematic set for a 60-room business hotel with banquet hall, restaurant and basement parking.',
    length: 100,
    breadth: 150,
    floors: 6,
    facing: Facing.N,
    priceRupees: 59999,
    sheets: [
      { type: A, preview: true },
      { type: S, preview: false },
      { type: E, preview: false },
      { type: SheetType.HVAC, preview: false },
    ],
  },
  {
    key: 'hotel-80x120',
    architect: 2,
    category: 'Hotels',
    title: 'Boutique Heritage Resort',
    description:
      'Twenty-four key boutique resort around a central lawn, designed in the regional heritage idiom.',
    length: 80,
    breadth: 120,
    floors: 2,
    facing: Facing.E,
    priceRupees: 39999,
    sheets: [
      { type: A, preview: true },
      { type: P, preview: false },
    ],
  },
  {
    key: 'shop-60x100',
    architect: 0,
    category: 'Shopping Complex',
    title: 'Neighbourhood Retail Complex',
    description:
      'Ground plus two retail arcade with 18 shops, anchor store, food court and two-level parking.',
    length: 60,
    breadth: 100,
    floors: 3,
    facing: Facing.S,
    priceRupees: 19999,
    sheets: [
      { type: A, preview: true },
      { type: S, preview: false },
      { type: E, preview: false },
    ],
  },
  {
    key: 'shop-30x60-free',
    architect: 2,
    category: 'Shopping Complex',
    title: 'Corner Showroom Layout (Free)',
    description:
      'Free layout of a double-height corner showroom on a 30x60 ft plot with a mezzanine office.',
    length: 30,
    breadth: 60,
    floors: 2,
    facing: Facing.NW,
    priceRupees: 0,
    sheets: [{ type: A, preview: true }],
  },
  {
    key: 'bank-40x70',
    architect: 1,
    category: 'Banks',
    title: 'Branch Bank with Vault',
    description:
      'Standard retail bank branch on a 40x70 ft plot: banking hall, strong room, manager cabins and ATM lobby.',
    length: 40,
    breadth: 70,
    floors: 2,
    facing: Facing.W,
    priceRupees: 7999,
    sheets: [
      { type: A, preview: true },
      { type: S, preview: false },
    ],
  },
  {
    key: 'gov-100x200',
    architect: 0,
    category: 'Government Buildings',
    title: 'Tehsil Office Complex',
    description:
      'Administrative block for a tehsil office with record room, courtroom, public counters and ramped access.',
    length: 100,
    breadth: 200,
    floors: 3,
    facing: Facing.N,
    priceRupees: 34999,
    sheets: [
      { type: A, preview: true },
      { type: S, preview: false },
      { type: SAN, preview: false },
    ],
  },
  {
    key: 'gov-70x110',
    architect: 2,
    category: 'Government Buildings',
    title: 'Primary Health Centre',
    description:
      'Single-storey primary health centre with OPD, labour room, pharmacy and staff quarters on a 70x110 ft site.',
    length: 70,
    breadth: 110,
    floors: 1,
    facing: Facing.SW,
    priceRupees: 9999,
    sheets: [
      { type: A, preview: true },
      { type: P, preview: false },
    ],
  },
];

const escapeXml = (s: string) =>
  s.replace(/[<>&'"]/g, (c) => `&#${c.charCodeAt(0)};`);

/** A simple floor-plan-looking placeholder whose plot rectangle matches the drawing's aspect ratio. */
async function renderPlaceholder(
  d: DrawingSeed,
  sheetType: SheetType,
  watermark: string | null,
  width: number,
): Promise<Buffer> {
  const w = 1600;
  const h = 1200;
  const pad = 160;
  const ratio = d.breadth / d.length;
  let pw = w - pad * 2;
  let ph = pw / ratio;
  if (ph > h - pad * 2) {
    ph = h - pad * 2;
    pw = ph * ratio;
  }
  const x = (w - pw) / 2;
  const y = (h - ph) / 2 + 20;
  const hue = (createHash('md5').update(d.key).digest()[0] * 360) / 255;
  const rooms: string[] = [];
  const cols = 3;
  const rows = 2;
  for (let r = 0; r < rows; r++) {
    for (let c = 0; c < cols; c++) {
      rooms.push(
        `<rect x="${x + (pw / cols) * c}" y="${y + (ph / rows) * r}" width="${pw / cols}" height="${ph / rows}" fill="none" stroke="#2a3a4a" stroke-width="3"/>`,
      );
    }
  }
  const wm = watermark
    ? Array.from({ length: 6 }, (_, i) =>
        Array.from(
          { length: 3 },
          (_, j) =>
            `<text x="${i * 340 - 120}" y="${j * 420 + 200}" transform="rotate(-30 ${i * 340} ${j * 420})" font-size="34" font-family="sans-serif" fill="#000" fill-opacity="0.15">${escapeXml(watermark)}</text>`,
        ).join(''),
      ).join('')
    : '';
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}">
    <rect width="100%" height="100%" fill="hsl(${hue.toFixed(0)},35%,96%)"/>
    <rect x="${x}" y="${y}" width="${pw}" height="${ph}" fill="hsl(${hue.toFixed(0)},40%,88%)" stroke="#12202e" stroke-width="8"/>
    ${rooms.join('')}
    <text x="${w / 2}" y="90" text-anchor="middle" font-size="54" font-family="sans-serif" fill="#12202e">${escapeXml(d.title)}</text>
    <text x="${w / 2}" y="140" text-anchor="middle" font-size="34" font-family="sans-serif" fill="#445">${d.length} x ${d.breadth} ft · ${sheetType}</text>
    ${wm}
  </svg>`;
  return sharp(Buffer.from(svg)).resize({ width }).png().toBuffer();
}

/** 64-bit difference hash as 16 hex chars. */
async function dHash(png: Buffer): Promise<string> {
  const px = await sharp(png)
    .grayscale()
    .resize(9, 8, { fit: 'fill' })
    .raw()
    .toBuffer();
  let bits = '';
  for (let r = 0; r < 8; r++) {
    for (let c = 0; c < 8; c++) {
      bits += px[r * 9 + c] > px[r * 9 + c + 1] ? '1' : '0';
    }
  }
  return BigInt('0b' + bits)
    .toString(16)
    .padStart(16, '0');
}

async function put(bucket: string, key: string, body: Buffer, mime: string) {
  await s3.send(
    new PutObjectCommand({
      Bucket: bucket,
      Key: key,
      Body: body,
      ContentType: mime,
    }),
  );
}

async function main() {
  console.log('Seeding SketchSquare dev data…');

  const categories = new Map<string, string>();
  for (const name of CATEGORIES) {
    const c = await prisma.category.upsert({
      where: { slug: slugify(name) },
      update: { name, isActive: true },
      create: { id: uid(`cat:${name}`), name, slug: slugify(name) },
    });
    categories.set(name, c.id);
  }

  const adminHash = await argon2.hash(SEED_ADMIN.password, {
    type: argon2.argon2id,
  });
  await prisma.user.upsert({
    where: { email: SEED_ADMIN.email },
    update: {},
    create: {
      id: uid('admin'),
      email: SEED_ADMIN.email,
      passwordHash: adminHash,
      fullName: 'SketchSquare Admin',
      address: 'SketchSquare HQ, Bengaluru',
      phone: '+919800000000',
      city: 'Bengaluru',
      role: 'ADMIN',
      verificationStatus: 'APPROVED',
    },
  });

  const archHash = await argon2.hash(SEED_ARCHITECT_PASSWORD, {
    type: argon2.argon2id,
  });
  const architectIds: string[] = [];
  for (const a of ARCHITECTS) {
    const id = uid(a.key);
    architectIds.push(id);
    await prisma.user.upsert({
      where: { email: a.email },
      update: {},
      create: {
        id,
        email: a.email,
        passwordHash: archHash,
        fullName: a.fullName,
        address: a.address,
        phone: a.phone,
        city: a.city,
        verificationStatus: 'APPROVED',
      },
    });
    await put(
      env.S3_BUCKET_KYC,
      `verification/${id}/coa-certificate.png`,
      await sharp({
        create: {
          width: 400,
          height: 300,
          channels: 3,
          background: '#dfe6ee',
        },
      })
        .png()
        .toBuffer(),
      'image/png',
    );
    await prisma.verificationRequest.upsert({
      where: { id: uid(`verify:${a.key}`) },
      update: {},
      create: {
        id: uid(`verify:${a.key}`),
        userId: id,
        coaRegistrationNumber: a.coa,
        documentKey: `verification/${id}/coa-certificate.png`,
        status: 'APPROVED',
        reviewerId: uid('admin'),
        reviewedAt: new Date(),
      },
    });
  }

  // A pending architect so the admin verification queue is not empty.
  const pendingId = uid('arch-pending');
  await prisma.user.upsert({
    where: { email: 'rohan.pending@sketchsquare.local' },
    update: {},
    create: {
      id: pendingId,
      email: 'rohan.pending@sketchsquare.local',
      passwordHash: archHash,
      fullName: 'Rohan Pending',
      address: '3 Park Street, Kolkata 700016',
      phone: '+919800000004',
      city: 'Kolkata',
      verificationStatus: 'PENDING',
    },
  });
  await prisma.verificationRequest.upsert({
    where: { id: uid('verify:pending') },
    update: {},
    create: {
      id: uid('verify:pending'),
      userId: pendingId,
      coaRegistrationNumber: 'CA/2020/40004',
      documentKey: `verification/${pendingId}/coa-certificate.png`,
    },
  });
  await put(
    env.S3_BUCKET_KYC,
    `verification/${pendingId}/coa-certificate.png`,
    await sharp({
      create: { width: 400, height: 300, channels: 3, background: '#eee' },
    })
      .png()
      .toBuffer(),
    'image/png',
  );

  for (const d of DRAWINGS) {
    const drawingId = uid(`drawing:${d.key}`);
    const architect = ARCHITECTS[d.architect];
    const architectId = architectIds[d.architect];
    const data = {
      architectId,
      categoryId: categories.get(d.category)!,
      title: d.title,
      description: d.description,
      city: architect.city,
      plotLengthFt: d.length,
      plotBreadthFt: d.breadth,
      floors: d.floors,
      facing: d.facing,
      pricePaise: d.priceRupees * 100,
      status: DrawingStatus.PUBLISHED,
    };
    await prisma.drawing.upsert({
      where: { id: drawingId },
      update: data,
      create: { id: drawingId, ...data },
    });

    for (const [i, sheet] of d.sheets.entries()) {
      const sheetId = uid(`sheet:${d.key}:${i}`);
      const original = await renderPlaceholder(d, sheet.type, null, 1600);
      const originalKey = `drawings/${drawingId}/${sheetId}.png`;
      await put(env.S3_BUCKET_ORIGINALS, originalKey, original, 'image/png');

      let previewKey: string | null = null;
      let pHash: string | null = null;
      if (sheet.preview) {
        const preview = await renderPlaceholder(
          d,
          sheet.type,
          `SketchSquare • ${architect.fullName} • PREVIEW`,
          1000,
        );
        previewKey = `drawings/${drawingId}/preview-${sheetId}.png`;
        await put(env.S3_BUCKET_PREVIEWS, previewKey, preview, 'image/png');
        pHash = await dHash(preview);
      }
      const sheetData = {
        drawingId,
        type: sheet.type,
        originalKey,
        originalMime: 'image/png',
        fileName: `${slugify(d.title)}-${sheet.type.toLowerCase()}.png`,
        sizeBytes: original.length,
        isPreview: sheet.preview,
        previewKey,
        pHash,
        sha256: createHash('sha256').update(original).digest('hex'),
      };
      await prisma.drawingSheet.upsert({
        where: { id: sheetId },
        update: sheetData,
        create: { id: sheetId, ...sheetData },
      });
    }
  }

  // Free drawings get downloads + reviews from the other architects so ratings are populated.
  const comments = [
    'Very clear layout, easy to adapt to our plot.',
    'Good use of space; the sections are well annotated.',
    'Solid starting point for a client presentation.',
  ];
  const freeDrawings = DRAWINGS.filter((d) => d.priceRupees === 0);
  for (const d of freeDrawings) {
    const drawingId = uid(`drawing:${d.key}`);
    const reviewers = architectIds.filter((_, i) => i !== d.architect);
    for (const [i, buyerId] of reviewers.entries()) {
      await prisma.freeDownload.upsert({
        where: { userId_drawingId: { userId: buyerId, drawingId } },
        update: {},
        create: { userId: buyerId, drawingId },
      });
      const rating = 4 + ((i + d.length) % 2);
      await prisma.review.upsert({
        where: { buyerId_drawingId: { buyerId, drawingId } },
        update: { rating, comment: comments[(i + d.length) % comments.length] },
        create: {
          buyerId,
          drawingId,
          rating,
          comment: comments[(i + d.length) % comments.length],
        },
      });
    }
  }

  // Recompute denormalised counters from the rows above.
  for (const d of DRAWINGS) {
    const drawingId = uid(`drawing:${d.key}`);
    const agg = await prisma.review.aggregate({
      where: { drawingId },
      _avg: { rating: true },
      _count: true,
    });
    await prisma.drawing.update({
      where: { id: drawingId },
      data: {
        avgRating: agg._avg.rating ?? 0,
        ratingCount: agg._count,
        purchaseCount: 0,
      },
    });
  }
  for (const id of architectIds) {
    const agg = await prisma.review.aggregate({
      where: { drawing: { architectId: id } },
      _avg: { rating: true },
      _count: true,
    });
    await prisma.user.update({
      where: { id },
      data: {
        architectRating: agg._avg.rating ?? 0,
        architectRatingCount: agg._count,
        freeDownloadsUsed: await prisma.freeDownload.count({
          where: { userId: id },
        }),
      },
    });
  }

  console.log(
    `Seeded ${CATEGORIES.length} categories, 1 admin, ${ARCHITECTS.length} approved architects (+1 pending), ${DRAWINGS.length} published drawings.`,
  );
}

main()
  .catch((e) => {
    console.error(e);
    process.exitCode = 1;
  })
  .finally(() => prisma.$disconnect());
