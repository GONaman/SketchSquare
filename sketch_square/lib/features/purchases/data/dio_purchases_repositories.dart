import 'dart:io';

import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/cursor_page.dart';
import '../../drawings/domain/review.dart';
import '../domain/purchase_models.dart';
import '../domain/purchases_repositories.dart';

class DioPurchasesRepository implements PurchasesRepository {
  DioPurchasesRepository(this._dio);
  final Dio _dio;

  @override
  Future<CursorPage<PurchaseItem>> list({String? cursor, int? limit}) async {
    try {
      final res = await _dio.get<Object?>(
        '/me/purchases',
        queryParameters: {
          if (cursor != null) 'cursor': cursor,
          if (limit != null) 'limit': limit,
        },
      );
      return CursorPage.fromJson(
        res.data! as Map<String, dynamic>,
        PurchaseItem.fromJson,
      );
    } catch (e) {
      throw toApiException(e);
    }
  }

  @override
  Future<DownloadLink> downloadLink(String drawingId, String sheetId) async {
    try {
      final res = await _dio.get<Object?>(
        '/drawings/$drawingId/download',
        queryParameters: {'sheetId': sheetId},
      );
      return DownloadLink.fromJson(res.data! as Map<String, dynamic>);
    } catch (e) {
      throw toApiException(e);
    }
  }
}

class DioReviewRepository implements ReviewRepository {
  DioReviewRepository(this._dio);
  final Dio _dio;

  @override
  Future<Review> submit(
    String drawingId, {
    required int rating,
    String? comment,
  }) async {
    try {
      final trimmed = comment?.trim();
      final res = await _dio.put<Object?>(
        '/drawings/$drawingId/review',
        data: {
          'rating': rating,
          if (trimmed != null && trimmed.isNotEmpty) 'comment': trimmed,
        },
      );
      return Review.fromJson(res.data! as Map<String, dynamic>);
    } catch (e) {
      throw toApiException(e);
    }
  }
}

/// Downloads presigned URLs with a bare [Dio]: the URL is already signed, and
/// the API's bearer token must never be sent to the storage host.
class HttpFileDownloader implements FileDownloader {
  HttpFileDownloader({Dio? dio, Future<Directory> Function()? targetDir})
    : _dio = dio ?? Dio(),
      _targetDir = targetDir ?? _defaultDir;

  final Dio _dio;
  final Future<Directory> Function() _targetDir;

  static Future<Directory> _defaultDir() async {
    final base = await getApplicationDocumentsDirectory();
    return Directory('${base.path}/downloads').create(recursive: true);
  }

  @override
  Future<String> download(
    DownloadLink link, {
    void Function(double)? onProgress,
  }) async {
    try {
      final dir = await _targetDir();
      final path = '${dir.path}/${safeFileName(link.fileName)}';
      await _dio.download(
        link.url,
        path,
        onReceiveProgress: (received, total) {
          if (total > 0) onProgress?.call(received / total);
        },
      );
      return path;
    } catch (e) {
      throw toApiException(e);
    }
  }
}

/// Strips path separators and other characters unsafe in file names.
String safeFileName(String name) {
  final cleaned = name.replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1f]'), '_').trim();
  return cleaned.isEmpty || cleaned == '.' || cleaned == '..'
      ? 'drawing'
      : cleaned;
}

class PlatformFileHandler implements FileHandler {
  @override
  Future<void> open(String path) async {
    final result = await OpenFilex.open(path);
    if (result.type != ResultType.done) {
      throw ApiException(
        code: ApiErrorCodes.unknown,
        message:
            result.type == ResultType.noAppToOpen
                ? 'No app installed can open this file. Use Share instead.'
                : 'Could not open the file.',
      );
    }
  }

  @override
  Future<void> share(String path) async {
    await SharePlus.instance.share(ShareParams(files: [XFile(path)]));
  }
}
