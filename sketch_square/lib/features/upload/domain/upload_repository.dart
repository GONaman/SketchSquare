import 'package:dio/dio.dart';

import '../../drawings/domain/drawing_summary.dart';
import 'drawing_form.dart';
import 'drawing_record.dart';
import 'sheet_upload_target.dart';

/// A file the user picked, independent of the picker plugin so tests can fake it.
class PickedSheetFile {
  const PickedSheetFile({
    required this.name,
    required this.sizeBytes,
    required this.openRead,
  });

  final String name;
  final int sizeBytes;
  final Stream<List<int>> Function() openRead;
}

abstract interface class SheetPicker {
  /// Returns the picked files, or an empty list if the user cancelled.
  Future<List<PickedSheetFile>> pickSheets();
}

/// Seller-side drawing endpoints used by the upload flow
/// (docs/API_CONTRACT.md → "Drawings — seller side").
abstract interface class UploadRepository {
  Future<List<CategoryRef>> fetchCategories();

  Future<DrawingRecord> createDraft(DrawingForm form);

  /// `PATCH /drawings/:id` with every form field (valid for drafts).
  Future<DrawingRecord> updateDraft(String id, DrawingForm form);

  Future<DrawingRecord> getDrawing(String id);

  Future<SheetUploadTarget> requestSheetUpload(
    String drawingId, {
    required String fileName,
    required String contentType,
    required int sizeBytes,
  });

  Future<Sheet> registerSheet(
    String drawingId, {
    required SheetType type,
    required String objectKey,
    required bool isPreview,
    required String fileName,
    required int sizeBytes,
  });

  Future<Sheet> updateSheet(
    String drawingId,
    String sheetId, {
    SheetType? type,
    bool? isPreview,
  });

  Future<void> deleteSheet(String drawingId, String sheetId);

  /// `POST /drawings/:id/publish` → 202 `{status: "PROCESSING"}`.
  Future<DrawingStatus> publish(String drawingId);
}

/// PUTs a file to a presigned URL (storage, not the API: no auth header).
abstract interface class SheetUploader {
  Future<void> upload(
    SheetUploadTarget target,
    PickedSheetFile file, {
    required void Function(int sent, int total) onProgress,
    CancelToken? cancelToken,
  });
}
