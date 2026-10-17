import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../domain/basket_repositories.dart';
import '../domain/cart.dart';
import '../domain/checkout_models.dart';

class DioCartRepository implements CartRepository {
  DioCartRepository(this._dio);
  final Dio _dio;

  @override
  Future<Cart> getCart() => _cart(() => _dio.get<Object?>('/cart'));

  @override
  Future<Cart> add(String drawingId) =>
      _cart(() => _dio.post<Object?>('/cart', data: {'drawingId': drawingId}));

  @override
  Future<Cart> remove(String drawingId) =>
      _cart(() => _dio.delete<Object?>('/cart/$drawingId'));

  Future<Cart> _cart(Future<Response<Object?>> Function() call) async {
    try {
      final res = await call();
      return Cart.fromJson(res.data! as Map<String, dynamic>);
    } catch (e) {
      throw toApiException(e);
    }
  }
}

class DioCheckoutRepository implements CheckoutRepository {
  DioCheckoutRepository(this._dio);
  final Dio _dio;

  @override
  Future<CheckoutOrder> createOrder() async {
    try {
      final res = await _dio.post<Object?>('/checkout');
      return CheckoutOrder.fromJson(res.data! as Map<String, dynamic>);
    } catch (e) {
      throw toApiException(e);
    }
  }

  @override
  Future<OrderStatus> verify(PaymentConfirmation confirmation) => _status(
    () => _dio.post<Object?>('/checkout/verify', data: confirmation.toJson()),
  );

  @override
  Future<OrderStatus> stubComplete(String orderId) => _status(
    () => _dio.post<Object?>(
      '/checkout/stub-complete',
      data: {'orderId': orderId},
    ),
  );

  @override
  Future<OrderStatus> status(String orderId) => _status(
    () => _dio.get<Object?>(
      '/checkout/status',
      queryParameters: {'orderId': orderId},
    ),
  );

  Future<OrderStatus> _status(Future<Response<Object?>> Function() call) async {
    try {
      final res = await call();
      final raw = (res.data! as Map<String, dynamic>)['status'];
      return OrderStatus.fromApi(raw);
    } catch (e) {
      throw toApiException(e);
    }
  }
}
