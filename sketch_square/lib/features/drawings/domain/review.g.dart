// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ReviewerRef _$ReviewerRefFromJson(Map<String, dynamic> json) => _ReviewerRef(
  id: json['id'] as String,
  fullName: json['fullName'] as String,
);

Map<String, dynamic> _$ReviewerRefToJson(_ReviewerRef instance) =>
    <String, dynamic>{'id': instance.id, 'fullName': instance.fullName};

_Review _$ReviewFromJson(Map<String, dynamic> json) => _Review(
  id: json['id'] as String,
  rating: (json['rating'] as num).toInt(),
  comment: json['comment'] as String?,
  reviewer: ReviewerRef.fromJson(json['reviewer'] as Map<String, dynamic>),
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$ReviewToJson(_Review instance) => <String, dynamic>{
  'id': instance.id,
  'rating': instance.rating,
  'comment': instance.comment,
  'reviewer': instance.reviewer,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
};
