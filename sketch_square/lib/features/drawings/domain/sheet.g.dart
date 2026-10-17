// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sheet.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Sheet _$SheetFromJson(Map<String, dynamic> json) => _Sheet(
  id: json['id'] as String,
  type: $enumDecode(_$SheetTypeEnumMap, json['type']),
  isPreview: json['isPreview'] as bool? ?? false,
  previewUrl: json['previewUrl'] as String?,
  originalMime: json['originalMime'] as String,
  fileName: json['fileName'] as String,
  sizeBytes: (json['sizeBytes'] as num).toInt(),
);

Map<String, dynamic> _$SheetToJson(_Sheet instance) => <String, dynamic>{
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
