import 'package:flutter/material.dart';

import '../format/plot_size.dart';
import '../theme/app_tokens.dart';
import '../theme/app_typography.dart';

/// Plot dimensions as the hero metadata of a drawing: a tiny rectangle drawn
/// in the plot's real aspect ratio next to `40×30 ft` in tabular figures.
class PlotSizeBadge extends StatelessWidget {
  const PlotSizeBadge({
    super.key,
    required this.lengthFt,
    required this.breadthFt,
    this.onImage = false,
    this.large = false,
  });

  final double lengthFt;
  final double breadthFt;

  /// Frosted dark style for placing over a drawing preview.
  final bool onImage;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fg = onImage ? Colors.white : scheme.onPrimaryContainer;
    final bg = onImage ? const Color(0xB30B1E52) : scheme.primaryContainer;
    final label = formatPlotSize(lengthFt, breadthFt);
    final box = large ? 18.0 : 14.0;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: large ? 10 : 8,
          vertical: large ? 6 : 4,
        ),
        child: Semantics(
          label: 'Plot size $label',
          excludeSemantics: true,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomPaint(
                size: Size.square(box),
                painter: _PlotGlyphPainter(
                  color: fg,
                  aspect: breadthFt <= 0 ? 1 : lengthFt / breadthFt,
                ),
              ),
              SizedBox(width: large ? 8 : 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      (large
                              ? theme.textTheme.labelLarge
                              : theme.textTheme.labelMedium)
                          ?.copyWith(color: fg)
                          .tabular,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlotGlyphPainter extends CustomPainter {
  const _PlotGlyphPainter({required this.color, required this.aspect});

  final Color color;
  final double aspect;

  @override
  void paint(Canvas canvas, Size size) {
    final a = aspect.clamp(0.4, 2.5);
    final w = a >= 1 ? size.width : size.width * a;
    final h = a >= 1 ? size.height / a : size.height;
    final rect = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: w,
      height: h,
    );
    final stroke =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4;
    canvas.drawRect(rect, stroke);
    // Dimension ticks on the top and left edges, like a drafting callout.
    final tick =
        Paint()
          ..color = color.withValues(alpha: 0.6)
          ..strokeWidth = 1;
    canvas.drawLine(rect.topLeft, rect.topLeft.translate(0, -2), tick);
    canvas.drawLine(rect.topRight, rect.topRight.translate(0, -2), tick);
  }

  @override
  bool shouldRepaint(_PlotGlyphPainter old) =>
      old.color != color || old.aspect != aspect;
}
