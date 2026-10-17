import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

import '../../../core/network/api_exception.dart';
import '../domain/verification_repository.dart';
import '../domain/verification_request.dart';

class DioVerificationRepository implements VerificationRepository {
  DioVerificationRepository(this._dio);

  final Dio _dio;

  @override
  Future<VerificationRequest> submit({
    required String coaRegistrationNumber,
    required VerificationDocument document,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/verification',
        data: FormData.fromMap({
          'coaRegistrationNumber': coaRegistrationNumber,
          'document': MultipartFile.fromBytes(
            document.bytes,
            filename: document.fileName,
            contentType: DioMediaType.parse(document.mimeType),
          ),
        }),
      );
      return VerificationRequest.fromJson(res.data!);
    } catch (e) {
      throw toApiException(e);
    }
  }

  @override
  Future<VerificationRequest?> mine() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/verification/me');
      final json = res.data?['verification'];
      return json == null
          ? null
          : VerificationRequest.fromJson(json as Map<String, dynamic>);
    } catch (e) {
      throw toApiException(e);
    }
  }
}

class FilePickerDocumentPicker implements DocumentPicker {
  const FilePickerDocumentPicker();

  @override
  Future<VerificationDocument?> pick() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: VerificationDocument.allowedExtensions,
      withData: true,
    );
    final file = result?.files.singleOrNull;
    final bytes = file?.bytes;
    if (file == null || bytes == null) return null;
    return VerificationDocument(fileName: file.name, bytes: bytes);
  }
}
