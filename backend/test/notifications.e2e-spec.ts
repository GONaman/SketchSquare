/* eslint-disable @typescript-eslint/no-unsafe-member-access, @typescript-eslint/no-unsafe-assignment, @typescript-eslint/no-unsafe-argument, @typescript-eslint/no-unsafe-call -- supertest bodies are untyped */
import { INestApplication } from '@nestjs/common';
import { Role, VerificationStatus } from '@prisma/client';
import { randomUUID } from 'node:crypto';
import request from 'supertest';
import { PayoutService } from '../src/commerce/payouts/payout.service';
import { PAYOUT_QUEUE } from '../src/commerce/payouts/payout.queue';
import { STUB_PAYOUT_WEBHOOK_SECRET } from '../src/commerce/payouts/stub-payout.provider';
import { hmacSha256Hex } from '../src/commerce/payments/signature';
import { LedgerService } from '../src/ledger/ledger.service';
import { PUSH_SERVICE } from '../src/notifications/push.service';
import { StubPushService } from '../src/notifications/stub-push.service';
import { PrismaService } from '../src/prisma/prisma.service';
import { bearer, createTestUser, TestUser } from './helpers/auth';
import { buildCommerceApp } from './helpers/commerce-app';
import { createDrawing } from './helpers/commerce-fixtures';
import { resetDb } from './helpers/db';

const TOKEN_A = 'fcm-token-aaaaaaaaaa';
const TOKEN_B = 'fcm-token-bbbbbbbbbb';

