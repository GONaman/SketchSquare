/* eslint-disable no-console */
/**
 * End-to-end smoke test over the REAL HTTP API (no Nest internals): every user flow from signup to withdrawal.
 *
 *   SMOKE_BASE_URL=http://localhost:3100 npm run smoke
 *   npm run smoke -- --capture ../sketch_square/test/fixtures/api   # also write response fixtures for the Flutter tests
 *
 * Needs the API running (stub Razorpay / stub payouts, i.e. no RAZORPAY_* keys), the seeded dev DB (admin account) and MinIO.
 * Every run creates fresh users/drawings (unique emails), so it is safe to repeat.
 */
import { createHmac } from 'node:crypto';
import { mkdirSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { execFileSync } from 'node:child_process';
import sharp from 'sharp';
import { PDFDocument } from 'pdf-lib';

const BASE = (process.env.SMOKE_BASE_URL ?? 'http://localhost:3100').replace(
  /\/$/,
  '',
);
const ADMIN = {
  email: process.env.SMOKE_ADMIN_EMAIL ?? 'admin@sketchsquare.local',
  password: process.env.SMOKE_ADMIN_PASSWORD ?? 'Admin@12345',
};
// Mirrors StubPaymentProvider / StubPayoutProvider (non-secret dev constants).
const STUB_PAYMENT_SECRET = 'sketchsquare-stub-payment-secret';
const STUB_PAYOUT_SECRET = 'sketchsquare-stub-payout-secret';

const captureIdx = process.argv.indexOf('--capture');
const CAPTURE_DIR =
  captureIdx >= 0
    ? process.argv[captureIdx + 1]
    : process.env.SMOKE_CAPTURE_DIR;
if (CAPTURE_DIR) mkdirSync(CAPTURE_DIR, { recursive: true });

type Json = any; // eslint-disable-line @typescript-eslint/no-explicit-any

class SmokeFailure extends Error {}

let stepNo = 0;
const t0 = Date.now();
// Unique per run so reruns against a persistent DB keep paging assertions exact.
const KEYWORD = `zq${Date.now().toString(36)}`;

function step(title: string): void {
  stepNo += 1;
  console.log(`\n[${String(stepNo).padStart(2, '0')}] ${title}`);
}

function ok(cond: unknown, msg: string): asserts cond {
  if (!cond) throw new SmokeFailure(`ASSERT FAILED: ${msg}`);
  console.log(`     ✓ ${msg}`);
}

type Kind =
  | 'string'
  | 'string?'
  | 'int'
  | 'int?'
  | 'number'
  | 'number?'
  | 'bool'
  | 'object'
  | 'object?'
  | 'array';

/** Asserts the contract shape of a JSON object: `key: kind` (a trailing `?` allows null). */
function shape(obj: Json, spec: Record<string, Kind>, label: string): void {
  ok(obj && typeof obj === 'object', `${label} is an object`);
  for (const [key, kind] of Object.entries(spec)) {
    const v = obj[key];
    const nullable = kind.endsWith('?');
    const base = kind.replace('?', '');
    let good: boolean;
    if (v === null) good = nullable;
    else if (base === 'string') good = typeof v === 'string';
    else if (base === 'int') good = Number.isInteger(v);
    else if (base === 'number') good = typeof v === 'number';
    else if (base === 'bool') good = typeof v === 'boolean';
    else if (base === 'array') good = Array.isArray(v);
    else good = typeof v === 'object' && !Array.isArray(v);
    if (!good) {
      throw new SmokeFailure(
        `SHAPE MISMATCH ${label}.${key}: expected ${kind}, got ${JSON.stringify(v)}`,
      );
    }
  }
  console.log(`     ✓ ${label} shape (${Object.keys(spec).length} fields)`);
}

const USER_SHAPE: Record<string, Kind> = {
  id: 'string',
  email: 'string',
  fullName: 'string',
  address: 'string',
  phone: 'string',
  avatarUrl: 'string?',
  city: 'string',
  role: 'string',
  verificationStatus: 'string',
  architectRating: 'number',
  freeDownloadsUsed: 'int',
  freeDownloadLimit: 'int',
  createdAt: 'string',
};
const SUMMARY_SHAPE: Record<string, Kind> = {
  id: 'string',
  title: 'string',
  category: 'object',
  city: 'string',
  plotLengthFt: 'number',
  plotBreadthFt: 'number',
  plotAreaSqft: 'number',
  floors: 'int',
  facing: 'string?',
  pricePaise: 'int',
  isFree: 'bool',
  avgRating: 'number',
  ratingCount: 'int',
  previewUrl: 'string?',
  architect: 'object',
  status: 'string',
  createdAt: 'string',
};
const REVIEW_SHAPE: Record<string, Kind> = {
  id: 'string',
  rating: 'int',
  comment: 'string?',
  reviewer: 'object',
  createdAt: 'string',
  updatedAt: 'string',
};
const WITHDRAWAL_SHAPE: Record<string, Kind> = {
  id: 'string',
  amountPaise: 'int',
  status: 'string',
  failureReason: 'string?',
  createdAt: 'string',
  updatedAt: 'string',
};

/** Strips secrets/volatile signatures so committed fixtures stay stable and harmless. */
function sanitize(value: Json): Json {
  const text = JSON.stringify(value)
    .replace(/eyJ[\w-]+\.[\w-]+\.[\w-]+/g, 'REDACTED.JWT.TOKEN')
    .replace(
      /X-Amz-(Signature|Credential|Security-Token)=[^"&]+/g,
      'X-Amz-$1=REDACTED',
    );
  return JSON.parse(text) as Json;
}

function capture(name: string, body: Json): void {
  if (!CAPTURE_DIR) return;
  writeFileSync(
    join(CAPTURE_DIR, `${name}.json`),
    JSON.stringify(sanitize(body), null, 2) + '\n',
  );
}

interface CallOpts {
  token?: string;
  body?: unknown;
  query?: Record<string, string | number | boolean | (string | number)[]>;
  headers?: Record<string, string>;
  raw?: string | Buffer | FormData;
  expect?: number;
  capture?: string;
}

interface Res {
  status: number;
  json: Json;
  headers: Headers;
}

async function call(
  method: string,
  path: string,
  opts: CallOpts = {},
): Promise<Res> {
  const url = new URL(BASE + path);
  for (const [k, v] of Object.entries(opts.query ?? {})) {
    for (const item of Array.isArray(v) ? v : [v]) {
      url.searchParams.append(k, String(item));
    }
  }
  const headers: Record<string, string> = { ...opts.headers };
  if (opts.token) headers.Authorization = `Bearer ${opts.token}`;
  let body: string | Buffer | FormData | undefined;
  if (opts.raw !== undefined) body = opts.raw;
  else if (opts.body !== undefined) {
    body = JSON.stringify(opts.body);
    headers['Content-Type'] = 'application/json';
  }
  const res = await fetch(url, {
    method,
    headers,
    body: body as BodyInit | undefined,
  });
  const text = await res.text();
  let json: Json = null;
  if (text) {
    try {
      json = JSON.parse(text);
    } catch {
      json = text;
    }
  }
  const expected = opts.expect ?? 200;
  // 200 and 201 are interchangeable for clients (any 2xx is success); everything else must match exactly.
  const bothOk = [200, 201].includes(expected) && [200, 201].includes(res.status);
  if (res.status !== expected && !bothOk) {
    throw new SmokeFailure(
      `${method} ${path} -> ${res.status} (expected ${expected}): ${text.slice(0, 400)}`,
    );
  }
  console.log(`     ${method} ${path} -> ${res.status}`);
  if (opts.capture) capture(opts.capture, json);
  return { status: res.status, json, headers: res.headers };
}

function expectError(res: Res, code: string, label: string): void {
  shape(
    res.json?.error,
    { code: 'string', message: 'string' },
    `${label} error`,
  );
  ok(
    res.json.error.code === code,
    `${label}: error.code === ${code} (got ${res.json.error.code})`,
  );
}

const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));

