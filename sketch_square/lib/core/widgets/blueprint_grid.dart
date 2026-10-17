import 'package:flutter/material.dart';

/// Draws the blueprint-paper grid: fine lines every [spacing] with a stronger
/// line every [majorEvery] cells. Use sparingly (splash, empty states).
class BlueprintGridPainter extends CustomPainter {
  const BlueprintGridPainter({
    required this.color,
    this.spacing = 24,
    this.majorEvery = 5,
  });

  final Color color;
  final double spacing;
  final int majorEvery;

  @override
  void paint(Canvas canvas, Size size) {
    final minor =
        Paint()
          ..color = color.withValues(alpha: 0.08)
          ..strokeWidth = 0.5;
    final major =
        Paint()
          ..color = color.withValues(alpha: 0.16)
          ..strokeWidth = 1;

    var i = 0;
    for (var x = 0.0; x <= size.width; x += spacing, i++) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        i % majorEvery == 0 ? major : minor,
      );
    }
    i = 0;
    for (var y = 0.0; y <= size.height; y += spacing, i++) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        i % majorEvery == 0 ? major : minor,
      );
    }
  }

  @override
  bool shouldRepaint(BlueprintGridPainter old) =>
      old.color != color ||
      old.spacing != spacing ||
      old.majorEvery != majorEvery;
}

/// Blueprint grid background with an optional [child] on top.
class BlueprintGrid extends StatelessWidget {
  const BlueprintGrid({
    super.key,
    this.child,
    this.color,
    this.spacing = 24,
    this.majorEvery = 5,
  });

  final Widget? child;
  final Color? color;
  final double spacing;
  final int majorEvery;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: BlueprintGridPainter(
        color: color ?? Theme.of(context).colorScheme.primary,
        spacing: spacing,
        majorEvery: majorEvery,
      ),
      child: child,
    );
  }
}
