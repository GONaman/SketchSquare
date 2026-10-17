/* eslint-disable @typescript-eslint/no-unsafe-member-access, @typescript-eslint/no-unsafe-assignment, @typescript-eslint/no-unsafe-argument, @typescript-eslint/no-unsafe-call -- supertest bodies are untyped */
import { INestApplication } from '@nestjs/common';
import { createHmac } from 'node:crypto';
import request from 'supertest';
import { STUB_PAYMENT_SECRET } from '../src/commerce/payments/stub-payment.provider';
import { PrismaService } from '../src/prisma/prisma.service';
import { buildCommerceApp } from './helpers/commerce-app';
import { bearer, createTestUser, TestUser } from './helpers/auth';
import { createDrawing } from './helpers/commerce-fixtures';
import { resetDb } from './helpers/db';

type User = TestUser;

describe('Cart, checkout, webhook and ledger (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let seller: User;
  let buyer: User;
  let paid1: Awaited<ReturnType<typeof createDrawing>>; // ₹1000 → fee 10000, net 90000
  let paid2: Awaited<ReturnType<typeof createDrawing>>; // ₹333.33 → fee 3333, net 30000

  beforeAll(async () => {
    ({ app, prisma } = await buildCommerceApp());
  });

  afterAll(async () => {
    await resetDb(prisma);
    await app.close();
  });

  beforeEach(async () => {
    await resetDb(prisma);
    seller = await createTestUser(app, { fullName: 'Seller' });
    buyer = await createTestUser(app, { fullName: 'Buyer' });
    paid1 = await createDrawing(prisma, seller.user.id, { pricePaise: 100000 });
    paid2 = await createDrawing(prisma, seller.user.id, { pricePaise: 33333 });
  });

  const as = (u: User) => bearer(u);
  const http = () => request(app.getHttpServer());
  const addToCart = (u: User, drawingId: string) =>
    http()
      .post('/cart')
      .set(...as(u))
      .send({ drawingId });
  const checkout = (u: User) =>
    http()
      .post('/checkout')
      .set(...as(u));

  function webhook(
    body: object,
    eventId: string,
    secret = STUB_PAYMENT_SECRET,
  ) {
    const raw = JSON.stringify(body);
    const sig = createHmac('sha256', secret).update(raw).digest('hex');
    return http()
      .post('/payments/razorpay/webhook')
      .set('content-type', 'application/json')
      .set('x-razorpay-signature', sig)
      .set('x-razorpay-event-id', eventId)
      .send(raw);
  }
  const captured = (orderId: string, paymentId: string, amount: number) => ({
    event: 'payment.captured',
    payload: {
      payment: { entity: { id: paymentId, order_id: orderId, amount } },
    },
  });

  async function ledgerSums() {
    const rows = await prisma.$queryRaw<
      { txnId: string; s: bigint }[]
    >`SELECT "txnId", SUM("amountPaise") AS s FROM "LedgerEntry" GROUP BY "txnId"`;
    return rows.map((r) => Number(r.s));
  }
  const balance = async (
    accountType: 'USER_WALLET' | 'PLATFORM_REVENUE' | 'PAYMENT_GATEWAY',
    owner?: string,
  ) =>
    (
      await prisma.ledgerEntry.aggregate({
        where: { accountType, accountOwnerId: owner ?? null },
        _sum: { amountPaise: true },
      })
    )._sum.amountPaise ?? 0;

  describe('cart', () => {
    it('adds, lists with total, and removes', async () => {
      await addToCart(buyer, paid1.id).expect(201);
      const res = await addToCart(buyer, paid2.id).expect(201);
      expect(res.body.totalPaise).toBe(133333);
      expect(res.body.items).toHaveLength(2);
      expect(res.body.items[0]).toMatchObject({
        isFree: false,
        category: { slug: 'houses' },
        architect: { id: seller.user.id },
      });
      const again = await addToCart(buyer, paid1.id).expect(201);
      expect(again.body.items).toHaveLength(2);
      const del = await http()
        .delete(`/cart/${paid1.id}`)
        .set(...as(buyer))
        .expect(200);
      expect(del.body.totalPaise).toBe(33333);
      const get = await http()
        .get('/cart')
        .set(...as(buyer))
        .expect(200);
      expect(get.body.items.map((i: { id: string }) => i.id)).toEqual([
        paid2.id,
      ]);
    });

    it('rejects own, free, already purchased, unpublished and unknown drawings', async () => {
      const free = await createDrawing(prisma, seller.user.id, {
        pricePaise: 0,
      });
      const draft = await createDrawing(prisma, seller.user.id, {
        status: 'DRAFT',
      });
      const own = await addToCart(seller, paid1.id).expect(400);
      expect(own.body.error.code).toBe('VALIDATION_ERROR');
      await addToCart(buyer, free.id).expect(400);
      await addToCart(buyer, draft.id).expect(404);
      await addToCart(buyer, '3f2a1b7c-0000-4000-8000-000000000000').expect(
        404,
      );
      await addToCart(buyer, 'not-a-uuid').expect(400);

      await addToCart(buyer, paid1.id).expect(201);
      const { body } = await checkout(buyer).expect(200);
      await http()
        .post('/checkout/stub-complete')
        .set(...as(buyer))
        .send({ orderId: body.orderId })
        .expect(200);
      const owned = await addToCart(buyer, paid1.id).expect(400);
      expect(owned.body.error.message).toMatch(/already own/);
    });
  });

  describe('checkout', () => {
    it('is stub mode: creates CREATED purchases with integer fees and one order', async () => {
      await addToCart(buyer, paid1.id);
      await addToCart(buyer, paid2.id);
      const { body } = await checkout(buyer).expect(200);
      expect(body).toMatchObject({
        razorpayKeyId: 'stub',
        amountPaise: 133333,
        currency: 'INR',
      });
      expect(body.orderId).toMatch(/^order_stub_/);
      expect(body.purchaseIds).toHaveLength(2);
      const purchases = await prisma.purchase.findMany({
        where: { buyerId: buyer.user.id },
        orderBy: { pricePaise: 'desc' },
      });
      expect(
        purchases.map((p) => [
          p.pricePaise,
          p.platformFeePaise,
          p.status,
          p.razorpayOrderId,
        ]),
      ).toEqual([
        [100000, 10000, 'CREATED', body.orderId],
        [33333, 3333, 'CREATED', body.orderId],
      ]);
    });

    it('400s on an empty cart', async () => {
      const res = await checkout(buyer).expect(400);
      expect(res.body.error.message).toMatch(/empty/);
    });

    it('drops drawings that became unavailable and reports them', async () => {
      await addToCart(buyer, paid1.id);
      await addToCart(buyer, paid2.id);
      await prisma.drawing.update({
        where: { id: paid2.id },
        data: { status: 'REMOVED' },
      });
      const res = await checkout(buyer).expect(400);
      expect(res.body.error.details.unavailableDrawingIds).toEqual([paid2.id]);
      expect(
        await prisma.cartItem.count({ where: { userId: buyer.user.id } }),
      ).toBe(1);
      expect(await prisma.purchase.count()).toBe(0);
    });

    it('parallel checkouts of the same cart share ONE order and one set of purchases', async () => {
      await addToCart(buyer, paid1.id);
      await addToCart(buyer, paid2.id);
      const results = await Promise.all(
        Array.from({ length: 6 }, () => checkout(buyer)),
      );
      results.forEach((r) => expect(r.status).toBe(200));
      expect(new Set(results.map((r) => r.body.orderId as string)).size).toBe(
        1,
      );
      expect(
        await prisma.purchase.count({ where: { status: 'CREATED' } }),
      ).toBe(2);
    });

    it('a changed cart supersedes the old unpaid purchase', async () => {
      await addToCart(buyer, paid1.id);
      const first = (await checkout(buyer).expect(200)).body;
      await addToCart(buyer, paid2.id);
      const second = (await checkout(buyer).expect(200)).body;
      expect(second.orderId).not.toBe(first.orderId);
      const statuses = await prisma.purchase.groupBy({
        by: ['status'],
        _count: true,
      });
      expect(
        Object.fromEntries(statuses.map((s) => [s.status, s._count])),
      ).toEqual({
        FAILED: 1,
        CREATED: 2,
      });
    });
  });

  describe('settlement (stub-complete, verify, webhook)', () => {
    async function openOrder() {
      await addToCart(buyer, paid1.id);
      await addToCart(buyer, paid2.id);
      return (await checkout(buyer).expect(200)).body as {
        orderId: string;
        amountPaise: number;
        purchaseIds: string[];
      };
    }

    it('stub-complete marks PAID, posts balanced ledger entries, bumps counters, clears the cart; replay is a no-op', async () => {
      const order = await openOrder();
      const complete = () =>
        http()
          .post('/checkout/stub-complete')
          .set(...as(buyer))
          .send({ orderId: order.orderId });
      await complete().expect(200, { status: 'PAID' });

      const purchases = await prisma.purchase.findMany({
        where: { buyerId: buyer.user.id },
      });
      expect(
        purchases.every(
          (p) => p.status === 'PAID' && p.paidAt && p.razorpayPaymentId,
        ),
      ).toBe(true);
      expect(await prisma.ledgerEntry.count()).toBe(6); // 2 purchases × (gateway, wallet, fee)
      expect(await ledgerSums()).toEqual([0, 0]);
      expect(await balance('USER_WALLET', seller.user.id)).toBe(90000 + 30000);
      expect(await balance('PLATFORM_REVENUE')).toBe(10000 + 3333);
      expect(await balance('PAYMENT_GATEWAY')).toBe(-133333);
      expect(
        (await prisma.drawing.findUniqueOrThrow({ where: { id: paid1.id } }))
          .purchaseCount,
      ).toBe(1);
      expect(
        await prisma.cartItem.count({ where: { userId: buyer.user.id } }),
      ).toBe(0);

      await complete().expect(200);
      expect(await prisma.ledgerEntry.count()).toBe(6);
      expect(
        (await prisma.drawing.findUniqueOrThrow({ where: { id: paid1.id } }))
          .purchaseCount,
      ).toBe(1);

      const status = await http()
        .get('/checkout/status')
        .query({ orderId: order.orderId })
        .set(...as(buyer))
        .expect(200);
      expect(status.body).toEqual({ status: 'PAID' });
    });

    it("other users cannot complete or poll someone else's order", async () => {
      const order = await openOrder();
      const other = await createTestUser(app);
      await http()
        .post('/checkout/stub-complete')
        .set(...as(other))
        .send({ orderId: order.orderId })
        .expect(404);
      await http()
        .get('/checkout/status')
        .query({ orderId: order.orderId })
        .set(...as(other))
        .expect(404);
      await http()
        .post('/checkout/verify')
        .set(...as(other))
        .send({
          razorpayOrderId: order.orderId,
          razorpayPaymentId: 'pay_1',
          razorpaySignature: 'x',
        })
        .expect(404);
      expect(await prisma.purchase.count({ where: { status: 'PAID' } })).toBe(
        0,
      );
    });

    it('verify rejects a bad signature and accepts a good one idempotently', async () => {
      const order = await openOrder();
      const body = {
        razorpayOrderId: order.orderId,
        razorpayPaymentId: 'pay_abc',
      };
      await http()
        .post('/checkout/verify')
        .set(...as(buyer))
        .send({ ...body, razorpaySignature: 'deadbeef' })
        .expect(400);
      expect(await prisma.purchase.count({ where: { status: 'PAID' } })).toBe(
        0,
      );

      const sig = createHmac('sha256', STUB_PAYMENT_SECRET)
        .update(`${order.orderId}|pay_abc`)
        .digest('hex');
      const ok = { ...body, razorpaySignature: sig };
      await http()
        .post('/checkout/verify')
        .set(...as(buyer))
        .send(ok)
        .expect(200, { status: 'PAID' });
      await http()
        .post('/checkout/verify')
        .set(...as(buyer))
        .send(ok)
        .expect(200, { status: 'PAID' });
      expect(await ledgerSums()).toEqual([0, 0]);
    });

    it('webhook rejects missing/invalid signatures', async () => {
      const order = await openOrder();
      await http()
        .post('/payments/razorpay/webhook')
        .set('content-type', 'application/json')
        .send(
          JSON.stringify(captured(order.orderId, 'pay_1', order.amountPaise)),
        )
        .expect(401);
      await webhook(
        captured(order.orderId, 'pay_1', order.amountPaise),
        'evt_bad',
        'wrong-secret',
      ).expect(401);
      expect(await prisma.purchase.count({ where: { status: 'PAID' } })).toBe(
        0,
      );
      expect(await prisma.processedWebhookEvent.count()).toBe(0);
    });

    it('webhook replay does nothing the second time', async () => {
      const order = await openOrder();
      const evt = captured(order.orderId, 'pay_w1', order.amountPaise);
      const first = await webhook(evt, 'evt_1').expect(200);
      expect(first.body).toEqual({ ok: true, duplicate: false });
      const second = await webhook(evt, 'evt_1').expect(200);
      expect(second.body).toEqual({ ok: true, duplicate: true });
      expect(await prisma.ledgerEntry.count()).toBe(6);
      expect(await ledgerSums()).toEqual([0, 0]);
      expect(
        (await prisma.drawing.findUniqueOrThrow({ where: { id: paid1.id } }))
          .purchaseCount,
      ).toBe(1);
      expect(await prisma.processedWebhookEvent.count()).toBe(1);
    });

    it('concurrent deliveries of one event + client verify + stub-complete settle exactly once', async () => {
      const order = await openOrder();
      const evt = captured(order.orderId, 'pay_c1', order.amountPaise);
      const sig = createHmac('sha256', STUB_PAYMENT_SECRET)
        .update(`${order.orderId}|pay_c1`)
        .digest('hex');
      const results = await Promise.all([
        ...Array.from({ length: 4 }, () => webhook(evt, 'evt_conc')),
        webhook(evt, 'evt_other_id_same_payment'),
        http()
          .post('/checkout/verify')
          .set(...as(buyer))
          .send({
            razorpayOrderId: order.orderId,
            razorpayPaymentId: 'pay_c1',
            razorpaySignature: sig,
          }),
        http()
          .post('/checkout/stub-complete')
          .set(...as(buyer))
          .send({ orderId: order.orderId }),
      ]);
      results.forEach((r) => expect(r.status).toBe(200));
      expect(await prisma.ledgerEntry.count()).toBe(6);
      expect(await ledgerSums()).toEqual([0, 0]);
      expect(await balance('USER_WALLET', seller.user.id)).toBe(120000);
      expect(
        (await prisma.drawing.findUniqueOrThrow({ where: { id: paid2.id } }))
          .purchaseCount,
      ).toBe(1);
    });

    it('payment.failed marks FAILED, and a later successful retry on the same order still settles', async () => {
      const order = await openOrder();
      await webhook(
        {
          event: 'payment.failed',
          payload: {
            payment: { entity: { id: 'pay_f1', order_id: order.orderId } },
          },
        },
        'evt_f1',
      ).expect(200);
      expect(await prisma.purchase.count({ where: { status: 'FAILED' } })).toBe(
        2,
      );
      const status = await http()
        .get('/checkout/status')
        .query({ orderId: order.orderId })
        .set(...as(buyer))
        .expect(200);
      expect(status.body.status).toBe('FAILED');
      await webhook(
        captured(order.orderId, 'pay_f2', order.amountPaise),
        'evt_f2',
      ).expect(200);
      expect(await prisma.purchase.count({ where: { status: 'PAID' } })).toBe(
        2,
      );
      expect(await ledgerSums()).toEqual([0, 0]);
    });

    it('a captured amount that differs from the order total is not settled', async () => {
      const order = await openOrder();
      await webhook(
        captured(order.orderId, 'pay_m1', order.amountPaise - 1),
        'evt_m1',
      ).expect(200);
      expect(await prisma.purchase.count({ where: { status: 'PAID' } })).toBe(
        0,
      );
      expect(await prisma.ledgerEntry.count()).toBe(0);
    });

    it('unknown orders and unrelated events are acknowledged and ignored', async () => {
      await webhook(captured('order_nope', 'pay_x', 100), 'evt_u1').expect(200);
      await webhook({ event: 'refund.created', payload: {} }, 'evt_u2').expect(
        200,
      );
      expect(await prisma.ledgerEntry.count()).toBe(0);
    });

    it('a second payment for an already-owned drawing is not double-booked', async () => {
      await addToCart(buyer, paid1.id);
      const first = (await checkout(buyer).expect(200)).body;
      await prisma.drawing.update({
        where: { id: paid1.id },
        data: { pricePaise: 120000 },
      });
      const second = (await checkout(buyer).expect(200)).body;
      expect(second.orderId).not.toBe(first.orderId);

      await webhook(
        captured(second.orderId, 'pay_s2', 120000),
        'evt_s2',
      ).expect(200);
      await webhook(captured(first.orderId, 'pay_s1', 100000), 'evt_s1').expect(
        200,
      );

      const paid = await prisma.purchase.findMany({
        where: { status: 'PAID' },
      });
      expect(paid).toHaveLength(1);
      expect(paid[0].pricePaise).toBe(120000);
      expect(await prisma.ledgerEntry.count()).toBe(3);
      expect(await ledgerSums()).toEqual([0]);
    });

    it('tiny prices with a zero fee still post a balanced transaction', async () => {
      const tiny = await createDrawing(prisma, seller.user.id, {
        pricePaise: 5,
      });
      await addToCart(buyer, tiny.id);
      const order = (await checkout(buyer).expect(200)).body;
      await http()
        .post('/checkout/stub-complete')
        .set(...as(buyer))
        .send({ orderId: order.orderId })
        .expect(200);
      expect(await prisma.ledgerEntry.count()).toBe(2);
      expect(await balance('USER_WALLET', seller.user.id)).toBe(5);
      expect(await ledgerSums()).toEqual([0]);
    });
  });
});
