import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sketch_square/core/format/file_size.dart';
import 'package:sketch_square/core/network/api_exception.dart';
import 'package:sketch_square/features/auth/presentation/current_user_provider.dart';
import 'package:sketch_square/features/auth/presentation/auth_controller.dart';
import 'package:sketch_square/features/purchases/data/dio_purchases_repositories.dart';
import 'package:sketch_square/features/purchases/data/purchases_providers.dart';
import 'package:sketch_square/features/purchases/domain/purchase_models.dart';
import 'package:sketch_square/features/purchases/presentation/download_controller.dart';
import 'package:sketch_square/features/purchases/presentation/purchases_controller.dart';

import '../../helpers/scripted_adapter.dart';
import 'fakes.dart';

const _drawingJson = {
  'id': 'd1',
  'title': 'Modern Villa',
  'category': {'id': 'c1', 'name': 'Villas', 'slug': 'villas'},
  'city': 'Bengaluru',
  'plotLengthFt': 30,
  'plotBreadthFt': 40,
  'plotAreaSqft': 1200,
  'floors': 2,
  'pricePaise': 150000,
  'isFree': false,
  'previewUrl': null,
  'architect': {'id': 'a1', 'fullName': 'Asha Rao', 'city': 'Bengaluru'},
  'status': 'PUBLISHED',
  'createdAt': '2026-01-01T00:00:00.000Z',
  'sheets': [
    {
      'id': 's1',
      'type': 'ARCHITECTURAL',
      'isPreview': false,
      'previewUrl': null,
      'originalMime': 'application/pdf',
      'fileName': 'plan.pdf',
      'sizeBytes': 2048,
    },
  ],
};

class _Harness {
  _Harness({List<PurchaseItem>? items}) {
    purchases = FakePurchasesRepository(items: items);
    container = ProviderContainer(
      overrides: [
        purchasesRepositoryProvider.overrideWithValue(purchases),
        fileDownloaderProvider.overrideWithValue(downloader),
        fileHandlerProvider.overrideWithValue(handler),
        currentUserProvider.overrideWithValue(stubUser),
      ],
    );
  }

  late final FakePurchasesRepository purchases;
  final downloader = FakeFileDownloader();
  final handler = FakeFileHandler();
  late final ProviderContainer container;

  PurchasesController get list =>
      container.read(purchasesControllerProvider.notifier);
  DownloadController get dl =>
      container.read(downloadControllerProvider.notifier);
  DownloadState? download(String sheetId) =>
      container.read(downloadControllerProvider)[sheetId];
}

