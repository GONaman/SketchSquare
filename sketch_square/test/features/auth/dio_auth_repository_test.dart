import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sketch_square/core/network/api_exception.dart';
import 'package:sketch_square/core/network/dio_client.dart';
import 'package:sketch_square/core/storage/secure_storage.dart';
import 'package:sketch_square/core/storage/token_store.dart';
import 'package:sketch_square/features/auth/data/dio_auth_repository.dart';
import 'package:sketch_square/features/auth/domain/user.dart';

import '../../helpers/scripted_adapter.dart';

const _userJson = {
  'id': 'u1',
  'email': 'a@b.co',
  'fullName': 'Asha Rao',
  'address': 'MG Road',
  'phone': '+919999999999',
  'avatarUrl': null,
  'city': 'Bengaluru',
  'role': 'ARCHITECT',
  'verificationStatus': 'PENDING',
  'architectRating': 0,
  'freeDownloadsUsed': 0,
  'freeDownloadLimit': 20,
  'createdAt': '2026-01-02T03:04:05.000Z',
};
const _tokensJson = {'accessToken': 'a', 'refreshToken': 'r', 'expiresIn': 900};

void main() {
  late ScriptedAdapter adapter;
  late DioAuthRepository repo;

  void respond(ResponseBody Function(RequestOptions o) handler) {
    adapter = ScriptedAdapter((o) => handler(o));
    repo = DioAuthRepository(
      createDio(
        tokenStore: SecureTokenStore(InMemorySecureStorage()),
        baseUrl: 'http://test',
        httpClientAdapter: adapter,
      ),
    );
  }

  test('signup posts the contract body and parses {user, tokens}', () async {
    respond(
      (_) => jsonResponse({'user': _userJson, 'tokens': _tokensJson}, 201),
    );
    final session = await repo.signup(
      email: 'a@b.co',
      password: 'password1',
      fullName: 'Asha Rao',
      phone: '+919999999999',
      address: 'MG Road',
      city: 'Bengaluru',
    );
    final req = adapter.requests.single;
    expect(req.method, 'POST');
    expect(req.path, '/auth/signup');
    expect(req.data, {
      'email': 'a@b.co',
      'password': 'password1',
      'fullName': 'Asha Rao',
      'phone': '+919999999999',
      'address': 'MG Road',
      'city': 'Bengaluru',
    });
    expect(session.user.verificationStatus, VerificationStatus.pending);
    expect(session.tokens.accessToken, 'a');
  });

  test('signup maps 409 CONFLICT', () async {
    respond((_) => errorResponse(409, 'CONFLICT', 'Email already registered'));
    await expectLater(
      repo.signup(
        email: 'a@b.co',
        password: 'password1',
        fullName: 'x',
        phone: '1',
        address: 'x',
        city: 'x',
      ),
      throwsA(
        isA<ApiException>().having(
          (e) => e.code,
          'code',
          ApiErrorCodes.conflict,
        ),
      ),
    );
  });

  test('login', () async {
    respond((_) => jsonResponse({'user': _userJson, 'tokens': _tokensJson}));
    final s = await repo.login(email: 'a@b.co', password: 'pw');
    expect(adapter.requests.single.path, '/auth/login');
    expect(adapter.requests.single.data, {'email': 'a@b.co', 'password': 'pw'});
    expect(s.user.email, 'a@b.co');
  });

  test('refresh unwraps {tokens}', () async {
    respond((_) => jsonResponse({'tokens': _tokensJson}));
    final t = await repo.refresh('old');
    expect(adapter.requests.single.data, {'refreshToken': 'old'});
    expect(t.refreshToken, 'r');
  });

  test('logout, forgot and reset password accept 204', () async {
    respond((_) => ResponseBody.fromString('', 204));
    await repo.logout('r');
    await repo.forgotPassword('a@b.co');
    await repo.resetPassword(token: 't', newPassword: 'newpassword1');
    expect(adapter.requests.map((r) => r.path), [
      '/auth/logout',
      '/auth/forgot-password',
      '/auth/reset-password',
    ]);
    expect(adapter.requests[0].data, {'refreshToken': 'r'});
    expect(adapter.requests[1].data, {'email': 'a@b.co'});
    expect(adapter.requests[2].data, {
      'token': 't',
      'newPassword': 'newpassword1',
    });
  });

  test('me parses User', () async {
    respond((_) => jsonResponse(_userJson));
    final u = await repo.me();
    expect(adapter.requests.single.path, '/me');
    expect(u.id, 'u1');
  });

  test('network errors become ApiException', () async {
    respond(
      (o) => throw DioException.connectionError(requestOptions: o, reason: 'x'),
    );
    await expectLater(
      repo.me(),
      throwsA(
        isA<ApiException>().having(
          (e) => e.code,
          'code',
          ApiErrorCodes.network,
        ),
      ),
    );
  });
}
