// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'drawing_sheet.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DrawingSheet _$DrawingSheetFromJson(Map<String, dynamic> json) =>
    _DrawingSheet(
      id: json['id'] as String,
      type:
          $enumDecodeNullable(_$SheetTypeEnumMap, json['type']) ??
          SheetType.other,
      isPreview: json['isPreview'] as bool? ?? false,
      previewUrl: json['previewUrl'] as String?,
      originalMime: json['originalMime'] as String? ?? '',
      fileName: json['fileName'] as String,
      sizeBytes: (json['sizeBytes'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$DrawingSheetToJson(_DrawingSheet instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$SheetTypeEnumMap[instance.type]!,
      'isPreview': instance.isPreview,
      'previewUrl': instance.previewUrl,
      'originalMime': instance.originalMime,
      'fileName': instance.fileName,
      'sizeBytes': instance.sizeBytes,
    };

const _$SheetTypeEnumMap = {
  SheetType.architectural: 'ARCHITECTURAL',
  SheetType.structural: 'STRUCTURAL',
  SheetType.electrical: 'ELECTRICAL',
  SheetType.sanitary: 'SANITARY',
  SheetType.plumbing: 'PLUMBING',
  SheetType.hvac: 'HVAC',
  SheetType.other: 'OTHER',
};
