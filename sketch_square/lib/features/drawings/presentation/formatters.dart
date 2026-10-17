import 'package:intl/intl.dart';

import '../domain/drawing_summary.dart';
import '../domain/plot_size.dart';

final _rupees = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 0,
);
final _rupeesWithPaise = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 2,
);

/// Integer paise -> `₹1,499` (or `₹1,499.50` when there are paise).
String formatPaise(int paise) =>
    paise % 100 == 0
        ? _rupees.format(paise ~/ 100)
        : _rupeesWithPaise.format(paise / 100);

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
