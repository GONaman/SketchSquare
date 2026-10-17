// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_verification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AdminApplicant _$AdminApplicantFromJson(Map<String, dynamic> json) =>
    _AdminApplicant(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      city: json['city'] as String?,
      address: json['address'] as String?,
    );

Map<String, dynamic> _$AdminApplicantToJson(_AdminApplicant instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fullName': instance.fullName,
      'email': instance.email,
      'phone': instance.phone,
      'city': instance.city,
      'address': instance.address,
    };

_AdminVerification _$AdminVerificationFromJson(Map<String, dynamic> json) =>
    _AdminVerification(
      id: json['id'] as String,
      status: $enumDecode(_$VerificationStatusEnumMap, json['status']),
      coaRegistrationNumber: json['coaRegistrationNumber'] as String,
      submittedAt: DateTime.parse(json['submittedAt'] as String),
      user: AdminApplicant.fromJson(json['user'] as Map<String, dynamic>),
      documentUrl: json['documentUrl'] as String?,
      reviewNote: json['reviewNote'] as String?,
    );

Map<String, dynamic> _$AdminVerificationToJson(_AdminVerification instance) =>
    <String, dynamic>{
      'id': instance.id,
      'status': _$VerificationStatusEnumMap[instance.status]!,
      'coaRegistrationNumber': instance.coaRegistrationNumber,
      'submittedAt': instance.submittedAt.toIso8601String(),
      'user': instance.user,
      'documentUrl': instance.documentUrl,
      'reviewNote': instance.reviewNote,
    };

const _$VerificationStatusEnumMap = {
  VerificationStatus.pending: 'PENDING',
  VerificationStatus.approved: 'APPROVED',
  VerificationStatus.rejected: 'REJECTED',
};
