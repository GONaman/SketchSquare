import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/cursor_page.dart';
import '../data/drawings_providers.dart';
import '../domain/review.dart';

/// Reviews list seeded with the first page from the detail response; "Show
/// more" follows the cursor via `GET /drawings/:id/reviews`.
class DrawingReviewsSection extends ConsumerStatefulWidget {
  const DrawingReviewsSection({
    super.key,
    required this.drawingId,
    required this.initial,
  });

  final String drawingId;
  final CursorPage<Review> initial;

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
    if (_items.isEmpty) {
      return Text(
        'No reviews yet.',
        key: const Key('reviews-empty'),
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final r in _items) _ReviewTile(review: r),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _error!,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        if (_cursor != null)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              key: const Key('reviews-more'),
              onPressed: _loading ? null : _more,
              child: Text(_loading ? 'Loading…' : 'Show more reviews'),
            ),
          ),
      ],
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});

  final Review review;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final comment = review.comment;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  review.reviewer.fullName,
                  style: theme.textTheme.titleSmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Semantics(
                label: '${review.rating} out of 5 stars',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 1; i <= 5; i++)
                      Icon(
                        i <= review.rating
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 16,
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (comment != null && comment.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(comment, style: theme.textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}
