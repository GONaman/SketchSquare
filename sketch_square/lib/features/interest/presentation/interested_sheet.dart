import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/pagination/paged_state.dart';
import '../../../core/widgets/blueprint_empty_state.dart';
import '../../../core/widgets/error_retry.dart';
import '../../../core/widgets/load_more_sentinel.dart';
import '../data/interest_providers.dart';
import '../domain/interest_repository.dart';

/// Owner-side list of the architects interested in [drawingId], shown from
/// Manage Drawings. Pages in as it scrolls.
Future<void> showInterestedSheet(
  BuildContext context, {
  required String drawingId,
  required String drawingTitle,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder:
      (_) => FractionallySizedBox(
        heightFactor: 0.75,
        child: InterestedList(drawingId: drawingId, drawingTitle: drawingTitle),
      ),
);

class InterestedList extends ConsumerStatefulWidget {
  const InterestedList({
    super.key,
    required this.drawingId,
    required this.drawingTitle,
  });

  final String drawingId;
  final String drawingTitle;

  @override
  ConsumerState<InterestedList> createState() => _InterestedListState();
}

class _InterestedListState extends ConsumerState<InterestedList> {
  PagedState<InterestedUser>? _state;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _loadFirst();
  }

  Future<void> _loadFirst() async {
    setState(() {
      _state = null;
      _error = null;
    });
    try {
      final page = await ref
          .read(interestRepositoryProvider)
          .listInterested(widget.drawingId);
      if (mounted) setState(() => _state = PagedState.fromPage(page));
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _loadMore() async {
    final current = _state;
    if (current == null || !current.canLoadMore) return;
    setState(() => _state = current.loadingMore());
    try {
      final page = await ref
          .read(interestRepositoryProvider)
          .listInterested(widget.drawingId, cursor: current.nextCursor);
      if (mounted) {
        setState(() => _state = current.appended(page, (u) => u.id));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _state = current.failedMore(toApiException(e)));
      }
    }
  }

  void _retryMore() {
    final current = _state;
    if (current == null) return;
    setState(
      () =>
          _state = PagedState(
            items: current.items,
            nextCursor: current.nextCursor,
          ),
    );
    _loadMore();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = _state;
    final Widget body;
    if (_error != null) {
      body = ErrorRetry(
        message: toApiException(_error!).message,
        onRetry: _loadFirst,
      );
    } else if (state == null) {
      body = const Center(child: CircularProgressIndicator());
    } else if (state.items.isEmpty) {
      body = const BlueprintEmptyState(
        icon: Icons.favorite_border,
        title: 'No interest yet',
        message: 'Architects who tap "I\'m interested" will show up here.',
      );
    } else {
      body = ListView.builder(
        itemCount: state.items.length + (state.hasMore ? 1 : 0),
        itemBuilder: (_, i) {
          if (i == state.items.length) {
            return LoadMoreSentinel(
              key: ValueKey('interested-more-${state.items.length}'),
              onLoadMore: _loadMore,
              loading: state.isLoadingMore,
              errorMessage: state.loadMoreError?.message,
              onRetry: _retryMore,
            );
          }
          final u = state.items[i];
          return ListTile(
            key: ValueKey('interested-${u.id}'),
            leading: const CircleAvatar(child: Icon(Icons.person_outline)),
            title: Text(u.fullName),
            subtitle: Text(
              [
                if (u.city != null && u.city!.isNotEmpty) u.city!,
                DateFormat.yMMMd().format(u.createdAt.toLocal()),
              ].join(' · '),
            ),
          );
        },
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            'Interested in "${widget.drawingTitle}"',
            key: const Key('interested-title'),
            style: theme.textTheme.titleMedium,
          ),
        ),
        Expanded(child: body),
      ],
    );
  }
}
