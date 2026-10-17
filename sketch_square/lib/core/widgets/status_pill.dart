import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

enum StatusTone { neutral, info, success, warning, danger, accent }

/// Small rounded status label ("Published", "Pending", "Refunded"). Colour is
/// never the only signal: the label text always carries the meaning.
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    this.tone = StatusTone.neutral,
    this.icon,
    this.dense = false,
  });

  final String label;
  final StatusTone tone;
  final IconData? icon;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final sem = AppSemanticColors.of(context);
    final (bg, fg) = switch (tone) {
      StatusTone.neutral => (scheme.surfaceContainerHigh, scheme.onSurface),
      StatusTone.info => (scheme.primaryContainer, scheme.onPrimaryContainer),
      StatusTone.success => (
        sem.successContainer,
        scheme.brightness == Brightness.dark
            ? sem.success
            : const Color(0xFF0B4A2F),
      ),
      StatusTone.warning => (
        sem.warningContainer,
        scheme.brightness == Brightness.dark
            ? sem.warning
            : const Color(0xFF6B4510),
      ),
      StatusTone.danger => (scheme.errorContainer, scheme.onErrorContainer),
      StatusTone.accent => (sem.accentContainer, sem.onAccentContainer),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: dense ? 8 : 10,
          vertical: dense ? 2 : 4,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: fg),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: fg,
                  fontSize: dense ? 11 : 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
