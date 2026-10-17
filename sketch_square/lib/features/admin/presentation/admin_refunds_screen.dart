import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/cursor_page.dart';
import '../../../core/pagination/paged_state.dart';
import '../../../core/router/routes.dart';
import '../../../core/widgets/load_more_sentinel.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/admin_purchase.dart';
import 'refunds_providers.dart';

String adminRefundPath(String id) => '${AppRoutes.admin}/refunds/$id';

/// ADMIN only: search purchases and open one to refund it.
class AdminRefundsScreen extends ConsumerStatefulWidget {
  const AdminRefundsScreen({super.key, this.debounce});

  /// Search typing delay; tests shorten it.
  final Duration? debounce;

  @override
  ConsumerState<AdminRefundsScreen> createState() => _AdminRefundsScreenState();
}

class _AdminRefundsScreenState extends ConsumerState<AdminRefundsScreen> {
  final _search = TextEditingController();
  Timer? _timer;
  PurchaseStatus? _status;
  String _query = '';
  PagedState<AdminPurchase>? _paged;
  ApiException? _error;
  bool _loading = true;
  // Ignores responses of superseded searches.
  int _seq = 0;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final seq = ++_seq;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await ref
          .read(adminRefundsRepositoryProvider)
          .purchases(q: _query, status: _status);
      if (!mounted || seq != _seq) return;
      setState(() {
        _paged = PagedState.fromPage(page);
        _loading = false;
      });
    } catch (e) {
      if (!mounted || seq != _seq) return;
      setState(() {
        _error = toApiException(e);
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    final current = _paged;
    if (current == null || !current.canLoadMore) return;
    final seq = _seq;
    setState(() => _paged = current.loadingMore());
    try {
      final CursorPage<AdminPurchase> page = await ref
          .read(adminRefundsRepositoryProvider)
          .purchases(q: _query, status: _status, cursor: current.nextCursor);
      if (!mounted || seq != _seq) return;
      setState(() => _paged = current.appended(page, (p) => p.id));
    } catch (e) {
      if (!mounted || seq != _seq) return;
      setState(() => _paged = current.failedMore(toApiException(e)));
    }
  }

  void _onQueryChanged(String value) {
    _timer?.cancel();
    _timer = Timer(widget.debounce ?? const Duration(milliseconds: 400), () {
      final q = value.trim();
      if (q == _query) return;
      _query = q;
      _reload();
    });
  }

  void _setStatus(PurchaseStatus? status) {
    if (status == _status) return;
    _status = status;
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(refundsVersionProvider, (_, __) => _reload());
    return Scaffold(
      appBar: AppBar(title: const Text('Refunds')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.gutter,
              AppSpacing.md,
              AppSpacing.gutter,
              AppSpacing.sm,
            ),
            child: _SearchField(
              key: const Key('refunds-search'),
              controller: _search,
              onChanged: (v) {
                setState(() {});
                _onQueryChanged(v);
              },
              onSubmitted: (v) {
                _timer?.cancel();
                final q = v.trim();
                if (q != _query) {
                  _query = q;
                  _reload();
                }
              },
              onClear: () {
                _search.clear();
                _onQueryChanged('');
                setState(() {});
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.gutter,
              0,
              AppSpacing.gutter,
              AppSpacing.sm,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: AppSpacing.sm,
                children: [
                  for (final (label, value) in <(String, PurchaseStatus?)>[
                    ('All', null),
                    ('Paid', PurchaseStatus.paid),
                    ('Refunded', PurchaseStatus.refunded),
                  ])
                    ChoiceChip(
                      key: Key('refunds-filter-${value?.wire ?? 'ALL'}'),
                      label: Text(label),
                      selected: _status == value,
                      onSelected: (_) => _setStatus(value),
                    ),
                ],
              ),
            ),
          ),
          Expanded(child: _content()),
        ],
      ),
    );
  }

  Widget _content() {
    final paged = _paged;
    if (_loading && paged == null) {
      return const ListRowSkeleton(count: 4);
    }
    if (_error != null) {
      return ErrorState(message: _error!.message, onRetry: _reload);
    }
    if (paged == null) return const SizedBox.shrink();
    if (paged.items.isEmpty) {
      return const EmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'No purchases found',
        message: 'Try a different search or filter.',
      );
    }
    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter,
          AppSpacing.xs,
          AppSpacing.gutter,
          AppSpacing.gutter,
        ),
        itemCount: paged.items.length + (paged.hasMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, i) {
          if (i == paged.items.length) {
            return LoadMoreSentinel(
              key: ValueKey('refunds-more-${paged.items.length}'),
              loading: paged.isLoadingMore,
              errorMessage: paged.loadMoreError?.message,
              onLoadMore: _loadMore,
              onRetry: _loadMore,
            );
          }
          return _PurchaseTile(paged.items[i]);
        },
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      hint: 'Buyer, seller, drawing or order id',
      prefixIcon: Icons.search,
      textInputAction: TextInputAction.search,
      suffix:
          controller.text.isEmpty
              ? null
              : IconButton(
                key: const Key('refunds-search-clear'),
                icon: const Icon(Icons.clear),
                tooltip: 'Clear',
                onPressed: onClear,
              ),
      onChanged: onChanged,
      onSubmitted: onSubmitted,
    );
  }
}

class _PurchaseTile extends StatelessWidget {
  const _PurchaseTile(this.item);

  final AdminPurchase item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return AppCard(
      key: Key('purchase-${item.id}'),
      onTap: () => context.push(adminRefundPath(item.id)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.drawingTitle,
                  style: theme.textTheme.titleSmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.buyer.fullName} • '
                  '${DateFormat.yMMMd().format(item.createdAt.toLocal())}',
                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatPaise(item.pricePaise),
                style: theme.textTheme.titleSmall?.tabular,
              ),
              const SizedBox(height: AppSpacing.xs),
              PurchaseStatusPill(item.status),
            ],
          ),
        ],
      ),
    );
  }
}

class PurchaseStatusPill extends StatelessWidget {
  const PurchaseStatusPill(this.status, {super.key});

  final PurchaseStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, tone) = switch (status) {
      PurchaseStatus.paid => ('Paid', StatusTone.success),
      PurchaseStatus.refunded => ('Refunded', StatusTone.warning),
      PurchaseStatus.failed => ('Failed', StatusTone.danger),
      PurchaseStatus.created => ('Awaiting payment', StatusTone.neutral),
    };
    return StatusPill(label: label, tone: tone, dense: true);
  }
}
