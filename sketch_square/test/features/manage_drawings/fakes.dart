import 'package:sketch_square/core/network/api_exception.dart';
import 'package:sketch_square/core/network/cursor_page.dart';
import 'package:sketch_square/features/drawings/domain/drawing_summary.dart';
import 'package:sketch_square/features/manage_drawings/domain/manage_drawings_repository.dart';
import 'package:sketch_square/features/upload/domain/drawing_record.dart';

import '../drawings/fixtures.dart';

const _wire = {
  DrawingStatus.draft: 'DRAFT',
  DrawingStatus.processing: 'PROCESSING',
  DrawingStatus.published: 'PUBLISHED',
  DrawingStatus.underReview: 'UNDER_REVIEW',
  DrawingStatus.failed: 'FAILED',
  DrawingStatus.removed: 'REMOVED',
};

Map<String, dynamic> managedJson(
  String id, {
  DrawingStatus status = DrawingStatus.published,
  int pricePaise = 49900,
  bool isFree = false,
  int views = 120,
  int sales = 3,
}) => {
  'drawing': {
    ...summaryJson(
      id: id,
      title: 'Drawing $id',
      pricePaise: pricePaise,
      isFree: isFree,
    ),
    'status': _wire[status],
  },
  'stats': {
    'viewCount': views,
    'purchaseCount': sales,
    'avgRating': 4.5,
    'ratingCount': 2,
  },
};

ManagedDrawing managed(
  String id, {
  DrawingStatus status = DrawingStatus.published,
  int pricePaise = 49900,
  bool isFree = false,
}) => ManagedDrawing.fromJson(
  managedJson(id, status: status, pricePaise: pricePaise, isFree: isFree),
);

ApiException apiError(String code, [String message = 'boom']) =>
    ApiException(code: code, message: message, statusCode: 400);

class FakeManageDrawingsRepository implements ManageDrawingsRepository {
  FakeManageDrawingsRepository(this.all, {this.pageSize = 20});

  final List<ManagedDrawing> all;
  final int pageSize;
  final calls = <String>[];
  final listFilters = <DrawingStatus?>[];
  final Map<String, List<ApiException>> failures = {};
  final updates = <Map<String, Object?>>[];

  void failNext(String method, ApiException e, {int times = 1}) =>
      failures.putIfAbsent(method, () => []).addAll(List.filled(times, e));

  void _maybeFail(String method) {
    calls.add(method);
    final q = failures[method];
    if (q != null && q.isNotEmpty) throw q.removeAt(0);
  }

  int count(String method) => calls.where((c) => c == method).length;

  @override
  Future<CursorPage<ManagedDrawing>> list({
    DrawingStatus? status,
    String? cursor,
    int limit = CursorPage.defaultLimit,
  }) async {
    _maybeFail('list');
    listFilters.add(status);
    final matching = [
      for (final m in all)
        if (status == null || m.drawing.status == status) m,
    ];
    final start = cursor == null ? 0 : int.parse(cursor);
    final end = (start + pageSize).clamp(0, matching.length);
    return CursorPage(
      items: matching.sublist(start, end),
      nextCursor: end < matching.length ? '$end' : null,
    );
  }

  @override
  Future<DrawingRecord> fetch(String id) async {
    _maybeFail('fetch');
    final m = all.firstWhere((m) => m.id == id);
    return DrawingRecord(
      id: id,
      title: m.drawing.title,
      description: 'A long enough description for $id.',
      pricePaise: m.drawing.pricePaise,
      isFree: m.drawing.isFree,
      status: m.drawing.status,
    );
  }

  @override
  Future<void> updatePublished(
    String id, {
    required String title,
    required String description,
    required int pricePaise,
  }) async {
    _maybeFail('updatePublished');
    updates.add({
      'id': id,
      'title': title,
      'description': description,
      'pricePaise': pricePaise,
    });
  }

  @override
  Future<void> delete(String id) async {
    _maybeFail('delete');
    all.removeWhere((m) => m.id == id);
  }
}
