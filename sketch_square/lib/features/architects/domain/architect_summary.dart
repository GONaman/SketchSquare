import 'package:freezed_annotation/freezed_annotation.dart';

part 'architect_summary.freezed.dart';
part 'architect_summary.g.dart';

/// `ArchitectSummary` from docs/API_CONTRACT.md.
@freezed
abstract class ArchitectSummary with _$ArchitectSummary {
  const factory ArchitectSummary({
    required String id,
    required String fullName,
    required String city,
    @Default(0) double architectRating,
    @Default(0) int ratingCount,
    String? avatarUrl,
  }) = _ArchitectSummary;

  factory ArchitectSummary.fromJson(Map<String, dynamic> json) =>
      _$ArchitectSummaryFromJson(json);
}
