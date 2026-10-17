import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:sketch_square/core/network/api_exception.dart';
import 'package:sketch_square/core/network/dio_client.dart';
import 'package:sketch_square/core/storage/secure_storage.dart';
import 'package:sketch_square/core/storage/token_store.dart';
import 'package:sketch_square/features/architects/data/dio_architects_repository.dart';
import 'package:sketch_square/features/drawings/data/dio_drawing_actions_repository.dart';
import 'package:sketch_square/features/drawings/data/dio_drawings_repository.dart';
import 'package:sketch_square/features/drawings/domain/drawing_detail.dart';
import 'package:sketch_square/features/drawings/domain/drawing_search_query.dart';
import 'package:sketch_square/features/drawings/domain/plot_size.dart';
import 'package:sketch_square/features/drawings/domain/sheet.dart';

import 'fixtures.dart';

void main() {
  late Dio dio;
  late DioAdapter adapter;

  setUp(() {
    dio = createDio(
      tokenStore: SecureTokenStore(InMemorySecureStorage()),
      baseUrl: 'http://test',
    );
    adapter = DioAdapter(dio: dio);
  });

  group('DioDrawingsRepository', () {
    test('search sends contract params and parses the page', () async {
      adapter.onGet(
        '/drawings/search',
        (s) => s.reply(200, {
          'items': [summaryJson(id: 'd1', sizeMatch: 0.9)],
          'nextCursor': 'next',
        }),
        queryParameters: {
          'length': '40',
          'breadth': '30',
          'unit': 'm',
          'city': ['Pune', 'Goa'],
          'sort': 'newest',
          'cursor': 'abc',
          'limit': 20,
        },
      );
      final page = await DioDrawingsRepository(dio).search(
        const DrawingSearchQuery(
          length: 40,
          breadth: 30,
          unit: LengthUnit.m,
          cities: ['Pune', 'Goa'],
          sort: DrawingSort.newest,
        ),
        cursor: 'abc',
      );
      expect(page.items.single.sizeMatch, 0.9);
      expect(page.items.single.plotBreadthFt, 30.5);
      expect(page.nextCursor, 'next');
    });

    test('search maps API errors to ApiException', () async {
      adapter.onGet(
        '/drawings/search',
        (s) => s.reply(400, {
          'error': {'code': 'VALIDATION_ERROR', 'message': 'bad'},
        }),
      );
      expect(
        DioDrawingsRepository(dio).search(const DrawingSearchQuery()),
        throwsA(
          isA<ApiException>().having((e) => e.code, 'code', 'VALIDATION_ERROR'),
        ),
      );
    });

    test('getDrawing parses detail, sheets, reviews and viewer', () async {
      adapter.onGet(
        '/drawings/d1',
        (s) => s.reply(
          200,
          detailJson(
            viewer: {
              'isOwner': false,
              'isPurchased': true,
              'inCart': false,
              'canDownload': true,
              'freeDownloadsRemaining': 18,
              'myReview': null,
            },
          ),
        ),
      );
      final d = await DioDrawingsRepository(dio).getDrawing('d1');
      expect(d.summary.title, 'Modern villa');
      expect(d.description, 'A spacious family home.');
      expect(d.sheets, hasLength(3));
      expect(d.sheets[1].type, SheetType.structural);
      expect(d.previewUrls, ['http://img/p1.png', 'http://img/p2.png']);
      expect(d.reviews.items.single.reviewer.fullName, 'Ravi K');
      expect(d.viewer.canDownload, isTrue);
      expect(d.viewer.freeDownloadsRemaining, 18);
      expect(d.viewer.isFavorite, isFalse);
    });

    test('detail falls back to the tile preview without preview sheets', () {
      final json = detailJson()..['sheets'] = <dynamic>[];
      json['previewUrl'] = 'http://img/tile.png';
      final d = DrawingDetail.fromJson(json);
      expect(d.previewUrls, ['http://img/tile.png']);
    });

    test('categories, cities and category request', () async {
      adapter
        ..onGet(
          '/categories',
          (s) => s.reply(200, [
            {'id': 'c1', 'name': 'Residential', 'slug': 'residential'},
          ]),
        )
        ..onGet(
          '/cities',
          (s) => s.reply(200, [
            {'city': 'Pune', 'count': 4},
          ]),
        )
        ..onPost(
          '/category-requests',
          (s) => s.reply(201, {
            'id': 'r',
            'requestedName': 'Farm',
            'status': 'PENDING',
          }),
          data: {'name': 'Farm'},
        );
      final repo = DioDrawingsRepository(dio);
      expect((await repo.listCategories()).single.slug, 'residential');
      expect((await repo.listCities()).single.count, 4);
      await repo.requestCategory('Farm');
    });
  });

  group('DioArchitectsRepository', () {
    test('top passes the city filter', () async {
      adapter.onGet(
        '/architects/top',
        (s) => s.reply(200, [
          {...architectJson(), 'drawingCount': 5},
        ]),
        queryParameters: {'city': 'Pune'},
      );
      final top = await DioArchitectsRepository(dio).top(city: 'Pune');
      expect(top.single.drawingCount, 5);
      expect(top.single.architect.fullName, 'Asha Rao');
    });

    test('getArchitect parses the first drawings page', () async {
      adapter.onGet(
        '/architects/a1',
        (s) => s.reply(200, {
          'architect': architectJson(),
          'drawings': {
            'items': [summaryJson()],
            'nextCursor': 'n',
          },
        }),
      );
      final p = await DioArchitectsRepository(dio).getArchitect('a1');
      expect(p.drawings.items, hasLength(1));
      expect(p.drawings.nextCursor, 'n');
    });
  });

  group('DioDrawingActionsRepository', () {
    test('addToCart posts the drawing id; favorite uses PUT/DELETE', () async {
      adapter
        ..onPost('/cart', (s) => s.reply(200, {}), data: {'drawingId': 'd1'})
        ..onPut('/drawings/d1/favorite', (s) => s.reply(204, null))
        ..onDelete('/drawings/d1/favorite', (s) => s.reply(204, null));
      final repo = DioDrawingActionsRepository(dio);
      await repo.addToCart('d1');
      await repo.setFavorite('d1', favorite: true);
      await repo.setFavorite('d1', favorite: false);
    });

    test('addToCart surfaces the server message', () async {
      adapter.onPost(
        '/cart',
        (s) => s.reply(400, {
          'error': {'code': 'VALIDATION_ERROR', 'message': 'Already purchased'},
        }),
        data: {'drawingId': 'd1'},
      );
      expect(
        DioDrawingActionsRepository(dio).addToCart('d1'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Already purchased',
          ),
        ),
      );
    });
  });
}
