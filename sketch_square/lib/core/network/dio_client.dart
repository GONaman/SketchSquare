import 'package:dio/dio.dart';

import '../storage/token_store.dart';
import 'api_config.dart';
import 'connectivity_status.dart';
import 'interceptors.dart';
import 'refresh_interceptor.dart';

/// Builds the app's [Dio]. [onSessionExpired] fires when a token refresh is
/// rejected by the server (the stored tokens are already cleared by then).
Dio createDio({
  required TokenStore tokenStore,
  String baseUrl = ApiConfig.baseUrl,
  HttpClientAdapter? httpClientAdapter,
  void Function()? onSessionExpired,
  void Function(bool online)? onConnectivityChanged,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Accept': 'application/json'},
    ),
  );
  if (httpClientAdapter != null) dio.httpClientAdapter = httpClientAdapter;
  dio.interceptors.addAll([
    AuthHeaderInterceptor(tokenStore),
    RefreshInterceptor(
      dio: dio,
      tokenStore: tokenStore,
      onSessionExpired: onSessionExpired,
    ),
    ErrorMappingInterceptor(),
    if (onConnectivityChanged != null)
      ConnectivityInterceptor(onConnectivityChanged),
  ]);
  return dio;
}
