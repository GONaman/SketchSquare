import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/network/cursor_page.dart';
import 'drawing_summary.dart';
import 'review.dart';
import 'sheet.dart';

part 'drawing_detail.freezed.dart';
part 'drawing_detail.g.dart';

/// `DrawingDetail.viewer`: what the current user may do with the drawing.
/// `isFavorite` / `isInterested` only exist from Phase 8, so they default to false.
@freezed
abstract class DrawingViewer with _$DrawingViewer {
  const factory DrawingViewer({
    @Default(false) bool isOwner,
    @Default(false) bool isPurchased,
    @Default(false) bool inCart,
    @Default(false) bool canDownload,
    int? freeDownloadsRemaining,
    Review? myReview,
    @Default(false) bool isFavorite,
    @Default(false) bool isInterested,
  }) = _DrawingViewer;

  factory DrawingViewer.fromJson(Map<String, dynamic> json) =>
      _$DrawingViewerFromJson(json);
}

/// `DrawingDetail = DrawingSummary & {...}` from docs/API_CONTRACT.md.
/// The summary part is kept as a nested [summary] so tiles and detail share it.
@Freezed(fromJson: false, toJson: false)
abstract class DrawingDetail with _$DrawingDetail {
  const DrawingDetail._();

  const factory DrawingDetail({
    required DrawingSummary summary,
    @Default('') String description,
    @Default(0) int viewCount,
    @Default(0) int purchaseCount,
    String? failureReason,
    @Default(<Sheet>[]) List<Sheet> sheets,
    @Default(CursorPage<Review>(items: [])) CursorPage<Review> reviews,
    @Default(DrawingViewer()) DrawingViewer viewer,
  }) = _DrawingDetail;

  factory DrawingDetail.fromJson(Map<String, dynamic> json) {
    final sheets = json['sheets'] as List<dynamic>? ?? const [];
    final reviews = json['reviews'] as Map<String, dynamic>?;
    final viewer = json['viewer'] as Map<String, dynamic>?;
    return DrawingDetail(
      summary: DrawingSummary.fromJson(json),
      description: json['description'] as String? ?? '',
      viewCount: (json['viewCount'] as num?)?.toInt() ?? 0,
      purchaseCount: (json['purchaseCount'] as num?)?.toInt() ?? 0,
      failureReason: json['failureReason'] as String?,
      sheets: sheets
          .map((e) => Sheet.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      reviews:
          reviews == null
              ? const CursorPage<Review>(items: [])
              : CursorPage.fromJson(reviews, Review.fromJson),
      viewer:
          viewer == null
              ? const DrawingViewer()
              : DrawingViewer.fromJson(viewer),
    );
  }

  /// Watermarked preview images, in sheet order. Falls back to the tile image.
  List<String> get previewUrls {
    final urls = [
      for (final s in sheets)
        if (s.isPreview && s.previewUrl != null) s.previewUrl!,
    ];
    final tile = summary.previewUrl;
    return urls.isEmpty && tile != null ? [tile] : urls;
  }
}
