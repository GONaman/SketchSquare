// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'drawing_detail.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DrawingViewer _$DrawingViewerFromJson(Map<String, dynamic> json) =>
    _DrawingViewer(
      isOwner: json['isOwner'] as bool? ?? false,
      isPurchased: json['isPurchased'] as bool? ?? false,
      inCart: json['inCart'] as bool? ?? false,
      canDownload: json['canDownload'] as bool? ?? false,
      freeDownloadsRemaining: (json['freeDownloadsRemaining'] as num?)?.toInt(),
      myReview:
          json['myReview'] == null
              ? null
              : Review.fromJson(json['myReview'] as Map<String, dynamic>),
      isFavorite: json['isFavorite'] as bool? ?? false,
      isInterested: json['isInterested'] as bool? ?? false,
    );

Map<String, dynamic> _$DrawingViewerToJson(_DrawingViewer instance) =>
    <String, dynamic>{
      'isOwner': instance.isOwner,
      'isPurchased': instance.isPurchased,
      'inCart': instance.inCart,
      'canDownload': instance.canDownload,
      'freeDownloadsRemaining': instance.freeDownloadsRemaining,
      'myReview': instance.myReview,
      'isFavorite': instance.isFavorite,
      'isInterested': instance.isInterested,
    };
