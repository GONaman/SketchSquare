import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/providers.dart';
import '../../../core/storage/token_store.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_session.dart';
import '../domain/auth_state.dart';
import '../domain/user.dart';
import 'auth_repository_provider.dart';
import 'intro_seen_provider.dart';

part 'auth_controller.g.dart';

/// The app session. Starts as [AuthState.initializing], validates any stored
/// tokens with `GET /me`, then settles on authenticated/unauthenticated.
/// Methods throw [ApiException] so screens can show inline errors.
@Riverpod(keepAlive: true)
class AuthController extends _$AuthController {
  AuthRepository get _repo => ref.read(authRepositoryProvider);
  TokenStore get _tokens => ref.read(tokenStoreProvider);

  @override
  AuthState build() {
    ref.listen(sessionExpiredProvider, (_, __) {
      state = const AuthState.unauthenticated();
    });
    Future.microtask(_bootstrap);
    return const AuthState.initializing();
  }

  Future<void> _bootstrap() async {
    try {
      if (await _tokens.read() == null) {
        state = const AuthState.unauthenticated();
        return;
      }
      state = AuthState.authenticated(user: await _repo.me());
    } catch (e) {
      // 401 means refresh already failed and tokens are cleared. For transport
      // errors the tokens are kept, so the next launch can still resume.
      state = const AuthState.unauthenticated();
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    final session = await _repo.login(email: email, password: password);
    await _adopt(session);
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String address,
    required String city,
  }) async {
    final session = await _repo.signup(
      email: email,
      password: password,
      fullName: fullName,
      phone: phone,
      address: address,
      city: city,
    );
    await _adopt(session);
  }

  Future<void> _adopt(AuthSession session) async {
    await _tokens.save(
      AuthTokens(
        accessToken: session.tokens.accessToken,
        refreshToken: session.tokens.refreshToken,
      ),
    );
    await ref.read(introSeenProvider.notifier).markSeen();
    state = AuthState.authenticated(user: session.user);
  }

  /// Re-reads `GET /me` (e.g. after the admin decided on a verification).
  Future<void> refreshUser() async {
    if (state is! Authenticated) return;
    state = AuthState.authenticated(user: await _repo.me());
  }

  /// Best effort server-side revoke; the local session always ends.
  Future<void> signOut() async {
    final tokens = await _tokens.read();
    await _tokens.clear();
    state = const AuthState.unauthenticated();
    if (tokens != null) {
      try {
        await _repo.logout(tokens.refreshToken);
      } catch (_) {}
    }
  }
}

/// Fixture used by tests and fakes.
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
