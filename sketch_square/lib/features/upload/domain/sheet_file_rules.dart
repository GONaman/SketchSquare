/// Client-side mirror of the contract limits for sheet files
/// (`POST /drawings/:id/sheets/upload-url`: ≤50MB; PDF/PNG/JPG/DWG/DXF).
abstract final class SheetFileRules {
  static const maxBytes = 50 * 1024 * 1024;
  static const maxPreviewSheets = 2;
  static const allowedExtensions = ['pdf', 'png', 'jpg', 'jpeg', 'dwg', 'dxf'];

  static String extensionOf(String fileName) {
    final dot = fileName.lastIndexOf('.');
    return dot < 0 ? '' : fileName.substring(dot + 1).toLowerCase();
  }

  static String? contentTypeFor(String fileName) => switch (extensionOf(
    fileName,
  )) {
    'pdf' => 'application/pdf',
    'png' => 'image/png',
    'jpg' || 'jpeg' => 'image/jpeg',
    'dwg' => 'application/acad',
    'dxf' => 'application/dxf',
    _ => null,
  };

  /// CAD sources are stored as-is: no preview or watermark is generated.
  static bool isCad(String fileName) {
    final ext = extensionOf(fileName);
    return ext == 'dwg' || ext == 'dxf';
  }

  static bool canBePreview(String fileName) => !isCad(fileName);

  /// Returns a user-facing error, or null if the file is acceptable.
  static String? validate(String fileName, int sizeBytes) {
    if (contentTypeFor(fileName) == null) {
      return 'Unsupported file type. Use PDF, PNG, JPG, DWG or DXF.';
    }
    if (sizeBytes <= 0) return 'This file is empty.';
    if (sizeBytes > maxBytes) return 'File is larger than 50 MB.';
    return null;
  }
}
