import 'package:sketch_square/core/network/api_exception.dart';
import 'package:sketch_square/core/network/cursor_page.dart';
import 'package:sketch_square/features/admin/domain/plagiarism_flag.dart';
import 'package:sketch_square/features/admin/domain/plagiarism_repository.dart';

ReviewDrawing makeReviewDrawing(
  String id, {
  String title = 'Duplex',
  String architect = 'Arya Architect',
}) => ReviewDrawing(
  id: id,
  title: title,
  city: 'Bengaluru',
  plotLengthFt: 40,
  plotBreadthFt: 30,
  pricePaise: 49900,
  architectName: architect,
  architectCity: 'Bengaluru',
);

PlagiarismFlag makeFlag(
  String id, {
  PlagiarismFlagStatus status = PlagiarismFlagStatus.pending,
  int distance = 4,
  String? reviewNote,
}) => PlagiarismFlag(
  id: id,
  status: status,
  hammingDistance: distance,
  reviewNote: reviewNote,
  createdAt: DateTime.utc(2026, 2, 1),
  drawing: makeReviewDrawing('d-$id', title: 'Held $id'),
  matchedDrawing: makeReviewDrawing(
    'm-$id',
    title: 'Original $id',
    architect: 'Omar Original',
  ),
);

class FakePlagiarismRepository implements PlagiarismRepository {
  FakePlagiarismRepository({List<PlagiarismFlag>? items, this.pageSize = 20})
    : items = items ?? [];

  final List<PlagiarismFlag> items;
  final int pageSize;
  final statusQueries = <PlagiarismFlagStatus>[];
  final approved = <String>[];
  final rejected = <(String, String)>[];
  ApiException? listError;
  ApiException? decisionError;

  @override
  Future<CursorPage<PlagiarismFlag>> flags({
    PlagiarismFlagStatus status = PlagiarismFlagStatus.pending,
    String? cursor,
    int limit = CursorPage.defaultLimit,
  }) async {
    statusQueries.add(status);
    if (listError != null) throw listError!;
    final all = items.where((f) => f.status == status).toList();
    final start = cursor == null ? 0 : int.parse(cursor);
    final end = (start + pageSize).clamp(0, all.length);
    return CursorPage(
      items: all.sublist(start, end),
      nextCursor: end < all.length ? '$end' : null,
    );
  }

  void _decide(String id, PlagiarismFlagStatus status, [String? note]) {
    if (decisionError != null) throw decisionError!;
    final i = items.indexWhere((f) => f.id == id);
    items[i] = makeFlag(id, status: status, reviewNote: note);
  }

  @override
  Future<void> approve(String id) async {
    _decide(id, PlagiarismFlagStatus.approved);
    approved.add(id);
  }

  @override
  Future<void> reject(String id, {required String reason}) async {
    _decide(id, PlagiarismFlagStatus.rejected, reason);
    rejected.add((id, reason));
  }
}
