import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
class PlotSizeFields extends StatelessWidget {
  const PlotSizeFields({
    super.key,
    required this.controller,
    this.showTolerance = false,
    this.onSubmitted,
  });

  final PlotSizeController controller;
  final bool showTolerance;
  final VoidCallback? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final theme = Theme.of(context);
        final suffix = controller.unit.apiValue;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _DimensionField(
                    fieldKey: const Key('plot-length'),
                    controller: controller.lengthText,
                    label: 'Length',
                    suffix: suffix,
                    error: controller.lengthError,
                    action: TextInputAction.next,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(10, 16, 10, 0),
                  child: Icon(Icons.close, size: 18),
                ),
                Expanded(
                  child: _DimensionField(
                    fieldKey: const Key('plot-breadth'),
                    controller: controller.breadthText,
                    label: 'Breadth',
                    suffix: suffix,
                    error: controller.breadthError,
                    action: TextInputAction.done,
                    onSubmitted: onSubmitted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SegmentedButton<LengthUnit>(
              key: const Key('plot-unit'),
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: LengthUnit.ft, label: Text('Feet')),
                ButtonSegment(value: LengthUnit.m, label: Text('Metres')),
              ],
              selected: {controller.unit},
              onSelectionChanged: (s) => controller.unit = s.first,
            ),
            if (showTolerance) ...[
              const SizedBox(height: 12),
              Text(
                'Tolerance ±${controller.tolerancePct}%',
                style: theme.textTheme.labelLarge,
              ),
              Slider(
                key: const Key('plot-tolerance'),
                value: controller.tolerancePct.toDouble(),
                min: minTolerancePct.toDouble(),
                max: maxTolerancePct.toDouble(),
                divisions: (maxTolerancePct - minTolerancePct) ~/ 5,
                label: '±${controller.tolerancePct}%',
                onChanged: (v) => controller.tolerancePct = v.round(),
              ),
              Text(
                'Also matches the plot rotated (length and breadth swapped).',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        );
      },
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
