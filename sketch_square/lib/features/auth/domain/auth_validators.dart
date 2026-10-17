/// Form validators for the auth screens. Each returns an error message or null,
/// so they plug straight into `TextFormField.validator`.
abstract final class AuthValidators {
  static const minPasswordLength = 8;

  static final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');
  static final _phone = RegExp(r'^\+?[0-9]{10,14}$');
  static final _coa = RegExp(r'^[A-Za-z0-9][A-Za-z0-9/\-]{3,29}$');

  static String? email(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'Enter your email';
    return _email.hasMatch(s) ? null : 'Enter a valid email address';
  }

  static String? password(String? v) {
    final s = v ?? '';
    if (s.isEmpty) return 'Enter a password';
    return s.length >= minPasswordLength
        ? null
        : 'Use at least $minPasswordLength characters';
  }

  /// Sign-in only checks presence; the server decides if it is correct.
  static String? requiredPassword(String? v) =>
      (v ?? '').isEmpty ? 'Enter your password' : null;

  static String? Function(String?) confirmPassword(String Function() other) =>
      (v) => v == other() ? null : 'Passwords do not match';

  static String? fullName(String? v) {
    final s = v?.trim() ?? '';
    if (s.length < 2) return 'Enter your full name';
    return null;
  }

  static String? phone(String? v) {
    final s = (v ?? '').replaceAll(RegExp(r'[\s\-()]'), '');
    if (s.isEmpty) return 'Enter your phone number';
    return _phone.hasMatch(s) ? null : 'Enter a valid phone number';
  }

  /// Removes spaces and dashes before sending to the API.
  static String normalizePhone(String v) =>
      v.replaceAll(RegExp(r'[\s\-()]'), '');

  static String? address(String? v) {
    final s = v?.trim() ?? '';
    return s.length < 5 ? 'Enter your full address' : null;
  }

  static String? city(String? v) {
    final s = v?.trim() ?? '';
    return s.length < 2 ? 'Enter your city' : null;
  }

  static String? resetToken(String? v) =>
      (v?.trim().isEmpty ?? true) ? 'Enter the code from your email' : null;

  /// Council of Architecture registration number, e.g. `CA/2015/12345`.
  static String? coaNumber(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'Enter your COA registration number';
    return _coa.hasMatch(s)
        ? null
        : 'Use 4–30 letters, digits, "/" or "-" (e.g. CA/2015/12345)';
  }
}
