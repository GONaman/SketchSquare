import 'package:sketch_square/core/network/api_exception.dart';
import 'package:sketch_square/features/auth/domain/auth_repository.dart';
import 'package:sketch_square/features/auth/domain/auth_session.dart';
import 'package:sketch_square/features/auth/domain/user.dart';
import 'package:sketch_square/features/auth/presentation/auth_controller.dart';

/// In-memory [AuthRepository]. Set [error] to make the next calls throw;
/// inspect [calls] to assert what the UI invoked.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({User? user, this.tokens = defaultTokens})
    : user = user ?? stubUser;

  static const defaultTokens = Tokens(
    accessToken: 'access-1',
    refreshToken: 'refresh-1',
  );

  User user;
  Tokens tokens;
  ApiException? error;
  final calls = <String>[];

  /// Overrides [error] for specific methods (e.g. `{'login': ...}`).
  final errors = <String, ApiException>{};

  T _run<T>(String name, T Function() body) {
    calls.add(name);
    final e = errors[name] ?? error;
    if (e != null) throw e;
    return body();
  }

  @override
  Future<AuthSession> signup({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String address,
    required String city,
  }) async => _run('signup', () {
    user = user.copyWith(
      email: email,
      fullName: fullName,
      phone: phone,
      address: address,
      city: city,
      role: UserRole.architect,
      verificationStatus: VerificationStatus.pending,
    );
    return AuthSession(user: user, tokens: tokens);
  });

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async => _run('login', () => AuthSession(user: user, tokens: tokens));

  @override
  Future<Tokens> refresh(String refreshToken) async =>
      _run('refresh', () => tokens);

  @override
  Future<void> logout(String refreshToken) async => _run('logout', () => null);

  @override
  Future<void> forgotPassword(String email) async =>
      _run('forgotPassword', () => null);

  @override
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async => _run('resetPassword', () => null);

  @override
  Future<User> me() async => _run('me', () => user);
}
