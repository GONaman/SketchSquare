// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'drawing_form.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DrawingForm _$DrawingFormFromJson(Map<String, dynamic> json) => _DrawingForm(
  title: json['title'] as String? ?? '',
  description: json['description'] as String? ?? '',
  categoryId: json['categoryId'] as String?,
  city: json['city'] as String? ?? '',
  plotLength: (json['plotLength'] as num?)?.toDouble(),
  plotBreadth: (json['plotBreadth'] as num?)?.toDouble(),
  unit: $enumDecodeNullable(_$PlotUnitEnumMap, json['unit']) ?? PlotUnit.ft,
  floors: (json['floors'] as num?)?.toInt(),
  bedrooms: (json['bedrooms'] as num?)?.toInt(),
  facing: json['facing'] as String?,
  tags:
      (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  isFree: json['isFree'] as bool? ?? false,
  pricePaise: (json['pricePaise'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$DrawingFormToJson(_DrawingForm instance) =>
    <String, dynamic>{
      'title': instance.title,
      'description': instance.description,
      'categoryId': instance.categoryId,
      'city': instance.city,
      'plotLength': instance.plotLength,
      'plotBreadth': instance.plotBreadth,
      'unit': _$PlotUnitEnumMap[instance.unit]!,
      'floors': instance.floors,
      'bedrooms': instance.bedrooms,
      'facing': instance.facing,
      'tags': instance.tags,
      'isFree': instance.isFree,
      'pricePaise': instance.pricePaise,
    };

const _$PlotUnitEnumMap = {PlotUnit.ft: 'ft', PlotUnit.m: 'm'};
