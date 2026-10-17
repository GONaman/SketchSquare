import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/widgets/widgets.dart';
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

  static const _labels = ['Poor', 'Fair', 'Good', 'Very good', 'Excellent'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        0,
        AppSpacing.gutter,
        AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.existing == null
                ? 'Rate this drawing'
                : 'Update your review',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            widget.drawingTitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              children: [
                for (var star = 1; star <= 5; star++)
                  IconButton(
                    key: Key('star-$star'),
                    tooltip: '$star star${star == 1 ? '' : 's'}',
                    iconSize: 36,
                    color: AppSemanticColors.of(context).warning,
                    icon: Icon(
                      star <= _rating
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                    ),
                    onPressed:
                        _saving ? null : () => setState(() => _rating = star),
                  ),
              ],
            ),
          ),
          Center(
            child: AnimatedSwitcher(
              duration: AppMotion.fast,
              child: Text(
                _rating == 0 ? 'Tap a star to rate' : _labels[_rating - 1],
                key: ValueKey(_rating),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _comment,
            enabled: !_saving,
            maxLines: 4,
            minLines: 3,
            label: 'Comment (optional)',
            textCapitalization: TextCapitalization.sentences,
            inputFormatters: [
              LengthLimitingTextInputFormatter(reviewCommentMaxLength),
            ],
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(_error!, style: TextStyle(color: scheme.error)),
            ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: 'Submit review',
            loading: _saving,
            onPressed: _rating == 0 || _saving ? null : _submit,
          ),
        ],
      ),
    );
  }
}