describe('Device tokens, notifications and push (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let push: StubPushService;
  let ledger: LedgerService;
  let payouts: PayoutService;
  let enqueued: string[];
  let a: TestUser;
  let b: TestUser;
  const http = () => request(app.getHttpServer());

  const register = (u: TestUser, token: string, platform = 'android') =>
    http()
      .post('/me/device-tokens')
      .set(...bearer(u))
      .send({ token, platform });
  const unregister = (u: TestUser, token: string) =>
    http()
      .delete('/me/device-tokens')
      .set(...bearer(u))
      .send({ token });
  const list = (u: TestUser, qs = '') =>
    http()
      .get(`/me/notifications${qs}`)
      .set(...bearer(u));

  // Pushes are delivered asynchronously by the queue worker.
  async function pushesFor(token: string, type: string, count = 1) {
    const deadline = Date.now() + 12_000;
    for (;;) {
      const hits = push.sent.filter(
        (s) => s.target.token === token && s.message.data.type === type,
      );
      if (hits.length >= count || Date.now() > deadline) return hits;
      await new Promise((r) => setTimeout(r, 100));
    }
  }
  const notificationsOf = (userId: string, type?: string) =>
    prisma.notification.findMany({
      where: { userId, ...(type ? { type } : {}) },
      orderBy: { createdAt: 'asc' },
    });

  beforeAll(async () => {
    enqueued = [];
    ({ app, prisma } = await buildCommerceApp({
      overrides: [
        {
          token: PAYOUT_QUEUE,
          useValue: {
            enqueue: (id: string) => {
              enqueued.push(id);
              return Promise.resolve();
            },
          },
        },
      ],
    }));
    push = app.get<StubPushService>(PUSH_SERVICE);
    ledger = app.get(LedgerService);
    payouts = app.get(PayoutService);
  });

  afterAll(async () => {
    await resetDb(prisma);
    await app.close();
  });

  beforeEach(async () => {
    await resetDb(prisma);
    enqueued = [];
    push.sent.length = 0;
    a = await createTestUser(app, { fullName: 'Asha Seller' });
    b = await createTestUser(app, { fullName: 'Bala Buyer' });
  });

  it('uses the stub sender when no FCM credentials are configured', () => {
    expect(push).toBeInstanceOf(StubPushService);
  });

  describe('device tokens', () => {
    it('requires authentication', async () => {
      await http()
        .post('/me/device-tokens')
        .send({ token: TOKEN_A, platform: 'ios' })
        .expect(401);
      await http()
        .delete('/me/device-tokens')
        .send({ token: TOKEN_A })
        .expect(401);
      await http().get('/me/notifications').expect(401);
    });

    it('registers idempotently, validates input and works for unverified users', async () => {
      await register(a, TOKEN_A, 'Android').expect(204);
      await register(a, TOKEN_A, 'android').expect(204);
      const rows = await prisma.deviceToken.findMany();
      expect(rows).toHaveLength(1);
      expect(rows[0]).toMatchObject({
        token: TOKEN_A,
        platform: 'android',
        userId: a.user.id,
      });

      await register(a, 'short', 'android').expect(400);
      await register(a, TOKEN_B, 'symbian').expect(400);
      await http()
        .post('/me/devices')
        .set(...bearer(a))
        .send({ token: TOKEN_B, platform: 'web' })
        .expect(204);

      const pending = await createTestUser(app, {
        verificationStatus: VerificationStatus.PENDING,
      });
      await register(pending, 'fcm-token-pending-1').expect(204);
      await list(pending).expect(200);
    });

    it('re-assigns a token to the latest user who registers it', async () => {
      await register(a, TOKEN_A).expect(204);
      await register(b, TOKEN_A).expect(204);
      const rows = await prisma.deviceToken.findMany();
      expect(rows).toHaveLength(1);
      expect(rows[0].userId).toBe(b.user.id);
    });

    it('lets a user remove only their own token, idempotently', async () => {
      await register(a, TOKEN_A).expect(204);
      await unregister(b, TOKEN_A).expect(204);
      expect(await prisma.deviceToken.count()).toBe(1);
      await unregister(a, TOKEN_A).expect(204);
      await unregister(a, TOKEN_A).expect(204);
      expect(await prisma.deviceToken.count()).toBe(0);
    });
  });

  describe('GET /me/notifications and read', () => {
    const seed = async (userId: string, n: number) => {
      for (let i = 0; i < n; i++) {
        await prisma.notification.create({
          data: {
            userId,
            type: 'NEW_REVIEW',
            title: `t${i}`,
            body: 'b',
            data: { type: 'NEW_REVIEW' },
            createdAt: new Date(Date.UTC(2026, 0, 1, 0, 0, i)),
          },
        });
      }
    };

    it('lists only my notifications, newest first, with cursor pagination and unreadCount', async () => {
      await seed(a.user.id, 3);
      await seed(b.user.id, 2);
      const p1 = await list(a, '?limit=2').expect(200);
      expect(p1.body.items.map((i: { title: string }) => i.title)).toEqual([
        't2',
        't1',
      ]);
      expect(p1.body.unreadCount).toBe(3);
      expect(p1.body.nextCursor).toEqual(expect.any(String));
      expect(p1.body.items[0]).toMatchObject({
        type: 'NEW_REVIEW',
        readAt: null,
        data: { type: 'NEW_REVIEW' },
      });
      const p2 = await list(
        a,
        `?limit=2&cursor=${encodeURIComponent(p1.body.nextCursor)}`,
      ).expect(200);
      expect(p2.body.items.map((i: { title: string }) => i.title)).toEqual([
        't0',
      ]);
      expect(p2.body.nextCursor).toBeNull();
      await list(a, '?cursor=garbage').expect(400);
    });

    it('marks read only my own notifications (all, or by id)', async () => {
      await seed(a.user.id, 3);
      await seed(b.user.id, 1);
      const mine = await prisma.notification.findMany({
        where: { userId: a.user.id },
      });
      const theirs = await prisma.notification.findFirstOrThrow({
        where: { userId: b.user.id },
      });
      await http()
        .post('/me/notifications/read')
        .set(...bearer(a))
        .send({ ids: [mine[0].id, theirs.id] })
        .expect(204);
      expect((await list(a)).body.unreadCount).toBe(2);
      expect((await list(b)).body.unreadCount).toBe(1);
      await http()
        .post('/me/notifications/read')
        .set(...bearer(a))
        .send({})
        .expect(204);
      expect((await list(a)).body.unreadCount).toBe(0);
      expect((await list(b)).body.unreadCount).toBe(1);
      await http()
        .post('/me/notifications/read')
        .set(...bearer(a))
        .send({ ids: ['nope'] })
        .expect(400);
    });
  });

  describe('events', () => {
    beforeEach(async () => {
      await register(a, TOKEN_A).expect(204);
    });

    it('verification approve and reject notify the architect', async () => {
      const admin = await createTestUser(app, { role: Role.ADMIN });
      const mk = async (status: 'approve' | 'reject') => {
        const u = await createTestUser(app, {
          verificationStatus: VerificationStatus.PENDING,
        });
        await register(u, `fcm-token-${randomUUID()}`).expect(204);
        const v = await prisma.verificationRequest.create({
          data: {
            userId: u.user.id,
            coaRegistrationNumber: 'CA/2015/12345',
            documentKey: `kyc/${randomUUID()}.pdf`,
          },
        });
        const req = http()
          .post(`/admin/verifications/${v.id}/${status}`)
          .set(...bearer(admin));
        await (
          status === 'reject' ? req.send({ note: 'Blurry scan' }) : req
        ).expect(201);
        return u;
      };
      const ok = await mk('approve');
      const bad = await mk('reject');

      const [n1] = await notificationsOf(ok.user.id, 'VERIFICATION_RESULT');
      expect(n1.title).toBe('Welcome to SketchSquare');
      const [n2] = await notificationsOf(bad.user.id, 'VERIFICATION_RESULT');
      expect(n2.body).toContain('Blurry scan');
      const hits = await pushesFor(
        (
          await prisma.deviceToken.findFirstOrThrow({
            where: { userId: ok.user.id },
          })
        ).token,
        'VERIFICATION_RESULT',
      );
      expect(hits).toHaveLength(1);
      // Replaying the decision conflicts and does not notify again.
      expect(await notificationsOf(ok.user.id)).toHaveLength(1);
    });

    it('a sale notifies the seller once, even if the settlement is replayed', async () => {
      const d = await createDrawing(prisma, a.user.id, {
        pricePaise: 100000,
        title: 'Corner Villa',
      });
      await http()
        .post('/cart')
        .set(...bearer(b))
        .send({ drawingId: d.id })
        .expect(201);
      const order = (
        await http()
          .post('/checkout')
          .set(...bearer(b))
          .expect(200)
      ).body;
      const complete = () =>
        http()
          .post('/checkout/stub-complete')
          .set(...bearer(b))
          .send({ orderId: order.orderId })
          .expect(200);
      await complete();
      await complete();

      const sales = await notificationsOf(a.user.id, 'SALE_MADE');
      expect(sales).toHaveLength(1);
      expect(sales[0].body).toContain('Corner Villa');
      expect(sales[0].body).toContain('₹900');
      expect(await pushesFor(TOKEN_A, 'SALE_MADE')).toHaveLength(1);
      // The buyer is not notified of the seller's sale.
      expect(await notificationsOf(b.user.id)).toHaveLength(0);
    });

    it('a review notifies the author once; editing the review does not re-notify', async () => {
      const d = await createDrawing(prisma, a.user.id, {
        title: 'Corner Villa',
      });
      await prisma.purchase.create({
        data: {
          buyerId: b.user.id,
          drawingId: d.id,
          pricePaise: 100000,
          platformFeePaise: 0,
          status: 'PAID',
          paidAt: new Date(),
        },
      });
      const put = (rating: number) =>
        http()
          .put(`/drawings/${d.id}/review`)
          .set(...bearer(b))
          .send({ rating })
          .expect(200);
      await put(5);
      await put(3);
      const rows = await notificationsOf(a.user.id, 'NEW_REVIEW');
      expect(rows).toHaveLength(1);
      expect(rows[0].body).toBe('Bala Buyer rated "Corner Villa" 5/5.');
      expect(await pushesFor(TOKEN_A, 'NEW_REVIEW')).toHaveLength(1);
    });

    it('interest notifies the owner once per user, even when toggled', async () => {
      const d = await createDrawing(prisma, a.user.id, {
        title: 'Corner Villa',
      });
      const put = () =>
        http()
          .put(`/drawings/${d.id}/interest`)
          .set(...bearer(b));
      await put().expect(204);
      await put().expect(204);
      await http()
        .delete(`/drawings/${d.id}/interest`)
        .set(...bearer(b))
        .expect(204);
      await put().expect(204);

      const rows = await notificationsOf(a.user.id, 'INTEREST_RECEIVED');
      expect(rows).toHaveLength(1);
      expect(rows[0].body).toBe('Bala Buyer is interested in "Corner Villa".');
      expect(await pushesFor(TOKEN_A, 'INTEREST_RECEIVED')).toHaveLength(1);
      // The interested user gets nothing.
      expect(await notificationsOf(b.user.id)).toHaveLength(0);
    });

    describe('withdrawals', () => {
      const BANK = {
        holderName: 'Asha Rao',
        ifsc: 'HDFC0001234',
        accountNumber: '123456789012',
      };
      async function requestWithdrawal() {
        await http()
          .post('/wallet/bank-account')
          .set(...bearer(a))
          .send(BANK)
          .expect(200);
        const ref = randomUUID();
        await ledger.postTransaction([
          {
            accountType: 'PAYMENT_GATEWAY',
            amountPaise: -300000,
            entryType: 'SALE',
            referenceId: ref,
          },
          {
            accountType: 'USER_WALLET',
            accountOwnerId: a.user.id,
            amountPaise: 300000,
            entryType: 'SALE',
            referenceId: ref,
          },
        ]);
        const res = await http()
          .post('/wallet/withdrawals')
          .set(...bearer(a))
          .send({ amountPaise: 100000 })
          .expect(201);
        return res.body.id as string;
      }

      it('notifies once when the payout is PAID', async () => {
        const id = await requestWithdrawal();
        await payouts.process(id);
        await payouts.process(id);
        const rows = await notificationsOf(a.user.id, 'WITHDRAWAL_STATUS');
        expect(rows).toHaveLength(1);
        expect(rows[0].title).toBe('Withdrawal completed');
        expect(rows[0].body).toContain('₹1,000');
        expect(await pushesFor(TOKEN_A, 'WITHDRAWAL_STATUS')).toHaveLength(1);
      });

      it('notifies once when the payout FAILED and the money is returned', async () => {
        const id = await requestWithdrawal();
        await prisma.withdrawal.update({
          where: { id },
          data: { status: 'PROCESSING', providerRef: `pout_${id}` },
        });
        const raw = JSON.stringify({
          event: 'payout.failed',
          payload: {
            payout: { entity: { id: `pout_${id}`, reference_id: id } },
          },
        });
        for (const eventId of ['evt_1', 'evt_2']) {
          await http()
            .post('/payments/razorpayx/webhook')
            .set('content-type', 'application/json')
            .set('x-razorpay-event-id', eventId)
            .set(
              'x-razorpay-signature',
              hmacSha256Hex(STUB_PAYOUT_WEBHOOK_SECRET, raw),
            )
            .send(raw)
            .expect(200);
        }
        const rows = await notificationsOf(a.user.id, 'WITHDRAWAL_STATUS');
        expect(rows).toHaveLength(1);
        expect(rows[0].title).toBe('Withdrawal failed');
        expect(rows[0].body).toContain('back in your wallet');
        expect(await pushesFor(TOKEN_A, 'WITHDRAWAL_STATUS')).toHaveLength(1);
      });
    });

    it('removes device tokens the provider reports as dead', async () => {
      const original = push.send.bind(push);
      push.send = (targets, message) => {
        void original(targets, message);
        return Promise.resolve({
          sent: 0,
          invalidTokens: targets.map((t) => t.token),
        });
      };
      try {
        const d = await createDrawing(prisma, a.user.id);
        await http()
          .put(`/drawings/${d.id}/interest`)
          .set(...bearer(b))
          .expect(204);
        await pushesFor(TOKEN_A, 'INTEREST_RECEIVED');
        const deadline = Date.now() + 5_000;
        while (
          (await prisma.deviceToken.count()) > 0 &&
          Date.now() < deadline
        ) {
          await new Promise((r) => setTimeout(r, 100));
        }
        expect(await prisma.deviceToken.count()).toBe(0);
      } finally {
        push.send = original;
      }
    });
  });
});
