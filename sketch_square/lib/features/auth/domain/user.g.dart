// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_User _$UserFromJson(Map<String, dynamic> json) => _User(
  id: json['id'] as String,
  email: json['email'] as String,
  fullName: json['fullName'] as String,
  address: json['address'] as String,
  phone: json['phone'] as String,
  avatarUrl: json['avatarUrl'] as String?,
  city: json['city'] as String,
  role: $enumDecode(_$UserRoleEnumMap, json['role']),
  verificationStatus: $enumDecode(
    _$VerificationStatusEnumMap,
    json['verificationStatus'],
  ),
  architectRating: (json['architectRating'] as num?)?.toDouble() ?? 0,
  freeDownloadsUsed: (json['freeDownloadsUsed'] as num?)?.toInt() ?? 0,
  freeDownloadLimit: (json['freeDownloadLimit'] as num?)?.toInt() ?? 20,
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$UserToJson(_User instance) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  'fullName': instance.fullName,
  'address': instance.address,
  'phone': instance.phone,
  'avatarUrl': instance.avatarUrl,
  'city': instance.city,
  'role': _$UserRoleEnumMap[instance.role]!,
  'verificationStatus':
      _$VerificationStatusEnumMap[instance.verificationStatus]!,
  'architectRating': instance.architectRating,
  'freeDownloadsUsed': instance.freeDownloadsUsed,
  'freeDownloadLimit': instance.freeDownloadLimit,
  'createdAt': instance.createdAt.toIso8601String(),
};

const _$UserRoleEnumMap = {
  UserRole.architect: 'ARCHITECT',
  UserRole.admin: 'ADMIN',
};

const _$VerificationStatusEnumMap = {
  VerificationStatus.pending: 'PENDING',
  VerificationStatus.approved: 'APPROVED',
  VerificationStatus.rejected: 'REJECTED',
};

_Tokens _$TokensFromJson(Map<String, dynamic> json) => _Tokens(
  accessToken: json['accessToken'] as String,
  refreshToken: json['refreshToken'] as String,
  expiresIn: (json['expiresIn'] as num?)?.toInt() ?? 900,
);

Map<String, dynamic> _$TokensToJson(_Tokens instance) => <String, dynamic>{
  'accessToken': instance.accessToken,
  'refreshToken': instance.refreshToken,
  'expiresIn': instance.expiresIn,
};
