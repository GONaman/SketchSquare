// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'city_count.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CityCount _$CityCountFromJson(Map<String, dynamic> json) => _CityCount(
  city: json['city'] as String,
  count: (json['count'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$CityCountToJson(_CityCount instance) =>
    <String, dynamic>{'city': instance.city, 'count': instance.count};
