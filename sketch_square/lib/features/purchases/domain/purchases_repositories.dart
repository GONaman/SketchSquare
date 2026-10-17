import '../../../core/network/cursor_page.dart';
import '../../drawings/domain/review.dart';
import 'purchase_models.dart';

abstract interface class PurchasesRepository {
  Future<CursorPage<PurchaseItem>> list({String? cursor, int? limit});

  /// Short-lived presigned URL; throws `ApiException` with `FORBIDDEN` or
  /// `FREE_LIMIT_REACHED` when not entitled.
  Future<DownloadLink> downloadLink(String drawingId, String sheetId);
}

abstract interface class ReviewRepository {
  /// `PUT /drawings/:id/review` (create or replace the caller's review).
  Future<Review> submit(
    String drawingId, {
    required int rating,
    String? comment,
  });
}

/// Fetches the presigned file into app storage. Must not send the API token.
abstract interface class FileDownloader {
  /// Returns the local file path.
  Future<String> download(
    DownloadLink link, {
    void Function(double)? onProgress,
  });
}

/// Hands a downloaded file to the OS.
abstract interface class FileHandler {
  Future<void> open(String path);
  Future<void> share(String path);
}
