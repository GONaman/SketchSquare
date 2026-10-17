/* eslint-disable @typescript-eslint/no-unsafe-member-access, @typescript-eslint/no-unsafe-assignment, @typescript-eslint/no-unsafe-argument, @typescript-eslint/no-unsafe-return, @typescript-eslint/no-unsafe-call -- supertest bodies are untyped */
import { INestApplication } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import request from 'supertest';
import { LedgerService } from '../src/ledger/ledger.service';
import { PayoutService } from '../src/commerce/payouts/payout.service';
import { PAYOUT_QUEUE } from '../src/commerce/payouts/payout.queue';
import { STUB_PAYOUT_WEBHOOK_SECRET } from '../src/commerce/payouts/stub-payout.provider';
import { hmacSha256Hex } from '../src/commerce/payments/signature';
import { PrismaService } from '../src/prisma/prisma.service';
import { bearer, createTestUser, TestUser } from './helpers/auth';
import { buildCommerceApp } from './helpers/commerce-app';
import { createDrawing } from './helpers/commerce-fixtures';
import { resetDb } from './helpers/db';

describe('Wallet, withdrawals and payouts (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let ledger: LedgerService;
  let payouts: PayoutService;
  let user: TestUser;
  let enqueued: string[];
  let enqueueFails = false;

  const http = () => request(app.getHttpServer());
  const GOOD_BANK = {
    holderName: 'Asha Rao',
    ifsc: 'HDFC0001234',
    accountNumber: '123456789012',
  };

  const credit = (userId: string, amountPaise: number, referenceId?: string) =>
    ledger.postTransaction([
      {
        accountType: 'PAYMENT_GATEWAY',
        amountPaise: -amountPaise,
        entryType: 'SALE',
        referenceId: referenceId ?? randomUUID(),
      },
      {
        accountType: 'USER_WALLET',
        accountOwnerId: userId,
        amountPaise,
        entryType: 'SALE',
        referenceId: referenceId ?? randomUUID(),
      },
    ]);

  const addBank = (u: TestUser = user, body: object = GOOD_BANK) =>
    http()
      .post('/wallet/bank-account')
      .set(...bearer(u))
      .send(body);
  const withdraw = (amountPaise: number, u: TestUser = user) =>
    http()
      .post('/wallet/withdrawals')
      .set(...bearer(u))
      .send({ amountPaise });
  const wallet = async (u: TestUser = user) =>
    (
      await http()
        .get('/wallet')
        .set(...bearer(u))
        .expect(200)
    ).body;

  const runQueued = async () => {
    const ids = enqueued.splice(0);
    for (const id of ids) await payouts.process(id);
    return ids;
  };

  const ledgerSum = async () =>
    (await prisma.ledgerEntry.aggregate({ _sum: { amountPaise: true } }))._sum
      .amountPaise ?? 0;

  const webhook = (
    body: object,
    opts: { eventId?: string; signature?: string } = {},
  ) => {
    const raw = JSON.stringify(body);
    return http()
      .post('/payments/razorpayx/webhook')
      .set('content-type', 'application/json')
      .set('x-razorpay-event-id', opts.eventId ?? randomUUID())
      .set(
        'x-razorpay-signature',
        opts.signature ?? hmacSha256Hex(STUB_PAYOUT_WEBHOOK_SECRET, raw),
      )
      .send(raw);
  };
  const payoutEvent = (event: string, withdrawalId: string) => ({
    event,
    payload: {
      payout: {
        entity: { id: `pout_${withdrawalId}`, reference_id: withdrawalId },
      },
    },
  });

  beforeAll(async () => {
    enqueued = [];
    ({ app, prisma } = await buildCommerceApp({
      overrides: [
        {
          token: PAYOUT_QUEUE,
          useValue: {
            enqueue: (id: string) => {
              if (enqueueFails) return Promise.reject(new Error('redis down'));
              enqueued.push(id);
              return Promise.resolve();
            },
          },
        },
      ],
    }));
    ledger = app.get(LedgerService);
    payouts = app.get(PayoutService);
  });

  afterAll(async () => {
    await app.close();
  });

  beforeEach(async () => {
    await resetDb(prisma);
    enqueued = [];
    enqueueFails = false;
    user = await createTestUser(app, { fullName: 'Asha Rao' });
  });

  describe('access', () => {
    it('requires authentication and an approved account', async () => {
      await http().get('/wallet').expect(401);
      const pending = await createTestUser(app, {
        verificationStatus: 'PENDING',
      });
      await http()
        .get('/wallet')
        .set(...bearer(pending))
        .expect(403);
      await http()
        .post('/wallet/withdrawals')
        .set(...bearer(pending))
        .send({ amountPaise: 100000 })
        .expect(403);
    });
  });

  describe('GET /wallet and bank account', () => {
    it('starts empty', async () => {
      expect(await wallet()).toEqual({
        balancePaise: 0,
        pendingWithdrawalPaise: 0,
        minWithdrawalPaise: 50000,
        withdrawalBlocked: false,
        bankAccount: null,
      });
    });

    it('validates bank details', async () => {
      await addBank(user, { ...GOOD_BANK, ifsc: 'BAD' }).expect(400);
      await addBank(user, { ...GOOD_BANK, accountNumber: '1234' }).expect(400);
      await addBank(user, {
        ...GOOD_BANK,
        accountNumber: '12345678ab90',
      }).expect(400);
      await addBank(user, { ...GOOD_BANK, holderName: 'A' }).expect(400);
      await addBank(user, { ...GOOD_BANK, extra: 1 }).expect(400);
    });

    it('stores only the last four digits and uppercases the IFSC', async () => {
      const res = await addBank(user, {
        ...GOOD_BANK,
        ifsc: 'hdfc0001234',
      }).expect(200);
      expect(res.body).toEqual({
        holderName: 'Asha Rao',
        ifsc: 'HDFC0001234',
        accountNumberLast4: '9012',
      });
      const row = await prisma.bankAccount.findUniqueOrThrow({
        where: { userId: user.user.id },
      });
      expect(JSON.stringify(row)).not.toContain('123456789012');
      expect(row.providerFundAccountId).toMatch(/^fa_stub_/);
      expect((await wallet()).bankAccount).toEqual(res.body);
    });

    it('replaces the bank account on a second call', async () => {
      await addBank().expect(200);
      const res = await addBank(user, {
        ...GOOD_BANK,
        accountNumber: '999988887777',
      }).expect(200);
      expect(res.body.accountNumberLast4).toBe('7777');
      expect(await prisma.bankAccount.count()).toBe(1);
    });

    it('cannot change the bank account while a withdrawal is in flight', async () => {
      await addBank();
      await credit(user.user.id, 200000);
      await withdraw(100000).expect(201);
      await addBank(user, {
        ...GOOD_BANK,
        accountNumber: '555566667777',
      }).expect(409);
    });
  });

  describe('POST /wallet/withdrawals validation', () => {
    it('rejects non-positive and non-integer amounts', async () => {
      await withdraw(0).expect(400);
      await withdraw(-5).expect(400);
      await http()
        .post('/wallet/withdrawals')
        .set(...bearer(user))
        .send({ amountPaise: 1000.5 })
        .expect(400);
      await http()
        .post('/wallet/withdrawals')
        .set(...bearer(user))
        .send({})
        .expect(400);
    });

    it('needs a bank account', async () => {
      await credit(user.user.id, 200000);
      const res = await withdraw(100000).expect(400);
      expect(res.body.error.code).toBe('VALIDATION_ERROR');
    });

    it('enforces the minimum', async () => {
      await addBank();
      await credit(user.user.id, 200000);
      const res = await withdraw(49999).expect(400);
      expect(res.body.error.code).toBe('BELOW_MIN_WITHDRAWAL');
      await withdraw(50000).expect(201);
    });

    it('rejects more than the balance', async () => {
      await addBank();
      await credit(user.user.id, 100000);
      const res = await withdraw(100001).expect(400);
      expect(res.body.error.code).toBe('INSUFFICIENT_BALANCE');
      expect((await wallet()).balancePaise).toBe(100000);
      await withdraw(100000).expect(201);
      expect((await wallet()).balancePaise).toBe(0);
    });

    it('is blocked while the balance is negative', async () => {
      await addBank();
      await ledger.postTransaction([
        {
          accountType: 'USER_WALLET',
          accountOwnerId: user.user.id,
          amountPaise: -30000,
          entryType: 'REFUND',
        },
        {
          accountType: 'PAYMENT_GATEWAY',
          amountPaise: 30000,
          entryType: 'REFUND',
        },
      ]);
      const w = await wallet();
      expect(w.balancePaise).toBe(-30000);
      expect(w.withdrawalBlocked).toBe(true);
      const res = await withdraw(50000).expect(403);
      expect(res.body.error.code).toBe('WITHDRAWAL_BLOCKED');
    });

    it('allows only one withdrawal in flight', async () => {
      await addBank();
      await credit(user.user.id, 500000);
      await withdraw(100000).expect(201);
      const res = await withdraw(100000).expect(409);
      expect(res.body.error.code).toBe('CONFLICT');
      expect((await wallet()).pendingWithdrawalPaise).toBe(100000);
    });
  });

  describe('successful payout', () => {
    it('debits the wallet at request time and ends PAID', async () => {
      await addBank();
      await credit(user.user.id, 300000);
      const res = await withdraw(120000).expect(201);
      expect(res.body).toMatchObject({
        amountPaise: 120000,
        status: 'REQUESTED',
        failureReason: null,
      });
      expect(enqueued).toEqual([res.body.id]);
      expect(await wallet()).toMatchObject({
        balancePaise: 180000,
        pendingWithdrawalPaise: 120000,
      });

      await runQueued();
      const list = await http()
        .get('/wallet/withdrawals')
        .set(...bearer(user))
        .expect(200);
      expect(list.body.items).toHaveLength(1);
      expect(list.body.items[0]).toMatchObject({
        id: res.body.id,
        status: 'PAID',
      });
      expect(await wallet()).toMatchObject({
        balancePaise: 180000,
        pendingWithdrawalPaise: 0,
      });
      const w = await prisma.withdrawal.findUniqueOrThrow({
        where: { id: res.body.id },
      });
      expect(w.providerRef).toBe(`pout_stub_${res.body.id}`);
      expect(await ledgerSum()).toBe(0);
      const clearing = await prisma.ledgerEntry.aggregate({
        where: { accountType: 'PAYOUT_CLEARING' },
        _sum: { amountPaise: true },
      });
      expect(clearing._sum.amountPaise).toBe(120000);

      // A second withdrawal is possible once the first is finished.
      await withdraw(60000).expect(201);
    });

    it('processing the same payout repeatedly is harmless', async () => {
      await addBank();
      await credit(user.user.id, 300000);
      const { body } = await withdraw(100000).expect(201);
      const outcomes = await Promise.all(
        Array.from({ length: 6 }, () => payouts.process(body.id)),
      );
      // A resumed attempt may repeat the (provider-idempotent) call, but the ledger and status change only once.
      expect(outcomes.every((o) => o === 'PAID' || o === 'SKIPPED')).toBe(true);
      expect(outcomes).toContain('PAID');
      expect(
        (await prisma.withdrawal.findUniqueOrThrow({ where: { id: body.id } }))
          .status,
      ).toBe('PAID');
      expect(await payouts.process(body.id)).toBe('SKIPPED');
      expect(await ledgerSum()).toBe(0);
      expect(await wallet()).toMatchObject({ balancePaise: 200000 });
    });
  });

  describe('failed payout', () => {
    const FAIL_BANK = { ...GOOD_BANK, accountNumber: '123456780000' };

    it('returns the money exactly once', async () => {
      await addBank(user, FAIL_BANK);
      await credit(user.user.id, 300000);
      const { body } = await withdraw(100000).expect(201);
      expect((await wallet()).balancePaise).toBe(200000);

      await runQueued();
      const w = await prisma.withdrawal.findUniqueOrThrow({
        where: { id: body.id },
      });
      expect(w.status).toBe('FAILED');
      expect(w.failureReason).toBeTruthy();
      expect(await wallet()).toMatchObject({
        balancePaise: 300000,
        pendingWithdrawalPaise: 0,
      });

      // Replays (queue retry, webhook) must not credit again.
      expect(await payouts.process(body.id)).toBe('SKIPPED');
      expect(await payouts.fail(body.id, 'again')).toBe(false);
      await webhook(payoutEvent('payout.failed', body.id)).expect(200);
      expect((await wallet()).balancePaise).toBe(300000);
      expect(
        await prisma.ledgerEntry.count({
          where: {
            entryType: 'WITHDRAWAL_REVERSAL',
            accountType: 'USER_WALLET',
          },
        }),
      ).toBe(1);
      expect(await ledgerSum()).toBe(0);

      // And the user can withdraw again.
      await addBank();
      await withdraw(300000).expect(201);
    });

    it('concurrent failures reverse once', async () => {
      await addBank();
      await credit(user.user.id, 300000);
      const { body } = await withdraw(100000).expect(201);
      const results = await Promise.all(
        Array.from({ length: 6 }, () => payouts.fail(body.id, 'boom')),
      );
      expect(results.filter(Boolean)).toHaveLength(1);
      expect((await wallet()).balancePaise).toBe(300000);
      expect(await ledgerSum()).toBe(0);
    });
  });

  describe('concurrency', () => {
    it('parallel withdrawals never overspend', async () => {
      await addBank();
      await credit(user.user.id, 1_000_000);
      const results = await Promise.all(
        Array.from({ length: 8 }, () => withdraw(600_000)),
      );
      const statuses = results.map((r) => r.status).sort();
      expect(statuses.filter((s) => s === 201)).toHaveLength(1);
      expect(statuses.filter((s) => s !== 201 && s !== 409)).toEqual([]);
      expect(await prisma.withdrawal.count()).toBe(1);
      expect((await wallet()).balancePaise).toBe(400_000);
      expect(await ledgerSum()).toBe(0);
    });

    it('withdrawals racing with a payout reversal keep the balance exact', async () => {
      await addBank();
      await credit(user.user.id, 1_000_000);
      const { body } = await withdraw(500_000).expect(201);
      const [, again] = await Promise.all([
        payouts.fail(body.id, 'bank rejected'),
        withdraw(500_000),
      ]);
      expect([201, 409]).toContain(again.status);
      const w = await wallet();
      expect(w.balancePaise).toBe(again.status === 201 ? 500_000 : 1_000_000);
      expect(w.balancePaise).toBeGreaterThanOrEqual(0);
      expect(await ledgerSum()).toBe(0);
    });
  });

  describe('enqueue failure', () => {
    it('keeps the committed withdrawal and recovery finds it', async () => {
      await addBank();
      await credit(user.user.id, 300000);
      enqueueFails = true;
      const { body } = await withdraw(100000).expect(201);
      expect(enqueued).toEqual([]);
      expect(await payouts.findUnstarted(60_000)).toEqual([]);
      expect(await payouts.findUnstarted(0)).toEqual([body.id]);
      await payouts.process(body.id);
      expect(await payouts.findUnstarted(0)).toEqual([]);
    });
  });

  describe('RazorpayX webhook', () => {
    async function inFlight() {
      await addBank();
      await credit(user.user.id, 300000);
      const { body } = await withdraw(100000).expect(201);
      // Simulate the provider having accepted the payout but not yet confirmed it.
      await prisma.withdrawal.update({
        where: { id: body.id },
        data: { status: 'PROCESSING', providerRef: `pout_${body.id}` },
      });
      return body.id as string;
    }

    it('rejects a bad or missing signature', async () => {
      const id = await inFlight();
      await webhook(payoutEvent('payout.processed', id), {
        signature: 'deadbeef',
      }).expect(401);
      await http()
        .post('/payments/razorpayx/webhook')
        .set('content-type', 'application/json')
        .send(payoutEvent('payout.processed', id))
        .expect(401);
      expect(
        (await prisma.withdrawal.findUniqueOrThrow({ where: { id } })).status,
      ).toBe('PROCESSING');
    });

    it('payout.processed marks PAID, once per event id', async () => {
      const id = await inFlight();
      const first = await webhook(payoutEvent('payout.processed', id), {
        eventId: 'evt_1',
      }).expect(200);
      expect(first.body).toEqual({ ok: true, duplicate: false });
      const dup = await webhook(payoutEvent('payout.processed', id), {
        eventId: 'evt_1',
      }).expect(200);
      expect(dup.body).toEqual({ ok: true, duplicate: true });
      expect(
        (await prisma.withdrawal.findUniqueOrThrow({ where: { id } })).status,
      ).toBe('PAID');
      expect((await wallet()).balancePaise).toBe(200000);
    });

    it('payout.failed reverses; concurrent duplicates reverse once', async () => {
      const id = await inFlight();
      const results = await Promise.all(
        Array.from({ length: 5 }, () =>
          webhook(payoutEvent('payout.failed', id), { eventId: 'evt_dup' }),
        ),
      );
      results.forEach((r) => expect(r.status).toBe(200));
      expect(results.filter((r) => r.body.duplicate === false)).toHaveLength(1);
      expect(
        (await prisma.withdrawal.findUniqueOrThrow({ where: { id } })).status,
      ).toBe('FAILED');
      expect((await wallet()).balancePaise).toBe(300000);
      expect(await ledgerSum()).toBe(0);
    });

    it('different event ids for the same failure still reverses once', async () => {
      const id = await inFlight();
      await webhook(payoutEvent('payout.rejected', id)).expect(200);
      await webhook(payoutEvent('payout.failed', id)).expect(200);
      expect((await wallet()).balancePaise).toBe(300000);
    });

    it('payout.reversed after PAID returns the money; failed after PAID does not', async () => {
      const id = await inFlight();
      await webhook(payoutEvent('payout.processed', id)).expect(200);
      await webhook(payoutEvent('payout.failed', id)).expect(200);
      expect(
        (await prisma.withdrawal.findUniqueOrThrow({ where: { id } })).status,
      ).toBe('PAID');
      expect((await wallet()).balancePaise).toBe(200000);

      await webhook(payoutEvent('payout.reversed', id)).expect(200);
      expect(
        (await prisma.withdrawal.findUniqueOrThrow({ where: { id } })).status,
      ).toBe('FAILED');
      expect((await wallet()).balancePaise).toBe(300000);
      expect(await ledgerSum()).toBe(0);
    });

    it('finds the withdrawal by provider reference and ignores unknown payouts', async () => {
      const id = await inFlight();
      await webhook({
        event: 'payout.processed',
        payload: { payout: { entity: { id: `pout_${id}` } } },
      }).expect(200);
      expect(
        (await prisma.withdrawal.findUniqueOrThrow({ where: { id } })).status,
      ).toBe('PAID');
      await webhook(payoutEvent('payout.processed', randomUUID())).expect(200);
      await webhook(payoutEvent('payout.processed', 'not-a-uuid')).expect(200);
    });

    it('rejects a malformed body', async () => {
      const raw = 'not json';
      await http()
        .post('/payments/razorpayx/webhook')
        .set('content-type', 'application/json')
        .set(
          'x-razorpay-signature',
          hmacSha256Hex(STUB_PAYOUT_WEBHOOK_SECRET, raw),
        )
        .send(raw)
        .expect(400);
    });
  });

  describe('GET /wallet/ledger', () => {
    it('lists the wallet entries with descriptions, newest first, paginated', async () => {
      const seller = user;
      const buyer = await createTestUser(app);
      const drawing = await createDrawing(prisma, seller.user.id, {
        title: 'Villa Plan',
      });
      const purchase = await prisma.purchase.create({
        data: {
          buyerId: buyer.user.id,
          drawingId: drawing.id,
          pricePaise: 100000,
          platformFeePaise: 10000,
          status: 'PAID',
          paidAt: new Date(),
        },
      });
      await ledger.postTransaction([
        {
          accountType: 'PAYMENT_GATEWAY',
          amountPaise: -100000,
          entryType: 'SALE',
          referenceId: purchase.id,
        },
        {
          accountType: 'USER_WALLET',
          accountOwnerId: seller.user.id,
          amountPaise: 90000,
          entryType: 'SALE',
          referenceId: purchase.id,
        },
        {
          accountType: 'PLATFORM_REVENUE',
          amountPaise: 10000,
          entryType: 'PLATFORM_FEE',
          referenceId: purchase.id,
        },
      ]);
      await credit(seller.user.id, 200000);
      await addBank();
      const { body: w } = await withdraw(60000).expect(201);
      await payouts.fail(w.id, 'x');

      const all = await http()
        .get('/wallet/ledger')
        .set(...bearer(seller))
        .expect(200);
      const types = all.body.items.map(
        (i: { entryType: string }) => i.entryType,
      );
      expect(types).toEqual([
        'WITHDRAWAL_REVERSAL',
        'WITHDRAWAL',
        'SALE',
        'SALE',
      ]);
      const byType = Object.fromEntries(
        all.body.items.map((i: { entryType: string; description: string }) => [
          i.entryType,
          i.description,
        ]),
      );
      expect(byType.WITHDRAWAL).toBe('Withdrawal to bank ••••9012');
      expect(byType.WITHDRAWAL_REVERSAL).toBe(
        'Withdrawal failed – amount returned',
      );
      expect(
        all.body.items.some(
          (i: { description: string; amountPaise: number }) =>
            i.description === 'Sale of "Villa Plan"' && i.amountPaise === 90000,
        ),
      ).toBe(true);
      expect(all.body.items[1].amountPaise).toBe(-60000);
      expect(all.body.items[0].referenceId).toBe(w.id);

      const seen: string[] = [];
      let cursor: string | null = null;
      do {
        const page: request.Response = await http()
          .get('/wallet/ledger')
          .query({ limit: 1, ...(cursor ? { cursor } : {}) })
          .set(...bearer(seller))
          .expect(200);
        expect(page.body.items.length).toBeLessThanOrEqual(1);
        seen.push(...page.body.items.map((i: { id: string }) => i.id));
        cursor = page.body.nextCursor;
      } while (cursor);
      expect(seen).toEqual(all.body.items.map((i: { id: string }) => i.id));
    });

    it('only shows the caller’s own entries', async () => {
      const other = await createTestUser(app);
      await credit(other.user.id, 100000);
      const res = await http()
        .get('/wallet/ledger')
        .set(...bearer(user))
        .expect(200);
      expect(res.body.items).toEqual([]);
      await http()
        .get('/wallet/ledger')
        .query({ cursor: '%%%' })
        .set(...bearer(user))
        .expect(400);
    });
  });

  describe('GET /wallet/withdrawals', () => {
    it('paginates newest first and is scoped to the user', async () => {
      await addBank();
      await credit(user.user.id, 1_000_000);
      const ids: string[] = [];
      for (let i = 0; i < 3; i++) {
        const { body } = await withdraw(100000).expect(201);
        ids.unshift(body.id);
        await runQueued();
      }
      const other = await createTestUser(app);
      const mine: string[] = [];
      let cursor: string | null = null;
      do {
        const page: request.Response = await http()
          .get('/wallet/withdrawals')
          .query({ limit: 2, ...(cursor ? { cursor } : {}) })
          .set(...bearer(user))
          .expect(200);
        mine.push(...page.body.items.map((i: { id: string }) => i.id));
        cursor = page.body.nextCursor;
      } while (cursor);
      expect(mine).toEqual(ids);
      const theirs = await http()
        .get('/wallet/withdrawals')
        .set(...bearer(other))
        .expect(200);
      expect(theirs.body.items).toEqual([]);
    });
  });
});
