import '../../drawings/domain/sheet.dart';

export '../../drawings/domain/sheet.dart';

extension SheetTypeX on SheetType {
  String get label => switch (this) {
    SheetType.hvac => 'HVAC',
    _ => name[0].toUpperCase() + name.substring(1),
  };

  /// Contract value, e.g. `ARCHITECTURAL`.
  String get wire => name.toUpperCase();
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
