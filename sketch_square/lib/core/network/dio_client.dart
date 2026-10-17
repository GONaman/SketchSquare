import 'package:dio/dio.dart';

import '../storage/token_store.dart';
import 'api_config.dart';
import 'interceptors.dart';

Dio createDio({
  required TokenStore tokenStore,
  String baseUrl = ApiConfig.baseUrl,
  HttpClientAdapter? httpClientAdapter,
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
    ErrorMappingInterceptor(),
  ]);
  return dio;
}
