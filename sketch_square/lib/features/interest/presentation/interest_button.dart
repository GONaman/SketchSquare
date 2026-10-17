import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../data/interest_providers.dart';

/// "I'm interested" toggle on a paid drawing the viewer does not own. Flips
/// immediately and rolls back (with a message) if the call fails.
class InterestButton extends ConsumerStatefulWidget {
  const InterestButton({
    super.key,
    required this.drawingId,
    required this.initial,
  });

  final String drawingId;
  final bool initial;

  @override
  ConsumerState<InterestButton> createState() => _InterestButtonState();
}

class _InterestButtonState extends ConsumerState<InterestButton> {
  late bool _interested = widget.initial;
  bool _busy = false;

  Future<void> _toggle() async {
    final previous = _interested;
    setState(() {
      _interested = !previous;
      _busy = true;
    });
    try {
      await ref
          .read(interestRepositoryProvider)
          .setInterest(widget.drawingId, interested: !previous);
    } catch (e) {
      if (!mounted) return;
      setState(() => _interested = previous);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(toApiException(e).message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _interested
                      ? "You've told the architect you're interested."
                      : 'Not ready to buy? Let the architect know you like it.',
                  key: const Key('interest-text'),
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              const SizedBox(width: 12),
              _interested
                  ? FilledButton.tonalIcon(
                    key: const Key('interest-button'),
                    onPressed: _busy ? null : _toggle,
                    icon: const Icon(Icons.thumb_up),
                    label: const Text("I'm interested"),
                  )
                  : OutlinedButton.icon(
                    key: const Key('interest-button'),
                    onPressed: _busy ? null : _toggle,
                    icon: const Icon(Icons.thumb_up_outlined),
                    label: const Text("I'm interested"),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
