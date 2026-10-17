import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../drawings/domain/review.dart';
import '../data/purchases_providers.dart';

const reviewCommentMaxLength = 1000;

/// Bottom sheet to rate a purchased drawing (`PUT /drawings/:id/review`).
/// Resolves to the saved [Review], or null when dismissed. Reusable from the
/// drawing detail screen via `viewer.myReview`.
Future<Review?> showReviewSheet(
  BuildContext context, {
  required String drawingId,
  required String drawingTitle,
  Review? existing,
}) {
  return showModalBottomSheet<Review>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder:
        (_) => ReviewSheet(
          drawingId: drawingId,
          drawingTitle: drawingTitle,
          existing: existing,
        ),
  );
}

class ReviewSheet extends ConsumerStatefulWidget {
  const ReviewSheet({
    super.key,
    required this.drawingId,
    required this.drawingTitle,
    this.existing,
  });

  final String drawingId;
  final String drawingTitle;
  final Review? existing;

  @override
  ConsumerState<ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends ConsumerState<ReviewSheet> {
  late int _rating = widget.existing?.rating ?? 0;
  late final _comment = TextEditingController(text: widget.existing?.comment);
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final review = await ref
          .read(reviewRepositoryProvider)
          .submit(widget.drawingId, rating: _rating, comment: _comment.text);
      if (mounted) Navigator.of(context).pop(review);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = toApiException(e).message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.existing == null
                ? 'Rate this drawing'
                : 'Update your review',
            style: theme.textTheme.titleMedium,
          ),
          Text(widget.drawingTitle, style: theme.textTheme.bodySmall),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var star = 1; star <= 5; star++)
                IconButton(
                  key: Key('star-$star'),
                  tooltip: '$star star${star == 1 ? '' : 's'}',
                  iconSize: 36,
                  color: Colors.amber.shade700,
                  icon: Icon(star <= _rating ? Icons.star : Icons.star_border),
                  onPressed:
                      _saving ? null : () => setState(() => _rating = star),
                ),
            ],
          ),
          TextField(
            controller: _comment,
            enabled: !_saving,
            maxLines: 4,
            maxLength: reviewCommentMaxLength,
            decoration: const InputDecoration(
              labelText: 'Comment (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _error!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _rating == 0 || _saving ? null : _submit,
              child:
                  _saving
                      ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Text('Submit review'),
            ),
          ),
        ],
      ),
    );
  }
}
