import 'package:freezed_annotation/freezed_annotation.dart';

import 'user.dart';

part 'auth_state.freezed.dart';

/// Session state consumed by the router guard.
@freezed
sealed class AuthState with _$AuthState {
  const factory AuthState.unauthenticated() = Unauthenticated;

  const factory AuthState.authenticated({required User user}) = Authenticated;
}
