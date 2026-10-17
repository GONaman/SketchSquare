import 'package:intl/intl.dart';

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

/// Integer paise -> `₹1,499` (or `₹1,499.50` when there are paise), using
/// Indian digit grouping (`₹1,24,999`). The single price formatter for the app.
String formatPaise(int paise) =>
    paise % 100 == 0
        ? _rupees.format(paise ~/ 100)
        : _rupeesWithPaise.format(paise / 100);

/// Compact price for tight spaces: `₹999`, `₹12.5K`, `₹1.2L`, `₹2.4Cr`.
String formatPaiseCompact(int paise) {
  final rupees = paise / 100;
  String trim(double v) =>
      v.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '');
  if (rupees >= 10000000) return '₹${trim(rupees / 10000000)}Cr';
  if (rupees >= 100000) return '₹${trim(rupees / 100000)}L';
  if (rupees >= 10000) return '₹${trim(rupees / 1000)}K';
  return formatPaise(paise);
}
