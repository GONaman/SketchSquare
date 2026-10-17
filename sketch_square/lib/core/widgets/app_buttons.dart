import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Filled call-to-action. Shows an inline spinner and ignores taps while
/// [loading]; keeps its width so the layout doesn't jump.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = true,
    this.accent = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool expand;

  /// Use the warm copper accent instead of blueprint blue (purchase CTAs).
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final button = FilledButton(
      onPressed: loading ? null : onPressed,
      style:
          accent
              ? FilledButton.styleFrom(
                backgroundColor: scheme.secondary,
                foregroundColor: scheme.onSecondary,
              )
              : null,
      child: _ButtonContent(
        label: label,
        icon: icon,
        loading: loading,
        color: accent ? scheme.onSecondary : scheme.onPrimary,
      ),
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Outlined secondary action with the same loading behaviour.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final button = OutlinedButton(
      onPressed: loading ? null : onPressed,
      child: _ButtonContent(
        label: label,
        icon: icon,
        loading: loading,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

class _ButtonContent extends StatelessWidget {
  const _ButtonContent({
    required this.label,
    required this.icon,
    required this.loading,
    required this.color,
  });

  final String label;
  final IconData? icon;
  final bool loading;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppMotion.fast,
      child:
          loading
              ? SizedBox.square(
                key: const ValueKey('loading'),
                dimension: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: color,
                  semanticsLabel: 'Loading',
                ),
              )
              : Row(
                key: const ValueKey('label'),
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
    );
  }
}
