import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/connectivity_status.dart';

/// Wraps the app and shows a "no connection" strip above it while the API is
/// unreachable. Placed in `MaterialApp.builder`, so it covers every screen.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(connectivityStatusProvider);
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        if (!online)
          Semantics(
            liveRegion: true,
            container: true,
            child: Material(
              color: scheme.errorContainer,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.cloud_off,
                        size: 18,
                        color: scheme.onErrorContainer,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'No connection. Retrying…',
                          style: TextStyle(color: scheme.onErrorContainer),
                        ),
                      ),
                      TextButton(
                        onPressed:
                            () =>
                                ref
                                    .read(connectivityStatusProvider.notifier)
                                    .probe(),
                        style: TextButton.styleFrom(
                          minimumSize: const Size(48, 48),
                          foregroundColor: scheme.onErrorContainer,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        // Keyed so the app keeps its state when the banner appears/disappears.
        Expanded(
          key: const ValueKey('app-content'),
          child: MediaQuery.removePadding(
            context: context,
            removeTop: !online,
            child: child,
          ),
        ),
      ],
    );
  }
}
