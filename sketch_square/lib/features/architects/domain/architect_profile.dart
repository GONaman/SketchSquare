import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/network/cursor_page.dart';
import '../../drawings/domain/drawing_summary.dart';
import 'architect_summary.dart';

part 'architect_profile.freezed.dart';

/// `GET /architects/top` item: `ArchitectSummary & {drawingCount}`.
@Freezed(fromJson: false, toJson: false)
abstract class TopArchitect with _$TopArchitect {
  const factory TopArchitect({
    required ArchitectSummary architect,
    @Default(0) int drawingCount,
  }) = _TopArchitect;

  factory TopArchitect.fromJson(Map<String, dynamic> json) => TopArchitect(
    architect: ArchitectSummary.fromJson(json),
    drawingCount: (json['drawingCount'] as num?)?.toInt() ?? 0,
  );
}

/// `GET /architects/:id` → `{ architect, drawings: page }`.
@Freezed(fromJson: false, toJson: false)
abstract class ArchitectProfile with _$ArchitectProfile {
  const factory ArchitectProfile({
    required ArchitectSummary architect,
    required CursorPage<DrawingSummary> drawings,
  }) = _ArchitectProfile;

  factory ArchitectProfile.fromJson(Map<String, dynamic> json) =>
      ArchitectProfile(
        architect: ArchitectSummary.fromJson(
          json['architect'] as Map<String, dynamic>,
        ),
        drawings: CursorPage.fromJson(
          json['drawings'] as Map<String, dynamic>? ?? const {},
          DrawingSummary.fromJson,
        ),
      );
}
