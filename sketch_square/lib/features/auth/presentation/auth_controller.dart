import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/auth_state.dart';
import '../domain/user.dart';

part 'auth_controller.g.dart';

/// Session state. STUB: always "logged in & approved" so the shell shows.
/// Phase 2 replaces `build` with the real token/session bootstrap.
@Riverpod(keepAlive: true)
class AuthController extends _$AuthController {
  @override
  AuthState build() => AuthState.authenticated(user: stubUser);
}

final stubUser = User(
  id: '00000000-0000-0000-0000-000000000000',
  email: 'architect@example.com',
  fullName: 'Stub Architect',
  address: '1 Blueprint Street',
  phone: '+910000000000',
  city: 'Bengaluru',
  role: UserRole.architect,
  verificationStatus: VerificationStatus.approved,
  createdAt: DateTime.utc(2026),
);
