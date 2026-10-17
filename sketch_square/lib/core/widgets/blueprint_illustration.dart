import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum BlueprintArtVariant { plan, plot, broken }

/// Self-contained blueprint-sheet illustration (grid + floor plan + dimension
/// callouts) with a medallion [icon] on top. No image assets.
class BlueprintIllustration extends StatelessWidget {
  const BlueprintIllustration({
    super.key,
    required this.icon,
    this.variant = BlueprintArtVariant.plan,
    this.tone,
    this.width = 220,
  });

  final IconData icon;
  final BlueprintArtVariant variant;

  /// Medallion colour; defaults to the primary.
  final Color? tone;
  final double width;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final sem = AppSemanticColors.of(context);
    final medallion = tone ?? scheme.primary;
    final onMedallion =
        ThemeData.estimateBrightnessForColor(medallion) == Brightness.dark
            ? Colors.white
            : scheme.surface;
    final height = width * 0.72;
    return ExcludeSemantics(
      child: SizedBox(
        width: width,
        height: height + 18,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              bottom: 18,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: sem.blueprintGrid.withValues(alpha: 0.18),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: CustomPaint(
                    painter: _SheetPainter(
                      line: sem.blueprintGrid,
                      variant: variant,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: medallion,
                  shape: BoxShape.circle,
                  border: Border.all(color: scheme.surface, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: medallion.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Icon(icon, size: 26, color: onMedallion),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetPainter extends CustomPainter {
  const _SheetPainter({required this.line, required this.variant});

  final Color line;
  final BlueprintArtVariant variant;

  @override
  void paint(Canvas canvas, Size size) {
    final grid =
        Paint()
          ..color = line.withValues(alpha: 0.10)
          ..strokeWidth = 0.7;
    const step = 14.0;
    for (var x = 0.0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (var y = 0.0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final wall =
        Paint()
          ..color = line.withValues(alpha: 0.75)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeJoin = StrokeJoin.round;
    final thin =
        Paint()
          ..color = line.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;

    final plan = Rect.fromLTWH(
      size.width * 0.17,
      size.height * 0.24,
      size.width * 0.66,
      size.height * 0.52,
    );

    if (variant == BlueprintArtVariant.plot) {
      final dashed = Path()..addRect(plan);
      _dash(canvas, dashed, wall);
    } else {
      canvas.drawRect(plan, wall);
      // Interior walls and a door swing.
      canvas.drawLine(
        Offset(plan.left + plan.width * 0.42, plan.top),
        Offset(plan.left + plan.width * 0.42, plan.top + plan.height * 0.55),
        wall,
      );
      canvas.drawLine(
        Offset(plan.left + plan.width * 0.42, plan.top + plan.height * 0.55),
        Offset(plan.right, plan.top + plan.height * 0.55),
        wall,
      );
      final door = Rect.fromCircle(
        center: Offset(plan.left + plan.width * 0.42, plan.bottom),
        radius: plan.height * 0.22,
      );
      canvas.drawArc(door, -math.pi / 2, math.pi / 2, false, thin);
    }

    if (variant == BlueprintArtVariant.broken) {
      final crack =
          Paint()
            ..color = line.withValues(alpha: 0.9)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round;
      final p =
          Path()
            ..moveTo(plan.right - plan.width * 0.1, plan.top - 6)
            ..lineTo(
              plan.right - plan.width * 0.2,
              plan.top + plan.height * 0.3,
            )
            ..lineTo(
              plan.right - plan.width * 0.12,
              plan.top + plan.height * 0.5,
            )
            ..lineTo(plan.right - plan.width * 0.26, plan.bottom + 6);
      canvas.drawPath(p, crack);
    }

    // Dimension line along the top with end ticks.
    final y = plan.top - 10;
    canvas.drawLine(Offset(plan.left, y), Offset(plan.right, y), thin);
    for (final x in [plan.left, plan.right]) {
      canvas.drawLine(Offset(x, y - 4), Offset(x, y + 4), thin);
    }
    // And down the left side.
    final x = plan.left - 10;
    canvas.drawLine(Offset(x, plan.top), Offset(x, plan.bottom), thin);
    for (final yy in [plan.top, plan.bottom]) {
      canvas.drawLine(Offset(x - 4, yy), Offset(x + 4, yy), thin);
    }
  }

  void _dash(Canvas canvas, Path path, Paint paint) {
    for (final m in path.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, d + 7), paint);
        d += 12;
      }
    }
  }

  @override
  bool shouldRepaint(_SheetPainter old) =>
      old.line != line || old.variant != variant;
}
