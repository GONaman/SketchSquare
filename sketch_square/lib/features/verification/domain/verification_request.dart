import 'dart:typed_data';

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../auth/domain/user.dart';

part 'verification_request.freezed.dart';
part 'verification_request.g.dart';

/// `VerificationRequest` from docs/API_CONTRACT.md.
@freezed
abstract class VerificationRequest with _$VerificationRequest {
  const factory VerificationRequest({
    required String id,
    required String coaRegistrationNumber,
    required VerificationStatus status,
    String? reviewNote,
    required DateTime submittedAt,
    DateTime? reviewedAt,
  }) = _VerificationRequest;

  factory VerificationRequest.fromJson(Map<String, dynamic> json) =>
      _$VerificationRequestFromJson(json);
}

/// A document picked for upload (PDF/JPG/PNG, at most [maxBytes]).
class VerificationDocument {
  const VerificationDocument({required this.fileName, required this.bytes});

  static const maxBytes = 10 * 1024 * 1024;
  static const allowedExtensions = ['pdf', 'jpg', 'jpeg', 'png'];

  final String fileName;
  final Uint8List bytes;

  String get extension =>
      fileName.contains('.') ? fileName.split('.').last.toLowerCase() : '';

  String get mimeType => switch (extension) {
    'pdf' => 'application/pdf',
    'png' => 'image/png',
    'jpg' || 'jpeg' => 'image/jpeg',
    _ => 'application/octet-stream',
  };

  /// Client-side check mirroring the server limits; null when acceptable.
  String? get problem {
    if (!allowedExtensions.contains(extension)) {
      return 'Choose a PDF, JPG or PNG file.';
    }
    if (bytes.length > maxBytes) return 'The file must be 10 MB or smaller.';
    if (bytes.isEmpty) return 'The file is empty.';
    return null;
  }
}
