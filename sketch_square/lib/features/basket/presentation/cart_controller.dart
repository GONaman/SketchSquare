import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/presentation/current_user_provider.dart';
import '../data/basket_providers.dart';
import '../domain/cart.dart';

part 'cart_controller.g.dart';

/// The signed-in user's basket. Mutations throw `ApiException` to the caller
/// (so screens can show the server's message) and leave the state untouched.
@Riverpod(keepAlive: true)
class CartController extends _$CartController {
  @override
  Future<Cart> build() {
    ref.watch(currentUserIdProvider);
    return ref.watch(cartRepositoryProvider).getCart();
  }

  Future<void> add(String drawingId) async {
    state = AsyncData(await ref.read(cartRepositoryProvider).add(drawingId));
  }

  Future<void> remove(String drawingId) async {
    state = AsyncData(await ref.read(cartRepositoryProvider).remove(drawingId));
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(
      () => ref.read(cartRepositoryProvider).getCart(),
    );
  }
}

/// Number of items for badges; 0 while loading or on error.
@riverpod
int cartCount(Ref ref) =>
    ref.watch(cartControllerProvider).valueOrNull?.itemCount ?? 0;
