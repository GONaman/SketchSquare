import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sketch_square/core/network/api_exception.dart';
import 'package:sketch_square/core/network/dio_client.dart';
import 'package:sketch_square/core/storage/secure_storage.dart';
import 'package:sketch_square/core/storage/token_store.dart';
import 'package:sketch_square/features/admin/data/dio_admin_repository.dart';
import 'package:sketch_square/features/auth/domain/user.dart';

import '../../helpers/scripted_adapter.dart';

const _item = {
  'id': 'v1',
  'status': 'PENDING',
  'coaRegistrationNumber': 'CA/2015/1',
  'submittedAt': '2026-01-02T03:04:05.000Z',
  'user': {
    'id': 'u1',
    'fullName': 'Asha Rao',
    'email': 'a@b.co',
    'phone': '+919999999999',
    'city': 'Bengaluru',
    'address': 'MG Road',
  },
};

void main() {
  late ScriptedAdapter adapter;
  late DioAdminRepository repo;

  void respond(ResponseBody Function(RequestOptions o) handler) {
    adapter = ScriptedAdapter((o) => handler(o));
    repo = DioAdminRepository(
      createDio(
        tokenStore: SecureTokenStore(InMemorySecureStorage()),
        baseUrl: 'http://test',
        httpClientAdapter: adapter,
      ),
    );
  }

  test('lists verifications with status, limit and cursor', () async {
    respond(
      (_) => jsonResponse({
        'items': [_item],
        'nextCursor': 'c2',
      }),
    );
    final page = await repo.verifications(cursor: 'c1', limit: 10);

    final req = adapter.requests.single;
    expect(req.method, 'GET');
    expect(req.path, '/admin/verifications');
    expect(req.queryParameters, {
      'status': 'PENDING',
      'limit': 10,
      'cursor': 'c1',
    });
    expect(page.nextCursor, 'c2');
    expect(page.items.single.user.fullName, 'Asha Rao');
    expect(page.items.single.status, VerificationStatus.pending);
    expect(page.items.single.documentUrl, isNull);
  });

  test('first page sends no cursor', () async {
    respond((_) => jsonResponse({'items': [], 'nextCursor': null}));
    await repo.verifications();
    expect(
      adapter.requests.single.queryParameters.containsKey('cursor'),
      false,
    );
  });

  test('detail includes documentUrl and reviewNote', () async {
    respond(
      (_) => jsonResponse({
        ..._item,
        'documentUrl': 'https://files/doc.pdf?sig=1',
        'reviewNote': 'earlier note',
      }),
    );
    final v = await repo.verification('v1');
    expect(adapter.requests.single.path, '/admin/verifications/v1');
    expect(v.documentUrl, 'https://files/doc.pdf?sig=1');
    expect(v.reviewNote, 'earlier note');
  });

  test('approve and reject hit the contract endpoints', () async {
    respond((_) => jsonResponse({'ok': true}));
    await repo.approve('v1');
    await repo.reject('v2', note: 'Blurry scan');

    expect(adapter.requests[0].method, 'POST');
    expect(adapter.requests[0].path, '/admin/verifications/v1/approve');
    expect(adapter.requests[1].path, '/admin/verifications/v2/reject');
    expect(adapter.requests[1].data, {'note': 'Blurry scan'});
  });

  test('server errors become ApiException', () async {
    respond((_) => errorResponse(403, 'FORBIDDEN', 'Admins only'));
    await expectLater(
      repo.verifications(),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', 'FORBIDDEN')),
    );
  });
}
