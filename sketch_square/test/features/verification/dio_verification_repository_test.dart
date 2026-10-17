import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sketch_square/core/network/api_exception.dart';
import 'package:sketch_square/core/network/dio_client.dart';
import 'package:sketch_square/core/storage/secure_storage.dart';
import 'package:sketch_square/core/storage/token_store.dart';
import 'package:sketch_square/features/auth/domain/user.dart';
import 'package:sketch_square/features/verification/data/dio_verification_repository.dart';
import 'package:sketch_square/features/verification/domain/verification_request.dart';

import '../../helpers/scripted_adapter.dart';

const _requestJson = {
  'id': 'v1',
  'coaRegistrationNumber': 'CA/2015/12345',
  'status': 'REJECTED',
  'reviewNote': 'Blurry scan',
  'submittedAt': '2026-01-02T03:04:05.000Z',
  'reviewedAt': '2026-01-03T03:04:05.000Z',
};

void main() {
  late ScriptedAdapter adapter;
  late DioVerificationRepository repo;

  void respond(ResponseBody Function(RequestOptions o) handler) {
    adapter = ScriptedAdapter((o) => handler(o));
    repo = DioVerificationRepository(
      createDio(
        tokenStore: SecureTokenStore(InMemorySecureStorage()),
        baseUrl: 'http://test',
        httpClientAdapter: adapter,
      ),
    );
  }

  test('submit posts multipart with the COA number and document', () async {
    respond((_) => jsonResponse(_requestJson, 201));
    final result = await repo.submit(
      coaRegistrationNumber: 'CA/2015/12345',
      document: VerificationDocument(
        fileName: 'coa.pdf',
        bytes: Uint8List.fromList([1, 2, 3]),
      ),
    );

    final req = adapter.requests.single;
    expect(req.method, 'POST');
    expect(req.path, '/verification');
    final form = req.data as FormData;
    expect(
      form.fields.singleWhere((f) => f.key == 'coaRegistrationNumber').value,
      'CA/2015/12345',
    );
    final file = form.files.singleWhere((f) => f.key == 'document').value;
    expect(file.filename, 'coa.pdf');
    expect(file.contentType?.mimeType, 'application/pdf');
    expect(file.length, 3);
    expect(result.status, VerificationStatus.rejected);
    expect(result.reviewNote, 'Blurry scan');
  });

  test('submit maps server errors to ApiException', () async {
    respond((_) => errorResponse(400, 'UPLOAD_INVALID', 'Bad file'));
    await expectLater(
      repo.submit(
        coaRegistrationNumber: 'CA/1',
        document: VerificationDocument(fileName: 'a.pdf', bytes: Uint8List(1)),
      ),
      throwsA(
        isA<ApiException>().having((e) => e.message, 'message', 'Bad file'),
      ),
    );
  });

  test('mine parses a request and null', () async {
    respond((_) => jsonResponse({'verification': _requestJson}));
    final found = await repo.mine();
    expect(adapter.requests.single.path, '/verification/me');
    expect(found?.coaRegistrationNumber, 'CA/2015/12345');
    expect(found?.reviewedAt, isNotNull);

    respond((_) => jsonResponse({'verification': null}));
    expect(await repo.mine(), isNull);
  });
}
