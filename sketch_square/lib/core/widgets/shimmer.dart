import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Sweeps a soft highlight across its [child] (usually [ShimmerBox]es). Stays
/// static when the platform asks to reduce motion.
class Shimmer extends StatefulWidget {
  const Shimmer({super.key, required this.child});

  final Widget child;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduce) {
      _c.stop();
    } else if (!_c.isAnimating) {
      // Finite so long-lived skeletons stop burning frames (and tests settle).
      _c.repeat(count: 8);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = scheme.surfaceContainerHighest;
    final highlight = Color.lerp(base, scheme.surfaceContainerLowest, 0.7)!;
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _c,
        child: widget.child,
        builder:
            (context, child) => ShaderMask(
              blendMode: BlendMode.srcATop,
              shaderCallback: (rect) {
                final dx = (_c.value * 2.4 - 0.7) * rect.width;
                return LinearGradient(
                  colors: [base, highlight, base],
                  stops: const [0.35, 0.5, 0.65],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  transform: _SlideTransform(dx),
                ).createShader(rect);
              },
              child: child,
            ),
      ),
    );
  }
}

class _SlideTransform extends GradientTransform {
  const _SlideTransform(this.dx);
  final double dx;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(dx, 0, 0);
}

/// Rounded placeholder block. Wrap a group in a single [Shimmer].
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    this.width,
    this.height,
    this.radius = AppRadius.sm,
    this.circle = false,
  });

  final double? width;
  final double? height;
  final double radius;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          shape: circle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: circle ? null : BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

/// Skeleton matching the DrawingCard layout (image + two text lines + price).
class DrawingCardSkeleton extends StatelessWidget {
  const DrawingCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: const Shimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: ShimmerBox(radius: AppRadius.lg)),
            Padding(
              padding: EdgeInsets.fromLTRB(12, 12, 12, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(width: 110, height: 14),
                  SizedBox(height: 8),
                  ShimmerBox(width: 70, height: 12),
                  SizedBox(height: 12),
                  ShimmerBox(width: 56, height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Generic list-row skeleton (thumbnail + two lines).
class ListRowSkeleton extends StatelessWidget {
  const ListRowSkeleton({super.key, this.count = 4});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Column(
        children: [
          for (var i = 0; i < count; i++)
            const Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.gutter,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: [
                  ShimmerBox(width: 64, height: 64, radius: AppRadius.sm),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerBox(height: 14),
                        SizedBox(height: 8),
                        ShimmerBox(width: 120, height: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
