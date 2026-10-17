import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/format/file_size.dart';
import '../../../core/format/plot_size.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/blueprint_empty_state.dart';
import '../../../core/widgets/drawing_thumbnail.dart';
import '../../../core/widgets/error_retry.dart';
import '../../auth/presentation/current_user_provider.dart';
import '../../drawings/domain/sheet.dart';
import '../../upload/domain/money.dart';
import '../domain/purchase_models.dart';
import 'download_controller.dart';
import 'purchases_controller.dart';
import 'review_sheet.dart';

class PurchasesScreen extends ConsumerWidget {
  const PurchasesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purchases = ref.watch(purchasesControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('My purchases')),
      body: purchases.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (e, _) => ErrorRetry(
              message: toApiException(e).message,
              onRetry: () => ref.invalidate(purchasesControllerProvider),
            ),
        data: (paged) {
          if (paged.items.isEmpty) {
            return const BlueprintEmptyState(
              icon: Icons.folder_open_outlined,
              title: 'No purchases yet',
              message: 'Drawings you buy or download for free appear here.',
            );
          }
          return RefreshIndicator(
            onRefresh: ref.read(purchasesControllerProvider.notifier).refresh,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: paged.items.length + 2,
              itemBuilder: (_, i) {
                if (i == 0) return const FreeQuotaBanner();
                if (i == paged.items.length + 1) {
                  return _PagingFooter(
                    loading: paged.isLoadingMore,
                    error: paged.loadMoreError,
                  );
                }
                if (i == paged.items.length) {
                  Future.microtask(
                    ref.read(purchasesControllerProvider.notifier).loadMore,
                  );
                }
                return PurchaseCard(item: paged.items[i - 1]);
              },
            ),
          );
        },
      ),
    );
  }
}

/// "Free downloads: 3 of 20 used" for the signed-in user.
class FreeQuotaBanner extends ConsumerWidget {
  const FreeQuotaBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final limit = user.freeDownloadLimit;
    final used = user.freeDownloadsUsed.clamp(0, limit);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Free downloads: $used of $limit used',
            key: const Key('free-quota-text'),
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(value: limit == 0 ? 1 : used / limit),
        ],
      ),
    );
  }
}

class _PagingFooter extends ConsumerWidget {
  const _PagingFooter({required this.loading, this.error});
  final bool loading;
  final ApiException? error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (error != null) {
      return TextButton(
        onPressed: ref.read(purchasesControllerProvider.notifier).retryLoadMore,
        child: Text('${error!.message} Tap to retry'),
      );
    }
    return const SizedBox.shrink();
  }
}

class PurchaseCard extends ConsumerWidget {
  const PurchaseCard({super.key, required this.item});
  final PurchaseItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final d = item.drawing;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DrawingThumbnail(url: d.previewUrl, size: 64),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d.title, style: theme.textTheme.titleSmall),
                      Text(
                        '${formatPlotSize(d.plotLengthFt, d.plotBreadthFt)} · ${d.city}',
                        style: theme.textTheme.bodySmall,
                      ),
                      Text(
                        '${item.isFree ? 'Free' : formatPaise(item.pricePaise)}'
                        ' · ${DateFormat.yMMMd().format(item.purchasedAt.toLocal())}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.star_outline),
                  label: const Text('Rate'),
                  onPressed: () => _rate(context),
                ),
              ],
            ),
            const Divider(),
            for (final sheet in item.sheets)
              SheetDownloadRow(
                drawingId: d.id,
                drawingTitle: d.title,
                sheet: sheet,
                isFreePurchase: item.isFree,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _rate(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final saved = await showReviewSheet(
      context,
      drawingId: item.drawing.id,
      drawingTitle: item.drawing.title,
    );
    if (saved != null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Thanks for your review')),
      );
    }
  }
}

class SheetDownloadRow extends ConsumerWidget {
  const SheetDownloadRow({
    super.key,
    required this.drawingId,
    required this.drawingTitle,
    required this.sheet,
    required this.isFreePurchase,
  });

  final String drawingId;
  final String drawingTitle;
  final Sheet sheet;
  final bool isFreePurchase;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(downloadControllerProvider)[sheet.id];
    final controller = ref.read(downloadControllerProvider.notifier);

    Widget trailing;
    if (state == null || state.status == DownloadStatus.failed) {
      trailing = IconButton(
        key: Key('download-${sheet.id}'),
        tooltip: 'Download ${sheet.fileName}',
        icon: const Icon(Icons.download_outlined),
        onPressed:
            () => controller.download(
              drawingId: drawingId,
              sheetId: sheet.id,
              isFreePurchase: isFreePurchase,
            ),
      );
    } else if (state.isBusy) {
      trailing = SizedBox.square(
        dimension: 24,
        child: CircularProgressIndicator(strokeWidth: 2, value: state.progress),
      );
    } else {
      trailing = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            key: Key('open-${sheet.id}'),
            tooltip: 'Open ${sheet.fileName}',
            icon: const Icon(Icons.open_in_new),
            onPressed: () => _guard(context, () => controller.open(sheet.id)),
          ),
          IconButton(
            key: Key('share-${sheet.id}'),
            tooltip: 'Share ${sheet.fileName}',
            icon: const Icon(Icons.share_outlined),
            onPressed: () => _guard(context, () => controller.share(sheet.id)),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.insert_drive_file_outlined, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${sheet.fileName} · ${formatBytes(sheet.sizeBytes)}',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            trailing,
          ],
        ),
        if (state?.status == DownloadStatus.failed)
          Padding(
            padding: const EdgeInsets.only(left: 28, bottom: 4),
            child: Text(
              state!.message ?? 'Download failed',
              key: Key('download-error-${sheet.id}'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _guard(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(toApiException(e).message)),
      );
    }
  }
}
