enum PasswordStrengthLevel { empty, weak, fair, good, strong }

/// Client-side hint only; the server decides what is acceptable
/// ([AuthValidators.minPasswordLength] is the only hard rule).
abstract final class PasswordStrength {
  static const minLength = 8;

  static PasswordStrengthLevel evaluate(String password) {
    if (password.isEmpty) return PasswordStrengthLevel.empty;
    if (password.length < minLength) return PasswordStrengthLevel.weak;

    var score = 0;
    if (password.length >= 12) score++;
    if (RegExp(r'[a-z]').hasMatch(password) &&
        RegExp(r'[A-Z]').hasMatch(password)) {
      score++;
    }
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(password)) score++;

    return switch (score) {
      0 => PasswordStrengthLevel.weak,
      1 => PasswordStrengthLevel.fair,
      2 || 3 => PasswordStrengthLevel.good,
      _ => PasswordStrengthLevel.strong,
    };
  }

  static String label(PasswordStrengthLevel level) => switch (level) {
    PasswordStrengthLevel.empty => '',
    PasswordStrengthLevel.weak => 'Weak',
    PasswordStrengthLevel.fair => 'Fair',
    PasswordStrengthLevel.good => 'Good',
    PasswordStrengthLevel.strong => 'Strong',
  };
}