async function poll<T>(
  what: string,
  fn: () => Promise<T | undefined>,
  timeoutMs = 60_000,
): Promise<T> {
  const start = Date.now();
  for (;;) {
    const v = await fn();
    if (v !== undefined) return v;
    if (Date.now() - start > timeoutMs) {
      throw new SmokeFailure(`timed out waiting for ${what}`);
    }
    await sleep(500);
  }
}

interface Account {
  email: string;
  password: string;
  user: Json;
  access: string;
  refresh: string;
}

const run = Date.now().toString(36);

async function signup(label: string): Promise<Account> {
  const email = `smoke-${label}-${run}@example.com`;
  const password = 'Smoke@12345';
  const { json } = await call('POST', '/auth/signup', {
    expect: 201,
    body: {
      email,
      password,
      fullName: `Smoke ${label} ${run}`,
      phone: '+919800000000',
      address: '12 Test Street, Pune',
      city: 'Pune',
    },
    capture: label === 'seller' ? 'auth_signup' : undefined,
  });
  shape(json.user, USER_SHAPE, 'signup.user');
  shape(
    json.tokens,
    { accessToken: 'string', refreshToken: 'string', expiresIn: 'int' },
    'signup.tokens',
  );
  ok(json.user.verificationStatus === 'PENDING', 'new user is PENDING');
  return {
    email,
    password,
    user: json.user,
    access: json.tokens.accessToken,
    refresh: json.tokens.refreshToken,
  };
}

async function pngBytes(
  w: number,
  h: number,
  rgb: [number, number, number] = [240, 240, 240],
): Promise<Buffer> {
  return sharp({
    create: {
      width: w,
      height: h,
      channels: 3,
      background: { r: rgb[0], g: rgb[1], b: rgb[2] },
    },
  })
    .png()
    .toBuffer();
}

async function pdfBytes(): Promise<Buffer> {
  const doc = await PDFDocument.create();
  doc.addPage([600, 800]).drawText('Smoke structural sheet', { x: 50, y: 700 });
  return Buffer.from(await doc.save());
}

/** upload-url -> PUT to the presigned URL (exactly as the Flutter uploader does) -> register. */
async function addSheet(
  seller: Account,
  drawingId: string,
  file: { name: string; mime: string; bytes: Buffer },
  type: string,
  isPreview: boolean,
  captureName?: string,
): Promise<Json> {
  const target = await call(
    'POST',
    `/drawings/${drawingId}/sheets/upload-url`,
    {
      token: seller.access,
      body: {
        fileName: file.name,
        contentType: file.mime,
        sizeBytes: file.bytes.length,
      },
      expect: 200,
      capture: captureName ? `${captureName}_upload_url` : undefined,
    },
  );
  shape(
    target.json,
    { uploadUrl: 'string', objectKey: 'string', headers: 'object' },
    'upload-url',
  );
  const put = await fetch(target.json.uploadUrl, {
    method: 'PUT',
    headers: target.json.headers,
    body: file.bytes as unknown as BodyInit,
  });
  ok(put.status === 200, `presigned PUT to storage succeeded (${put.status})`);
  const sheet = await call('POST', `/drawings/${drawingId}/sheets`, {
    token: seller.access,
    expect: 201,
    body: {
      type,
      objectKey: target.json.objectKey,
      isPreview,
      fileName: file.name,
      sizeBytes: file.bytes.length,
    },
    capture: captureName ? `${captureName}_sheet` : undefined,
  });
  shape(
    sheet.json,
    {
      id: 'string',
      type: 'string',
      isPreview: 'bool',
      previewUrl: 'string?',
      originalMime: 'string',
      fileName: 'string',
      sizeBytes: 'int',
    },
    'sheet',
  );
  return sheet.json;
}

async function createPublishedDrawing(
  seller: Account,
  categoryId: string,
  opts: {
    title: string;
    pricePaise: number;
    isFree?: boolean;
    length: number;
    breadth: number;
    capturePrefix?: string;
  },
): Promise<Json> {
  const create = await call('POST', '/drawings', {
    token: seller.access,
    expect: 201,
    body: {
      title: opts.title,
      description:
        'Smoke test drawing with a unique searchable keyword ' + KEYWORD,
      categoryId,
      city: 'Pune',
      plotLength: opts.length,
      plotBreadth: opts.breadth,
      unit: 'ft',
      floors: 2,
      facing: 'NE',
      bedrooms: 3,
      tags: ['Vastu', 'Courtyard'],
      pricePaise: opts.pricePaise,
      isFree: opts.isFree ?? false,
    },
    capture: opts.capturePrefix ? `${opts.capturePrefix}_create` : undefined,
  });
  ok(create.json.status === 'DRAFT', 'created drawing is DRAFT');
  ok(
    create.json.bedrooms === 3 && create.json.tags.length === 2,
    'bedrooms/tags echoed',
  );
  const id = create.json.id as string;
  await addSheet(
    seller,
    id,
    { name: 'plan.png', mime: 'image/png', bytes: await pngBytes(1200, 800) },
    'ARCHITECTURAL',
    true,
    opts.capturePrefix,
  );
  await addSheet(
    seller,
    id,
    { name: 'structure.pdf', mime: 'application/pdf', bytes: await pdfBytes() },
    'STRUCTURAL',
    false,
  );
  const pub = await call('POST', `/drawings/${id}/publish`, {
    token: seller.access,
    expect: 202,
    capture: opts.capturePrefix ? `${opts.capturePrefix}_publish` : undefined,
  });
  ok(pub.json.status === 'PROCESSING', 'publish -> 202 PROCESSING');
  const detail = await poll('drawing to be PUBLISHED', async () => {
    const d = await call('GET', `/drawings/${id}`, { token: seller.access });
    if (d.json.status === 'FAILED') {
      throw new SmokeFailure(`publish FAILED: ${d.json.failureReason}`);
    }
    return d.json.status === 'PUBLISHED' ? d.json : undefined;
  });
  ok(
    detail.sheets.some((s: Json) => s.isPreview && s.previewUrl),
    'preview sheet has previewUrl once PUBLISHED',
  );
  return detail;
}

