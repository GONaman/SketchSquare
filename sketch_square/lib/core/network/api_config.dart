abstract final class ApiConfig {
  /// Override with `--dart-define=API_BASE_URL=...`. The default targets the
  /// host machine from the Android emulator (iOS simulator: http://localhost:3000).
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );
}
