import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/cursor_page.dart';
import '../../../core/widgets/widgets.dart';
import '../data/drawings_providers.dart';
import '../domain/review.dart';

/// Reviews list seeded with the first page from the detail response; "Show
/// more" follows the cursor via `GET /drawings/:id/reviews`.
class DrawingReviewsSection extends ConsumerStatefulWidget {
  const DrawingReviewsSection({
    super.key,
    required this.drawingId,
    required this.initial,
    this.avgRating,
    this.ratingCount,
  });

  final String drawingId;
  final CursorPage<Review> initial;

  /// Overall rating from the drawing summary; the breakdown below it is
  /// computed from the reviews loaded so far (the API has no distribution).
  final double? avgRating;
  final int? ratingCount;

  @override
  ConsumerState<DrawingReviewsSection> createState() =>
      _DrawingReviewsSectionState();
}

class _DrawingReviewsSectionState extends ConsumerState<DrawingReviewsSection> {
  late List<Review> _items = widget.initial.items;
  late String? _cursor = widget.initial.nextCursor;
  bool _loading = false;
  String? _error;

  Future<void> _more() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await ref
          .read(drawingsRepositoryProvider)
          .listReviews(widget.drawingId, cursor: _cursor);
      if (!mounted) return;
      final seen = {for (final r in _items) r.id};
      setState(() {
        _items = [
          ..._items,
          for (final r in page.items)
            if (seen.add(r.id)) r,
        ];
        _cursor = page.nextCursor;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = toApiException(e).message;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    if (_items.isEmpty) {
      return AppCard(
        style: AppCardStyle.tonal,
        child: Row(
          children: [
            Icon(Icons.rate_review_outlined, color: scheme.onSurfaceVariant),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'No reviews yet.',
                key: const Key('reviews-empty'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      );
    }
    final total = widget.ratingCount ?? _items.length;
    final average =
        widget.avgRating ??
        _items.fold<int>(0, (a, r) => a + r.rating) / _items.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RatingSummary(average: average, total: total, reviews: _items),
        const SizedBox(height: AppSpacing.sm),
        for (var i = 0; i < _items.length; i++) ...[
          if (i > 0) Divider(height: 1, color: scheme.outlineVariant),
          _ReviewTile(review: _items[i]),
        ],
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(_error!, style: TextStyle(color: scheme.error)),
          ),
        if (_cursor != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: SecondaryButton(
              key: const Key('reviews-more'),
              onPressed: _loading ? null : _more,
              label: _loading ? 'Loading…' : 'Show more reviews',
            ),
          ),
      ],
    );
  }
}

/// Big average, stars and a 5→1 bar breakdown of the loaded reviews.
class _RatingSummary extends StatelessWidget {
  const _RatingSummary({
    required this.average,
    required this.total,
    required this.reviews,
  });

  final double average;
  final int total;
  final List<Review> reviews;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final warning = AppSemanticColors.of(context).warning;
    final counts = [
      for (var star = 5; star >= 1; star--)
        reviews.where((r) => r.rating == star).length,
    ];
    final most = counts.fold<int>(1, (a, b) => a > b ? a : b);
    return Semantics(
      label:
          'Average rating ${average.toStringAsFixed(1)} out of 5 from '
          '$total ${total == 1 ? 'rating' : 'ratings'}',
      container: true,
      child: ExcludeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  average.toStringAsFixed(1),
                  key: const Key('rating-average'),
                  style: theme.textTheme.displaySmall?.tabular,
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 1; i <= 5; i++)
                      Icon(
                        average >= i - 0.25
                            ? Icons.star_rounded
                            : (average >= i - 0.75
                                ? Icons.star_half_rounded
                                : Icons.star_outline_rounded),
                        size: 16,
                        color: warning,
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '$total ${total == 1 ? 'rating' : 'ratings'}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(width: AppSpacing.xl),
            Expanded(
              child: Column(
                key: const Key('rating-distribution'),
                children: [
                  for (var i = 0; i < 5; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 12,
                            child: Text(
                              '${5 - i}',
                              style: theme.textTheme.labelSmall?.tabular,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                              child: LinearProgressIndicator(
                                value: counts[i] / most,
                                minHeight: 6,
                                backgroundColor: scheme.surfaceContainerHigh,
                                color: warning,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});

  final Review review;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final comment = review.comment;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppAvatar(name: review.reviewer.fullName, size: 36),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        review.reviewer.fullName,
                        style: theme.textTheme.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      DateFormat.yMMMd().format(review.createdAt.toLocal()),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Semantics(
                  label: '${review.rating} out of 5 stars',
                  child: ExcludeSemantics(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 1; i <= 5; i++)
                          Icon(
                            i <= review.rating
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 16,
                            color: AppSemanticColors.of(context).warning,
                          ),
                      ],
                    ),
                  ),
                ),
                if (comment != null && comment.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(comment, style: theme.textTheme.bodyMedium),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
