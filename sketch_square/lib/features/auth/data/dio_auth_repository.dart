import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_session.dart';
import '../domain/user.dart';

class DioAuthRepository implements AuthRepository {
  DioAuthRepository(this._dio);

  final Dio _dio;

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } catch (e) {
      throw toApiException(e);
    }
  }

  @override
  Future<AuthSession> signup({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String address,
    required String city,
  }) => _guard(() async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/auth/signup',
      data: {
        'email': email,
        'password': password,
        'fullName': fullName,
        'phone': phone,
        'address': address,
        'city': city,
      },
    );
    return AuthSession.fromJson(res.data!);
  });

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) => _guard(() async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    return AuthSession.fromJson(res.data!);
  });

  @override
  Future<Tokens> refresh(String refreshToken) => _guard(() async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/auth/refresh',
      data: {'refreshToken': refreshToken},
    );
    return Tokens.fromJson(res.data!['tokens'] as Map<String, dynamic>);
  });

  @override
  Future<void> logout(String refreshToken) => _guard(
    () => _dio.post<void>('/auth/logout', data: {'refreshToken': refreshToken}),
  );

  @override
  Future<void> forgotPassword(String email) => _guard(
    () => _dio.post<void>('/auth/forgot-password', data: {'email': email}),
  );

  @override
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) => _guard(
    () => _dio.post<void>(
      '/auth/reset-password',
      data: {'token': token, 'newPassword': newPassword},
    ),
  );

  @override
  Future<User> me() => _guard(() async {
    final res = await _dio.get<Map<String, dynamic>>('/me');
    return User.fromJson(res.data!);
  });
}
