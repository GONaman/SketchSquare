// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'drawing_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CategoryRef _$CategoryRefFromJson(Map<String, dynamic> json) => _CategoryRef(
  id: json['id'] as String,
  name: json['name'] as String,
  slug: json['slug'] as String,
);

Map<String, dynamic> _$CategoryRefToJson(_CategoryRef instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'slug': instance.slug,
    };

_DrawingSummary _$DrawingSummaryFromJson(Map<String, dynamic> json) =>
    _DrawingSummary(
      id: json['id'] as String,
      title: json['title'] as String,
      category: CategoryRef.fromJson(json['category'] as Map<String, dynamic>),
      city: json['city'] as String,
      plotLengthFt: (json['plotLengthFt'] as num).toDouble(),
      plotBreadthFt: (json['plotBreadthFt'] as num).toDouble(),
      plotAreaSqft: (json['plotAreaSqft'] as num).toDouble(),
      floors: (json['floors'] as num).toInt(),
      facing: json['facing'] as String?,
      pricePaise: (json['pricePaise'] as num).toInt(),
      isFree: json['isFree'] as bool,
      avgRating: (json['avgRating'] as num?)?.toDouble() ?? 0,
      ratingCount: (json['ratingCount'] as num?)?.toInt() ?? 0,
      previewUrl: json['previewUrl'] as String?,
      architect: ArchitectSummary.fromJson(
        json['architect'] as Map<String, dynamic>,
      ),
      status: $enumDecode(_$DrawingStatusEnumMap, json['status']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      sizeMatch: (json['sizeMatch'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$DrawingSummaryToJson(_DrawingSummary instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'category': instance.category,
      'city': instance.city,
      'plotLengthFt': instance.plotLengthFt,
      'plotBreadthFt': instance.plotBreadthFt,
      'plotAreaSqft': instance.plotAreaSqft,
      'floors': instance.floors,
      'facing': instance.facing,
      'pricePaise': instance.pricePaise,
      'isFree': instance.isFree,
      'avgRating': instance.avgRating,
      'ratingCount': instance.ratingCount,
      'previewUrl': instance.previewUrl,
      'architect': instance.architect,
      'status': _$DrawingStatusEnumMap[instance.status]!,
      'createdAt': instance.createdAt.toIso8601String(),
      'sizeMatch': instance.sizeMatch,
    };

const _$DrawingStatusEnumMap = {
  DrawingStatus.draft: 'DRAFT',
  DrawingStatus.processing: 'PROCESSING',
  DrawingStatus.published: 'PUBLISHED',
  DrawingStatus.underReview: 'UNDER_REVIEW',
  DrawingStatus.removed: 'REMOVED',
  DrawingStatus.failed: 'FAILED',
};
