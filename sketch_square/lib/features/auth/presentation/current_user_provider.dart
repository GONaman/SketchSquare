import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/auth_state.dart';
import '../domain/user.dart';
import 'auth_controller.dart';

part 'current_user_provider.g.dart';

/// The signed-in user, or null. Per-user caches (basket, wallet, purchases)
/// `watch` [currentUserIdProvider] so they rebuild when the account changes.
@riverpod
User? currentUser(Ref ref) => switch (ref.watch(authControllerProvider)) {
  Authenticated(:final user) => user,
  _ => null,
};

@riverpod
String? currentUserId(Ref ref) =>
    ref.watch(currentUserProvider.select((u) => u?.id));
