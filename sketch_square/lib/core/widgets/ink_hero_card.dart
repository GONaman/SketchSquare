import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import 'blueprint_grid.dart';

/// Deep-ink gradient surface with the blueprint grid, for hero blocks such as
/// the wallet balance or the order-success header. Children should use
/// `AppSemanticColors.onInk` / white for text.
class InkHeroCard extends StatelessWidget {
  const InkHeroCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.radius,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius? radius;

  @override
  Widget build(BuildContext context) {
    final sem = AppSemanticColors.of(context);
    final r = radius ?? BorderRadius.circular(AppRadius.xl);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: r,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(sem.ink, AppColors.blueprintBlue, 0.55)!,
            sem.ink,
          ],
        ),
        boxShadow: AppElevation.level2(Theme.of(context).brightness),
      ),
      child: ClipRRect(
        borderRadius: r,
        child: Stack(
          children: [
            const Positioned.fill(
              child: ExcludeSemantics(
                child: CustomPaint(
                  painter: BlueprintGridPainter(
                    color: Colors.white,
                    spacing: 22,
                    majorEvery: 4,
                  ),
                ),
              ),
            ),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }
}
