import 'auth_session.dart';
import 'user.dart';

/// Auth endpoints from docs/API_CONTRACT.md. Implementations throw
/// `ApiException` (see `toApiException`). Token persistence is the
/// controller's job, not the repository's.
abstract interface class AuthRepository {
  Future<AuthSession> signup({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String address,
    required String city,
  });

  Future<AuthSession> login({required String email, required String password});

  Future<Tokens> refresh(String refreshToken);

  Future<void> logout(String refreshToken);

  Future<void> forgotPassword(String email);

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  });

  /// `GET /me`.
  Future<User> me();
}
