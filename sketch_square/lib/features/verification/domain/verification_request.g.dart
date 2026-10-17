// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'verification_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_VerificationRequest _$VerificationRequestFromJson(Map<String, dynamic> json) =>
    _VerificationRequest(
      id: json['id'] as String,
      coaRegistrationNumber: json['coaRegistrationNumber'] as String,
      status: $enumDecode(_$VerificationStatusEnumMap, json['status']),
      reviewNote: json['reviewNote'] as String?,
      submittedAt: DateTime.parse(json['submittedAt'] as String),
      reviewedAt:
          json['reviewedAt'] == null
              ? null
              : DateTime.parse(json['reviewedAt'] as String),
    );

Map<String, dynamic> _$VerificationRequestToJson(
  _VerificationRequest instance,
) => <String, dynamic>{
  'id': instance.id,
  'coaRegistrationNumber': instance.coaRegistrationNumber,
  'status': _$VerificationStatusEnumMap[instance.status]!,
  'reviewNote': instance.reviewNote,
  'submittedAt': instance.submittedAt.toIso8601String(),
  'reviewedAt': instance.reviewedAt?.toIso8601String(),
};

const _$VerificationStatusEnumMap = {
  VerificationStatus.pending: 'PENDING',
  VerificationStatus.approved: 'APPROVED',
  VerificationStatus.rejected: 'REJECTED',
};
