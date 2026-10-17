import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { App } from 'supertest/types';
import { AppModule } from '../src/app.module';
import { configureApp } from '../src/app.setup';
import { PrismaService } from '../src/prisma/prisma.service';
import { bearer, createTestUser, TestUser } from './helpers/auth';
import { resetDb } from './helpers/db';
import { createCategory, createDrawing } from './helpers/fixtures';
import { waitForEmail } from './helpers/mailpit';

interface ErrBody {
  error: { code: string; message: string };
}

interface FlagItem {
  id: string;
  status: string;
  hammingDistance: number;
  drawing: {
    id: string;
    title: string;
    status: string;
    architect: { id: string };
    sheets: { previewUrl: string | null; isPreview: boolean }[];
  };
  matchedDrawing: { id: string; status: string };
  flaggedSheet: { id: string; previewUrl: string | null };
  matchedSheet: { id: string; previewUrl: string | null };
}

describe('Admin plagiarism review (e2e)', () => {
  let app: INestApplication<App>;
  let prisma: PrismaService;
  let categoryId: string;
  let admin: TestUser;
  let alice: TestUser; // original author
  let bob: TestUser; // flagged uploader
  const http = () => request(app.getHttpServer());
  const stamp = Date.now();

  async function flagged(
    title: string,
    distance = 3,
    matchedTitle = 'Original',
  ) {
    const original = await createDrawing(prisma, {
      architectId: alice.user.id,
      categoryId,
      title: matchedTitle,
      previewKeys: [`orig-${title}.png`],
    });
    const copy = await createDrawing(prisma, {
      architectId: bob.user.id,
      categoryId,
      title,
      status: 'UNDER_REVIEW',
      previewKeys: [`copy-${title}.png`],
    });
    const [mine, theirs] = await Promise.all([
      prisma.drawingSheet.findFirstOrThrow({ where: { drawingId: copy.id } }),
      prisma.drawingSheet.findFirstOrThrow({
        where: { drawingId: original.id },
      }),
    ]);
    const flag = await prisma.plagiarismFlag.create({
      data: {
        drawingId: copy.id,
        matchedDrawingId: original.id,
        sheetId: mine.id,
        matchedSheetId: theirs.id,
        hammingDistance: distance,
      },
    });
    return { original, copy, flag };
  }

  const list = (query = '', as = admin) =>
    http()
      .get(`/admin/plagiarism-flags${query}`)
      .set(...bearer(as));
  const decide = (id: string, action: 'approve' | 'reject', body = {}) =>
    http()
      .post(`/admin/plagiarism-flags/${id}/${action}`)
      .set(...bearer(admin))
      .send(body);

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();
    app = moduleRef.createNestApplication();
    configureApp(app);
    await app.init();
    prisma = app.get(PrismaService);
  });

  beforeEach(async () => {
    await resetDb(prisma);
    categoryId = (await createCategory(prisma)).id;
    admin = await createTestUser(app, { role: 'ADMIN', fullName: 'Admin' });
    alice = await createTestUser(app, { fullName: 'Alice' });
    bob = await createTestUser(app, {
      fullName: 'Bob',
      email: `bob-${stamp}-${Math.random().toString(36).slice(2)}@example.com`,
    });
  });

  afterAll(async () => {
    await resetDb(prisma);
    await app.close();
  });

  it('is admin-only', async () => {
    const { flag } = await flagged('Copy');
    await http().get('/admin/plagiarism-flags').expect(401);
    await list('', bob).expect(403);
    await http()
      .post(`/admin/plagiarism-flags/${flag.id}/approve`)
      .set(...bearer(bob))
      .expect(403);
    await http()
      .post(`/admin/plagiarism-flags/${flag.id}/reject`)
      .set(...bearer(bob))
      .send({ reason: 'x' })
      .expect(403);
    expect(
      (
        await prisma.drawing.findUniqueOrThrow({
          where: { id: flag.drawingId },
        })
      ).status,
    ).toBe('UNDER_REVIEW');
  });

  it('lists pending flags oldest first with both drawings side by side, paginated', async () => {
    const first = await flagged('First copy', 2);
    const second = await flagged('Second copy', 7, 'Another original');

    const res = await list('?limit=1').expect(200);
    const page = res.body as { items: FlagItem[]; nextCursor: string | null };
    expect(page.items).toHaveLength(1);
    expect(page.nextCursor).toBeTruthy();
    const item = page.items[0];
    expect(item).toMatchObject({
      id: first.flag.id,
      status: 'PENDING',
      hammingDistance: 2,
      drawing: { id: first.copy.id, status: 'UNDER_REVIEW' },
      matchedDrawing: { id: first.original.id, status: 'PUBLISHED' },
    });
    expect(item.drawing.architect.id).toBe(bob.user.id);
    expect(item.flaggedSheet.id).toBe(first.flag.sheetId);
    expect(item.matchedSheet.id).toBe(first.flag.matchedSheetId);
    expect(item.flaggedSheet.previewUrl).toContain('copy-First copy.png');
    expect(item.matchedSheet.previewUrl).toContain('orig-First copy.png');
    expect(item.drawing.sheets).toHaveLength(1);
    expect(JSON.stringify(res.body)).not.toContain('originalKey');

    const next = await list(`?limit=1&cursor=${page.nextCursor}`).expect(200);
    const nextPage = next.body as { items: FlagItem[]; nextCursor: null };
    expect(nextPage.items.map((i) => i.id)).toEqual([second.flag.id]);
    expect(nextPage.nextCursor).toBeNull();

    await list('?status=NOPE').expect(400);
    const decided = await list('?status=APPROVED').expect(200);
    expect((decided.body as { items: unknown[] }).items).toHaveLength(0);
  });

  it('hides flags whose drawing is no longer under review', async () => {
    const { copy } = await flagged('Withdrawn');
    await prisma.drawing.update({
      where: { id: copy.id },
      data: { status: 'REMOVED' },
    });
    const res = await list().expect(200);
    expect((res.body as { items: unknown[] }).items).toHaveLength(0);
  });

  it('approve publishes the drawing, resolves all its flags and emails the uploader', async () => {
    const { copy, flag } = await flagged('Looks similar');
    const other = await flagged('unused');
    await prisma.drawing.update({
      where: { id: other.copy.id },
      data: { status: 'REMOVED' },
    });
    // A second pending flag on the same drawing is resolved by the same decision.
    const extra = await prisma.plagiarismFlag.create({
      data: { ...pick(flag), matchedDrawingId: other.original.id },
    });

    const res = await decide(flag.id, 'approve').expect(201);
    expect(res.body).toEqual({ ok: true });

    const d = await prisma.drawing.findUniqueOrThrow({
      where: { id: copy.id },
    });
    expect(d.status).toBe('PUBLISHED');
    const flags = await prisma.plagiarismFlag.findMany({
      where: { id: { in: [flag.id, extra.id] } },
    });
    expect(flags.map((f) => f.status)).toEqual(['APPROVED', 'APPROVED']);
    expect(flags.every((f) => f.reviewedById === admin.user.id)).toBe(true);
    expect(flags.every((f) => f.reviewedAt !== null)).toBe(true);
    const audit = await prisma.auditLog.findFirstOrThrow({
      where: { action: 'plagiarism.approve' },
    });
    expect(audit).toMatchObject({ actorId: admin.user.id, entityId: flag.id });

    const mail = await waitForEmail(bob.user.email, 'now live');
    expect(mail.Text).toContain('Looks similar');

    const visible = await http()
      .get(`/drawings/${copy.id}`)
      .set(...bearer(alice))
      .expect(200);
    expect((visible.body as { status: string }).status).toBe('PUBLISHED');

    expect((await decide(flag.id, 'approve').expect(409)).body).toMatchObject({
      error: { code: 'CONFLICT' },
    });
    await decide(flag.id, 'reject', { reason: 'late' }).expect(409);
  });

  it('reject needs a reason, removes the drawing, records the note and emails the uploader', async () => {
    const { copy, flag } = await flagged('Stolen plan');

    const noReason = await decide(flag.id, 'reject', {}).expect(400);
    expect((noReason.body as ErrBody).error.code).toBe('VALIDATION_ERROR');
    await decide(flag.id, 'reject', { reason: '   ' }).expect(400);
    await decide(flag.id, 'reject', { reason: 'x'.repeat(501) }).expect(400);

    await decide(flag.id, 'reject', {
      reason: 'Matches an existing drawing by another architect',
    }).expect(201);

    const d = await prisma.drawing.findUniqueOrThrow({
      where: { id: copy.id },
    });
    expect(d).toMatchObject({
      status: 'REMOVED',
      failureReason: 'Matches an existing drawing by another architect',
    });
    const f = await prisma.plagiarismFlag.findUniqueOrThrow({
      where: { id: flag.id },
    });
    expect(f).toMatchObject({
      status: 'REJECTED',
      reviewNote: 'Matches an existing drawing by another architect',
      reviewedById: admin.user.id,
    });
    expect(
      await prisma.auditLog.count({ where: { action: 'plagiarism.reject' } }),
    ).toBe(1);

    const mail = await waitForEmail(bob.user.email, 'not approved');
    expect(mail.Text).toContain(
      'Reason: Matches an existing drawing by another architect',
    );
    await http()
      .get(`/drawings/${copy.id}`)
      .set(...bearer(alice))
      .expect(404);
    await decide(flag.id, 'approve').expect(409);
  });

  it('returns 404 for unknown flags, 400 for bad ids and 409 if the owner removed the drawing meanwhile', async () => {
    await decide('11111111-1111-4111-8111-111111111111', 'approve').expect(404);
    await http()
      .post('/admin/plagiarism-flags/not-a-uuid/approve')
      .set(...bearer(admin))
      .expect(400);

    const { copy, flag } = await flagged('Deleted by owner');
    await http()
      .delete(`/drawings/${copy.id}`)
      .set(...bearer(bob))
      .expect(204);
    await decide(flag.id, 'approve').expect(409);
    expect(
      (await prisma.drawing.findUniqueOrThrow({ where: { id: copy.id } }))
        .status,
    ).toBe('REMOVED');
  });
});

function pick(flag: {
  drawingId: string;
  matchedDrawingId: string;
  sheetId: string;
  matchedSheetId: string;
  hammingDistance: number;
}) {
  return {
    drawingId: flag.drawingId,
    matchedDrawingId: flag.matchedDrawingId,
    sheetId: flag.sheetId,
    matchedSheetId: flag.matchedSheetId,
    hammingDistance: flag.hammingDistance,
  };
}
