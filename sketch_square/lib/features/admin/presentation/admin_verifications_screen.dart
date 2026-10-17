import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/router/routes.dart';
import '../../../core/widgets/blueprint_empty_state.dart';
import '../../../core/widgets/error_retry.dart';
import '../domain/admin_verification.dart';
import 'admin_providers.dart';

String adminVerificationPath(String id) =>
    '${AppRoutes.admin}/verification/$id';

/// ADMIN only: pending architect verification requests.
class AdminVerificationsScreen extends ConsumerWidget {
  const AdminVerificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(pendingVerificationsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending verifications'),
        actions: [
          IconButton(
            key: const Key('open-plagiarism'),
            icon: const Icon(Icons.fact_check_outlined),
            tooltip: 'Plagiarism review',
            onPressed: () => context.push('${AppRoutes.admin}/plagiarism'),
          ),
          IconButton(
            key: const Key('open-refunds'),
            icon: const Icon(Icons.receipt_long_outlined),
            tooltip: 'Refunds',
            onPressed: () => context.push('${AppRoutes.admin}/refunds'),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (e, _) => ErrorRetry(
              message: toApiException(e).message,
              onRetry: () => ref.invalidate(pendingVerificationsProvider),
            ),
        data: (paged) {
          Future<void> refresh() async {
            ref.invalidate(pendingVerificationsProvider);
            await ref.read(pendingVerificationsProvider.future);
          }

          if (paged.items.isEmpty) {
            return RefreshIndicator(
              onRefresh: refresh,
              child: LayoutBuilder(
                builder:
                    (context, c) => SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: c.maxHeight,
                        child: const BlueprintEmptyState(
                          icon: Icons.verified_outlined,
                          title: 'All caught up',
                          message: 'No architects are waiting for review.',
                        ),
                      ),
                    ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: refresh,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: paged.items.length + (paged.hasMore ? 1 : 0),
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                if (i == paged.items.length) {
                  return _LoadMore(
                    paged.isLoadingMore,
                    paged.loadMoreError?.message,
                    () =>
                        ref
                            .read(pendingVerificationsProvider.notifier)
                            .loadMore(),
                  );
                }
                return _VerificationTile(paged.items[i]);
              },
            ),
          );
        },
      ),
    );
  }
}

class _VerificationTile extends StatelessWidget {
  const _VerificationTile(this.item);

  final AdminVerification item;

  @override
  Widget build(BuildContext context) {
    final city = item.user.city;
    return ListTile(
      title: Text(item.user.fullName),
      subtitle: Text(
        [
          'COA ${item.coaRegistrationNumber}',
          if (city != null && city.isNotEmpty) city,
          'Submitted ${DateFormat.yMMMd().format(item.submittedAt.toLocal())}',
        ].join(' • '),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push(adminVerificationPath(item.id)),
    );
  }
}

/// Fetches the next page when it scrolls into view (or on tap after a failure).
class _LoadMore extends StatefulWidget {
  const _LoadMore(this.loading, this.error, this.onLoad);

  final bool loading;
  final String? error;
  final VoidCallback onLoad;

  @override
  State<_LoadMore> createState() => _LoadMoreState();
}

class _LoadMoreState extends State<_LoadMore> {
  @override
  void initState() {
    super.initState();
    if (!widget.loading && widget.error == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onLoad();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.error != null) {
      return ListTile(
        leading: const Icon(Icons.refresh),
        title: Text('${widget.error} Tap to retry.'),
        onTap: widget.onLoad,
      );
    }
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}
