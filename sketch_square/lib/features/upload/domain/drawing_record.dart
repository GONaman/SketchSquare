import 'package:freezed_annotation/freezed_annotation.dart';

import '../../drawings/domain/drawing_summary.dart';
import 'drawing_form.dart';
import 'sheet_upload_target.dart';

part 'drawing_record.freezed.dart';
part 'drawing_record.g.dart';

/// Seller-side view of `DrawingDetail` (docs/API_CONTRACT.md). Parsing is
/// deliberately lenient: only the fields the upload/manage flows rely on are
/// required, the rest default.
@freezed
abstract class DrawingRecord with _$DrawingRecord {
  const DrawingRecord._();

  const factory DrawingRecord({
    required String id,
    required String title,
    @Default('') String description,
    CategoryRef? category,
    @Default('') String city,
    @Default(0) double plotLengthFt,
    @Default(0) double plotBreadthFt,
    @Default(0) double plotAreaSqft,
    @Default(1) int floors,
    int? bedrooms,
    String? facing,
    @Default(<String>[]) List<String> tags,
    @Default(0) int pricePaise,
    @Default(false) bool isFree,
    required DrawingStatus status,
    String? failureReason,
    @Default(<Sheet>[]) List<Sheet> sheets,
    String? previewUrl,
    @Default(0) int viewCount,
    @Default(0) int purchaseCount,
  }) = _DrawingRecord;

  factory DrawingRecord.fromJson(Map<String, dynamic> json) =>
      _$DrawingRecordFromJson(json);

  bool get isDraft => status == DrawingStatus.draft;

  /// Rebuilds the editable form from a persisted draft (feet are shown back as feet).
  DrawingForm toForm() => DrawingForm(
    title: title,
    description: description,
    categoryId: category?.id,
    city: city,
    plotLength: plotLengthFt == 0 ? null : plotLengthFt,
    plotBreadth: plotBreadthFt == 0 ? null : plotBreadthFt,
    unit: PlotUnit.ft,
    floors: floors,
    bedrooms: bedrooms,
    facing: facing,
    tags: tags,
    isFree: isFree,
    pricePaise: pricePaise,
  );
}
