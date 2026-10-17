import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/pagination/paged_state.dart';
import '../../../core/providers.dart';
import '../data/dio_admin_repository.dart';
import '../domain/admin_repository.dart';
import '../domain/admin_verification.dart';

part 'admin_providers.g.dart';

@Riverpod(keepAlive: true)
AdminRepository adminRepository(Ref ref) =>
    DioAdminRepository(ref.watch(dioProvider));

/// Opens a presigned document URL outside the app; tests override it.
typedef DocumentLauncher = Future<bool> Function(Uri url);

@Riverpod(keepAlive: true)
DocumentLauncher documentLauncher(Ref ref) =>
    (url) => launchUrl(url, mode: LaunchMode.externalApplication);

/// PENDING verification requests, cursor-paginated.
@riverpod
class PendingVerifications extends _$PendingVerifications {
  @override
  Future<PagedState<AdminVerification>> build() async => PagedState.fromPage(
    await ref.watch(adminRepositoryProvider).verifications(),
  );

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.canLoadMore) return;
    state = AsyncData(current.loadingMore());
    try {
      final page = await ref
          .read(adminRepositoryProvider)
          .verifications(cursor: current.nextCursor);
      state = AsyncData(current.appended(page, (v) => v.id));
    } catch (e) {
      state = AsyncData(current.failedMore(toApiException(e)));
    }
  }

  /// Drops a decided request without refetching the whole list.
  void remove(String id) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(
      PagedState(
        items: [
          for (final v in current.items)
            if (v.id != id) v,
        ],
        nextCursor: current.nextCursor,
      ),
    );
  }
}

@riverpod
Future<AdminVerification> adminVerification(Ref ref, String id) =>
    ref.watch(adminRepositoryProvider).verification(id);
