import 'package:dio/dio.dart';

import '../storage/token_store.dart';
import 'api_exception.dart';

/// Adds `Authorization: Bearer <access token>` when a token is stored.
///
/// The refresh-on-401 logic lives in `refresh_interceptor.dart`.
class AuthHeaderInterceptor extends Interceptor {
  AuthHeaderInterceptor(this._tokenStore);

  final TokenStore _tokenStore;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final tokens = await _tokenStore.read();
    if (tokens != null && !options.headers.containsKey('Authorization')) {
      options.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
    }
    handler.next(options);
  }
}

/// Maps every failure to an [ApiException] carried in `DioException.error`, so
/// callers can `catch (e) { toApiException(e) }`.
class ErrorMappingInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.next(err.copyWith(error: ApiException.fromDioException(err)));
  }
}
