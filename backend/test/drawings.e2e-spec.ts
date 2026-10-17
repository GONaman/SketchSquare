import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { App } from 'supertest/types';
import { AppModule } from '../src/app.module';
import { configureApp } from '../src/app.setup';
import { PrismaService } from '../src/prisma/prisma.service';
import { bearer, createTestUser } from './helpers/auth';
import { resetDb } from './helpers/db';

interface ErrBody {
  error: { code: string; message: string };
}
interface DetailBody {
  id: string;
  status: string;
  plotLengthFt: number;
  plotBreadthFt: number;
  plotAreaSqft: number;
  pricePaise: number;
  isFree: boolean;
  tags: string[];
  bedrooms: number | null;
  title: string;
  sheets: unknown[];
  previewUrl: string | null;
  architect: { id: string };
}

describe('Drawings CRUD (e2e)', () => {
  let app: INestApplication<App>;
  let prisma: PrismaService;
  const http = () => request(app.getHttpServer());
  let categoryId: string;

  const body = (over: Record<string, unknown> = {}) => ({
    title: 'Modern 2BHK',
    description: 'Compact family home',
    categoryId,
    city: 'Pune',
    plotLength: 40,
    plotBreadth: 30,
    unit: 'ft',
    floors: 2,
    facing: 'N',
    pricePaise: 49900,
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
  });

  beforeEach(async () => {
    await resetDb(prisma);
    categoryId = (
      await prisma.category.create({
        data: { name: 'Residential', slug: 'residential' },
      })
    ).id;
  });

  afterAll(async () => {
    await resetDb(prisma);
    await app.close();
  });

  it('requires authentication and approval', async () => {
    await http().post('/drawings').send(body()).expect(401);
    const pending = await createTestUser(app, {
      verificationStatus: 'PENDING',
    });
    await http()
      .post('/drawings')
      .set(...bearer(pending))
      .send(body())
      .expect(403);
  });

  it('creates a DRAFT, converting units and maintaining the area trigger', async () => {
    const me = await createTestUser(app);
    const res = await http()
      .post('/drawings')
      .set(...bearer(me))
      .send(
        body({
          unit: 'm',
          plotLength: 10,
          plotBreadth: 5,
          tags: ['Vastu', 'vastu', ' corner '],
          bedrooms: 3,
        }),
      )
      .expect(201);
    const d = res.body as DetailBody;
    expect(d.status).toBe('DRAFT');
    expect(d.plotLengthFt).toBeCloseTo(32.81, 2);
    expect(d.plotBreadthFt).toBeCloseTo(16.4, 2);
    expect(d.plotAreaSqft).toBeCloseTo(32.81 * 16.4, 1);
    expect(d.tags).toEqual(['vastu', 'corner']);
    expect(d.bedrooms).toBe(3);
    expect(d.architect.id).toBe(me.user.id);
    expect(d.sheets).toEqual([]);
    expect(d.previewUrl).toBeNull();
  });

  it('isFree forces price 0; price is required otherwise', async () => {
    const me = await createTestUser(app);
    const free = await http()
      .post('/drawings')
      .set(...bearer(me))
      .send(body({ isFree: true, pricePaise: 999 }))
      .expect(201);
    expect((free.body as DetailBody).pricePaise).toBe(0);
    expect((free.body as DetailBody).isFree).toBe(true);

    const res = await http()
      .post('/drawings')
      .set(...bearer(me))
      .send(body({ pricePaise: undefined }))
      .expect(400);
    expect((res.body as ErrBody).error.code).toBe('VALIDATION_ERROR');
  });

  it('validates input and category', async () => {
    const me = await createTestUser(app);
    const bad: Record<string, unknown>[] = [
      { title: 'x' },
      { unit: 'yd' },
      { plotLength: -1 },
      { floors: 0 },
      { bedrooms: 21 },
      { tags: Array(9).fill('a') },
      { tags: ['x'.repeat(25)] },
      { pricePaise: -5 },
      { pricePaise: 1.5 },
      { categoryId: 'nope' },
      { unexpected: 1 },
    ];
    for (const over of bad) {
      const res = await http()
        .post('/drawings')
        .set(...bearer(me))
        .send(body(over))
        .expect(400);
      expect((res.body as ErrBody).error.code).toBe('VALIDATION_ERROR');
    }
    const missing = await http()
      .post('/drawings')
      .set(...bearer(me))
      .send(body({ categoryId: '11111111-1111-4111-8111-111111111111' }))
      .expect(400);
    expect((missing.body as ErrBody).error.message).toContain('categoryId');
    await prisma.category.update({
      where: { id: categoryId },
      data: { isActive: false },
    });
    await http()
      .post('/drawings')
      .set(...bearer(me))
      .send(body())
      .expect(400);
  });

  it('only the owner may modify or delete (403), unknown id is 404', async () => {
    const owner = await createTestUser(app);
    const other = await createTestUser(app);
    const { id } = (
      await http()
        .post('/drawings')
        .set(...bearer(owner))
        .send(body())
        .expect(201)
    ).body as DetailBody;

    await http()
      .patch(`/drawings/${id}`)
      .set(...bearer(other))
      .send({ title: 'Hijack' })
      .expect(403);
    await http()
      .delete(`/drawings/${id}`)
      .set(...bearer(other))
      .expect(403);
    await http()
      .patch('/drawings/11111111-1111-4111-8111-111111111111')
      .set(...bearer(owner))
      .send({ title: 'Nothing' })
      .expect(404);
    await http()
      .patch('/drawings/not-a-uuid')
      .set(...bearer(owner))
      .send({ title: 'Nothing' })
      .expect(400);
  });

  it('drafts accept any field; published only title/description/price', async () => {
    const me = await createTestUser(app);
    const { id } = (
      await http()
        .post('/drawings')
        .set(...bearer(me))
        .send(body())
        .expect(201)
    ).body as DetailBody;

    const draft = await http()
      .patch(`/drawings/${id}`)
      .set(...bearer(me))
      .send({ city: 'Mumbai', plotLength: 50, floors: 3, isFree: true })
      .expect(200);
    expect((draft.body as DetailBody).plotLengthFt).toBe(50);
    expect((draft.body as DetailBody).pricePaise).toBe(0);

    await prisma.drawing.update({
      where: { id },
      data: { status: 'PUBLISHED' },
    });
    const ok = await http()
      .patch(`/drawings/${id}`)
      .set(...bearer(me))
      .send({ title: 'New title here', pricePaise: 12300 })
      .expect(200);
    expect((ok.body as DetailBody).title).toBe('New title here');
    expect((ok.body as DetailBody).pricePaise).toBe(12300);

    const locked = await http()
      .patch(`/drawings/${id}`)
      .set(...bearer(me))
      .send({ city: 'Delhi' })
      .expect(400);
    expect((locked.body as ErrBody).error.code).toBe('VALIDATION_ERROR');
  });

  it('rejects edits while PROCESSING (409)', async () => {
    const me = await createTestUser(app);
    const { id } = (
      await http()
        .post('/drawings')
        .set(...bearer(me))
        .send(body())
        .expect(201)
    ).body as DetailBody;
    await prisma.drawing.update({
      where: { id },
      data: { status: 'PROCESSING' },
    });
    await http()
      .patch(`/drawings/${id}`)
      .set(...bearer(me))
      .send({ title: 'Edit now' })
      .expect(409);
  });

  it('DELETE soft-deletes (204), is idempotent, and hides the drawing from later edits', async () => {
    const me = await createTestUser(app);
    const { id } = (
      await http()
        .post('/drawings')
        .set(...bearer(me))
        .send(body())
        .expect(201)
    ).body as DetailBody;
    await http()
      .delete(`/drawings/${id}`)
      .set(...bearer(me))
      .expect(204);
    await http()
      .delete(`/drawings/${id}`)
      .set(...bearer(me))
      .expect(204);
    expect(
      (await prisma.drawing.findUniqueOrThrow({ where: { id } })).status,
    ).toBe('REMOVED');
    await http()
      .patch(`/drawings/${id}`)
      .set(...bearer(me))
      .send({ title: 'Zombie edit' })
      .expect(404);
  });
});
