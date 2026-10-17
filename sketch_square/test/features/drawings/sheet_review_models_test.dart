import 'package:flutter_test/flutter_test.dart';
import 'package:sketch_square/features/drawings/domain/review.dart';
import 'package:sketch_square/features/drawings/domain/sheet.dart';

void main() {
  test('Sheet parses contract JSON', () {
    final sheet = Sheet.fromJson({
      'id': 's1',
      'type': 'STRUCTURAL',
      'isPreview': true,
      'previewUrl': 'https://cdn/p.png',
      'originalMime': 'application/pdf',
      'fileName': 'plan.pdf',
      'sizeBytes': 1024,
    });
    expect(sheet.type, SheetType.structural);
    expect(sheet.isPreview, isTrue);
    expect(sheet.previewUrl, 'https://cdn/p.png');
    expect(sheet.toJson()['type'], 'STRUCTURAL');
  });

  test('Review parses contract JSON with null comment', () {
    final review = Review.fromJson({
      'id': 'r1',
      'rating': 4,
      'comment': null,
      'reviewer': {'id': 'u1', 'fullName': 'Asha Rao'},
      'createdAt': '2026-01-01T00:00:00.000Z',
      'updatedAt': '2026-01-02T00:00:00.000Z',
    });
    expect(review.rating, 4);
    expect(review.comment, isNull);
    expect(review.reviewer.fullName, 'Asha Rao');
    expect(review.updatedAt.day, 2);
  });
}