async function main(): Promise<void> {
  step('Health');
  const health = await call('GET', '/health', { capture: 'health' });
  ok(
    health.json.status === 'ok',
    `health ok ${JSON.stringify(health.json.checks)}`,
  );

  step('Signup (seller, buyer) + unverified access is blocked');
  const seller = await signup('seller');
  const buyer = await signup('buyer');
  const me0 = await call('GET', '/me', { token: seller.access });
  ok(
    me0.json.verificationStatus === 'PENDING',
    'GET /me allowed while PENDING',
  );
  const blocked = await call('GET', '/wallet', {
    token: seller.access,
    expect: 403,
  });
  expectError(blocked, 'VERIFICATION_REQUIRED', 'unverified /wallet');
  const dup = await call('POST', '/auth/signup', {
    expect: 409,
    body: {
      email: seller.email,
      password: seller.password,
      fullName: 'X Y',
      phone: '+919800000000',
      address: 'addr',
      city: 'Pune',
    },
    capture: 'error_conflict',
  });
  expectError(dup, 'CONFLICT', 'duplicate signup');
  const badSignup = await call('POST', '/auth/signup', {
    expect: 400,
    body: { email: 'nope', password: 'short' },
    capture: 'error_validation',
  });
  expectError(badSignup, 'VALIDATION_ERROR', 'invalid signup');
  ok(
    badSignup.json.error.details?.fields,
    'validation error carries details.fields',
  );
  const noAuth = await call('GET', '/me', {
    expect: 401,
    capture: 'error_unauthorized',
  });
  expectError(noAuth, 'UNAUTHORIZED', 'no token');

  step('Verification upload (multipart) + admin approves');
  for (const who of [seller, buyer]) {
    const form = new FormData();
    form.set('coaRegistrationNumber', `CA/2020/${run}`);
    form.set(
      'document',
      new Blob([new Uint8Array(await pngBytes(300, 200))], {
        type: 'image/png',
      }),
      'coa.png',
    );
    const v = await call('POST', '/verification', {
      token: who.access,
      raw: form,
      expect: 201,
      capture: who === seller ? 'verification_submit' : undefined,
    });
    shape(
      v.json,
      {
        id: 'string',
        coaRegistrationNumber: 'string',
        status: 'string',
        reviewNote: 'string?',
        submittedAt: 'string',
        reviewedAt: 'string?',
      },
      'verification',
    );
    ok(v.json.status === 'PENDING', 'verification PENDING');
  }
  const mine = await call('GET', '/verification/me', {
    token: seller.access,
    capture: 'verification_me',
  });
  ok(
    mine.json.verification?.status === 'PENDING',
    'GET /verification/me -> { verification }',
  );

  const adminLogin = await call('POST', '/auth/login', { body: ADMIN });
  const admin = adminLogin.json.tokens.accessToken as string;
  const queue = await poll('verifications in admin queue', async () => {
    const q = await call('GET', '/admin/verifications', {
      token: admin,
      query: { status: 'PENDING', limit: 50 },
      capture: 'admin_verifications',
    });
    const mineItems = q.json.items.filter((i: Json) =>
      [seller.user.id, buyer.user.id].includes(i.user.id),
    );
    return mineItems.length === 2 ? mineItems : undefined;
  });
  shape(
    queue[0],
    {
      id: 'string',
      status: 'string',
      coaRegistrationNumber: 'string',
      submittedAt: 'string',
      user: 'object',
    },
    'admin verification item',
  );
  const adminDetail = await call('GET', `/admin/verifications/${queue[0].id}`, {
    token: admin,
    capture: 'admin_verification_detail',
  });
  ok(
    typeof adminDetail.json.documentUrl === 'string',
    'admin detail has presigned documentUrl',
  );
  const docRes = await fetch(adminDetail.json.documentUrl);
  ok(docRes.status === 200, `presigned KYC document readable (${docRes.status})`);
  for (const item of queue) {
    const a = await call('POST', `/admin/verifications/${item.id}/approve`, {
      token: admin,
      expect: 200,
      capture: 'admin_approve',
    });
    ok(a.json.ok === true, 'approve -> { ok: true }');
  }

  step('Login / refresh rotation / reuse detection / logout');
  const login = await call('POST', '/auth/login', {
    body: { email: seller.email, password: seller.password },
    capture: 'auth_login',
  });
  shape(login.json.user, USER_SHAPE, 'login.user');
  ok(
    login.json.user.verificationStatus === 'APPROVED',
    'seller APPROVED after admin approval',
  );
  const wrong = await call('POST', '/auth/login', {
    body: { email: seller.email, password: 'WrongPass123' },
    expect: 401,
  });
  expectError(wrong, 'UNAUTHORIZED', 'wrong password');
  seller.access = login.json.tokens.accessToken;
  seller.refresh = login.json.tokens.refreshToken;
  const refreshed = await call('POST', '/auth/refresh', {
    body: { refreshToken: seller.refresh },
    capture: 'auth_refresh',
  });
  shape(
    refreshed.json.tokens,
    { accessToken: 'string', refreshToken: 'string', expiresIn: 'int' },
    'refresh.tokens',
  );
  ok(
    refreshed.json.tokens.refreshToken !== seller.refresh,
    'refresh token rotated',
  );
  const reuse = await call('POST', '/auth/refresh', {
    body: { refreshToken: seller.refresh },
    expect: 401,
  });
  expectError(reuse, 'UNAUTHORIZED', 'refresh reuse');
  const familyRevoked = await call('POST', '/auth/refresh', {
    body: { refreshToken: refreshed.json.tokens.refreshToken },
    expect: 401,
  });
  expectError(familyRevoked, 'UNAUTHORIZED', 'family revoked after reuse');
  const relogin = await call('POST', '/auth/login', {
    body: { email: seller.email, password: seller.password },
  });
  seller.refresh = relogin.json.tokens.refreshToken;
  const lo = await call('POST', '/auth/logout', {
    body: { refreshToken: seller.refresh },
    expect: 204,
  });
  ok(lo.json === null, 'logout -> 204 empty');
  await call('POST', '/auth/refresh', {
    body: { refreshToken: seller.refresh },
    expect: 401,
  });
  const relogin2 = await call('POST', '/auth/login', {
    body: { email: seller.email, password: seller.password },
  });
  seller.access = relogin2.json.tokens.accessToken;
  seller.refresh = relogin2.json.tokens.refreshToken;
  const buyerLogin = await call('POST', '/auth/login', {
    body: { email: buyer.email, password: buyer.password },
  });
  buyer.access = buyerLogin.json.tokens.accessToken;
  buyer.refresh = buyerLogin.json.tokens.refreshToken;
  const fp = await call('POST', '/auth/forgot-password', {
    body: { email: 'nobody@example.com' },
    expect: 204,
  });
  ok(fp.json === null, 'forgot-password always 204');

  step('Profile: GET /me, PATCH /me, immutable fields, avatar upload');
  const me = await call('GET', '/me', { token: seller.access, capture: 'me' });
  shape(me.json, USER_SHAPE, 'me');
  const patched = await call('PATCH', '/me', {
    token: seller.access,
    body: { phone: '+919811111111', city: 'Mumbai' },
    capture: 'me_patch',
  });
  ok(
    patched.json.phone === '+919811111111' && patched.json.city === 'Mumbai',
    'phone+city updated',
  );
  const immut = await call('PATCH', '/me', {
    token: seller.access,
    body: { fullName: 'Hacker' },
    expect: 400,
  });
  expectError(immut, 'VALIDATION_ERROR', 'fullName immutable');
  await call('PATCH', '/me', { token: seller.access, body: { city: 'Pune' } });
  const avatarPng = await pngBytes(800, 800, [30, 60, 140]);
  const avatarTarget = await call('POST', '/me/avatar/upload-url', {
    token: seller.access,
    body: { contentType: 'image/png' },
    expect: 200,
    capture: 'avatar_upload_url',
  });
  shape(
    avatarTarget.json,
    { uploadUrl: 'string', objectKey: 'string', headers: 'object' },
    'avatar upload-url',
  );
  // The Flutter client PUTs with only `Content-Type`; any extra signed header in `headers` would break it.
  console.log(`     avatar headers: ${JSON.stringify(avatarTarget.json.headers)}`);
  const avatarPut = await fetch(avatarTarget.json.uploadUrl, {
    method: 'PUT',
    headers: { 'Content-Type': 'image/png' },
    body: avatarPng as unknown as BodyInit,
  });
  ok(
    avatarPut.status === 200,
    `avatar PUT with only Content-Type succeeded (${avatarPut.status})`,
  );
  const avatarDone = await call('POST', '/me/avatar/confirm', {
    token: seller.access,
    body: { objectKey: avatarTarget.json.objectKey },
    expect: 200,
    capture: 'avatar_confirm',
  });
  ok(
    typeof avatarDone.json.avatarUrl === 'string',
    'avatarUrl set after confirm',
  );
  const av = await fetch(avatarDone.json.avatarUrl);
  ok(av.status === 200, `avatarUrl is fetchable (${av.status})`);
  const avMeta = await sharp(Buffer.from(await av.arrayBuffer())).metadata();
  ok(avMeta.width === 512, `avatar resized to 512px (got ${avMeta.width})`);

  step('Categories / cities / category request');
  const cats = await call('GET', '/categories', {
    token: seller.access,
    capture: 'categories',
  });
  ok(
    Array.isArray(cats.json) && cats.json.length >= 6,
    'GET /categories -> bare array',
  );
  shape(cats.json[0], { id: 'string', name: 'string', slug: 'string' }, 'category');
  const categoryId = cats.json[0].id as string;
  const cities = await call('GET', '/cities', {
    token: seller.access,
    capture: 'cities',
  });
  shape(cities.json[0], { city: 'string', count: 'int' }, 'city count');
  const creq = await call('POST', '/category-requests', {
    token: seller.access,
    body: { name: `Smoke Cat ${run}` },
    expect: 201,
    capture: 'category_request',
  });
  shape(
    creq.json,
    { id: 'string', requestedName: 'string', status: 'string' },
    'category request',
  );
  const creqs = await call('GET', '/admin/category-requests', {
    token: admin,
    query: { status: 'PENDING', limit: 50 },
    capture: 'admin_category_requests',
  });
  shape(
    creqs.json.items[0],
    {
      id: 'string',
      requestedName: 'string',
      status: 'string',
      user: 'object',
      createdAt: 'string',
    },
    'admin category request',
  );
  const capproved = await call(
    'POST',
    `/admin/category-requests/${creq.json.id}/approve`,
    { token: admin, expect: 200, capture: 'admin_category_approve' },
  );
  ok(
    capproved.json.ok === true && capproved.json.category.slug,
    'category request approved -> category',
  );

  step('Create paid drawing, presigned upload, register sheets, publish, wait');
  const paid = await createPublishedDrawing(seller, categoryId, {
    title: 'Smoke Paid Villa',
    pricePaise: 100_000,
    length: 33.3,
    breadth: 47.7,
    capturePrefix: 'drawing',
  });
  capture('drawing_detail_seller', paid);
  shape(
    paid,
    {
      ...SUMMARY_SHAPE,
      description: 'string',
      viewCount: 'int',
      purchaseCount: 'int',
      failureReason: 'string?',
      sheets: 'array',
      reviews: 'object',
      viewer: 'object',
      bedrooms: 'int?',
      tags: 'array',
    },
    'drawing detail',
  );
  ok(paid.viewer.isOwner === true, 'viewer.isOwner for the seller');
  const prevRes = await fetch(
    paid.sheets.find((s: Json) => s.isPreview).previewUrl,
  );
  ok(
    prevRes.status === 200 &&
      (prevRes.headers.get('content-type') ?? '').startsWith('image/'),
    'previewUrl is a publicly fetchable image',
  );
  const prevMeta = await sharp(
    Buffer.from(await prevRes.arrayBuffer()),
  ).metadata();
  ok(
    Math.max(prevMeta.width ?? 0, prevMeta.height ?? 0) <= 1600,
    'preview downscaled to <= 1600px',
  );

  step('Draft PATCH with the exact body the Flutter form sends');
  const draft = await call('POST', '/drawings', {
    token: seller.access,
    expect: 201,
    body: {
      title: 'Draft one',
      description: 'd',
      categoryId,
      city: 'Pune',
      plotLength: 30,
      plotBreadth: 40,
      unit: 'ft',
      floors: 1,
      pricePaise: 0,
      isFree: true,
    },
  });
  const draftPatch = await call('PATCH', `/drawings/${draft.json.id}`, {
    token: seller.access,
    body: {
      title: 'Draft renamed',
      description: 'dd',
      categoryId,
      city: 'Pune',
      plotLength: 10,
      plotBreadth: 12,
      unit: 'm',
      floors: 2,
      facing: 'N',
      pricePaise: 250_000,
      isFree: false,
      bedrooms: 2,
      tags: ['a'],
    },
    capture: 'drawing_patch_draft',
  });
  ok(
    draftPatch.json.pricePaise === 250_000 &&
      Math.abs(draftPatch.json.plotLengthFt - 32.8084) < 0.01,
    'draft PATCH converts metres -> feet',
  );
  const publishNoSheets = await call('POST', `/drawings/${draft.json.id}/publish`, {
    token: seller.access,
    expect: 400,
  });
  expectError(publishNoSheets, 'VALIDATION_ERROR', 'publish without sheets');
  await call('DELETE', `/drawings/${draft.json.id}`, {
    token: seller.access,
    expect: 204,
  });

  step('Create free drawing (+ second paid drawing for stub checkout)');
  const free = await createPublishedDrawing(seller, categoryId, {
    title: 'Smoke Free Bungalow',
    pricePaise: 0,
    isFree: true,
    length: 33.3,
    breadth: 47.7,
  });
  ok(free.isFree && free.pricePaise === 0, 'free drawing has price 0');
  const paid2 = await createPublishedDrawing(seller, categoryId, {
    title: 'Smoke Paid Duplex',
    pricePaise: 100_000,
    length: 33.3,
    breadth: 47.7,
  });

  step('Search: text, plot size (incl. rotated, metres), filters, sorts, cursors');
  const s1 = await call('GET', '/drawings/search', {
    token: buyer.access,
    query: { q: KEYWORD, limit: 2 },
    capture: 'search_text',
  });
  ok(Array.isArray(s1.json.items), 'search -> { items, nextCursor }');
  shape(s1.json.items[0], SUMMARY_SHAPE, 'search item');
  ok(
    s1.json.items.length === 2 && typeof s1.json.nextCursor === 'string',
    'limit=2 yields a nextCursor',
  );
  const s1b = await call('GET', '/drawings/search', {
    token: buyer.access,
    query: { q: KEYWORD, limit: 2, cursor: s1.json.nextCursor },
  });
  ok(
    s1b.json.items.length === 1 && s1b.json.nextCursor === null,
    'second page has the last item, nextCursor null',
  );
  const exact = await call('GET', '/drawings/search', {
    token: buyer.access,
    query: { length: 33.3, breadth: 47.7, tolerancePct: 1 },
    capture: 'search_size',
  });
  ok(
    exact.json.items.length >= 3 &&
      exact.json.items.every(
        (i: Json) => i.sizeMatch !== null && i.sizeMatch > 0.9,
      ),
    'exact size search finds our 3 drawings with sizeMatch ~1',
  );
  const rotated = await call('GET', '/drawings/search', {
    token: buyer.access,
    query: { length: 47.7, breadth: 33.3, tolerancePct: 1 },
  });
  ok(rotated.json.items.length >= 3, 'rotated plot (length<->breadth) also matches');
  const metres = await call('GET', '/drawings/search', {
    token: buyer.access,
    query: { length: 10.1498, breadth: 14.539, unit: 'm', tolerancePct: 2 },
  });
  ok(metres.json.items.length >= 3, 'unit=m search converts to feet');
  const onlyLength = await call('GET', '/drawings/search', {
    token: buyer.access,
    query: { length: 30 },
    expect: 400,
  });
  expectError(onlyLength, 'VALIDATION_ERROR', 'length without breadth');
  const sizeSort = await call('GET', '/drawings/search', {
    token: buyer.access,
    query: { length: 33, breadth: 48, sort: 'size_match' },
  });
  ok(sizeSort.json.items.length >= 3, 'sort=size_match with a size works');
  const sizeSortNoSize = await call('GET', '/drawings/search', {
    token: buyer.access,
    query: { sort: 'size_match' },
    expect: 400,
  });
  expectError(sizeSortNoSize, 'VALIDATION_ERROR', 'size_match without size');
  for (const sort of [
    'relevance',
    'price_asc',
    'price_desc',
    'drawing_rating',
    'architect_rating',
    'newest',
    'popularity',
  ]) {
    const r = await call('GET', '/drawings/search', {
      token: buyer.access,
      query: { sort, limit: 5 },
    });
    ok(Array.isArray(r.json.items), `sort=${sort} ok`);
  }
  const prices = (
    await call('GET', '/drawings/search', {
      token: buyer.access,
      query: { q: KEYWORD, sort: 'price_desc' },
    })
  ).json.items.map((i: Json) => i.pricePaise);
  ok(
    prices.every((p: number, i: number) => i === 0 || prices[i - 1] >= p),
    'price_desc is ordered',
  );
  const filtered = await call('GET', '/drawings/search', {
    token: buyer.access,
    query: {
      q: KEYWORD,
      city: ['pune', 'Delhi'],
      priceType: 'paid',
      floors: [2, 3],
      bedrooms: 3,
      tag: 'vastu',
      facing: 'NE',
      minPricePaise: 1,
      maxPricePaise: 200_000,
      minDrawingRating: 0,
      minArchitectRating: 0,
      categoryId,
      architectId: seller.user.id,
    },
    capture: 'search_filtered',
  });
  ok(
    filtered.json.items.length === 2 &&
      filtered.json.items.every((i: Json) => !i.isFree),
    'combined filters (city/priceType/floors/bedrooms/tag/facing/price/category/architect) -> the 2 paid drawings',
  );
  const freeOnly = await call('GET', '/drawings/search', {
    token: buyer.access,
    query: { q: KEYWORD, priceType: 'free' },
  });
  ok(
    freeOnly.json.items.length === 1 && freeOnly.json.items[0].isFree,
    'priceType=free',
  );
  const wrongSortCursor = await call('GET', '/drawings/search', {
    token: buyer.access,
    query: {
      q: KEYWORD,
      limit: 1,
      sort: 'price_asc',
      cursor: s1.json.nextCursor,
    },
    expect: 400,
  });
  expectError(wrongSortCursor, 'VALIDATION_ERROR', 'cursor bound to sort');

  step('Drawing detail as buyer (view recorded, viewer flags)');
  const detail = await call('GET', `/drawings/${paid.id}`, {
    token: buyer.access,
    capture: 'drawing_detail_buyer',
  });
  ok(
    detail.json.viewer.isOwner === false &&
      detail.json.viewer.isPurchased === false &&
      detail.json.viewer.canDownload === false,
    'buyer viewer flags before purchase',
  );
  ok(
    detail.json.viewer.inCart === false && detail.json.viewer.myReview === null,
    'not in cart, no review yet',
  );
  ok(
    detail.json.sheets.every((s: Json) => s.isPreview || s.previewUrl === null),
    'only preview sheets carry previewUrl',
  );
  const detailFree = await call('GET', `/drawings/${free.id}`, {
    token: buyer.access,
    capture: 'drawing_detail_free',
  });
  ok(
    typeof detailFree.json.viewer.freeDownloadsRemaining === 'number',
    'free drawing exposes freeDownloadsRemaining',
  );
  const archPage = await call('GET', `/architects/${seller.user.id}`, {
    token: buyer.access,
    capture: 'architect_profile',
  });
  shape(
    archPage.json.architect,
    {
      id: 'string',
      fullName: 'string',
      city: 'string',
      architectRating: 'number',
      ratingCount: 'int',
      avatarUrl: 'string?',
    },
    'architect summary',
  );
  ok(
    Array.isArray(archPage.json.drawings.items),
    'architect profile -> drawings page',
  );
  const archDrawings = await call(
    'GET',
    `/architects/${seller.user.id}/drawings`,
    { token: buyer.access, query: { limit: 1 }, capture: 'architect_drawings' },
  );
  ok(
    archDrawings.json.items.length === 1 && archDrawings.json.nextCursor,
    'architect drawings paged',
  );
  const top = await call('GET', '/architects/top', {
    token: buyer.access,
    query: { city: 'Delhi' },
    capture: 'architects_top',
  });
  ok(Array.isArray(top.json), 'architects/top -> bare array');
  const viewers = await call('GET', `/drawings/${paid.id}/viewers`, {
    token: seller.access,
    capture: 'drawing_viewers',
  });
  ok(
    viewers.json.items.some((v: Json) => v.viewer.id === buyer.user.id),
    'owner sees buyer in viewers',
  );
  shape(
    viewers.json.items[0],
    { viewer: 'object', lastViewedAt: 'string' },
    'viewer item',
  );

  step('Favorites');
  await call('PUT', `/drawings/${paid.id}/favorite`, {
    token: buyer.access,
    expect: 204,
  });
  const favs = await call('GET', '/me/favorites', {
    token: buyer.access,
    capture: 'favorites',
  });
  ok(
    favs.json.items.some((i: Json) => i.id === paid.id),
    'favorite listed',
  );
  const afterFav = await call('GET', `/drawings/${paid.id}`, {
    token: buyer.access,
  });
  ok(afterFav.json.viewer.isFavorite === true, 'viewer.isFavorite');
  await call('DELETE', `/drawings/${paid.id}/favorite`, {
    token: buyer.access,
    expect: 204,
  });

  step('Cart');
  const own = await call('POST', '/cart', {
    token: seller.access,
    body: { drawingId: paid.id },
    expect: 400,
  });
  expectError(own, 'VALIDATION_ERROR', 'own drawing in cart');
  const freeCart = await call('POST', '/cart', {
    token: buyer.access,
    body: { drawingId: free.id },
    expect: 400,
  });
  expectError(freeCart, 'VALIDATION_ERROR', 'free drawing in cart');
  const cart1 = await call('POST', '/cart', {
    token: buyer.access,
    body: { drawingId: paid.id },
    expect: 201,
    capture: 'cart_add',
  });
  shape(cart1.json, { items: 'array', totalPaise: 'int' }, 'cart');
  shape(cart1.json.items[0], SUMMARY_SHAPE, 'cart item');
  await call('POST', '/cart', {
    token: buyer.access,
    body: { drawingId: paid2.id },
    expect: 201,
  });
  const cart2 = await call('DELETE', `/cart/${paid2.id}`, {
    token: buyer.access,
    expect: 200,
  });
  ok(
    cart2.json.items.length === 1 && cart2.json.totalPaise === 100_000,
    'cart remove -> cart with 1 item',
  );
  const cartGet = await call('GET', '/cart', {
    token: buyer.access,
    capture: 'cart',
  });
  ok(cartGet.json.totalPaise === 100_000, 'GET /cart total');

  step('Checkout (stub) -> signed webhook -> idempotent replay');
  const dlBefore = await call('GET', `/drawings/${paid.id}/download`, {
    token: buyer.access,
    query: { sheetId: paid.sheets[0].id },
    expect: 403,
  });
  expectError(dlBefore, 'FORBIDDEN', 'download before purchase');
  const co = await call('POST', '/checkout', {
    token: buyer.access,
    expect: 200,
    capture: 'checkout',
  });
  shape(
    co.json,
    {
      orderId: 'string',
      razorpayKeyId: 'string',
      amountPaise: 'int',
      currency: 'string',
      purchaseIds: 'array',
    },
    'checkout',
  );
  ok(
    co.json.razorpayKeyId === 'stub' &&
      co.json.amountPaise === 100_000 &&
      co.json.currency === 'INR',
    'stub mode: key "stub", 100000 paise INR',
  );
  const st0 = await call('GET', '/checkout/status', {
    token: buyer.access,
    query: { orderId: co.json.orderId },
    capture: 'checkout_status_created',
  });
  ok(st0.json.status === 'CREATED', 'status CREATED before payment');
  const eventBody = JSON.stringify({
    event: 'payment.captured',
    payload: {
      payment: {
        entity: {
          id: `pay_smoke_${run}`,
          order_id: co.json.orderId,
          amount: 100_000,
        },
      },
    },
  });
  const sign = (secret: string, b: string) =>
    createHmac('sha256', secret).update(b).digest('hex');
  const badSig = await call('POST', '/payments/razorpay/webhook', {
    raw: eventBody,
    headers: {
      'Content-Type': 'application/json',
      'x-razorpay-signature': 'deadbeef',
      'x-razorpay-event-id': `evt_bad_${run}`,
    },
    expect: 401,
  });
  expectError(badSig, 'UNAUTHORIZED', 'bad webhook signature');
  const hookHeaders = {
    'Content-Type': 'application/json',
    'x-razorpay-signature': sign(STUB_PAYMENT_SECRET, eventBody),
    'x-razorpay-event-id': `evt_${run}`,
  };
  const hook1 = await call('POST', '/payments/razorpay/webhook', {
    raw: eventBody,
    headers: hookHeaders,
    expect: 200,
  });
  ok(
    hook1.json.ok === true && hook1.json.duplicate === false,
    'webhook processed',
  );
  const hook2 = await call('POST', '/payments/razorpay/webhook', {
    raw: eventBody,
    headers: hookHeaders,
    expect: 200,
  });
  ok(hook2.json.duplicate === true, 'webhook replay is a duplicate no-op');
  const st1 = await call('GET', '/checkout/status', {
    token: buyer.access,
    query: { orderId: co.json.orderId },
    capture: 'checkout_status_paid',
  });
  ok(st1.json.status === 'PAID', 'status PAID after webhook');
  const verifyAgain = await call('POST', '/checkout/verify', {
    token: buyer.access,
    body: {
      razorpayOrderId: co.json.orderId,
      razorpayPaymentId: `pay_smoke_${run}`,
      razorpaySignature: sign(
        STUB_PAYMENT_SECRET,
        `${co.json.orderId}|pay_smoke_${run}`,
      ),
    },
    expect: 200,
    capture: 'checkout_verify',
  });
  ok(verifyAgain.json.status === 'PAID', 'POST /checkout/verify idempotent -> PAID');
  const cartAfter = await call('GET', '/cart', { token: buyer.access });
  ok(cartAfter.json.items.length === 0, 'cart cleared after payment');

  step('Second checkout through /checkout/stub-complete (what the app uses in stub mode)');
  await call('POST', '/cart', {
    token: buyer.access,
    body: { drawingId: paid2.id },
    expect: 201,
  });
  const co2 = await call('POST', '/checkout', {
    token: buyer.access,
    expect: 200,
  });
  const sc = await call('POST', '/checkout/stub-complete', {
    token: buyer.access,
    body: { orderId: co2.json.orderId },
    expect: 200,
    capture: 'checkout_stub_complete',
  });
  ok(sc.json.status === 'PAID', 'stub-complete -> PAID');

  step('Download (buyer-watermarked), free quota, my purchases');
  const pdfSheet = paid.sheets.find(
    (s: Json) => s.originalMime === 'application/pdf',
  );
  const dl = await call('GET', `/drawings/${paid.id}/download`, {
    token: buyer.access,
    query: { sheetId: pdfSheet.id },
    capture: 'download',
  });
  shape(
    dl.json,
    { url: 'string', expiresInSeconds: 'int', fileName: 'string' },
    'download',
  );
  const dlRes = await fetch(dl.json.url);
  const dlBytes = Buffer.from(await dlRes.arrayBuffer());
  ok(
    dlRes.status === 200 && dlBytes.subarray(0, 4).toString() === '%PDF',
    'presigned download returns the PDF',
  );
  try {
    const text = execFileSync('pdftotext', ['-', '-'], {
      input: dlBytes,
    }).toString();
    ok(
      /Licensed to/.test(text) && text.includes(`Smoke buyer ${run}`),
      'PDF carries the buyer footer "Licensed to <buyer> …"',
    );
  } catch (e) {
    if (e instanceof SmokeFailure) throw e;
    console.log('     (pdftotext not available — watermark text check skipped)');
  }
  const pngSheet = paid.sheets.find((s: Json) => s.originalMime === 'image/png');
  const dlPng = await call('GET', `/drawings/${paid.id}/download`, {
    token: buyer.access,
    query: { sheetId: pngSheet.id },
  });
  const pngDl = await fetch(dlPng.json.url);
  const pngMeta = await sharp(Buffer.from(await pngDl.arrayBuffer())).metadata();
  ok(
    (pngMeta.height ?? 0) > 800,
    `image download has the footer strip (height ${pngMeta.height} > 800)`,
  );

  const before = (await call('GET', '/me', { token: buyer.access })).json
    .freeDownloadsUsed as number;
  const fdl = await call('GET', `/drawings/${free.id}/download`, {
    token: buyer.access,
    query: { sheetId: free.sheets[0].id },
    capture: 'download_free',
  });
  ok(typeof fdl.json.url === 'string', 'free drawing download link');
  await call('GET', `/drawings/${free.id}/download`, {
    token: buyer.access,
    query: { sheetId: free.sheets[0].id },
  });
  const meAfter = await call('GET', '/me', {
    token: buyer.access,
    capture: 'me_buyer',
  });
  ok(
    meAfter.json.freeDownloadsUsed === before + 1,
    'free quota consumed exactly once per drawing',
  );
  const detailAfter = await call('GET', `/drawings/${free.id}`, {
    token: buyer.access,
  });
  ok(
    detailAfter.json.viewer.canDownload === true &&
      typeof detailAfter.json.viewer.freeDownloadsRemaining === 'number',
    'viewer.canDownload + freeDownloadsRemaining after claim',
  );
  const purchases = await call('GET', '/me/purchases', {
    token: buyer.access,
    capture: 'purchases',
  });
  const kinds = purchases.json.items.map((p: Json) => p.kind).sort();
  ok(
    JSON.stringify(kinds) === JSON.stringify(['FREE', 'PAID', 'PAID']),
    `purchases: ${kinds.join(',')}`,
  );
  const pItem = purchases.json.items.find((p: Json) => p.kind === 'PAID');
  shape(
    pItem,
    {
      kind: 'string',
      purchasedAt: 'string',
      pricePaise: 'int',
      purchaseId: 'string?',
      drawing: 'object',
    },
    'purchase item',
  );
  ok(Array.isArray(pItem.drawing.sheets), 'purchase.drawing.sheets present');
  const ownerDl = await call('GET', `/drawings/${paid.id}/download`, {
    token: seller.access,
    query: { sheetId: pngSheet.id },
  });
  ok(typeof ownerDl.json.url === 'string', 'owner can download their own sheet');

  step('Review (entitled buyer), owner cannot review, ratings recomputed');
  const rv = await call('PUT', `/drawings/${paid.id}/review`, {
    token: buyer.access,
    body: { rating: 4, comment: 'Great plan' },
    expect: 200,
    capture: 'review',
  });
  shape(rv.json, REVIEW_SHAPE, 'review');
  const rv2 = await call('PUT', `/drawings/${paid.id}/review`, {
    token: buyer.access,
    body: { rating: 5 },
    expect: 200,
  });
  ok(
    rv2.json.id === rv.json.id && rv2.json.rating === 5,
    'review is editable (same id)',
  );
  const ownReview = await call('PUT', `/drawings/${paid.id}/review`, {
    token: seller.access,
    body: { rating: 5 },
    expect: 403,
  });
  expectError(ownReview, 'FORBIDDEN', 'owner review');
  const revs = await call('GET', `/drawings/${paid.id}/reviews`, {
    token: buyer.access,
    capture: 'reviews',
  });
  ok(revs.json.items.length === 1, 'review list');
  const d3 = await call('GET', `/drawings/${paid.id}`, { token: buyer.access });
  ok(
    d3.json.avgRating === 5 &&
      d3.json.ratingCount === 1 &&
      d3.json.viewer.myReview?.rating === 5,
    'drawing avgRating/ratingCount/myReview updated',
  );
  ok(
    d3.json.purchaseCount === 1 && d3.json.viewer.isPurchased === true,
    'purchaseCount + isPurchased',
  );

  step('Seller: my drawings, buyers, stats');
  const mineDrawings = await call('GET', '/me/drawings', {
    token: seller.access,
    query: { status: 'PUBLISHED' },
    capture: 'me_drawings',
  });
  shape(
    mineDrawings.json.items[0].stats,
    {
      viewCount: 'int',
      purchaseCount: 'int',
      avgRating: 'number',
      ratingCount: 'int',
    },
    'stats',
  );
  shape(mineDrawings.json.items[0].drawing, SUMMARY_SHAPE, 'managed drawing summary');
  const buyers = await call('GET', `/drawings/${paid.id}/buyers`, {
    token: seller.access,
    capture: 'drawing_buyers',
  });
  shape(
    buyers.json.items[0],
    { buyer: 'object', pricePaise: 'int', purchasedAt: 'string' },
    'buyer item',
  );
  const notOwner = await call('GET', `/drawings/${paid.id}/buyers`, {
    token: buyer.access,
    expect: 403,
  });
  expectError(notOwner, 'FORBIDDEN', 'non-owner buyers list');
  const edited = await call('PATCH', `/drawings/${paid.id}`, {
    token: seller.access,
    body: {
      title: 'Smoke Paid Villa v2',
      description: 'updated',
      pricePaise: 110_000,
    },
    capture: 'drawing_patch_published',
  });
  ok(
    edited.json.pricePaise === 110_000,
    'published drawing: title/description/price editable',
  );
  const sizeEdit = await call('PATCH', `/drawings/${paid.id}`, {
    token: seller.access,
    body: { floors: 5 },
    expect: 400,
  });
  expectError(sizeEdit, 'VALIDATION_ERROR', 'size edit on published');

  step('Wallet: summary, ledger, bank account, withdrawal, failure reversal, payout webhook');
  const w0 = await call('GET', '/wallet', {
    token: seller.access,
    capture: 'wallet_initial',
  });
  shape(
    w0.json,
    {
      balancePaise: 'int',
      pendingWithdrawalPaise: 'int',
      minWithdrawalPaise: 'int',
      withdrawalBlocked: 'bool',
      bankAccount: 'object?',
    },
    'wallet',
  );
  ok(
    w0.json.balancePaise === 180_000,
    `2 sales net of 10% fee -> 180000 paise (got ${w0.json.balancePaise})`,
  );
  ok(
    w0.json.bankAccount === null && w0.json.pendingWithdrawalPaise === 0,
    'no bank account / nothing pending yet',
  );
  const ledger = await call('GET', '/wallet/ledger', {
    token: seller.access,
    capture: 'wallet_ledger',
  });
  shape(
    ledger.json.items[0],
    {
      id: 'string',
      entryType: 'string',
      amountPaise: 'int',
      description: 'string',
      referenceId: 'string?',
      createdAt: 'string',
    },
    'ledger entry',
  );
  ok(
    ledger.json.items.every((e: Json) => e.entryType === 'SALE'),
    'wallet ledger: SALE entries',
  );
  const noBank = await call('POST', '/wallet/withdrawals', {
    token: seller.access,
    body: { amountPaise: 50_000 },
    expect: 400,
  });
  expectError(noBank, 'VALIDATION_ERROR', 'withdraw without bank account');
  const badIfsc = await call('POST', '/wallet/bank-account', {
    token: seller.access,
    body: { holderName: 'Smoke Seller', ifsc: 'BAD', accountNumber: '123456789012' },
    expect: 400,
  });
  expectError(badIfsc, 'VALIDATION_ERROR', 'bad ifsc');
  const bank = await call('POST', '/wallet/bank-account', {
    token: seller.access,
    body: {
      holderName: 'Smoke Seller',
      ifsc: 'hdfc0001234',
      accountNumber: '123456789012',
    },
    expect: 200,
    capture: 'wallet_bank_account',
  });
  shape(
    bank.json,
    { holderName: 'string', ifsc: 'string', accountNumberLast4: 'string' },
    'bank account',
  );
  ok(
    bank.json.accountNumberLast4 === '9012' && bank.json.ifsc === 'HDFC0001234',
    'bank account normalised, last4 only',
  );
  const below = await call('POST', '/wallet/withdrawals', {
    token: seller.access,
    body: { amountPaise: 100 },
    expect: 400,
  });
  expectError(below, 'BELOW_MIN_WITHDRAWAL', 'below min');
  const tooMuch = await call('POST', '/wallet/withdrawals', {
    token: seller.access,
    body: { amountPaise: 9_000_000 },
    expect: 400,
  });
  expectError(tooMuch, 'INSUFFICIENT_BALANCE', 'insufficient');
  const wd = await call('POST', '/wallet/withdrawals', {
    token: seller.access,
    body: { amountPaise: 50_000 },
    expect: 201,
    capture: 'wallet_withdrawal',
  });
  shape(wd.json, WITHDRAWAL_SHAPE, 'withdrawal');
  const w1 = await call('GET', '/wallet', {
    token: seller.access,
    capture: 'wallet_after_withdrawal',
  });
  ok(
    w1.json.balancePaise === 130_000,
    `amount leaves the wallet immediately (got ${w1.json.balancePaise})`,
  );
  const paidWd = await poll('stub payout to finish', async () => {
    const l = await call('GET', '/wallet/withdrawals', {
      token: seller.access,
      capture: 'wallet_withdrawals',
    });
    shape(l.json.items[0], WITHDRAWAL_SHAPE, 'withdrawal item');
    return l.json.items[0].status === 'PAID' ? l.json.items[0] : undefined;
  });
  ok(paidWd.id === wd.json.id, 'withdrawal reached PAID (stub provider)');
  const w2 = await call('GET', '/wallet', { token: seller.access });
  ok(
    w2.json.balancePaise === 130_000 && w2.json.pendingWithdrawalPaise === 0,
    'PAID withdrawal: balance stays debited, nothing pending',
  );
  // Account numbers ending 0000 make the stub bank reject -> reversal.
  await call('POST', '/wallet/bank-account', {
    token: seller.access,
    body: {
      holderName: 'Smoke Seller',
      ifsc: 'HDFC0001234',
      accountNumber: '123456780000',
    },
    expect: 200,
  });
  const wdFail = await call('POST', '/wallet/withdrawals', {
    token: seller.access,
    body: { amountPaise: 50_000 },
    expect: 201,
  });
  const failed = await poll('stub payout failure', async () => {
    const l = await call('GET', '/wallet/withdrawals', { token: seller.access });
    const w = l.json.items.find((i: Json) => i.id === wdFail.json.id);
    return w.status === 'FAILED' ? w : undefined;
  });
  ok(
    typeof failed.failureReason === 'string',
    'failed payout carries failureReason',
  );
  const w3 = await call('GET', '/wallet', {
    token: seller.access,
    capture: 'wallet_after_failed_withdrawal',
  });
  ok(
    w3.json.balancePaise === 130_000,
    'failed payout returned the money to the wallet',
  );
  const ledger2 = await call('GET', '/wallet/ledger', {
    token: seller.access,
    query: { limit: 50 },
    capture: 'wallet_ledger_full',
  });
  const types = new Set(ledger2.json.items.map((e: Json) => e.entryType));
  ok(
    ['SALE', 'WITHDRAWAL', 'WITHDRAWAL_REVERSAL'].every((t) => types.has(t)),
    `ledger has ${[...types].join(', ')}`,
  );
  const pBody = JSON.stringify({
    event: 'payout.processed',
    payload: { payout: { entity: { id: 'pout_x', reference_id: wd.json.id } } },
  });
  const px = await call('POST', '/payments/razorpayx/webhook', {
    raw: pBody,
    headers: {
      'Content-Type': 'application/json',
      'x-razorpay-signature': sign(STUB_PAYOUT_SECRET, pBody),
      'x-razorpay-event-id': `evt_px_${run}`,
    },
    expect: 200,
  });
  ok(px.json.ok === true, 'razorpayx webhook accepted with a valid signature');
  const pxBad = await call('POST', '/payments/razorpayx/webhook', {
    raw: pBody,
    headers: {
      'Content-Type': 'application/json',
      'x-razorpay-signature': 'bad',
    },
    expect: 401,
  });
  expectError(pxBad, 'UNAUTHORIZED', 'bad razorpayx signature');

  step('Authorization spot checks');
  const noAdmin = await call('GET', '/admin/verifications', {
    token: buyer.access,
    expect: 403,
  });
  expectError(noAdmin, 'FORBIDDEN', 'architect on admin route');
  const nf = await call(
    'GET',
    '/drawings/00000000-0000-4000-8000-000000000000',
    { token: buyer.access, expect: 404 },
  );
  expectError(nf, 'NOT_FOUND', 'missing drawing');
  const hidden = await call('GET', `/drawings/${draft.json.id}`, {
    token: buyer.access,
    expect: 404,
  });
  expectError(hidden, 'NOT_FOUND', 'removed drawing hidden from others');

  step('Remove a drawing: hidden from search, buyer keeps access');
  await call('DELETE', `/drawings/${paid2.id}`, {
    token: seller.access,
    expect: 204,
  });
  const gone = await call('GET', '/drawings/search', {
    token: buyer.access,
    query: { q: KEYWORD },
  });
  ok(
    !gone.json.items.some((i: Json) => i.id === paid2.id),
    'removed drawing no longer in search',
  );
  const dl2 = await call('GET', `/drawings/${paid2.id}/download`, {
    token: buyer.access,
    query: { sheetId: paid2.sheets[0].id },
  });
  ok(
    typeof dl2.json.url === 'string',
    'past buyer can still download a REMOVED drawing',
  );

  console.log(
    `\nSMOKE PASSED — ${stepNo} steps in ${((Date.now() - t0) / 1000).toFixed(1)}s`,
  );
}

main().catch((err: unknown) => {
  console.error(
    `\nSMOKE FAILED at step ${stepNo}:`,
    err instanceof Error ? err.message : err,
  );
  process.exit(1);
});
