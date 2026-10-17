import 'package:flutter_test/flutter_test.dart';
import 'package:sketch_square/features/drawings/domain/plot_size.dart';

PlotSizeValidation check(
  String l,
  String b, {
  LengthUnit unit = LengthUnit.ft,
  bool allowEmpty = false,
}) => validatePlotSize(
  lengthText: l,
  breadthText: b,
  unit: unit,
  allowEmpty: allowEmpty,
);

void main() {
  group('validatePlotSize', () {
    test('accepts valid numbers, decimals and decimal commas', () {
      final v = check('40', '30,5');
      expect(v.isValid, isTrue);
      expect(v.hasSize, isTrue);
      expect(v.length, 40);
      expect(v.breadth, 30.5);
    });

    test('requires both fields unless empty is allowed', () {
      final v = check('', '');
      expect(v.lengthError, 'Length is required');
      expect(v.breadthError, 'Breadth is required');
      expect(check('', '', allowEmpty: true).isValid, isTrue);
      expect(check('', '', allowEmpty: true).hasSize, isFalse);
    });

    test('one filled field is an error even when empty is allowed', () {
      final v = check('40', '', allowEmpty: true);
      expect(v.isValid, isFalse);
      expect(v.length, 40);
      expect(v.breadthError, 'Breadth is required');
    });

    test('rejects non-numbers, zero and negatives', () {
      expect(check('abc', '30').lengthError, 'Enter a valid number');
      expect(check('40', '0').breadthError, 'Breadth must be greater than 0');
      expect(check('-5', '30').lengthError, 'Length must be greater than 0');
      expect(check('NaN', '30').isValid, isFalse);
      expect(check('Infinity', '30').isValid, isFalse);
    });

    test('enforces bounds in feet after unit conversion', () {
      expect(check('4', '30').lengthError, 'Length is too small');
      expect(check('5', '30').isValid, isTrue);
      expect(check('1001', '30').lengthError, 'Length is too large');
      // 1 m ≈ 3.28 ft is too small, 100 m ≈ 328 ft is fine, 400 m ≈ 1312 ft is too large.
      expect(check('1', '10', unit: LengthUnit.m).lengthError, isNotNull);
      expect(check('100', '10', unit: LengthUnit.m).isValid, isTrue);
      expect(check('400', '10', unit: LengthUnit.m).lengthError, isNotNull);
    });
  });

  test('formatDimension trims trailing zeros', () {
    expect(formatDimension(30), '30');
    expect(formatDimension(30.0), '30');
    expect(formatDimension(32.5), '32.5');
    expect(formatDimension(32.54), '32.5');
  });

  test('LengthUnit.fromApi falls back to feet', () {
    expect(LengthUnit.fromApi('m'), LengthUnit.m);
    expect(LengthUnit.fromApi('yd'), LengthUnit.ft);
    expect(LengthUnit.fromApi(null), LengthUnit.ft);
  });
}
