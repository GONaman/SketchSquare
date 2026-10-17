import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:sketch_square/core/network/api_exception.dart';
import 'package:sketch_square/core/network/dio_client.dart';
import 'package:sketch_square/core/storage/secure_storage.dart';
import 'package:sketch_square/core/storage/token_store.dart';

void main() {
  group('ApiException.tryParseBody', () {
    test('parses the backend envelope', () {
      final e =
          ApiException.tryParseBody({
            'error': {
              'code': 'VALIDATION_ERROR',
              'message': 'bad',
              'details': {'field': 'email'},
            },
          }, statusCode: 400)!;
      expect(e.code, 'VALIDATION_ERROR');
      expect(e.message, 'bad');
      expect(e.details, {'field': 'email'});
      expect(e.statusCode, 400);
    });

    test('joins list messages and allows missing details', () {
      final e =
          ApiException.tryParseBody({
            'error': {
              'code': 'VALIDATION_ERROR',
              'message': ['a is required', 'b is invalid'],
            },
          })!;
      expect(e.message, 'a is required\nb is invalid');
      expect(e.details, isNull);
    });

    test('returns null for non-envelope bodies', () {
      expect(ApiException.tryParseBody(null), isNull);
      expect(ApiException.tryParseBody('oops'), isNull);
      expect(ApiException.tryParseBody({'message': 'x'}), isNull);
      expect(ApiException.tryParseBody({'error': 'x'}), isNull);
      expect(
        ApiException.tryParseBody({
          'error': {'code': 1},
        }),
        isNull,
      );
    });
  });

  group('through Dio', () {
    late Dio dio;
    late DioAdapter adapter;

    setUp(() {
      dio = createDio(
        tokenStore: SecureTokenStore(InMemorySecureStorage()),
        baseUrl: 'http://test',
      );
      adapter = DioAdapter(dio: dio);
    });

    Future<ApiException> failure(String path) async {
      try {
        await dio.get<dynamic>(path);
      } on DioException catch (e) {
        expect(e.error, isA<ApiException>());
        return e.error as ApiException;
      }
      fail('should throw');
    }

    test('maps an error envelope to ApiException', () async {
      adapter.onGet(
        '/drawings/x',
        (s) => s.reply(404, {
          'error': {'code': 'NOT_FOUND', 'message': 'Drawing not found'},
        }),
      );
      final api = await failure('/drawings/x');
      expect(api.code, ApiErrorCodes.notFound);
      expect(api.message, 'Drawing not found');
      expect(api.statusCode, 404);
    });

    test('falls back to a status-derived code without an envelope', () async {
      adapter.onGet('/boom', (s) => s.reply(503, 'Service Unavailable'));
      expect((await failure('/boom')).code, ApiErrorCodes.internal);
    });

    test('maps connection errors and timeouts', () async {
      adapter.onGet(
        '/net',
        (s) => s.throws(
          0,
          DioException.connectionError(
            requestOptions: RequestOptions(path: '/net'),
            reason: 'down',
          ),
        ),
      );
      adapter.onGet(
        '/slow',
        (s) => s.throws(
          0,
          DioException.receiveTimeout(
            timeout: const Duration(seconds: 1),
            requestOptions: RequestOptions(path: '/slow'),
          ),
        ),
      );
      expect((await failure('/net')).code, ApiErrorCodes.network);
      expect((await failure('/slow')).code, ApiErrorCodes.timeout);
    });

    test('adds the bearer token from the token store', () async {
      final store = SecureTokenStore(InMemorySecureStorage());
      await store.save(const AuthTokens(accessToken: 'a1', refreshToken: 'r1'));
      final authed = createDio(tokenStore: store, baseUrl: 'http://test');
      DioAdapter(dio: authed).onGet(
        '/me',
        (s) => s.reply(200, {'ok': true}),
        headers: {'Authorization': 'Bearer a1'},
      );
      final res = await authed.get<dynamic>('/me');
      expect(res.statusCode, 200);
    });
  });

  test('toApiException wraps unknown errors', () {
    expect(toApiException(StateError('x')).code, ApiErrorCodes.unknown);
  });
}
