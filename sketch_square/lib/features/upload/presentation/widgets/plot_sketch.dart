import 'package:flutter/material.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/blueprint_grid.dart';

/// Live drawing of the plot being described: a rectangle in the real aspect
/// ratio with dimension lines, so the seller sees the size they typed.
class PlotSketch extends StatelessWidget {
  const PlotSketch({
    super.key,
    required this.length,
    required this.breadth,
    required this.unitLabel,
  });

  final double? length;
  final double? breadth;
  final String unitLabel;

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l = length, b = breadth;
    final valid = l != null && b != null && l > 0 && b > 0;
    final label =
        valid
            ? 'Plot sketch: ${_fmt(l)} by ${_fmt(b)} $unitLabel'
            : 'Plot sketch appears when you enter length and width';
    return Semantics(
      label: label,
      child: ExcludeSemantics(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              border: Border.all(color: scheme.outlineVariant),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: BlueprintGridPainter(
                      color: scheme.primary,
                      spacing: 16,
                      majorEvery: 4,
                    ),
                  ),
                ),
                SizedBox(
                  height: 132,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _PlotPainter(
                      length: valid ? l : null,
                      breadth: valid ? b : null,
                      unit: unitLabel,
                      stroke: scheme.primary,
                      fill: scheme.primary.withValues(alpha: 0.10),
                      dim: scheme.onSurfaceVariant,
                      textStyle:
                          Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: scheme.onSurface,
                                fontWeight: FontWeight.w600,
                              )
                              .tabular,
                    ),
                  ),
                ),
                if (!valid)
                  Positioned.fill(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          'Enter length and width to see your plot',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlotPainter extends CustomPainter {
  _PlotPainter({
    required this.length,
    required this.breadth,
    required this.unit,
    required this.stroke,
    required this.fill,
    required this.dim,
    required this.textStyle,
  });

  final double? length;
  final double? breadth;
  final String unit;
  final Color stroke;
  final Color fill;
  final Color dim;
  final TextStyle? textStyle;

  void _label(Canvas canvas, String text, Offset centre) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, centre - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final l = length, b = breadth;
    const padX = 56.0, padY = 30.0;
    final box = Rect.fromLTWH(
      padX,
      padY,
      size.width - padX * 2,
      size.height - padY * 2,
    );
    if (l == null || b == null) {
      final dash =
          Paint()
            ..color = dim.withValues(alpha: 0.5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: box.center, width: 96, height: 64),
          const Radius.circular(4),
        ),
        dash,
      );
      return;
    }
    final ratio = (l / b).clamp(0.35, 2.8);
    var w = box.width, h = w / ratio;
    if (h > box.height) {
      h = box.height;
      w = h * ratio;
    }
    final rect = Rect.fromCenter(center: box.center, width: w, height: h);
    canvas.drawRect(rect, Paint()..color = fill);
    canvas.drawRect(
      rect,
      Paint()
        ..color = stroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final line =
        Paint()
          ..color = dim
          ..strokeWidth = 1;
    // Length along the top.
    final ty = rect.top - 12;
    canvas.drawLine(Offset(rect.left, ty), Offset(rect.right, ty), line);
    for (final x in [rect.left, rect.right]) {
      canvas.drawLine(Offset(x, ty - 4), Offset(x, ty + 4), line);
    }
    _label(
      canvas,
      '${PlotSketch._fmt(l)} $unit',
      Offset(rect.center.dx, ty - 9),
    );
    // Width along the left.
    final lx = rect.left - 12;
    canvas.drawLine(Offset(lx, rect.top), Offset(lx, rect.bottom), line);
    for (final y in [rect.top, rect.bottom]) {
      canvas.drawLine(Offset(lx - 4, y), Offset(lx + 4, y), line);
    }
    canvas.save();
    canvas.translate(lx - 11, rect.center.dy);
    canvas.rotate(-1.5708);
    _label(canvas, '${PlotSketch._fmt(b)} $unit', Offset.zero);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PlotPainter old) =>
      old.length != length ||
      old.breadth != breadth ||
      old.unit != unit ||
      old.stroke != stroke ||
      old.textStyle != textStyle;
}
