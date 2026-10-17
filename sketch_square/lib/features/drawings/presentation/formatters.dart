import 'package:intl/intl.dart';

import '../domain/drawing_summary.dart';
import '../domain/plot_size.dart';

export '../../../core/format/price.dart' show formatPaise;

/// `40×30.5 ft`
String formatPlotSize(DrawingSummary d) =>
    '${formatDimension(d.plotLengthFt)}×${formatDimension(d.plotBreadthFt)} ft';

String formatArea(double sqft) =>
    '${NumberFormat.decimalPattern('en_IN').format(sqft.round())} sq ft';

String formatRating(double rating) => rating.toStringAsFixed(1);

/// `Exact match`, `92% match`.
String formatSizeMatch(double match) {
  final pct = (match * 100).round();
  return pct >= 100 ? 'Exact match' : '$pct% match';
}
