import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/format/plot_size.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/pagination/paged_state.dart';
import '../../../core/widgets/blueprint_empty_state.dart';
import '../../../core/widgets/error_retry.dart';
import '../../../core/widgets/load_more_sentinel.dart';
import '../../drawings/presentation/formatters.dart' show formatPaise;
import '../domain/plagiarism_flag.dart';
import 'plagiarism_providers.dart';

const maxRejectReasonLength = 500;

String? validateRejectReason(String? value) {
  final reason = (value ?? '').trim();
  if (reason.isEmpty) return 'Enter a reason for the uploader.';
  if (reason.length > maxRejectReasonLength) {
    return 'Keep the reason under $maxRejectReasonLength characters.';
  }
  return null;
}

/// ADMIN only: drawings held `UNDER_REVIEW` because a preview resembles
/// another architect's drawing, shown side by side to approve or reject.
class AdminPlagiarismScreen extends ConsumerStatefulWidget {
  const AdminPlagiarismScreen({super.key});

  @override
  ConsumerState<AdminPlagiarismScreen> createState() =>
      _AdminPlagiarismScreenState();
}

class _AdminPlagiarismScreenState extends ConsumerState<AdminPlagiarismScreen> {
  PlagiarismFlagStatus _status = PlagiarismFlagStatus.pending;
  PagedState<PlagiarismFlag>? _paged;
  ApiException? _error;
  bool _loading = true;
  String? _busyId;
  // Ignores responses of superseded loads.
  int _seq = 0;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final seq = ++_seq;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await ref
          .read(plagiarismRepositoryProvider)
          .flags(status: _status);
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
      final page = await ref
          .read(plagiarismRepositoryProvider)
          .flags(status: _status, cursor: current.nextCursor);
      if (!mounted || seq != _seq) return;
      setState(() => _paged = current.appended(page, (f) => f.id));
    } catch (e) {
      if (!mounted || seq != _seq) return;
      setState(() => _paged = current.failedMore(toApiException(e)));
    }
  }

  void _setStatus(PlagiarismFlagStatus status) {
    if (status == _status) return;
    _status = status;
    _paged = null;
    _reload();
  }

  void _toast(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  Future<void> _decide(
    PlagiarismFlag flag, {
    required Future<void> Function() call,
    required String doneMessage,
  }) async {
    setState(() => _busyId = flag.id);
    try {
      await call();
      if (!mounted) return;
      _toast(doneMessage);
      _reload();
    } catch (e) {
      final err = toApiException(e);
      if (!mounted) return;
      _toast(err.message);
      // Already decided elsewhere: refresh so the stale card disappears.
      if (err.code == ApiErrorCodes.conflict) _reload();
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _approve(PlagiarismFlag flag) async {
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Approve and publish?'),
            content: Text(
              '"${flag.drawing.title}" by ${flag.drawing.architectName} goes '
              'live and the uploader is emailed.',
            ),
            actions: [
              TextButton(
                key: const Key('approve-cancel'),
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                key: const Key('approve-confirm'),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Approve'),
              ),
            ],
          ),
    );
    if (ok != true || !mounted) return;
    await _decide(
      flag,
      call: () => ref.read(plagiarismRepositoryProvider).approve(flag.id),
      doneMessage: 'Drawing approved and published.',
    );
  }

  Future<void> _reject(PlagiarismFlag flag) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => _RejectDialog(title: flag.drawing.title),
    );
    if (reason == null || !mounted) return;
    await _decide(
      flag,
      call:
          () => ref
              .read(plagiarismRepositoryProvider)
              .reject(flag.id, reason: reason),
      doneMessage: 'Drawing rejected and the uploader was notified.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Plagiarism review')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                children: [
                  for (final s in PlagiarismFlagStatus.values)
                    ChoiceChip(
                      key: Key('plagiarism-filter-${s.wire}'),
                      label: Text(
                        toBeginningOfSentenceCase(s.wire.toLowerCase()),
                      ),
                      selected: _status == s,
                      onSelected: (_) => _setStatus(s),
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
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && paged == null) {
      return ErrorRetry(message: _error!.message, onRetry: _reload);
    }
    if (paged == null) return const SizedBox.shrink();
    if (paged.items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _reload,
        child: LayoutBuilder(
          builder:
              (context, c) => SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: c.maxHeight,
                  child: BlueprintEmptyState(
                    icon: Icons.fact_check_outlined,
                    title:
                        _status == PlagiarismFlagStatus.pending
                            ? 'Nothing to review'
                            : 'No ${_status.wire.toLowerCase()} flags',
                    message:
                        _status == PlagiarismFlagStatus.pending
                            ? 'No drawings are waiting for a plagiarism check.'
                            : 'Nothing here yet.',
                  ),
                ),
              ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: paged.items.length + (paged.hasMore ? 1 : 0),
        itemBuilder: (context, i) {
          if (i == paged.items.length) {
            return LoadMoreSentinel(
              key: ValueKey('more-${paged.items.length}'),
              loading: paged.isLoadingMore,
              errorMessage: paged.loadMoreError?.message,
              onLoadMore: _loadMore,
              onRetry: _loadMore,
            );
          }
          final flag = paged.items[i];
          return PlagiarismFlagCard(
            flag: flag,
            busy: _busyId == flag.id,
            onApprove: () => _approve(flag),
            onReject: () => _reject(flag),
          );
        },
      ),
    );
  }
}

