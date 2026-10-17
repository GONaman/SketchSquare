import 'package:freezed_annotation/freezed_annotation.dart';

part 'sheet.freezed.dart';
part 'sheet.g.dart';

@JsonEnum(alwaysCreate: true)
enum SheetType {
  @JsonValue('ARCHITECTURAL')
  architectural,
  @JsonValue('STRUCTURAL')
  structural,
  @JsonValue('ELECTRICAL')
  electrical,
  @JsonValue('SANITARY')
  sanitary,
  @JsonValue('PLUMBING')
  plumbing,
  @JsonValue('HVAC')
  hvac,
  @JsonValue('OTHER')
  other,
}

/// `Sheet` from docs/API_CONTRACT.md. Never carries original keys/urls;
/// `previewUrl` is only set for preview sheets.
@freezed
abstract class Sheet with _$Sheet {
  const factory Sheet({
    required String id,
    required SheetType type,
    @Default(false) bool isPreview,
    String? previewUrl,
    required String originalMime,
    required String fileName,
    required int sizeBytes,
  }) = _Sheet;

  factory Sheet.fromJson(Map<String, dynamic> json) => _$SheetFromJson(json);
}
