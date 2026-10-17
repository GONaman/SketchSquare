// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'architect_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ArchitectSummary _$ArchitectSummaryFromJson(Map<String, dynamic> json) =>
    _ArchitectSummary(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      city: json['city'] as String,
      architectRating: (json['architectRating'] as num?)?.toDouble() ?? 0,
      ratingCount: (json['ratingCount'] as num?)?.toInt() ?? 0,
      avatarUrl: json['avatarUrl'] as String?,
    );

Map<String, dynamic> _$ArchitectSummaryToJson(_ArchitectSummary instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fullName': instance.fullName,
      'city': instance.city,
      'architectRating': instance.architectRating,
      'ratingCount': instance.ratingCount,
      'avatarUrl': instance.avatarUrl,
    };
