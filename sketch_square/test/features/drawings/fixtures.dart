import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sketch_square/core/network/api_exception.dart';
import 'package:sketch_square/core/network/cursor_page.dart';
import 'package:sketch_square/features/architects/data/architects_providers.dart';
import 'package:sketch_square/features/architects/domain/architect_profile.dart';
import 'package:sketch_square/features/architects/domain/architect_summary.dart';
import 'package:sketch_square/features/architects/domain/architects_repository.dart';
import 'package:sketch_square/features/drawings/data/drawings_providers.dart';
import 'package:sketch_square/features/drawings/domain/city_count.dart';
import 'package:sketch_square/features/drawings/domain/drawing_actions_repository.dart';
import 'package:sketch_square/features/drawings/domain/drawing_detail.dart';
import 'package:sketch_square/features/drawings/domain/drawing_search_query.dart';
import 'package:sketch_square/features/drawings/domain/drawing_summary.dart';
import 'package:sketch_square/features/drawings/domain/drawings_repository.dart';
import 'package:sketch_square/features/drawings/domain/review.dart';

Map<String, dynamic> architectJson({
  String id = 'a1',
  String name = 'Asha Rao',
}) => {
  'id': id,
  'fullName': name,
  'city': 'Pune',
  'architectRating': 4.5,
  'ratingCount': 12,
  'avatarUrl': null,
};

Map<String, dynamic> summaryJson({
  String id = 'd1',
  String title = 'Modern villa',
  int pricePaise = 49900,
  bool isFree = false,
  double? sizeMatch,
  String? previewUrl,
}) => {
  'id': id,
  'title': title,
  'category': {'id': 'c1', 'name': 'Residential', 'slug': 'residential'},
  'city': 'Pune',
  'plotLengthFt': 40,
  'plotBreadthFt': 30.5,
  'plotAreaSqft': 1220,
  'floors': 2,
  'facing': 'N',
  'pricePaise': pricePaise,
  'isFree': isFree,
  'avgRating': 4.2,
  'ratingCount': 7,
  'previewUrl': previewUrl,
  'architect': architectJson(),
  'status': 'PUBLISHED',
  'createdAt': '2026-01-02T03:04:05.000Z',
  if (sizeMatch != null) 'sizeMatch': sizeMatch,
};

DrawingSummary summary(
  String id, {
  String title = 'Modern villa',
  int pricePaise = 49900,
  bool isFree = false,
  double? sizeMatch,
}) => DrawingSummary.fromJson(
  summaryJson(
    id: id,
    title: title,
    pricePaise: pricePaise,
    isFree: isFree,
    sizeMatch: sizeMatch,
  ),
);

Map<String, dynamic> reviewJson({String id = 'r1', int rating = 5}) => {
  'id': id,
  'rating': rating,
  'comment': 'Great plan',
  'reviewer': {'id': 'u9', 'fullName': 'Ravi K'},
  'createdAt': '2026-02-01T00:00:00.000Z',
  'updatedAt': '2026-02-01T00:00:00.000Z',
};

Map<String, dynamic> detailJson({
  String id = 'd1',
  Map<String, dynamic>? viewer,
  bool isFree = false,
  int pricePaise = 49900,
}) => {
  ...summaryJson(id: id, isFree: isFree, pricePaise: pricePaise),
  'description': 'A spacious family home.',
  'viewCount': 10,
  'purchaseCount': 2,
  'failureReason': null,
  'sheets': [
    {
      'id': 's1',
      'type': 'ARCHITECTURAL',
      'isPreview': true,
      'previewUrl': 'http://img/p1.png',
      'originalMime': 'application/pdf',
      'fileName': 'plan.pdf',
      'sizeBytes': 1000,
    },
    {
      'id': 's2',
      'type': 'STRUCTURAL',
      'isPreview': false,
      'previewUrl': null,
      'originalMime': 'application/pdf',
      'fileName': 'structure.pdf',
      'sizeBytes': 2000,
    },
    {
      'id': 's3',
      'type': 'ARCHITECTURAL',
      'isPreview': true,
      'previewUrl': 'http://img/p2.png',
      'originalMime': 'image/png',
      'fileName': 'elevation.png',
      'sizeBytes': 3000,
    },
  ],
  'reviews': {
    'items': [reviewJson()],
    'nextCursor': null,
  },
  'viewer':
      viewer ??
      {
        'isOwner': false,
        'isPurchased': false,
        'inCart': false,
        'canDownload': false,
        'freeDownloadsRemaining': null,
        'myReview': null,
      },
};

