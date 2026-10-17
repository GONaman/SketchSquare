import 'package:freezed_annotation/freezed_annotation.dart';

part 'drawing_form.freezed.dart';
part 'drawing_form.g.dart';

@JsonEnum(alwaysCreate: true)
enum PlotUnit {
  @JsonValue('ft')
  ft('ft'),
  @JsonValue('m')
  m('m');

  const PlotUnit(this.label);
  final String label;

  static const metresToFeet = 3.28084;

  double toFeet(double value) => this == ft ? value : value * metresToFeet;
}

const facingOptions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];

/// Everything the seller types into the upload form. Persisted locally as the
/// resume-safe draft snapshot and mapped to the `POST/PATCH /drawings` body.
@freezed
abstract class DrawingForm with _$DrawingForm {
  const DrawingForm._();

  const factory DrawingForm({
    @Default('') String title,
    @Default('') String description,
    String? categoryId,
    @Default('') String city,
    double? plotLength,
    double? plotBreadth,
    @Default(PlotUnit.ft) PlotUnit unit,
    int? floors,
    int? bedrooms,
    String? facing,
    @Default(<String>[]) List<String> tags,
    @Default(false) bool isFree,
    // Integer paise; 0 while unset. Ignored when [isFree].
    @Default(0) int pricePaise,
  }) = _DrawingForm;

  factory DrawingForm.fromJson(Map<String, dynamic> json) =>
      _$DrawingFormFromJson(json);

  double? get plotAreaSqft {
    final l = plotLength, b = plotBreadth;
    if (l == null || b == null || l <= 0 || b <= 0) return null;
    return unit.toFeet(l) * unit.toFeet(b);
  }

  /// Body for `POST /drawings` / `PATCH /drawings/:id`.
  ///
  /// `bedrooms` and `tags` are contract extensions (see docs/API_CONTRACT.md)
  /// and are only sent when [includeExtended] is true.
  Map<String, dynamic> toRequestJson({bool includeExtended = false}) => {
    'title': title.trim(),
    'description': description.trim(),
    'categoryId': categoryId,
    'city': city.trim(),
    'plotLength': plotLength,
    'plotBreadth': plotBreadth,
    'unit': unit.label,
    'floors': floors,
    if (facing != null) 'facing': facing,
    'pricePaise': isFree ? 0 : pricePaise,
    'isFree': isFree,
    if (includeExtended) ...{
      if (bedrooms != null) 'bedrooms': bedrooms,
      'tags': tags,
    },
  };
}
