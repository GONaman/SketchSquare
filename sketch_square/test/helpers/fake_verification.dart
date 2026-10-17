import 'dart:typed_data';

import 'package:sketch_square/core/network/api_exception.dart';
import 'package:sketch_square/features/auth/domain/user.dart';
import 'package:sketch_square/features/verification/domain/verification_repository.dart';
import 'package:sketch_square/features/verification/domain/verification_request.dart';

class FakeVerificationRepository implements VerificationRepository {
  FakeVerificationRepository({this.current});

  VerificationRequest? current;
  ApiException? submitError;
  ApiException? mineError;
  final submissions = <({String coa, VerificationDocument document})>[];
  int mineCalls = 0;

  @override
  Future<VerificationRequest> submit({
    required String coaRegistrationNumber,
    required VerificationDocument document,
  }) async {
    if (submitError != null) throw submitError!;
    submissions.add((coa: coaRegistrationNumber, document: document));
    return current = VerificationRequest(
      id: 'v1',
      coaRegistrationNumber: coaRegistrationNumber,
      status: VerificationStatus.pending,
      submittedAt: DateTime.utc(2026, 1, 2),
    );
  }

  @override
  Future<VerificationRequest?> mine() async {
    mineCalls++;
    if (mineError != null) throw mineError!;
    return current;
  }
}

class FakeDocumentPicker implements DocumentPicker {
  FakeDocumentPicker([VerificationDocument? document])
    : document = document ?? defaultDocument;

  static final defaultDocument = VerificationDocument(
    fileName: 'coa.pdf',
    bytes: Uint8List.fromList([1, 2, 3]),
  );

  VerificationDocument? document;

  @override
  Future<VerificationDocument?> pick() async => document;
}
