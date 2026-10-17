import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// App logo glyph: a plot rectangle with dimension ticks on a blueprint tile.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 30});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.blueprintBlue,
            borderRadius: BorderRadius.circular(size * 0.28),
          ),
          child: CustomPaint(
            painter: _MarkPainter(
              line: Colors.white,
              accent: AppColors.copperLight,
            ),
          ),
        ),
      ),
    );
  }
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter({required this.line, required this.accent});

  final Color line;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final rect = Rect.fromLTWH(s * 0.26, s * 0.30, s * 0.48, s * 0.44);
    canvas.drawRect(
      rect,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.07,
    );
    final tick =
        Paint()
          ..color = accent
          ..strokeWidth = s * 0.06
          ..strokeCap = StrokeCap.round;
    final y = s * 0.19;
    canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), tick);
    final x = s * 0.15;
    canvas.drawLine(Offset(x, rect.top), Offset(x, rect.bottom), tick);
  }

  @override
  bool shouldRepaint(_MarkPainter old) =>
      old.line != line || old.accent != accent;
}

/// Logo + "SketchSquare" wordmark for app bars.
class Wordmark extends StatelessWidget {
  const Wordmark({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.titleLarge;
    return Semantics(
      label: 'SketchSquare',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BrandMark(),
          const SizedBox(width: 10),
          Flexible(
            child: Text.rich(
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Sketch',
                    style: style?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(
                    text: 'Square',
                    style: style?.copyWith(
                      fontWeight: FontWeight.w400,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
