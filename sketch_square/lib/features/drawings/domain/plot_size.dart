/// Unit the user types plot dimensions in. The API stores feet; `unit` is sent
/// with `length`/`breadth` and converted server-side.
enum LengthUnit {
  ft('ft', 1),
  m('m', 3.280839895);

  const LengthUnit(this.apiValue, this.feetPerUnit);

  final String apiValue;
  final double feetPerUnit;

  double toFeet(double value) => value * feetPerUnit;

  static LengthUnit fromApi(String? value) => LengthUnit.values.firstWhere(
    (u) => u.apiValue == value,
    orElse: () => ft,
  );
}

/// Accepted plot dimension range, expressed in feet.
const double minPlotDimensionFt = 5;
const double maxPlotDimensionFt = 1000;

/// Result of validating the two plot-size text fields.
class PlotSizeValidation {
  const PlotSizeValidation({
    this.length,
    this.breadth,
    this.lengthError,
    this.breadthError,
  });

  final double? length;
  final double? breadth;
  final String? lengthError;
  final String? breadthError;

  bool get isValid => lengthError == null && breadthError == null;

  /// Valid and both numbers present.
  bool get hasSize => isValid && length != null && breadth != null;
}

/// Validates plot size input. With [allowEmpty] both fields may be blank (no
/// size filter); otherwise both are required. Entering only one is always an error.
PlotSizeValidation validatePlotSize({
  required String lengthText,
  required String breadthText,
  required LengthUnit unit,
  bool allowEmpty = false,
}) {
  final bothBlank = lengthText.trim().isEmpty && breadthText.trim().isEmpty;
  if (bothBlank && allowEmpty) return const PlotSizeValidation();

  final (length, lengthError) = _parseDimension('Length', lengthText, unit);
  final (breadth, breadthError) = _parseDimension('Breadth', breadthText, unit);
  return PlotSizeValidation(
    length: lengthError == null ? length : null,
    breadth: breadthError == null ? breadth : null,
    lengthError: lengthError,
    breadthError: breadthError,
  );
}

(double?, String?) _parseDimension(String label, String text, LengthUnit unit) {
  final trimmed = text.trim().replaceAll(',', '.');
  if (trimmed.isEmpty) return (null, '$label is required');
  final value = double.tryParse(trimmed);
  if (value == null || value.isNaN || value.isInfinite) {
    return (null, 'Enter a valid number');
  }
  if (value <= 0) return (null, '$label must be greater than 0');
  final ft = unit.toFeet(value);
  if (ft < minPlotDimensionFt) return (null, '$label is too small');
  if (ft > maxPlotDimensionFt) return (null, '$label is too large');
  return (value, null);
}

/// `30` for whole numbers, `32.5` otherwise.
String formatDimension(double value) {
  final rounded = (value * 10).round() / 10;
  return rounded == rounded.roundToDouble()
      ? rounded.toInt().toString()
      : rounded.toString();
}
