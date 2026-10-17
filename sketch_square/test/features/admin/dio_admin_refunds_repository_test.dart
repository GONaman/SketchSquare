import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sketch_square/core/network/api_exception.dart';
import 'package:sketch_square/core/network/dio_client.dart';
import 'package:sketch_square/core/storage/secure_storage.dart';
import 'package:sketch_square/core/storage/token_store.dart';
import 'package:sketch_square/features/admin/data/dio_admin_refunds_repository.dart';
import 'package:sketch_square/features/admin/domain/admin_purchase.dart';

import '../../helpers/scripted_adapter.dart';

const _refund = {
  'id': 'r1',
  'reason': 'Duplicate',
  'amountPaise': 50000,
  'refundedAt': '2026-02-03T04:00:00.000Z',
  'refundedBy': {'id': 'a1', 'fullName': 'Ada Admin'},
  'providerStatus': 'FAILED',
  'providerRefundId': null,
  'providerError': 'gateway down',
};

const _item = {
  'id': 'p1',
  'status': 'REFUNDED',
  'pricePaise': 50000,
  'platformFeePaise': 5000,
  'sellerNetPaise': 45000,
  'razorpayOrderId': 'order_1',
  'razorpayPaymentId': null,
  'createdAt': '2026-02-01T10:00:00.000Z',
  'paidAt': '2026-02-01T10:05:00.000Z',
  'buyer': {'id': 'b1', 'fullName': 'Bella', 'email': 'b@x.test'},
  'seller': {'id': 's1', 'fullName': 'Sam', 'email': 's@x.test'},
  'drawing': {'id': 'd1', 'title': 'Villa'},
  'refund': _refund,
};

void main() {
  late ScriptedAdapter adapter;
  late DioAdminRefundsRepository repo;

  void respond(ResponseBody Function(RequestOptions o) handler) {
    adapter = ScriptedAdapter((o) => handler(o));
    repo = DioAdminRefundsRepository(
      createDio(
        tokenStore: SecureTokenStore(InMemorySecureStorage()),
        baseUrl: 'http://test',
        httpClientAdapter: adapter,
      ),
    );
  }

  test('lists purchases with search, status, cursor and limit', () async {
    respond(
      (_) => jsonResponse({
        'items': [_item],
        'nextCursor': 'c2',
      }),
    );
    final page = await repo.purchases(
      q: '  villa ',
      status: PurchaseStatus.refunded,
      cursor: 'c1',
      limit: 10,
    );

    final req = adapter.requests.single;
    expect(req.method, 'GET');
    expect(req.path, '/admin/purchases');
    expect(req.queryParameters, {
      'q': 'villa',
      'status': 'REFUNDED',
      'limit': 10,
      'cursor': 'c1',
    });
    expect(page.nextCursor, 'c2');
    final p = page.items.single;
    expect(p.status, PurchaseStatus.refunded);
    expect(p.drawingTitle, 'Villa');
    expect(p.buyer.email, 'b@x.test');
    expect(p.refund!.providerStatus, RefundProviderStatus.failed);
    expect(p.refund!.providerError, 'gateway down');
    expect(p.sellerBalancePaise, isNull);
  });

  test('omits empty search and status', () async {
    respond((_) => jsonResponse({'items': [], 'nextCursor': null}));
    await repo.purchases(q: ' ');
    expect(adapter.requests.single.queryParameters, {'limit': 20});
  });

  test('reads the detail with the seller balance', () async {
    respond((_) => jsonResponse({..._item, 'sellerBalancePaise': -500}));
    final p = await repo.purchase('p1');
    expect(adapter.requests.single.path, '/admin/purchases/p1');
    expect(p.sellerBalancePaise, -500);
  });

  test('refund posts the reason and parses the result', () async {
    respond(
      (_) => jsonResponse({
        'ok': true,
        'alreadyRefunded': true,
        'refund': _refund,
      }),
    );
    final r = await repo.refund('p1', reason: 'Duplicate');

    final req = adapter.requests.single;
    expect(req.method, 'POST');
    expect(req.path, '/admin/purchases/p1/refund');
    expect(req.data, {'reason': 'Duplicate'});
    expect(r.alreadyRefunded, isTrue);
    expect(r.refund.amountPaise, 50000);
  });

  test('maps error envelopes to ApiException', () async {
    respond((_) => errorResponse(409, 'CONFLICT', 'Not refundable'));
    await expectLater(
      repo.refund('p1', reason: 'abc'),
      throwsA(
        isA<ApiException>()
            .having((e) => e.code, 'code', 'CONFLICT')
            .having((e) => e.message, 'message', 'Not refundable'),
      ),
    );
  });
}