/// One flagged pair: the uploaded drawing next to the one it resembles.
class PlagiarismFlagCard extends StatelessWidget {
  const PlagiarismFlagCard({
    super.key,
    required this.flag,
    required this.busy,
    required this.onApprove,
    required this.onReject,
  });

  final PlagiarismFlag flag;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pending = flag.status == PlagiarismFlagStatus.pending;
    return Card(
      key: Key('flag-${flag.id}'),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${flag.similarityPercent}% similar previews '
              '(hash distance ${flag.hammingDistance})',
              key: const Key('flag-similarity'),
              style: theme.textTheme.titleSmall,
            ),
            Text(
              'Flagged ${DateFormat.yMMMd().format(flag.createdAt.toLocal())}',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _DrawingColumn(
                    key: const Key('flag-uploaded'),
                    label: 'Uploaded (held)',
                    drawing: flag.drawing,
                    previewUrl: flag.flaggedPreviewUrl,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DrawingColumn(
                    key: const Key('flag-existing'),
                    label: 'Existing',
                    drawing: flag.matchedDrawing,
                    previewUrl: flag.matchedPreviewUrl,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (pending)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      key: Key('reject-${flag.id}'),
                      onPressed: busy ? null : onReject,
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      key: Key('approve-${flag.id}'),
                      onPressed: busy ? null : onApprove,
                      child:
                          busy
                              ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text('Approve'),
                    ),
                  ),
                ],
              )
            else
              Text(
                [
                  flag.status == PlagiarismFlagStatus.approved
                      ? 'Approved'
                      : 'Rejected',
                  if (flag.reviewNote != null && flag.reviewNote!.isNotEmpty)
                    flag.reviewNote!,
                ].join(': '),
                key: const Key('flag-decision'),
                style: theme.textTheme.bodyMedium,
              ),
          ],
        ),
      ),
    );
  }
}

class _DrawingColumn extends StatelessWidget {
  const _DrawingColumn({
    super.key,
    required this.label,
    required this.drawing,
    required this.previewUrl,
  });

  final String label;
  final ReviewDrawing drawing;
  final String? previewUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final placeholder = ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Center(
        child: Icon(Icons.architecture, color: scheme.onSurfaceVariant),
      ),
    );
    final url = previewUrl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(color: scheme.primary),
        ),
        const SizedBox(height: 4),
        Semantics(
          label: '$label preview of ${drawing.title}',
          button: url != null,
          child: GestureDetector(
            onTap: url == null ? null : () => _showFullScreen(context, url),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child:
                    url == null
                        ? placeholder
                        : CachedNetworkImage(
                          imageUrl: url,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => placeholder,
                          errorWidget: (_, __, ___) => placeholder,
                        ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          drawing.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall,
        ),
        Text(
          'by ${drawing.architectName}'
          '${drawing.architectCity.isEmpty ? '' : ' • ${drawing.architectCity}'}',
          style: theme.textTheme.bodySmall,
        ),
        Text(
          [
            formatPlotSize(drawing.plotLengthFt, drawing.plotBreadthFt),
            if (drawing.city.isNotEmpty) drawing.city,
            drawing.isFree ? 'Free' : formatPaise(drawing.pricePaise),
          ].join(' • '),
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

void _showFullScreen(BuildContext context, String url) {
  showDialog<void>(
    context: context,
    builder:
        (context) => Dialog.fullscreen(
          child: Stack(
            children: [
              Positioned.fill(
                child: InteractiveViewer(
                  maxScale: 5,
                  child: CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.contain,
                    errorWidget:
                        (_, __, ___) =>
                            const Center(child: Icon(Icons.broken_image)),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  tooltip: 'Close',
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
  );
}

class _RejectDialog extends StatefulWidget {
  const _RejectDialog({required this.title});

  final String title;

  @override
  State<_RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<_RejectDialog> {
  final _form = GlobalKey<FormState>();
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reject this drawing?'),
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '"${widget.title}" is removed and the uploader receives your '
              'reason by email.',
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('reject-reason-field'),
              controller: _reason,
              minLines: 2,
              maxLines: 4,
              maxLength: maxRejectReasonLength,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Reason'),
              validator: validateRejectReason,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const Key('reject-cancel'),
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('reject-confirm'),
          onPressed: () {
            if (_form.currentState!.validate()) {
              Navigator.pop(context, _reason.text.trim());
            }
          },
          child: const Text('Reject'),
        ),
      ],
    );
  }
}
