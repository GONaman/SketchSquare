import 'drawing_form.dart';
import 'money.dart';

/// Pure validators for the upload form; each returns a user-facing message or
/// null. Limits are client-side guard rails, the backend stays authoritative.
abstract final class DrawingFormValidators {
  static const titleMin = 5, titleMax = 100;
  static const descriptionMin = 20, descriptionMax = 2000;
  static const plotMinFt = 5.0, plotMaxFt = 2000.0;
  static const floorsMax = 20, bedroomsMax = 20;
  static const maxTags = 8, tagMaxLength = 24;

  static String? title(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return 'Enter a title';
    if (t.length < titleMin) {
      return 'Title must be at least $titleMin characters';
    }
    if (t.length > titleMax) {
      return 'Title must be at most $titleMax characters';
    }
    return null;
  }

  static String? description(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return 'Enter a description';
    if (t.length < descriptionMin) {
      return 'Describe the drawing in at least $descriptionMin characters';
    }
    if (t.length > descriptionMax) {
      return 'Description must be at most $descriptionMax characters';
    }
    return null;
  }

  static String? category(String? id) =>
      (id == null || id.isEmpty) ? 'Choose a category' : null;

  static String? city(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return 'Enter a city';
    if (t.length > 60) return 'City name is too long';
    return null;
  }

  static String? plotDimension(double? v, PlotUnit unit) {
    if (v == null) return 'Required';
    if (v <= 0) return 'Must be greater than 0';
    final ft = unit.toFeet(v);
    if (ft < plotMinFt) return 'Too small';
    if (ft > plotMaxFt) return 'Too large';
    return null;
  }

  static String? floors(int? v) {
    if (v == null) return 'Required';
    if (v < 1 || v > floorsMax) return '1 to $floorsMax';
    return null;
  }

  /// Bedrooms are optional (0 is valid, e.g. for banks or hotels).
  static String? bedrooms(int? v) {
    if (v == null) return null;
    if (v < 0 || v > bedroomsMax) return '0 to $bedroomsMax';
    return null;
  }

  static String? tag(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return 'Tag is empty';
    if (t.length > tagMaxLength) {
      return 'Tags are at most $tagMaxLength characters';
    }
    return null;
  }

  static String? price(bool isFree, int pricePaise) {
    if (isFree) return null;
    if (pricePaise < 100) return 'Enter a price of at least ₹1 or mark it free';
    if (pricePaise > maxPricePaise) return 'Price cannot exceed ₹10,00,000';
    return null;
  }

  /// Field-name → message for the details step (empty map = valid).
  static Map<String, String> details(DrawingForm f) => {
    if (title(f.title) case final e?) 'title': e,
    if (description(f.description) case final e?) 'description': e,
    if (category(f.categoryId) case final e?) 'category': e,
    if (city(f.city) case final e?) 'city': e,
    if (plotDimension(f.plotLength, f.unit) case final e?) 'plotLength': e,
    if (plotDimension(f.plotBreadth, f.unit) case final e?) 'plotBreadth': e,
    if (floors(f.floors) case final e?) 'floors': e,
    if (bedrooms(f.bedrooms) case final e?) 'bedrooms': e,
    if (f.tags.length > maxTags) 'tags': 'At most $maxTags tags',
  };

  static Map<String, String> pricing(DrawingForm f) => {
    if (price(f.isFree, f.pricePaise) case final e?) 'price': e,
  };

  static bool isDetailsValid(DrawingForm f) => details(f).isEmpty;
}
