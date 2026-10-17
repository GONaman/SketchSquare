import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/providers.dart';
import '../domain/basket_repositories.dart';
import '../domain/payment_gateway.dart';
import 'dio_basket_repositories.dart';
import 'pending_checkout_store.dart';
import 'razorpay_gateway.dart';

part 'basket_providers.g.dart';

@Riverpod(keepAlive: true)
CartRepository cartRepository(Ref ref) =>
    DioCartRepository(ref.watch(dioProvider));

@Riverpod(keepAlive: true)
CheckoutRepository checkoutRepository(Ref ref) =>
    DioCheckoutRepository(ref.watch(dioProvider));

@Riverpod(keepAlive: true)
PaymentGateway paymentGateway(Ref ref) => RazorpayGateway();

@Riverpod(keepAlive: true)
PendingCheckoutStore pendingCheckoutStore(Ref ref) =>
    PrefsPendingCheckoutStore(ref.watch(sharedPreferencesProvider));
