import 'package:sketch_square/core/network/api_exception.dart';
import 'package:sketch_square/core/network/cursor_page.dart';
import 'package:sketch_square/features/drawings/domain/review.dart';
import 'package:sketch_square/features/purchases/domain/purchase_models.dart';
import 'package:sketch_square/features/purchases/domain/purchases_repositories.dart';

import '../../helpers/commerce_fixtures.dart';

const offline = ApiException(
  code: ApiErrorCodes.network,
  message: 'No connection',
);

PurchaseItem fakePurchase({
  String id = 'd1',
  String title = 'Modern Villa',
  PurchaseKind kind = PurchaseKind.paid,
  List<String>? sheetIds,
}) => PurchaseItem(
  kind: kind,
  purchasedAt: DateTime.utc(2026, 3, 4),
  pricePaise: kind == PurchaseKind.free ? 0 : 150000,
  purchaseId: kind == PurchaseKind.free ? null : 'p-$id',
  drawing: fakeDrawing(id: id, title: title, isFree: kind == PurchaseKind.free),
  sheets: [
    for (final s in sheetIds ?? ['s-$id']) fakeSheet(id: s, fileName: '$s.pdf'),
  ],
);

/// Serves [items] in pages of [pageSize] using the index as the cursor.
class FakePurchasesRepository implements PurchasesRepository {
  FakePurchasesRepository({List<PurchaseItem>? items, this.pageSize = 2})
    : items = items ?? [];

  List<PurchaseItem> items;
  int pageSize;
  ApiException? listError;
  ApiException? downloadError;
  final cursors = <String?>[];
  final downloads = <String>[];

  @override
  Future<CursorPage<PurchaseItem>> list({String? cursor, int? limit}) async {
    cursors.add(cursor);
    if (listError != null) throw listError!;
    final start = cursor == null ? 0 : int.parse(cursor);
    final end = (start + pageSize).clamp(0, items.length);
    return CursorPage(
      items: items.sublist(start, end),
      nextCursor: end < items.length ? '$end' : null,
    );
  }

  @override
  Future<DownloadLink> downloadLink(String drawingId, String sheetId) async {
    downloads.add('$drawingId/$sheetId');
    if (downloadError != null) throw downloadError!;
    return DownloadLink(
      url: 'https://storage.test/$sheetId?sig=1',
      fileName: '$sheetId.pdf',
    );
  }
}

class FakeFileDownloader implements FileDownloader {
  ApiException? error;
  final links = <DownloadLink>[];

  @override
  Future<String> download(
    DownloadLink link, {
    void Function(double)? onProgress,
  }) async {
    links.add(link);
    onProgress?.call(.5);
    if (error != null) throw error!;
    return '/files/${link.fileName}';
  }
}

class FakeFileHandler implements FileHandler {
  final opened = <String>[];
  final shared = <String>[];

  @override
  Future<void> open(String path) async => opened.add(path);

  @override
  Future<void> share(String path) async => shared.add(path);
}

class FakeReviewRepository implements ReviewRepository {
  ApiException? error;
  final submitted = <({String drawingId, int rating, String? comment})>[];

  @override
  Future<Review> submit(
    String drawingId, {
    required int rating,
    String? comment,
  }) async {
    if (error != null) throw error!;
    submitted.add((drawingId: drawingId, rating: rating, comment: comment));
    return Review(
      id: 'r1',
      rating: rating,
      comment: comment,
      reviewer: const ReviewerRef(id: 'u1', fullName: 'Me'),
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );
  }
}
