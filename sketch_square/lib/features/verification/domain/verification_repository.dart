import 'verification_request.dart';

abstract interface class VerificationRepository {
  /// `POST /verification` (multipart). Allowed when REJECTED, or while still
  /// PENDING (replaces the earlier submission).
  Future<VerificationRequest> submit({
    required String coaRegistrationNumber,
    required VerificationDocument document,
  });

  /// `GET /verification/me`; null if nothing was submitted yet.
  Future<VerificationRequest?> mine();
}

/// Lets the user choose a document; swapped for a fake in tests.
abstract interface class DocumentPicker {
  /// Returns null if the user cancelled.
  Future<VerificationDocument?> pick();
}
