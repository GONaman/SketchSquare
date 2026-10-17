import 'package:freezed_annotation/freezed_annotation.dart';

import '../../architects/domain/architect_summary.dart';

part 'drawing_summary.freezed.dart';
part 'drawing_summary.g.dart';

@JsonEnum(alwaysCreate: true)
enum DrawingStatus {
  @JsonValue('DRAFT')
  draft,
  @JsonValue('PROCESSING')
  processing,
  @JsonValue('PUBLISHED')
  published,
  @JsonValue('UNDER_REVIEW')
  underReview,
  @JsonValue('REMOVED')
  removed,
  @JsonValue('FAILED')
  failed,
}

@freezed
abstract class CategoryRef with _$CategoryRef {
  const factory CategoryRef({
    required String id,
    required String name,
    required String slug,
  }) = _CategoryRef;

  factory CategoryRef.fromJson(Map<String, dynamic> json) =>
      _$CategoryRefFromJson(json);
}

/// `DrawingSummary` (list tile) from docs/API_CONTRACT.md.
/// Money is integer paise; lengths are feet.
@freezed
abstract class DrawingSummary with _$DrawingSummary {
  const factory DrawingSummary({
    required String id,
    required String title,
    required CategoryRef category,
    required String city,
    required double plotLengthFt,
    required double plotBreadthFt,
    required double plotAreaSqft,
    required int floors,
    String? facing,
    required int pricePaise,
    required bool isFree,
    @Default(0) double avgRating,
    @Default(0) int ratingCount,
    String? previewUrl,
    required ArchitectSummary architect,
    required DrawingStatus status,
    required DateTime createdAt,
    // 0..1, only present for plot-size searches (1 = exact).
    double? sizeMatch,
  }) = _DrawingSummary;

  factory DrawingSummary.fromJson(Map<String, dynamic> json) =>
      _$DrawingSummaryFromJson(json);
}
