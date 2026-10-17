import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import 'app_buttons.dart';
import 'blueprint_illustration.dart';

/// Friendly empty state: blueprint illustration, title, optional message and
/// action. Centre it in any screen body.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
    this.variant = BlueprintArtVariant.plan,
    this.compact = false,
    this.tone,
  });

  final IconData icon;

  /// Medallion colour; defaults to the primary.
  final Color? tone;
  final String title;
  final String? message;
  final Widget? action;
  final BlueprintArtVariant variant;

  /// Smaller art for inline use inside lists/cards.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BlueprintIllustration(
              icon: icon,
              variant: variant,
              tone: tone,
              width: compact ? 160 : 220,
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              title,
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                message!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: AppSpacing.xl),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Error state with a retry action.
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    required this.message,
    required this.onRetry,
    this.title = 'Something went wrong',
    this.retryLabel = 'Retry',
  });

  final String title;
  final String message;
  final VoidCallback onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.cloud_off_rounded,
      tone: Theme.of(context).colorScheme.error,
      variant: BlueprintArtVariant.broken,
      title: title,
      message: message,
      action: SecondaryButton(
        label: retryLabel,
        icon: Icons.refresh_rounded,
        expand: false,
        onPressed: onRetry,
      ),
    );
  }
}
