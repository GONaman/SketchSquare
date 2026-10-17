import 'package:flutter_test/flutter_test.dart';
import 'package:sketch_square/features/upload/domain/drawing_form.dart';
import 'package:sketch_square/features/upload/domain/drawing_form_validators.dart';
import 'package:sketch_square/features/upload/domain/money.dart';
import 'package:sketch_square/features/upload/domain/sheet_file_rules.dart';

DrawingForm validForm() => const DrawingForm(
  title: 'Modern 30x40 duplex',
  description: 'A two floor duplex with a central courtyard and parking.',
  categoryId: 'cat-1',
  city: 'Bengaluru',
  plotLength: 40,
  plotBreadth: 30,
  floors: 2,
  bedrooms: 3,
  isFree: false,
  pricePaise: 49900,
);

void main() {
  group('DrawingFormValidators', () {
    test('a complete form has no detail errors', () {
      expect(DrawingFormValidators.details(validForm()), isEmpty);
    });

    test('empty form flags every required field', () {
      final errors = DrawingFormValidators.details(const DrawingForm());
      expect(
        errors.keys,
        containsAll([
          'title',
          'description',
          'category',
          'city',
          'plotLength',
          'plotBreadth',
          'floors',
        ]),
      );
      expect(errors.containsKey('bedrooms'), isFalse);
    });

    test('title and description length bounds', () {
      expect(DrawingFormValidators.title('abcd'), isNotNull);
      expect(DrawingFormValidators.title('abcde'), isNull);
      expect(DrawingFormValidators.title('a' * 101), isNotNull);
      expect(DrawingFormValidators.description('too short'), isNotNull);
      expect(DrawingFormValidators.description('x' * 20), isNull);
    });

    test('plot dimensions are range-checked after unit conversion', () {
      expect(DrawingFormValidators.plotDimension(0, PlotUnit.ft), isNotNull);
      expect(DrawingFormValidators.plotDimension(4, PlotUnit.ft), isNotNull);
      // 1 m = 3.28 ft < 5 ft, but 2 m = 6.56 ft is fine.
      expect(DrawingFormValidators.plotDimension(1, PlotUnit.m), isNotNull);
      expect(DrawingFormValidators.plotDimension(2, PlotUnit.m), isNull);
      expect(DrawingFormValidators.plotDimension(2001, PlotUnit.ft), isNotNull);
      expect(DrawingFormValidators.plotDimension(null, PlotUnit.ft), isNotNull);
    });

    test('floors and bedrooms', () {
      expect(DrawingFormValidators.floors(0), isNotNull);
      expect(DrawingFormValidators.floors(21), isNotNull);
      expect(DrawingFormValidators.floors(3), isNull);
      expect(DrawingFormValidators.bedrooms(null), isNull);
      expect(DrawingFormValidators.bedrooms(0), isNull);
      expect(DrawingFormValidators.bedrooms(-1), isNotNull);
    });

    test('price is required unless free', () {
      expect(DrawingFormValidators.price(false, 0), isNotNull);
      expect(DrawingFormValidators.price(false, 99), isNotNull);
      expect(DrawingFormValidators.price(false, 100), isNull);
      expect(DrawingFormValidators.price(true, 0), isNull);
      expect(DrawingFormValidators.price(false, maxPricePaise + 1), isNotNull);
    });

    test('too many tags is an error', () {
      final f = validForm().copyWith(tags: List.generate(9, (i) => 'tag$i'));
      expect(DrawingFormValidators.details(f)['tags'], isNotNull);
    });
  });

  group('DrawingForm', () {
    test('area converts metres to square feet', () {
      final f = validForm().copyWith(
        unit: PlotUnit.m,
        plotLength: 10,
        plotBreadth: 10,
      );
      expect(f.plotAreaSqft, closeTo(1076.39, 0.01));
      expect(validForm().plotAreaSqft, 1200);
      expect(const DrawingForm().plotAreaSqft, isNull);
    });

    test('request body follows the contract; free forces price 0', () {
      final body = validForm().copyWith(isFree: true).toRequestJson();
      expect(body, {
        'title': 'Modern 30x40 duplex',
        'description':
            'A two floor duplex with a central courtyard and parking.',
        'categoryId': 'cat-1',
        'city': 'Bengaluru',
        'plotLength': 40.0,
        'plotBreadth': 30.0,
        'unit': 'ft',
        'floors': 2,
        'pricePaise': 0,
        'isFree': true,
      });
    });

    test('bedrooms/tags only sent when extended metadata is enabled', () {
      final f = validForm().copyWith(tags: ['modern']);
      expect(f.toRequestJson().containsKey('tags'), isFalse);
      final ext = f.toRequestJson(includeExtended: true);
      expect(ext['tags'], ['modern']);
      expect(ext['bedrooms'], 3);
    });

    test('survives a JSON round trip (local draft snapshot)', () {
      final f = validForm().copyWith(tags: ['a', 'b'], unit: PlotUnit.m);
      expect(DrawingForm.fromJson(f.toJson()), f);
    });
  });

  group('money', () {
    test('parseRupeesToPaise', () {
      expect(parseRupeesToPaise('499'), 49900);
      expect(parseRupeesToPaise('499.5'), 49950);
      expect(parseRupeesToPaise('1,299.05'), 129905);
      expect(parseRupeesToPaise(' 0 '), 0);
      expect(parseRupeesToPaise('1.234'), isNull);
      expect(parseRupeesToPaise('-5'), isNull);
      expect(parseRupeesToPaise('abc'), isNull);
      expect(parseRupeesToPaise(''), isNull);
    });

    test('sellerNetPaise deducts 10% fee, rounding the fee up', () {
      expect(sellerNetPaise(100000), 90000);
      expect(sellerNetPaise(12345), 12345 - 1235);
      expect(sellerNetPaise(0), 0);
    });

    test('formatting', () {
      expect(formatPaise(49900), '₹499');
      expect(formatPaise(49950), '₹499.50');
      expect(formatPaise(12345600), '₹1,23,456');
      expect(paiseToInput(49900), '499');
      expect(paiseToInput(49905), '499.05');
      expect(paiseToInput(0), '');
    });
  });

  group('SheetFileRules', () {
    test('accepts contract formats case-insensitively', () {
      for (final n in ['a.pdf', 'b.PNG', 'c.jpg', 'd.JPEG', 'e.dwg', 'f.dxf']) {
        expect(SheetFileRules.validate(n, 1024), isNull, reason: n);
      }
    });

    test('rejects unknown types, empty and oversize files', () {
      expect(SheetFileRules.validate('a.exe', 10), isNotNull);
      expect(SheetFileRules.validate('noext', 10), isNotNull);
      expect(SheetFileRules.validate('a.pdf', 0), isNotNull);
      expect(
        SheetFileRules.validate('a.pdf', SheetFileRules.maxBytes + 1),
        isNotNull,
      );
      expect(SheetFileRules.validate('a.pdf', SheetFileRules.maxBytes), isNull);
    });

    test('CAD files cannot be previews', () {
      expect(SheetFileRules.canBePreview('x.dwg'), isFalse);
      expect(SheetFileRules.canBePreview('x.DXF'), isFalse);
      expect(SheetFileRules.canBePreview('x.pdf'), isTrue);
      expect(SheetFileRules.contentTypeFor('x.jpeg'), 'image/jpeg');
    });
  });
}
