import 'package:intl/intl.dart';

/// Platform commission shown in the pricing step. The backend applies the real
/// `PLATFORM_FEE_BPS` (default 1000 = 10%); this is only the on-screen estimate.
const platformFeeBps = 1000;

const maxPricePaise = 100000000; // ₹10,00,000

/// Parses a rupee string such as `499`, `499.5` or `1,299.00` into integer
/// paise without going through floating point. Returns null if invalid
/// (more than two decimals, negative, empty, non-numeric).
int? parseRupeesToPaise(String input) {
  final cleaned = input.trim().replaceAll(',', '');
  final match = RegExp(r'^(\d{1,9})(?:\.(\d{1,2}))?$').firstMatch(cleaned);
  if (match == null) return null;
  final rupees = int.parse(match.group(1)!);
  final decimals = (match.group(2) ?? '').padRight(2, '0');
  return rupees * 100 + int.parse(decimals);
}

/// Amount the seller receives after the platform fee (integer paise, the fee
/// is rounded up so the estimate is never optimistic).
int sellerNetPaise(int pricePaise, {int feeBps = platformFeeBps}) {
  final fee = (pricePaise * feeBps + 9999) ~/ 10000;
  return pricePaise - fee;
}

final _rupees = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 2,
);
final _rupeesWhole = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 0,
);

String formatPaise(int paise) =>
    paise % 100 == 0
        ? _rupeesWhole.format(paise ~/ 100)
        : _rupees.format(paise / 100);

/// Paise as an editable rupee string for a text field ("499" / "499.50").
String paiseToInput(int paise) {
  if (paise <= 0) return '';
  final r = paise ~/ 100, p = paise % 100;
  return p == 0 ? '$r' : '$r.${p.toString().padLeft(2, '0')}';
}
