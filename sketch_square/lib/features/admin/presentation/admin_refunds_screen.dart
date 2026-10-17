import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/cursor_page.dart';
import '../../../core/pagination/paged_state.dart';
import '../../../core/router/routes.dart';
import '../../../core/widgets/blueprint_empty_state.dart';
import '../../../core/widgets/error_retry.dart';
import '../../drawings/presentation/formatters.dart';
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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              key: const Key('refunds-search'),
              controller: _search,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Buyer, seller, drawing, order or payment id',
                prefixIcon: const Icon(Icons.search),
                suffixIcon:
                    _search.text.isEmpty
                        ? null
                        : IconButton(
                          key: const Key('refunds-search-clear'),
                          icon: const Icon(Icons.clear),
                          tooltip: 'Clear',
                          onPressed: () {
                            _search.clear();
                            _onQueryChanged('');
                            setState(() {});
                          },
                        ),
              ),
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
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
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
          Expanded(child: _content()),
        ],
      ),
    );
  }

  Widget _content() {
    final paged = _paged;
    if (_loading && paged == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return ErrorRetry(message: _error!.message, onRetry: _reload);
    }
    if (paged == null) return const SizedBox.shrink();
    if (paged.items.isEmpty) {
      return const BlueprintEmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'No purchases found',
        message: 'Try a different search or filter.',
      );
    }
    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: paged.items.length + (paged.hasMore ? 1 : 0),
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          if (i == paged.items.length) {
            return _LoadMore(
              paged.isLoadingMore,
              paged.loadMoreError?.message,
              _loadMore,
            );
          }
          return _PurchaseTile(paged.items[i]);
        },
      ),
    );
  }
}

class _PurchaseTile extends StatelessWidget {
  const _PurchaseTile(this.item);

  final AdminPurchase item;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: Key('purchase-${item.id}'),
      title: Text(item.drawingTitle),
      subtitle: Text(
        [
          item.buyer.fullName,
          formatPaise(item.pricePaise),
          DateFormat.yMMMd().format(item.createdAt.toLocal()),
        ].join(' • '),
      ),
      trailing: PurchaseStatusChip(item.status),
      onTap: () => context.push(adminRefundPath(item.id)),
    );
  }
}

class PurchaseStatusChip extends StatelessWidget {
  const PurchaseStatusChip(this.status, {super.key});

  final PurchaseStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = switch (status) {
      PurchaseStatus.paid => scheme.primary,
      PurchaseStatus.refunded => scheme.tertiary,
      PurchaseStatus.failed => scheme.error,
      PurchaseStatus.created => scheme.outline,
    };
    return Text(
      status.wire,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: color,
        fontWeight: FontWeight.w600,
      ),
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
