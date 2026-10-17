import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sketch_square/core/network/api_exception.dart';
import 'package:sketch_square/core/network/dio_client.dart';
import 'package:sketch_square/core/storage/secure_storage.dart';
import 'package:sketch_square/core/storage/token_store.dart';

import '../../helpers/scripted_adapter.dart';

Map<String, Object?> _tokens(String a, String r) => {
  'tokens': {'accessToken': a, 'refreshToken': r, 'expiresIn': 900},
};

void main() {
  late SecureTokenStore store;
  late int expired;

  setUp(() async {
    store = SecureTokenStore(InMemorySecureStorage());
    await store.save(
      const AuthTokens(accessToken: 'old-access', refreshToken: 'old-refresh'),
    );
    expired = 0;
  });

  Dio build(ScriptedAdapter adapter) => createDio(
    tokenStore: store,
    baseUrl: 'http://test',
    httpClientAdapter: adapter,
    onSessionExpired: () => expired++,
  );

  /// `/data` is 200 only with the new access token.
  ScriptedAdapter backend({
    Future<ResponseBody> Function(RequestOptions)? onRefresh,
  }) {
    late final ScriptedAdapter adapter;
    adapter = ScriptedAdapter((o) async {
      switch (o.path) {
        case '/auth/refresh':
          if (onRefresh != null) return onRefresh(o);
          await Future<void>.delayed(const Duration(milliseconds: 20));
          return jsonResponse(_tokens('new-access', 'new-refresh'));
        case '/data':
          return o.headers['Authorization'] == 'Bearer new-access'
              ? jsonResponse({'ok': true})
              : errorResponse(401, 'UNAUTHORIZED');
        default:
          return errorResponse(404, 'NOT_FOUND');
      }
    });
    return adapter;
  }

  test('refreshes on 401, persists rotated tokens and retries once', () async {
    final adapter = backend();
    final res = await build(adapter).get<Map<String, dynamic>>('/data');

    expect(res.data, {'ok': true});
    expect(adapter.count('/data'), 2);
    expect(adapter.count('/auth/refresh'), 1);
    expect(adapter.requests.firstWhere((r) => r.path == '/auth/refresh').data, {
      'refreshToken': 'old-refresh',
    });
    expect(
      await store.read(),
      const AuthTokens(accessToken: 'new-access', refreshToken: 'new-refresh'),
    );
    expect(expired, 0);
  });

  test('concurrent 401s share a single refresh call', () async {
    final adapter = backend();
    final dio = build(adapter);

    final results = await Future.wait([
      dio.get<Map<String, dynamic>>('/data'),
      dio.get<Map<String, dynamic>>('/data'),
      dio.get<Map<String, dynamic>>('/data'),
    ]);

    expect(results.map((r) => r.statusCode), everyElement(200));
    expect(adapter.count('/auth/refresh'), 1);
    expect(adapter.count('/data'), 6);
  });

  test('a request that raced a refresh is retried without refreshing', () async {
    final adapter = backend();
    final dio = build(adapter);
    // Another caller already rotated the tokens after this request was signed.
    await store.save(
      const AuthTokens(accessToken: 'new-access', refreshToken: 'new-refresh'),
    );
    final res = await dio.get<Map<String, dynamic>>(
      '/data',
      options: Options(headers: {'Authorization': 'Bearer old-access'}),
    );
    expect(res.statusCode, 200);
    expect(adapter.count('/auth/refresh'), 0);
  });

  test(
    'rejected refresh clears tokens, signals expiry, surfaces 401',
    () async {
      final adapter = backend(
        onRefresh: (_) async => errorResponse(401, 'UNAUTHORIZED', 'revoked'),
      );
      await expectLater(
        build(adapter).get<Map<String, dynamic>>('/data'),
        throwsA(
          isA<DioException>().having(
            (e) => (e.error as ApiException).code,
            'code',
            ApiErrorCodes.unauthorized,
          ),
        ),
      );
      expect(await store.read(), isNull);
      expect(expired, 1);
      expect(adapter.count('/data'), 1);
    },
  );

  test('transport failure during refresh keeps the session', () async {
    final adapter = backend(
      onRefresh:
          (o) async =>
              throw DioException.connectionError(
                requestOptions: o,
                reason: 'offline',
              ),
    );
    await expectLater(
      build(adapter).get<Map<String, dynamic>>('/data'),
      throwsA(isA<DioException>()),
    );
    expect(await store.read(), isNotNull);
    expect(expired, 0);
  });

  test('server error during refresh keeps the session', () async {
    final adapter = backend(
      onRefresh: (_) async => errorResponse(500, 'INTERNAL'),
    );
    await expectLater(
      build(adapter).get<Map<String, dynamic>>('/data'),
      throwsA(isA<DioException>()),
    );
    expect(await store.read(), isNotNull);
    expect(expired, 0);
  });

  test('retries only once when the retried request is still 401', () async {
    final adapter = ScriptedAdapter(
      (o) async =>
          o.path == '/auth/refresh'
              ? jsonResponse(_tokens('new-access', 'new-refresh'))
              : errorResponse(401, 'UNAUTHORIZED'),
    );
    await expectLater(
      build(adapter).get<Map<String, dynamic>>('/data'),
      throwsA(isA<DioException>()),
    );
    expect(adapter.count('/data'), 2);
    expect(adapter.count('/auth/refresh'), 1);
    expect(expired, 0);
  });

  test('auth endpoints never trigger a refresh', () async {
    final adapter = ScriptedAdapter(
      (_) async => errorResponse(401, 'UNAUTHORIZED', 'bad credentials'),
    );
    await expectLater(
      build(adapter).post<void>('/auth/login', data: {}),
      throwsA(isA<DioException>()),
    );
    expect(adapter.count('/auth/refresh'), 0);
    expect(await store.read(), isNotNull);
  });

  test('no stored tokens: 401 passes through untouched', () async {
    await store.clear();
    final adapter = backend();
    await expectLater(
      build(adapter).get<Map<String, dynamic>>('/data'),
      throwsA(isA<DioException>()),
    );
    expect(adapter.count('/auth/refresh'), 0);
  });
}
