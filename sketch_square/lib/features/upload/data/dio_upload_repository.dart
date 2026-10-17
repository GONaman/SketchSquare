import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../drawings/domain/drawing_summary.dart';
import '../domain/drawing_form.dart';
import '../domain/drawing_record.dart';
import '../domain/sheet_upload_target.dart';
import '../domain/upload_repository.dart';

/// `bedrooms` / `tags` are sent by default (the backend accepts them, see
/// docs/API_CONTRACT.md and DECISIONS U1). Build with
/// `--dart-define=UPLOAD_SEND_EXTENDED_METADATA=false` against an older backend.
abstract final class UploadConfig {
  static const sendExtendedMetadata = bool.fromEnvironment(
    'UPLOAD_SEND_EXTENDED_METADATA',
    defaultValue: true,
  );
}

class DioUploadRepository implements UploadRepository {
  DioUploadRepository(this._dio, {this.sendExtendedMetadata = true});

  final Dio _dio;
  final bool sendExtendedMetadata;

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } catch (e) {
      throw toApiException(e);
    }
  }

  Map<String, dynamic> _body(DrawingForm form) =>
      form.toRequestJson(includeExtended: sendExtendedMetadata);

  @override
  Future<List<CategoryRef>> fetchCategories() => _guard(() async {
    final res = await _dio.get<List<dynamic>>('/categories');
    return [
      for (final c in res.data ?? const [])
        CategoryRef.fromJson(c as Map<String, dynamic>),
    ];
  });

  @override
  Future<DrawingRecord> createDraft(DrawingForm form) => _guard(() async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/drawings',
      data: _body(form),
    );
    return DrawingRecord.fromJson(res.data!);
  });

  @override
  Future<DrawingRecord> updateDraft(String id, DrawingForm form) =>
      _guard(() async {
        final res = await _dio.patch<Map<String, dynamic>>(
          '/drawings/$id',
          data: _body(form),
        );
        return DrawingRecord.fromJson(res.data!);
      });

  @override
  Future<DrawingRecord> getDrawing(String id) => _guard(() async {
    final res = await _dio.get<Map<String, dynamic>>('/drawings/$id');
    return DrawingRecord.fromJson(res.data!);
  });

  @override
  Future<SheetUploadTarget> requestSheetUpload(
    String drawingId, {
    required String fileName,
    required String contentType,
    required int sizeBytes,
  }) => _guard(() async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/drawings/$drawingId/sheets/upload-url',
      data: {
        'fileName': fileName,
        'contentType': contentType,
        'sizeBytes': sizeBytes,
      },
    );
    return SheetUploadTarget.fromJson(res.data!);
  });

  @override
  Future<Sheet> registerSheet(
    String drawingId, {
    required SheetType type,
    required String objectKey,
    required bool isPreview,
    required String fileName,
    required int sizeBytes,
  }) => _guard(() async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/drawings/$drawingId/sheets',
      data: {
        'type': type.wire,
        'objectKey': objectKey,
        'isPreview': isPreview,
        'fileName': fileName,
        'sizeBytes': sizeBytes,
      },
    );
    return Sheet.fromJson(res.data!);
  });

  @override
  Future<Sheet> updateSheet(
    String drawingId,
    String sheetId, {
    SheetType? type,
    bool? isPreview,
  }) => _guard(() async {
    final res = await _dio.patch<Map<String, dynamic>>(
      '/drawings/$drawingId/sheets/$sheetId',
      data: {
        if (type != null) 'type': type.wire,
        if (isPreview != null) 'isPreview': isPreview,
      },
    );
    return Sheet.fromJson(res.data!);
  });

  @override
  Future<void> deleteSheet(String drawingId, String sheetId) =>
      _guard(() => _dio.delete<void>('/drawings/$drawingId/sheets/$sheetId'));

  @override
  Future<DrawingStatus> publish(String drawingId) => _guard(() async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/drawings/$drawingId/publish',
    );
    return _statusMap[res.data?['status']] ?? DrawingStatus.processing;
  });
}

const _statusMap = {
  'DRAFT': DrawingStatus.draft,
  'PROCESSING': DrawingStatus.processing,
  'PUBLISHED': DrawingStatus.published,
  'UNDER_REVIEW': DrawingStatus.underReview,
  'REMOVED': DrawingStatus.removed,
  'FAILED': DrawingStatus.failed,
};
