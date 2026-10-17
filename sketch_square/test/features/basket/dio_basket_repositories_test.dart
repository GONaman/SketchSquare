import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sketch_square/core/network/api_exception.dart';
import 'package:sketch_square/features/basket/data/dio_basket_repositories.dart';
import 'package:sketch_square/features/basket/domain/checkout_models.dart';

import '../../helpers/scripted_adapter.dart';

const _drawingJson = {
  'id': 'd1',
  'title': 'Modern Villa',
  'category': {'id': 'c1', 'name': 'Villas', 'slug': 'villas'},
  'city': 'Bengaluru',
  'plotLengthFt': 30,
  'plotBreadthFt': 40,
  'plotAreaSqft': 1200,
  'floors': 2,
  'pricePaise': 150000,
  'isFree': false,
  'previewUrl': null,
  'architect': {
    'id': 'a1',
    'fullName': 'Asha Rao',
    'city': 'Bengaluru',
    'architectRating': 4.5,
    'ratingCount': 3,
    'avatarUrl': null,
  },
  'status': 'PUBLISHED',
  'createdAt': '2026-01-01T00:00:00.000Z',
};

Dio _dio(ScriptedAdapter adapter) =>
    Dio(BaseOptions(baseUrl: 'http://test'))
      ..httpClientAdapter = adapter
      ..interceptors.add(_Mapper());

class _Mapper extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final parsed = ApiException.tryParseBody(
      err.response?.data,
      statusCode: err.response?.statusCode,
    );
    handler.next(parsed == null ? err : err.copyWith(error: parsed));
  }
}

void main() {
  test('cart endpoints use the contract paths and parse the cart', () async {
    final adapter = ScriptedAdapter(
      (_) => jsonResponse({
        'items': [_drawingJson],
        'totalPaise': 150000,
      }),
    );
    final repo = DioCartRepository(_dio(adapter));

    final cart = await repo.getCart();
    expect(cart.items.single.title, 'Modern Villa');
    expect(cart.totalPaise, 150000);

    await repo.add('d1');
    await repo.remove('d1');

    expect(adapter.requests.map((r) => '${r.method} ${r.path}'), [
      'GET /cart',
      'POST /cart',
      'DELETE /cart/d1',
    ]);
    expect(adapter.requests[1].data, {'drawingId': 'd1'});
  });

  test('cart errors become ApiException with the server code', () async {
    final adapter = ScriptedAdapter(
      (_) =>
          errorResponse(400, 'VALIDATION_ERROR', 'Cannot add your own drawing'),
    );
    final repo = DioCartRepository(_dio(adapter));

    await expectLater(
      repo.add('d1'),
      throwsA(
        isA<ApiException>()
            .having((e) => e.code, 'code', 'VALIDATION_ERROR')
            .having((e) => e.message, 'message', 'Cannot add your own drawing'),
      ),
    );
  });

  test('checkout endpoints: order, verify, stub-complete, status', () async {
    final adapter = ScriptedAdapter((o) {
      if (o.path == '/checkout') {
        return jsonResponse({
          'orderId': 'order_1',
          'razorpayKeyId': 'stub',
          'amountPaise': 150000,
          'currency': 'INR',
          'purchaseIds': ['p1'],
        }, 201);
      }
      return jsonResponse({'status': 'PAID'});
    });
    final repo = DioCheckoutRepository(_dio(adapter));

    final order = await repo.createOrder();
    expect(order.isStub, isTrue);
    expect(order.purchaseIds, ['p1']);

    const confirmation = PaymentConfirmation(
      razorpayOrderId: 'o',
      razorpayPaymentId: 'p',
      razorpaySignature: 's',
    );
    expect(await repo.verify(confirmation), OrderStatus.paid);
    expect(await repo.stubComplete('order_1'), OrderStatus.paid);
    expect(await repo.status('order_1'), OrderStatus.paid);

    expect(adapter.requests[1].data, {
      'razorpayOrderId': 'o',
      'razorpayPaymentId': 'p',
      'razorpaySignature': 's',
    });
    expect(adapter.requests[2].path, '/checkout/stub-complete');
    expect(adapter.requests[2].data, {'orderId': 'order_1'});
    expect(adapter.requests[3].queryParameters, {'orderId': 'order_1'});
  });

  test('OrderStatus.fromApi maps unknown values to created', () {
    expect(OrderStatus.fromApi('PAID'), OrderStatus.paid);
    expect(OrderStatus.fromApi('FAILED'), OrderStatus.failed);
    expect(OrderStatus.fromApi('CREATED'), OrderStatus.created);
    expect(OrderStatus.fromApi('???'), OrderStatus.created);
  });
}
