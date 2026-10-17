import { INestApplication } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import sharp from 'sharp';
import { App } from 'supertest/types';
import { AppModule } from '../src/app.module';
import { configureApp } from '../src/app.setup';
import { Env } from '../src/config/env.schema';
import { ContributionService } from '../src/drawings/contribution.service';
import { PrismaService } from '../src/prisma/prisma.service';
import { StorageService } from '../src/storage/storage.service';
import { bearer, createTestUser, TestUser } from './helpers/auth';
import { resetDb } from './helpers/db';
import { createCategory, createDrawing } from './helpers/fixtures';

interface ErrBody {
  error: { code: string; message: string; details?: Record<string, number> };
}

interface StatusBody {
  freePublished: number;
  paidPublished: number;
  paidPending: number;
  freeNeeded: number;
  canPublishPaid: boolean;
  guidance: string;
}

describe('Contribution rule (e2e)', () => {
  describe('default ratio (1 free per paid)', () => {
    let app: INestApplication<App>;
    let prisma: PrismaService;
    let storage: StorageService;
    let me: TestUser;
    let categoryId: string;
    const keys: string[] = [];
    const http = () => request(app.getHttpServer());
    const publish = (id: string, user = me) =>
      http()
        .post(`/drawings/${id}/publish`)
        .set(...bearer(user));
    const getStatus = async (user = me) =>
      (
        await http()
          .get('/me/contribution-status')
          .set(...bearer(user))
          .expect(200)
      ).body as StatusBody;

    // A DRAFT with one preview sheet whose original really exists, so a successful publish can process it.
    async function draft(pricePaise: number, color = '#336699') {
      const d = await createDrawing(prisma, {
        architectId: me.user.id,
        categoryId,
        pricePaise,
        status: 'DRAFT',
      });
      const key = `contribution-test/${d.id}.png`;
      keys.push(key);
      const png = await sharp({
        create: { width: 400, height: 300, channels: 3, background: color },
      })
        .png()
        .toBuffer();
      await storage.putOriginal(key, png, 'image/png');
      await prisma.drawingSheet.create({
        data: {
          drawingId: d.id,
          originalKey: key,
          originalMime: 'image/png',
          fileName: 'a.png',
          sizeBytes: png.length,
          isPreview: true,
        },
      });
      return d.id;
    }

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
      categoryId = (await createCategory(prisma)).id;
      me = await createTestUser(app);
    });

    afterAll(async () => {
      await Promise.all(keys.map((k) => storage.deleteOriginal(k)));
      await resetDb(prisma);
      await app.close();
    });

    it('requires authentication', async () => {
      await http().get('/me/contribution-status').expect(401);
    });

    it('reports status for a new architect', async () => {
      const s = await getStatus();
      expect(s).toMatchObject({
        freePublished: 0,
        paidPublished: 0,
        paidPending: 0,
        canPublishPaid: true,
        freeNeeded: 0,
      });
      expect(s.guidance).toContain('first paid drawing');
    });

    it('lets the first paid drawing through, then blocks the 2nd until a free one is published', async () => {
      const first = await draft(500);
      await publish(first).expect(202);
      // A pending paid drawing already counts, so the rule cannot be bypassed by publishing quickly.
      const second = await draft(700, '#993366');
      const blocked = await publish(second).expect(403);
      const err = (blocked.body as ErrBody).error;
      expect(err.code).toBe('CONTRIBUTION_REQUIRED');
      expect(err.message).toContain('1 more free drawing');
      expect(err.details).toMatchObject({ freeNeeded: 1, freePerPaid: 1 });
      expect(
        (await prisma.drawing.findUniqueOrThrow({ where: { id: second } }))
          .status,
      ).toBe('DRAFT');

      await prisma.drawing.update({
        where: { id: first },
        data: { status: 'PUBLISHED' },
      });
      let s = await getStatus();
      expect(s).toMatchObject({
        paidPublished: 1,
        freePublished: 0,
        canPublishPaid: false,
        freeNeeded: 1,
      });

      // A free drawing is never blocked, and once it is PUBLISHED the paid one goes through.
      const free = await draft(0, '#66aa33');
      await publish(free).expect(202);
      await publish(second).expect(403); // free one is still PROCESSING, not PUBLISHED
      await prisma.drawing.update({
        where: { id: free },
        data: { status: 'PUBLISHED' },
      });
      s = await getStatus();
      expect(s).toMatchObject({ freePublished: 1, canPublishPaid: true });
      await publish(second).expect(202);
      s = await getStatus();
      expect(s.paidPending).toBe(1);
      expect(s.canPublishPaid).toBe(false);
    });

    it('serialises concurrent paid publishes', async () => {
      const a = await draft(500, '#111111');
      const b = await draft(500, '#eeeeee');
      const results = await Promise.all([publish(a), publish(b)]);
      expect(results.map((r) => r.status).sort()).toEqual([202, 403]);
    });

    it('does not count other architects or non-published drawings', async () => {
      const other = await createTestUser(app);
      await createDrawing(prisma, {
        architectId: other.user.id,
        categoryId,
        pricePaise: 0,
      });
      await createDrawing(prisma, {
        architectId: me.user.id,
        categoryId,
        pricePaise: 0,
        status: 'REMOVED',
      });
      await createDrawing(prisma, {
        architectId: me.user.id,
        categoryId,
        pricePaise: 400,
      });
      expect(await getStatus()).toMatchObject({
        freePublished: 0,
        paidPublished: 1,
        canPublishPaid: false,
      });
      expect(await getStatus(other)).toMatchObject({
        freePublished: 1,
        paidPublished: 0,
        canPublishPaid: true,
      });
    });
  });

  describe('rule disabled (ratio 0)', () => {
    it('never blocks paid drawings', async () => {
      const moduleRef = await Test.createTestingModule({
        imports: [AppModule],
      }).compile();
      const app = moduleRef.createNestApplication<INestApplication<App>>();
      await app.init();
      const prisma = app.get(PrismaService);
      try {
        await resetDb(prisma);
        const me = await createTestUser(app);
        const categoryId = (await createCategory(prisma)).id;
        for (let i = 0; i < 2; i++) {
          await createDrawing(prisma, {
            architectId: me.user.id,
            categoryId,
            pricePaise: 100,
          });
        }
        const service = new ContributionService(prisma, {
          get: () => 0,
        } as unknown as ConfigService<Env, true>);
        expect(await service.status(me.user.id)).toMatchObject({
          paidPublished: 2,
          canPublishPaid: true,
          freeNeeded: 0,
        });
        await expect(
          service.assertCanPublishPaid(me.user.id),
        ).resolves.toBeUndefined();
      } finally {
        await resetDb(prisma);
        await app.close();
      }
    });
  });
});