/// Fake discovery repository. [searchPages] are served in order for any query
/// (cursor `p<n>` selects page n); every call is recorded.
class FakeDrawingsRepository implements DrawingsRepository {
  FakeDrawingsRepository({
    this.searchPages = const [],
    this.categories = const [],
    this.cities = const [],
    DrawingDetail? detail,
    this.searchError,
    this.requestedCategories,
  }) : detail = detail ?? DrawingDetail.fromJson(detailJson());

  List<List<DrawingSummary>> searchPages;
  List<CategoryRef> categories;
  List<CityCount> cities;
  DrawingDetail detail;
  ApiException? searchError;
  List<String>? requestedCategories;

  final searchCalls = <({DrawingSearchQuery query, String? cursor})>[];
  final reviewCursors = <String?>[];
  CursorPage<Review> reviewsPage = const CursorPage(items: []);

  @override
  Future<CursorPage<DrawingSummary>> search(
    DrawingSearchQuery query, {
    String? cursor,
    int limit = CursorPage.defaultLimit,
  }) async {
    searchCalls.add((query: query, cursor: cursor));
    if (searchError != null) throw searchError!;
    final index = cursor == null ? 0 : int.parse(cursor.substring(1));
    if (searchPages.isEmpty) return const CursorPage(items: []);
    return CursorPage(
      items: searchPages[index],
      nextCursor: index + 1 < searchPages.length ? 'p${index + 1}' : null,
    );
  }

  @override
  Future<DrawingDetail> getDrawing(String id) async => detail;

  @override
  Future<CursorPage<Review>> listReviews(
    String drawingId, {
    String? cursor,
    int limit = CursorPage.defaultLimit,
  }) async {
    reviewCursors.add(cursor);
    return reviewsPage;
  }

  @override
  Future<List<CategoryRef>> listCategories() async => categories;

  @override
  Future<List<CityCount>> listCities() async => cities;

  @override
  Future<void> requestCategory(String name) async =>
      requestedCategories?.add(name);
}

class FakeArchitectsRepository implements ArchitectsRepository {
  FakeArchitectsRepository({this.topList = const [], ArchitectProfile? profile})
    : profile =
          profile ??
          ArchitectProfile(
            architect: ArchitectSummary.fromJson(architectJson()),
            drawings: CursorPage(items: [summary('d1')]),
          );

  List<TopArchitect> topList;
  ArchitectProfile profile;
  final topCities = <String?>[];

  @override
  Future<List<TopArchitect>> top({String? city}) async {
    topCities.add(city);
    return topList;
  }

  @override
  Future<ArchitectProfile> getArchitect(String id) async => profile;

  @override
  Future<CursorPage<DrawingSummary>> listDrawings(
    String architectId, {
    String? cursor,
    int limit = CursorPage.defaultLimit,
  }) async => const CursorPage(items: []);
}

class FakeDrawingActions implements DrawingActionsRepository {
  final carted = <String>[];
  final favorites = <String, bool>{};
  ApiException? error;

  @override
  Future<void> addToCart(String drawingId) async {
    if (error != null) throw error!;
    carted.add(drawingId);
  }

  @override
  Future<void> setFavorite(String drawingId, {required bool favorite}) async {
    if (error != null) throw error!;
    favorites[drawingId] = favorite;
  }
}

/// Provider overrides replacing every discovery repository with a fake.
List<Override> discoveryFakes({
  FakeDrawingsRepository? drawings,
  FakeArchitectsRepository? architects,
  FakeDrawingActions? actions,
}) => [
  drawingsRepositoryProvider.overrideWithValue(
    drawings ?? FakeDrawingsRepository(),
  ),
  architectsRepositoryProvider.overrideWithValue(
    architects ?? FakeArchitectsRepository(),
  ),
  drawingActionsRepositoryProvider.overrideWithValue(
    actions ?? FakeDrawingActions(),
  ),
];
