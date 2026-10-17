import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:sketch_square/core/network/api_exception.dart';
import 'package:sketch_square/features/drawings/domain/drawing_summary.dart';
import 'package:sketch_square/features/manage_drawings/data/dio_manage_drawings_repository.dart';

import 'fakes.dart';

void main() {
  late Dio dio;
  late DioAdapter adapter;
  late DioManageDrawingsRepository repo;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'http://test'));
    adapter = DioAdapter(dio: dio);
    repo = DioManageDrawingsRepository(dio);
  });

  test('list parses drawings with stats and the cursor', () async {
    adapter.onGet(
      '/me/drawings',
      (s) => s.reply(200, {
        'items': [managedJson('d1', views: 42, sales: 5)],
        'nextCursor': 'abc',
      }),
      queryParameters: {'limit': 20},
    );
    final page = await repo.list();
    expect(page.nextCursor, 'abc');
    final item = page.items.single;
    expect(item.drawing.title, 'Drawing d1');
    expect(item.stats.viewCount, 42);
    expect(item.stats.purchaseCount, 5);
    expect(item.stats.avgRating, 4.5);
    expect(item.stats.ratingCount, 2);
  });

  test('list sends the wire status and cursor', () async {
    adapter.onGet(
      '/me/drawings',
      (s) => s.reply(200, {'items': [], 'nextCursor': null}),
      queryParameters: {'status': 'UNDER_REVIEW', 'cursor': 'c1', 'limit': 20},
    );
    final page = await repo.list(
      status: DrawingStatus.underReview,
      cursor: 'c1',
    );
    expect(page.items, isEmpty);
    expect(page.hasMore, isFalse);
  });

  test('stats default to zero when missing', () async {
    adapter.onGet(
      '/me/drawings',
      (s) => s.reply(200, {
        'items': [
          {'drawing': managedJson('d1')['drawing']},
        ],
      }),
      queryParameters: {'limit': 20},
    );
    final item = (await repo.list()).items.single;
    expect(item.stats.viewCount, 0);
    expect(item.stats.ratingCount, 0);
  });

  test('updatePublished patches only title, description and price', () async {
    adapter.onPatch(
      '/drawings/d1',
      (s) => s.reply(200, {'id': 'd1'}),
      data: {
        'title': 'New title',
        'description': 'New description text',
        'pricePaise': 59900,
      },
    );
    await repo.updatePublished(
      'd1',
      title: ' New title ',
      description: 'New description text ',
      pricePaise: 59900,
    );
  });

  test('delete calls DELETE /drawings/:id', () async {
    adapter.onDelete('/drawings/d1', (s) => s.reply(204, null));
    await repo.delete('d1');
  });

  test('errors become ApiException with the server code', () async {
    adapter.onDelete(
      '/drawings/d1',
      (s) => s.reply(403, {
        'error': {'code': 'FORBIDDEN', 'message': 'Not your drawing'},
      }),
    );
    await expectLater(
      repo.delete('d1'),
      throwsA(
        isA<ApiException>()
            .having((e) => e.code, 'code', ApiErrorCodes.forbidden)
            .having((e) => e.message, 'message', 'Not your drawing'),
      ),
    );
  });

  test('fetch parses the seller-side detail', () async {
    adapter.onGet(
      '/drawings/d1',
      (s) => s.reply(200, {
        'id': 'd1',
        'title': 'T',
        'description': 'Desc',
        'status': 'PUBLISHED',
        'pricePaise': 100,
        'isFree': false,
      }),
    );
    final r = await repo.fetch('d1');
    expect(r.description, 'Desc');
    expect(r.status, DrawingStatus.published);
  });
}
