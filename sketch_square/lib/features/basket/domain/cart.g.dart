// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cart.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Cart _$CartFromJson(Map<String, dynamic> json) => _Cart(
  items:
      (json['items'] as List<dynamic>?)
          ?.map((e) => DrawingSummary.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  totalPaise: (json['totalPaise'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$CartToJson(_Cart instance) => <String, dynamic>{
  'items': instance.items,
  'totalPaise': instance.totalPaise,
};