void main() {
  test('PurchaseItem.fromJson parses kind, drawing and sheets', () {
    final item = PurchaseItem.fromJson({
      'kind': 'FREE',
      'purchasedAt': '2026-03-04T10:00:00.000Z',
      'pricePaise': 0,
      'purchaseId': null,
      'drawing': _drawingJson,
    });
    expect(item.isFree, isTrue);
    expect(item.purchaseId, isNull);
    expect(item.drawing.title, 'Modern Villa');
    expect(item.sheets.single.fileName, 'plan.pdf');
  });

  group('PurchasesController paging', () {
    final five = [for (var i = 1; i <= 5; i++) fakePurchase(id: 'd$i')];

    test('loads the first page then appends, without duplicates', () async {
      final h = _Harness(items: five);
      addTearDown(h.container.dispose);

      var s = await h.container.read(purchasesControllerProvider.future);
      expect(s.items.map((p) => p.key), ['d1', 'd2']);
      expect(s.canLoadMore, isTrue);

      await h.list.loadMore();
      s = h.container.read(purchasesControllerProvider).requireValue;
      expect(s.items.map((p) => p.key), ['d1', 'd2', 'd3', 'd4']);

      await h.list.loadMore();
      s = h.container.read(purchasesControllerProvider).requireValue;
      expect(s.items.length, 5);
      expect(s.hasMore, isFalse);
      await h.list.loadMore();
      expect(h.purchases.cursors, [null, '2', '4']);
    });

    test('a failed page keeps items; retry continues', () async {
      final h = _Harness(items: five);
      addTearDown(h.container.dispose);
      await h.container.read(purchasesControllerProvider.future);

      h.purchases.listError = offline;
      await h.list.loadMore();
      var s = h.container.read(purchasesControllerProvider).requireValue;
      expect(s.items.length, 2);
      expect(s.loadMoreError?.code, ApiErrorCodes.network);
      expect(s.canLoadMore, isFalse);

      h.purchases.listError = null;
      h.list.retryLoadMore();
      await Future<void>.delayed(Duration.zero);
      s = h.container.read(purchasesControllerProvider).requireValue;
      expect(s.items.length, 4);
      expect(s.loadMoreError, isNull);
    });

    test('refresh reloads the first page', () async {
      final h = _Harness(items: five);
      addTearDown(h.container.dispose);
      await h.container.read(purchasesControllerProvider.future);
      h.purchases.items = [fakePurchase(id: 'new')];

      await h.list.refresh();

      final s = h.container.read(purchasesControllerProvider).requireValue;
      expect(s.items.map((p) => p.key), ['new']);
    });
  });

  group('DownloadController', () {
    test('downloads, then open/share use the local file', () async {
      final h = _Harness();
      addTearDown(h.container.dispose);

      await h.dl.download(drawingId: 'd1', sheetId: 's1');

      expect(h.download('s1')!.status, DownloadStatus.done);
      expect(h.download('s1')!.path, '/files/s1.pdf');
      expect(h.purchases.downloads, ['d1/s1']);

      await h.dl.open('s1');
      await h.dl.share('s1');
      expect(h.handler.opened, ['/files/s1.pdf']);
      expect(h.handler.shared, ['/files/s1.pdf']);
    });

    test('FREE_LIMIT_REACHED is flagged as quota reached', () async {
      final h = _Harness();
      addTearDown(h.container.dispose);
      h.purchases.downloadError = const ApiException(
        code: ApiErrorCodes.freeLimitReached,
        message: 'limit',
        statusCode: 403,
      );

      await h.dl.download(drawingId: 'd1', sheetId: 's1');

      final s = h.download('s1')!;
      expect(s.status, DownloadStatus.failed);
      expect(s.quotaReached, isTrue);
      expect(s.message, contains('Free download limit'));
      expect(h.downloader.links, isEmpty);
    });

    test('other failures keep the server message and allow retry', () async {
      final h = _Harness();
      addTearDown(h.container.dispose);
      h.downloader.error = offline;

      await h.dl.download(drawingId: 'd1', sheetId: 's1');
      expect(h.download('s1')!.message, 'No connection');
      expect(h.download('s1')!.quotaReached, isFalse);

      h.downloader.error = null;
      await h.dl.download(drawingId: 'd1', sheetId: 's1');
      expect(h.download('s1')!.status, DownloadStatus.done);
    });

    test('open before a download exists is a no-op', () async {
      final h = _Harness();
      addTearDown(h.container.dispose);
      await h.dl.open('s9');
      expect(h.handler.opened, isEmpty);
    });
  });

  group('Dio repositories', () {
    Dio dio(ScriptedAdapter a) =>
        Dio(BaseOptions(baseUrl: 'http://test'))..httpClientAdapter = a;

    test('purchases list and download link use contract paths', () async {
      final a = ScriptedAdapter((o) {
        if (o.path == '/me/purchases') {
          return jsonResponse({
            'items': [
              {
                'kind': 'PAID',
                'purchasedAt': '2026-03-04T10:00:00.000Z',
                'pricePaise': 150000,
                'purchaseId': 'p1',
                'drawing': _drawingJson,
              },
            ],
            'nextCursor': 'abc',
          });
        }
        return jsonResponse({
          'url': 'https://s/x',
          'expiresInSeconds': 300,
          'fileName': 'plan.pdf',
        });
      });
      final repo = DioPurchasesRepository(dio(a));

      final page = await repo.list(cursor: 'c1', limit: 10);
      expect(page.nextCursor, 'abc');
      expect(page.items.single.purchaseId, 'p1');
      final link = await repo.downloadLink('d1', 's1');
      expect(link.fileName, 'plan.pdf');

      expect(a.requests[0].queryParameters, {'cursor': 'c1', 'limit': 10});
      expect(a.requests[1].path, '/drawings/d1/download');
      expect(a.requests[1].queryParameters, {'sheetId': 's1'});
    });

    test('review submit is a PUT with trimmed optional comment', () async {
      final a = ScriptedAdapter(
        (_) => jsonResponse({
          'id': 'r1',
          'rating': 4,
          'comment': null,
          'reviewer': {'id': 'u', 'fullName': 'Me'},
          'createdAt': '2026-01-01T00:00:00.000Z',
          'updatedAt': '2026-01-01T00:00:00.000Z',
        }),
      );
      final repo = DioReviewRepository(dio(a));

      await repo.submit('d1', rating: 4, comment: '   ');
      await repo.submit('d1', rating: 5, comment: ' great ');

      expect(a.requests[0].method, 'PUT');
      expect(a.requests[0].path, '/drawings/d1/review');
      expect(a.requests[0].data, {'rating': 4});
      expect(a.requests[1].data, {'rating': 5, 'comment': 'great'});
    });
  });

  test('safeFileName and formatBytes', () {
    expect(safeFileName('../evil/plan.pdf'), '.._evil_plan.pdf');
    expect(safeFileName('a:b*c.pdf'), 'a_b_c.pdf');
    expect(safeFileName('..'), 'drawing');
    expect(safeFileName('  '), 'drawing');
    expect(formatBytes(500), '500 B');
    expect(formatBytes(2048), '2.0 KB');
    expect(formatBytes(5 * 1024 * 1024), '5.0 MB');
    expect(formatBytes(150 * 1024 * 1024), '150 MB');
  });
}
