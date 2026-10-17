import 'package:freezed_annotation/freezed_annotation.dart';

part 'drawing_sheet.freezed.dart';
part 'drawing_sheet.g.dart';

@JsonEnum(alwaysCreate: true)
enum SheetType {
  @JsonValue('ARCHITECTURAL')
  architectural('Architectural'),
  @JsonValue('STRUCTURAL')
  structural('Structural'),
  @JsonValue('ELECTRICAL')
  electrical('Electrical'),
  @JsonValue('SANITARY')
  sanitary('Sanitary'),
  @JsonValue('PLUMBING')
  plumbing('Plumbing'),
  @JsonValue('HVAC')
  hvac('HVAC'),
  @JsonValue('OTHER')
  other('Other');

  const SheetType(this.label);
  final String label;

  String get wire => _$SheetTypeEnumMap[this]!;
}

/// `Sheet` from docs/API_CONTRACT.md. `previewUrl` is only set for preview
/// sheets once processing has finished.
@freezed
abstract class DrawingSheet with _$DrawingSheet {
  const factory DrawingSheet({
    required String id,
    @Default(SheetType.other) SheetType type,
    @Default(false) bool isPreview,
    String? previewUrl,
    @Default('') String originalMime,
    required String fileName,
    @Default(0) int sizeBytes,
  }) = _DrawingSheet;

  factory DrawingSheet.fromJson(Map<String, dynamic> json) =>
      _$DrawingSheetFromJson(json);
}

/// Response of `POST /drawings/:id/sheets/upload-url`.
class SheetUploadTarget {
  const SheetUploadTarget({
    required this.uploadUrl,
    required this.objectKey,
    this.headers = const {},
  });

  final String uploadUrl;
  final String objectKey;

  /// Headers the client must send verbatim with the PUT.
  final Map<String, String> headers;

  factory SheetUploadTarget.fromJson(Map<String, dynamic> json) =>
      SheetUploadTarget(
        uploadUrl: json['uploadUrl'] as String,
        objectKey: json['objectKey'] as String,
        headers: {
          for (final e
              in (json['headers'] as Map<String, dynamic>? ?? const {}).entries)
            e.key: e.value.toString(),
        },
      );
}
