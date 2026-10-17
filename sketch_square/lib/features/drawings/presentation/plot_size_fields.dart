import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/widgets/widgets.dart';
import '../domain/drawing_search_query.dart';
import '../domain/plot_size.dart';

/// State behind [PlotSizeFields]: text controllers, unit, tolerance and
/// validation errors. Owned (and disposed) by the screen that embeds the fields.
class PlotSizeController extends ChangeNotifier {
  PlotSizeController({
    double? length,
    double? breadth,
    LengthUnit unit = LengthUnit.ft,
    int tolerancePct = defaultTolerancePct,
  }) : _unit = unit,
       _tolerancePct = tolerancePct,
       lengthText = TextEditingController(
         text: length == null ? '' : formatDimension(length),
       ),
       breadthText = TextEditingController(
         text: breadth == null ? '' : formatDimension(breadth),
       );

  final TextEditingController lengthText;
  final TextEditingController breadthText;

  LengthUnit _unit;
  int _tolerancePct;
  String? lengthError;
  String? breadthError;

  LengthUnit get unit => _unit;
  int get tolerancePct => _tolerancePct;

  set unit(LengthUnit value) {
    if (value == _unit) return;
    _unit = value;
    lengthError = breadthError = null;
    notifyListeners();
  }

  set tolerancePct(int value) {
    _tolerancePct = value.clamp(minTolerancePct, maxTolerancePct);
    notifyListeners();
  }

  /// Validates, updates the shown errors and returns the result.
  PlotSizeValidation validate({bool allowEmpty = false}) {
    final result = validatePlotSize(
      lengthText: lengthText.text,
      breadthText: breadthText.text,
      unit: _unit,
      allowEmpty: allowEmpty,
    );
    lengthError = result.lengthError;
    breadthError = result.breadthError;
    notifyListeners();
    return result;
  }

  /// The two numbers as typed (null unless both parse), without touching errors.
  (double, double)? peekSize() {
    final l = double.tryParse(lengthText.text.trim().replaceAll(',', '.'));
    final b = double.tryParse(breadthText.text.trim().replaceAll(',', '.'));
    if (l == null || b == null || l <= 0 || b <= 0) return null;
    return (l, b);
  }

  void clear() {
    lengthText.clear();
    breadthText.clear();
    lengthError = breadthError = null;
    _tolerancePct = defaultTolerancePct;
    notifyListeners();
  }

  @override
  void dispose() {
    lengthText.dispose();
    breadthText.dispose();
    super.dispose();
  }
}

/// Length × breadth inputs with an ft/m toggle and optional tolerance slider.
///
/// With [trailing] (e.g. the search button) the unit toggle shrinks to `ft | m`
/// and shares one row with it, which keeps hero cards short. With
/// [showTolerance] the tolerance slider, the live size range it covers and the
/// "rotated plots are included" note follow (filters sheet).
class PlotSizeFields extends StatelessWidget {
  const PlotSizeFields({
    super.key,
    required this.controller,
    this.showTolerance = false,
    this.onSubmitted,
    this.trailing,
  });

  final PlotSizeController controller;
  final bool showTolerance;
  final VoidCallback? onSubmitted;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final suffix = controller.unit.apiValue;
        final inline = trailing != null;
        final unitToggle = SegmentedButton<LengthUnit>(
          key: const Key('plot-unit'),
          showSelectedIcon: false,
          segments: [
            ButtonSegment(
              value: LengthUnit.ft,
              label: Text(inline ? 'ft' : 'Feet'),
            ),
            ButtonSegment(
              value: LengthUnit.m,
              label: Text(inline ? 'm' : 'Metres'),
            ),
          ],
          selected: {controller.unit},
          onSelectionChanged: (s) => controller.unit = s.first,
        );
        final lengthField = _DimensionField(
          fieldKey: const Key('plot-length'),
          controller: controller.lengthText,
          label: 'Length',
          suffix: suffix,
          error: controller.lengthError,
          action: TextInputAction.next,
        );
        Widget breadthField(TextInputAction action) => _DimensionField(
          fieldKey: const Key('plot-breadth'),
          controller: controller.breadthText,
          label: 'Breadth',
          suffix: suffix,
          error: controller.breadthError,
          action: action,
          onSubmitted: onSubmitted,
        );
        const times = Padding(
          padding: EdgeInsets.fromLTRB(6, 16, 6, 0),
          child: Icon(Icons.close, size: 18),
        );
        return LayoutBuilder(
          builder: (context, constraints) {
            // Roomy and a trailing action: everything on a single line.
            if (inline && constraints.maxWidth >= 600) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: lengthField),
                      times,
                      Expanded(child: breadthField(TextInputAction.done)),
                      const SizedBox(width: AppSpacing.md),
                      SizedBox(height: 56, child: Center(child: unitToggle)),
                      const SizedBox(width: AppSpacing.md),
                      SizedBox(width: 160, height: 56, child: trailing),
                    ],
                  ),
                  if (showTolerance) _ToleranceBlock(controller: controller),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: lengthField),
                    times,
                    Expanded(child: breadthField(TextInputAction.done)),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                if (inline)
                  Row(
                    children: [
                      unitToggle,
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: trailing!),
                    ],
                  )
                else
                  unitToggle,
                if (showTolerance) _ToleranceBlock(controller: controller),
              ],
            );
          },
        );
      },
    );
  }
}

class _ToleranceBlock extends StatelessWidget {
  const _ToleranceBlock({required this.controller});

  final PlotSizeController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final pct = controller.tolerancePct;
    final unit = controller.unit.apiValue;
    final size = controller.peekSize();
    final t = pct / 100;
    String range(double v) =>
        '${formatDimension(v * (1 - t))}–${formatDimension(v * (1 + t))}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: Text('Tolerance', style: theme.textTheme.labelLarge),
            ),
            StatusPill(
              key: const Key('plot-tolerance-value'),
              label: '±$pct%',
              tone: StatusTone.info,
              dense: true,
            ),
          ],
        ),
        Slider(
          key: const Key('plot-tolerance'),
          value: pct.toDouble(),
          min: minTolerancePct.toDouble(),
          max: maxTolerancePct.toDouble(),
          divisions: (maxTolerancePct - minTolerancePct) ~/ 5,
          label: '±$pct%',
          onChanged: (v) => controller.tolerancePct = v.round(),
        ),
        AppCard(
          style: AppCardStyle.tonal,
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.crop_rotate_rounded, size: 18, color: scheme.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  size == null
                      ? 'Plots are matched in both orientations, so '
                          '30×40 also finds 40×30.'
                      : 'Matches ${range(size.$1)} × ${range(size.$2)} $unit, '
                          'and rotated plots (${formatDimension(size.$2)}×'
                          '${formatDimension(size.$1)} $unit) too.',
                  key: const Key('plot-rotation-note'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DimensionField extends StatelessWidget {
  const _DimensionField({
    required this.fieldKey,
    required this.controller,
    required this.label,
    required this.suffix,
    required this.error,
    required this.action,
    this.onSubmitted,
  });

  final Key fieldKey;
  final TextEditingController controller;
  final String label;
  final String suffix;
  final String? error;
  final TextInputAction action;
  final VoidCallback? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: fieldKey,
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: action,
      style: Theme.of(context).textTheme.titleMedium?.tabular,
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      onSubmitted: onSubmitted == null ? null : (_) => onSubmitted!(),
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        errorText: error,
        errorMaxLines: 2,
      ),
    );
  }
}
