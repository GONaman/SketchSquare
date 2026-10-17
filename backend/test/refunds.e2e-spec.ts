/* eslint-disable @typescript-eslint/no-unsafe-member-access, @typescript-eslint/no-unsafe-assignment, @typescript-eslint/no-unsafe-argument, @typescript-eslint/no-unsafe-return, @typescript-eslint/no-unsafe-call -- supertest bodies are untyped */
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { PAYOUT_QUEUE } from '../src/commerce/payouts/payout.queue';
import { PrismaService } from '../src/prisma/prisma.service';
import { REFUND_PROVIDER } from '../src/refunds/refund.provider';
import { bearer, createTestUser, TestUser } from './helpers/auth';
import { buildCommerceApp } from './helpers/commerce-app';
import { createDrawing } from './helpers/commerce-fixtures';
import { resetDb } from './helpers/db';

type Drawing = Awaited<ReturnType<typeof createDrawing>>;

describe('Admin purchases and refunds (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let admin: TestUser;
  let seller: TestUser;
  let buyer: TestUser;
  let drawing: Drawing; // ₹1000 → fee 10000, net 90000
  const providerRefund = jest.fn();

  beforeAll(async () => {
    ({ app, prisma } = await buildCommerceApp({
      overrides: [
        { token: REFUND_PROVIDER, useValue: { refund: providerRefund } },
        { token: PAYOUT_QUEUE, useValue: { enqueue: () => Promise.resolve() } },
      ],
    }));
  });

  afterAll(async () => {
    await resetDb(prisma);
    await app.close();
  });

  beforeEach(async () => {
    await resetDb(prisma);
    providerRefund.mockReset();
    providerRefund.mockImplementation((i: { idempotencyKey: string }) =>
      Promise.resolve({ refundId: `rfnd_test_${i.idempotencyKey}` }),
    );
    admin = await createTestUser(app, {
      fullName: 'Admin',
      role: 'ADMIN',
    });
    seller = await createTestUser(app, { fullName: 'Seller Sam' });
    buyer = await createTestUser(app, { fullName: 'Buyer Bea' });
    drawing = await createDrawing(prisma, seller.user.id, {
      pricePaise: 100000,
      title: 'Lakeview Villa',
    });
  });

  const http = () => request(app.getHttpServer());
  const refund = (id: string, reason = 'Wrong file delivered', u = admin) =>
    http()
      .post(`/admin/purchases/${id}/refund`)
      .set(...bearer(u))
      .send({ reason });

  /** Buys `d` through the real cart → checkout → stub-complete flow and returns the PAID purchase id. */
  async function buy(u: TestUser, d: Drawing): Promise<string> {
    await http()
      .post('/cart')
      .set(...bearer(u))
      .send({ drawingId: d.id })
      .expect(201);
    const co = await http()
      .post('/checkout')
      .set(...bearer(u))
      .expect(200);
    await http()
      .post('/checkout/stub-complete')
      .set(...bearer(u))
      .send({ orderId: co.body.orderId })
      .expect(200);
    return co.body.purchaseIds[0];
  }

  const download = async (u: TestUser, d: Drawing) => {
    const sheet = await prisma.drawingSheet.findFirstOrThrow({
      where: { drawingId: d.id },
      orderBy: { createdAt: 'asc' },
    });
    return http()
      .get(`/drawings/${d.id}/download`)
      .query({ sheetId: sheet.id })
      .set(...bearer(u));
  };
  const sumOf = async (
    accountType: 'USER_WALLET' | 'PLATFORM_REVENUE' | 'PAYMENT_GATEWAY',
    owner?: string,
  ) =>
    (
      await prisma.ledgerEntry.aggregate({
        where: { accountType, accountOwnerId: owner ?? null },
        _sum: { amountPaise: true },
      })
    )._sum.amountPaise ?? 0;
  const unbalancedTxns = async () =>
    (
      await prisma.$queryRaw<
        { s: bigint }[]
      >`SELECT SUM("amountPaise") AS s FROM "LedgerEntry" GROUP BY "txnId" HAVING SUM("amountPaise") <> 0`
    ).length;

  describe('authorization', () => {
    it('rejects anonymous and non-admin callers on every endpoint', async () => {
      const id = await buy(buyer, drawing);
      await http().get('/admin/purchases').expect(401);
      await http()
        .get('/admin/purchases')
        .set(...bearer(seller))
        .expect(403);
      await http()
        .get(`/admin/purchases/${id}`)
        .set(...bearer(buyer))
        .expect(403);
      await refund(id, 'x'.repeat(10), buyer).expect(403);
      await refund(id, 'x'.repeat(10), seller).expect(403);
      expect(
        (await prisma.purchase.findUniqueOrThrow({ where: { id } })).status,
      ).toBe('PAID');
      expect(providerRefund).not.toHaveBeenCalled();
    });
  });

  describe('listing', () => {
    it('searches by buyer, seller, drawing title, status and paginates', async () => {
      const second = await createDrawing(prisma, seller.user.id, {
        pricePaise: 50000,
        title: 'Hillside Cottage',
      });
      const other = await createTestUser(app, { fullName: 'Other Olive' });
      const p1 = await buy(buyer, drawing);
      const p2 = await buy(buyer, second);
      const p3 = await buy(other, drawing);
      await refund(p2).expect(200);

      const list = (qs: Record<string, string>) =>
        http()
          .get('/admin/purchases')
          .query(qs)
          .set(...bearer(admin))
          .expect(200);
      const ids = (r: request.Response) => r.body.items.map((i: any) => i.id);

      expect(ids(await list({ q: 'Buyer Bea' })).sort()).toEqual(
        [p1, p2].sort(),
      );
      expect(ids(await list({ q: 'hillside' }))).toEqual([p2]);
      expect(ids(await list({ q: 'seller sam' }))).toHaveLength(3);
      expect(ids(await list({ q: buyer.user.email }))).toHaveLength(2);
      expect(ids(await list({ q: p3 }))).toEqual([p3]);
      expect(ids(await list({ status: 'REFUNDED' }))).toEqual([p2]);
      expect(
        ids(await list({ status: 'PAID', buyerId: other.user.id })),
      ).toEqual([p3]);
      expect(ids(await list({ drawingId: drawing.id })).sort()).toEqual(
        [p1, p3].sort(),
      );

      const first = await list({ limit: '2' });
      expect(first.body.items).toHaveLength(2);
      expect(first.body.nextCursor).toEqual(expect.any(String));
      const rest = await list({ limit: '2', cursor: first.body.nextCursor });
      expect(rest.body.items).toHaveLength(1);
      expect(rest.body.nextCursor).toBeNull();
      expect([...ids(first), ...ids(rest)].sort()).toEqual([p1, p2, p3].sort());

      const item = (await list({ q: p1 })).body.items[0];
      expect(item).toMatchObject({
        status: 'PAID',
        pricePaise: 100000,
        platformFeePaise: 10000,
        sellerNetPaise: 90000,
        buyer: { id: buyer.user.id, fullName: 'Buyer Bea' },
        seller: { id: seller.user.id },
        drawing: { id: drawing.id, title: 'Lakeview Villa' },
        refund: null,
      });
    });

    it('detail shows the seller balance; 404 for unknown ids', async () => {
      const id = await buy(buyer, drawing);
      const res = await http()
        .get(`/admin/purchases/${id}`)
        .set(...bearer(admin))
        .expect(200);
      expect(res.body.sellerBalancePaise).toBe(90000);
      await http()
        .get('/admin/purchases/00000000-0000-4000-8000-000000000000')
        .set(...bearer(admin))
        .expect(404);
    });
  });

  describe('refund', () => {
    it('refunds a paid purchase: status, zero-sum ledger, counters, access, audit', async () => {
      const id = await buy(buyer, drawing);
      expect((await download(buyer, drawing)).status).toBe(200);
      expect(
        (await prisma.drawing.findUniqueOrThrow({ where: { id: drawing.id } }))
          .purchaseCount,
      ).toBe(1);

      const res = await refund(id).expect(200);
      expect(res.body).toMatchObject({
        ok: true,
        alreadyRefunded: false,
        refund: {
          reason: 'Wrong file delivered',
          amountPaise: 100000,
          providerStatus: 'SUCCEEDED',
          providerRefundId: `rfnd_test_${id}`,
          refundedBy: { id: admin.user.id },
        },
      });
      expect(providerRefund).toHaveBeenCalledTimes(1);
      expect(providerRefund).toHaveBeenCalledWith(
        expect.objectContaining({
          paymentId: expect.stringMatching(/^pay_stub_/),
          amountPaise: 100000,
          idempotencyKey: id,
        }),
      );

      expect(
        (await prisma.purchase.findUniqueOrThrow({ where: { id } })).status,
      ).toBe('REFUNDED');
      expect(await unbalancedTxns()).toBe(0);
      // Everything the sale booked is reversed.
      expect(await sumOf('USER_WALLET', seller.user.id)).toBe(0);
      expect(await sumOf('PLATFORM_REVENUE')).toBe(0);
      expect(await sumOf('PAYMENT_GATEWAY')).toBe(0);
      const entries = await prisma.ledgerEntry.findMany({
        where: { entryType: 'REFUND' },
      });
      expect(entries).toHaveLength(3);
      expect(new Set(entries.map((e) => e.txnId)).size).toBe(1);
      expect(entries.every((e) => e.referenceId === id)).toBe(true);
      expect(
        (await prisma.drawing.findUniqueOrThrow({ where: { id: drawing.id } }))
          .purchaseCount,
      ).toBe(0);
      expect(
        await prisma.auditLog.count({
          where: { action: 'purchase.refund', entityId: id },
        }),
      ).toBe(1);

      // Access is revoked everywhere the buyer could use it.
      expect((await download(buyer, drawing)).status).toBe(403);
      const lib = await http()
        .get('/me/purchases')
        .set(...bearer(buyer))
        .expect(200);
      expect(lib.body.items).toHaveLength(0);
      await http()
        .put(`/drawings/${drawing.id}/review`)
        .set(...bearer(buyer))
        .send({ rating: 1 })
        .expect(403);
      const detail = await http()
        .get(`/drawings/${drawing.id}`)
        .set(...bearer(buyer))
        .expect(200);
      expect(detail.body.viewer).toMatchObject({
        isPurchased: false,
        canDownload: false,
      });
      const buyers = await http()
        .get(`/drawings/${drawing.id}/buyers`)
        .set(...bearer(seller))
        .expect(200);
      expect(buyers.body.items).toHaveLength(0);

      const seen = await http()
        .get('/wallet/ledger')
        .set(...bearer(seller))
        .expect(200);
      expect(seen.body.items[0]).toMatchObject({
        entryType: 'REFUND',
        amountPaise: -90000,
        description: 'Refund of "Lakeview Villa"',
      });
    });

    it('keeps an existing review (decision RF3) but the buyer cannot edit it afterwards', async () => {
      const id = await buy(buyer, drawing);
      await http()
        .put(`/drawings/${drawing.id}/review`)
        .set(...bearer(buyer))
        .send({ rating: 2, comment: 'meh' })
        .expect(200);
      await refund(id).expect(200);
      const d = await prisma.drawing.findUniqueOrThrow({
        where: { id: drawing.id },
      });
      expect(d.ratingCount).toBe(1);
      await http()
        .put(`/drawings/${drawing.id}/review`)
        .set(...bearer(buyer))
        .send({ rating: 5 })
        .expect(403);
    });

    it('is idempotent: refunding twice books once', async () => {
      const id = await buy(buyer, drawing);
      await refund(id).expect(200);
      const before = await prisma.ledgerEntry.count();
      const again = await refund(id, 'second attempt').expect(200);
      expect(again.body).toMatchObject({
        ok: true,
        alreadyRefunded: true,
        refund: { reason: 'Wrong file delivered', providerStatus: 'SUCCEEDED' },
      });
      expect(await prisma.ledgerEntry.count()).toBe(before);
      expect(await prisma.refund.count()).toBe(1);
      expect(providerRefund).toHaveBeenCalledTimes(1);
      expect(
        (await prisma.drawing.findUniqueOrThrow({ where: { id: drawing.id } }))
          .purchaseCount,
      ).toBe(0);
    });

    it('books exactly once under concurrent refunds', async () => {
      const id = await buy(buyer, drawing);
      const results = await Promise.all(
        Array.from({ length: 6 }, () => refund(id)),
      );
      expect(results.every((r) => r.status === 200)).toBe(true);
      expect(
        results.filter((r) => r.body.alreadyRefunded === false),
      ).toHaveLength(1);
      expect(await prisma.refund.count()).toBe(1);
      expect(
        await prisma.ledgerEntry.count({ where: { entryType: 'REFUND' } }),
      ).toBe(3);
      expect(await unbalancedTxns()).toBe(0);
      expect(await sumOf('USER_WALLET', seller.user.id)).toBe(0);
      expect(providerRefund).toHaveBeenCalledTimes(1);
      expect(
        (await prisma.drawing.findUniqueOrThrow({ where: { id: drawing.id } }))
          .purchaseCount,
      ).toBe(0);
    });

    it('validates the request and the purchase state', async () => {
      const id = await buy(buyer, drawing);
      await http()
        .post(`/admin/purchases/${id}/refund`)
        .set(...bearer(admin))
        .send({})
        .expect(400);
      await refund(id, '  ').expect(400);
      await refund(id, 'x'.repeat(501)).expect(400);
      await http()
        .post('/admin/purchases/not-a-uuid/refund')
        .set(...bearer(admin))
        .send({ reason: 'test reason' })
        .expect(400);
      await refund('00000000-0000-4000-8000-000000000000').expect(404);

      const unpaid = await prisma.purchase.create({
        data: {
          buyerId: buyer.user.id,
          drawingId: drawing.id,
          pricePaise: 100000,
          platformFeePaise: 10000,
          status: 'CREATED',
        },
      });
      const res = await refund(unpaid.id).expect(409);
      expect(res.body.error.code).toBe('CONFLICT');
      expect(await prisma.refund.count()).toBe(0);
      expect(
        await prisma.ledgerEntry.count({ where: { entryType: 'REFUND' } }),
      ).toBe(0);
    });

    it('records a failed gateway call and retries only the gateway on the next request', async () => {
      const id = await buy(buyer, drawing);
      providerRefund.mockRejectedValueOnce(new Error('gateway down'));
      const first = await refund(id).expect(200);
      expect(first.body.refund).toMatchObject({
        providerStatus: 'FAILED',
        providerError: 'gateway down',
      });
      // The books already moved; the buyer lost access regardless of the gateway.
      expect(await sumOf('USER_WALLET', seller.user.id)).toBe(0);
      expect((await download(buyer, drawing)).status).toBe(403);

      const before = await prisma.ledgerEntry.count();
      const retry = await refund(id).expect(200);
      expect(retry.body).toMatchObject({
        alreadyRefunded: true,
        refund: {
          providerStatus: 'SUCCEEDED',
          providerRefundId: `rfnd_test_${id}`,
          providerError: null,
        },
      });
      expect(await prisma.ledgerEntry.count()).toBe(before);
      expect(providerRefund).toHaveBeenCalledTimes(2);
    });

    it('lets the buyer purchase the drawing again after a refund', async () => {
      const id = await buy(buyer, drawing);
      await refund(id).expect(200);
      const again = await buy(buyer, drawing);
      expect(again).not.toBe(id);
      expect((await download(buyer, drawing)).status).toBe(200);
    });
  });

  describe('seller wallet going negative', () => {
    const GOOD_BANK = {
      holderName: 'Sam Seller',
      ifsc: 'HDFC0001234',
      accountNumber: '123456789012',
    };
    const walletOf = async () =>
      (
        await http()
          .get('/wallet')
          .set(...bearer(seller))
          .expect(200)
      ).body;
    const withdraw = (amountPaise: number) =>
      http()
        .post('/wallet/withdrawals')
        .set(...bearer(seller))
        .send({ amountPaise });

    it('allows a negative balance and blocks withdrawals until it is positive again', async () => {
      await http()
        .post('/wallet/bank-account')
        .set(...bearer(seller))
        .send(GOOD_BANK)
        .expect(200);
      const id = await buy(buyer, drawing);
      // Seller cashes out everything before the refund arrives.
      await withdraw(90000).expect(201);
      await prisma.withdrawal.updateMany({ data: { status: 'PAID' } });

      const warn = await http()
        .get(`/admin/purchases/${id}`)
        .set(...bearer(admin))
        .expect(200);
      expect(warn.body.sellerBalancePaise).toBe(0);

      await refund(id).expect(200);
      expect(await walletOf()).toMatchObject({
        balancePaise: -90000,
        withdrawalBlocked: true,
      });
      const blocked = await withdraw(50000).expect(403);
      expect(blocked.body.error.code).toBe('WITHDRAWAL_BLOCKED');
      expect(await prisma.withdrawal.count()).toBe(1);

      // New sales eat the debt first; withdrawals open up once the balance is positive.
      const buyer2 = await createTestUser(app, { fullName: 'Buyer Two' });
      const d2 = await createDrawing(prisma, seller.user.id, {
        pricePaise: 100000,
      });
      const d3 = await createDrawing(prisma, seller.user.id, {
        pricePaise: 100000,
      });
      await buy(buyer2, d2);
      expect(await walletOf()).toMatchObject({
        balancePaise: 0,
        withdrawalBlocked: false,
      });
      await buy(buyer2, d3);
      expect((await walletOf()).balancePaise).toBe(90000);
      await withdraw(50000).expect(201);
      expect(await unbalancedTxns()).toBe(0);
    });
  });
});
