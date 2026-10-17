import 'dart:async';

import 'package:dio/dio.dart';

import '../storage/token_store.dart';

/// Refreshes the access token on a 401 and retries the request once.
///
/// - Single-flight: concurrent 401s share one `POST /auth/refresh` call (the
///   refresh token rotates, so a second parallel call would revoke the family).
/// - If the stored access token already differs from the one the failed request
///   used, another request refreshed meanwhile and we just retry.
/// - If the server rejects the refresh token the session is over: tokens are
///   cleared and [onSessionExpired] fires. A transport failure during refresh
///   keeps the session and surfaces the original error.
class RefreshInterceptor extends Interceptor {
  RefreshInterceptor({
    required Dio dio,
    required TokenStore tokenStore,
    this.onSessionExpired,
  }) : _dio = dio,
       _tokenStore = tokenStore;

  static const retriedKey = 'auth.retried';
  static const _authPaths = {
    '/auth/login',
    '/auth/signup',
    '/auth/refresh',
    '/auth/logout',
    '/auth/forgot-password',
    '/auth/reset-password',
  };

  final Dio _dio;
  final TokenStore _tokenStore;
  final void Function()? onSessionExpired;

  Future<AuthTokens?>? _inFlight;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final request = err.requestOptions;
    if (err.response?.statusCode != 401 ||
        request.extra[retriedKey] == true ||
        _authPaths.contains(request.path)) {
      return handler.next(err);
    }

    final stored = await _tokenStore.read();
    if (stored == null) return handler.next(err);

    final sentWith = request.headers['Authorization'];
    final AuthTokens? fresh;
    if (sentWith != null && sentWith != 'Bearer ${stored.accessToken}') {
      fresh = stored;
    } else {
      try {
        fresh =
            await (_inFlight ??= _refresh(
              stored,
            ).whenComplete(() => _inFlight = null));
      } on DioException {
        return handler.next(err);
      }
    }
    if (fresh == null) return handler.next(err);

    try {
      final retry = request.copyWith(
        headers: {
          ...request.headers,
          'Authorization': 'Bearer ${fresh.accessToken}',
        },
        extra: {...request.extra, retriedKey: true},
      );
      final response = await _dio.fetch<dynamic>(retry);
      handler.resolve(response);
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  /// Returns the new tokens, or null if the session ended. Throws a
  /// [DioException] for transport errors, where the session must stay intact.
  Future<AuthTokens?> _refresh(AuthTokens stored) async {
    // Bare client: no interceptors, so no recursion through this class.
    final bare = Dio(
      BaseOptions(
        baseUrl: _dio.options.baseUrl,
        connectTimeout: _dio.options.connectTimeout,
        receiveTimeout: _dio.options.receiveTimeout,
        headers: {'Accept': 'application/json'},
      ),
    )..httpClientAdapter = _dio.httpClientAdapter;
    try {
      final response = await bare.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': stored.refreshToken},
      );
      final tokens =
          (response.data?['tokens'] as Map?)?.cast<String, dynamic>();
      final access = tokens?['accessToken'];
      final refresh = tokens?['refreshToken'];
      if (access is String && refresh is String) {
        final fresh = AuthTokens(accessToken: access, refreshToken: refresh);
        await _tokenStore.save(fresh);
        return fresh;
      }
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == null || status >= 500) rethrow;
    }
    await _tokenStore.clear();
    onSessionExpired?.call();
    return null;
  }
}
