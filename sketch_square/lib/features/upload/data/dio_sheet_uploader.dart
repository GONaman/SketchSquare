import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

import '../../../core/network/api_exception.dart';
import '../domain/drawing_sheet.dart';
import '../domain/sheet_file_rules.dart';
import '../domain/upload_repository.dart';

/// Streams the file to the presigned URL with a plain Dio (no API auth header,
/// no error envelope) and reports byte progress.
class DioSheetUploader implements SheetUploader {
  DioSheetUploader([Dio? dio])
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 20),
              // Large files on slow links: only guard against stalled sends.
              sendTimeout: const Duration(minutes: 10),
              receiveTimeout: const Duration(seconds: 60),
            ),
          );

  final Dio _dio;

  @override
  Future<void> upload(
    SheetUploadTarget target,
    PickedSheetFile file, {
    required void Function(int sent, int total) onProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      await _dio.put<void>(
        target.uploadUrl,
        data: file.openRead(),
        cancelToken: cancelToken,
        onSendProgress: onProgress,
        options: Options(
          headers: {
            ...target.headers,
            Headers.contentLengthHeader: file.sizeBytes,
          },
          contentType:
              target.headers['Content-Type'] ??
              target.headers['content-type'] ??
              SheetFileRules.contentTypeFor(file.name),
        ),
      );
    } catch (e) {
      throw toApiException(e);
    }
  }
}

class FilePickerSheetPicker implements SheetPicker {
  const FilePickerSheetPicker();

  @override
  Future<List<PickedSheetFile>> pickSheets() async {
    final result = await FilePicker.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: SheetFileRules.allowedExtensions,
      withData: false,
      withReadStream: false,
    );
    if (result == null) return const [];
    return [
      for (final f in result.files)
        PickedSheetFile(
          name: f.name,
          sizeBytes: f.size,
          openRead: () => f.xFile.openRead(),
        ),
    ];
  }
}
