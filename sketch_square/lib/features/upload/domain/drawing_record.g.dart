// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'drawing_record.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DrawingRecord _$DrawingRecordFromJson(Map<String, dynamic> json) =>
    _DrawingRecord(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      category:
          json['category'] == null
              ? null
              : CategoryRef.fromJson(json['category'] as Map<String, dynamic>),
      city: json['city'] as String? ?? '',
      plotLengthFt: (json['plotLengthFt'] as num?)?.toDouble() ?? 0,
      plotBreadthFt: (json['plotBreadthFt'] as num?)?.toDouble() ?? 0,
      plotAreaSqft: (json['plotAreaSqft'] as num?)?.toDouble() ?? 0,
      floors: (json['floors'] as num?)?.toInt() ?? 1,
      bedrooms: (json['bedrooms'] as num?)?.toInt(),
      facing: json['facing'] as String?,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          const <String>[],
      pricePaise: (json['pricePaise'] as num?)?.toInt() ?? 0,
      isFree: json['isFree'] as bool? ?? false,
      status: $enumDecode(_$DrawingStatusEnumMap, json['status']),
      failureReason: json['failureReason'] as String?,
      sheets:
          (json['sheets'] as List<dynamic>?)
              ?.map((e) => DrawingSheet.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <DrawingSheet>[],
      previewUrl: json['previewUrl'] as String?,
      viewCount: (json['viewCount'] as num?)?.toInt() ?? 0,
      purchaseCount: (json['purchaseCount'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$DrawingRecordToJson(_DrawingRecord instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'category': instance.category,
      'city': instance.city,
      'plotLengthFt': instance.plotLengthFt,
      'plotBreadthFt': instance.plotBreadthFt,
      'plotAreaSqft': instance.plotAreaSqft,
      'floors': instance.floors,
      'bedrooms': instance.bedrooms,
      'facing': instance.facing,
      'tags': instance.tags,
      'pricePaise': instance.pricePaise,
      'isFree': instance.isFree,
      'status': _$DrawingStatusEnumMap[instance.status]!,
      'failureReason': instance.failureReason,
      'sheets': instance.sheets,
      'previewUrl': instance.previewUrl,
      'viewCount': instance.viewCount,
      'purchaseCount': instance.purchaseCount,
    };

const _$DrawingStatusEnumMap = {
  DrawingStatus.draft: 'DRAFT',
  DrawingStatus.processing: 'PROCESSING',
  DrawingStatus.published: 'PUBLISHED',
  DrawingStatus.underReview: 'UNDER_REVIEW',
  DrawingStatus.removed: 'REMOVED',
  DrawingStatus.failed: 'FAILED',
};
