import 'package:freezed_annotation/freezed_annotation.dart';

import '../../auth/domain/user.dart' show VerificationStatus;

part 'admin_verification.freezed.dart';
part 'admin_verification.g.dart';

/// Applicant summary embedded in an admin verification item.
@freezed
abstract class AdminApplicant with _$AdminApplicant {
  const factory AdminApplicant({
    required String id,
    required String fullName,
    required String email,
    String? phone,
    String? city,
    String? address,
  }) = _AdminApplicant;

  factory AdminApplicant.fromJson(Map<String, dynamic> json) =>
      _$AdminApplicantFromJson(json);
}

/// Item of `GET /admin/verifications`; `documentUrl` (presigned, 5 min) and
/// `reviewNote` are only present on `GET /admin/verifications/:id`.
@freezed
abstract class AdminVerification with _$AdminVerification {
  const factory AdminVerification({
    required String id,
    required VerificationStatus status,
    required String coaRegistrationNumber,
    required DateTime submittedAt,
    required AdminApplicant user,
    String? documentUrl,
    String? reviewNote,
  }) = _AdminVerification;

  factory AdminVerification.fromJson(Map<String, dynamic> json) =>
      _$AdminVerificationFromJson(json);
}
