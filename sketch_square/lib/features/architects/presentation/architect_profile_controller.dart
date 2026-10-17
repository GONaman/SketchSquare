import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/pagination/paged_state.dart';
import '../../drawings/domain/drawing_summary.dart';
import '../data/architects_providers.dart';
import '../domain/architect_summary.dart';

part 'architect_profile_controller.g.dart';

/// An architect plus a cursor-paginated list of their drawings.
class ArchitectProfileState {
  const ArchitectProfileState({
    required this.architect,
    required this.drawings,
  });

  final ArchitectSummary architect;
  final PagedState<DrawingSummary> drawings;

  ArchitectProfileState withDrawings(PagedState<DrawingSummary> drawings) =>
      ArchitectProfileState(architect: architect, drawings: drawings);
}

/// `GET /architects/:id` for the first page, then `GET /architects/:id/drawings`.
@riverpod
class ArchitectProfileController extends _$ArchitectProfileController {
  bool _disposed = false;

  @override
  Future<ArchitectProfileState> build(String architectId) async {
    ref.onDispose(() => _disposed = true);
    final profile = await ref
        .watch(architectsRepositoryProvider)
        .getArchitect(architectId);
    return ArchitectProfileState(
      architect: profile.architect,
      drawings: PagedState.fromPage(profile.drawings),
    );
  }

  /// Loads the next page. After a failure it waits for `retry: true`.
  Future<void> loadMore({bool retry = false}) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final drawings = current.drawings;
    if (!drawings.hasMore || drawings.isLoadingMore) return;
    if (drawings.loadMoreError != null && !retry) return;

    state = AsyncData(current.withDrawings(drawings.loadingMore()));
    try {
      final page = await ref
          .read(architectsRepositoryProvider)
          .listDrawings(architectId, cursor: drawings.nextCursor);
      if (_disposed) return;
      state = AsyncData(
        current.withDrawings(drawings.appended(page, (d) => d.id)),
      );
    } catch (e) {
      if (_disposed) return;
      state = AsyncData(
        current.withDrawings(drawings.failedMore(toApiException(e))),
      );
    }
  }
}
