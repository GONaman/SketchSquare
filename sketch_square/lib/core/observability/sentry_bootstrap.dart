import 'dart:async';

import 'package:sentry_flutter/sentry_flutter.dart';

/// Crash reporting is off unless built with `--dart-define=SENTRY_DSN=...`.
abstract final class SentryConfig {
  static const dsn = String.fromEnvironment('SENTRY_DSN');
  static const environment = String.fromEnvironment(
    'SENTRY_ENVIRONMENT',
    defaultValue: 'development',
  );
  static const release = String.fromEnvironment('SENTRY_RELEASE');
}

typedef SentryInit =
    Future<void> Function(
      FutureOr<void> Function(SentryFlutterOptions) configure, {
      FutureOr<void> Function()? appRunner,
    });

/// Runs [appRunner] inside Sentry's error zone when [dsn] is set, otherwise
/// just runs it. [init] is injectable for tests.
Future<void> runWithSentry(
  Future<void> Function() appRunner, {
  String dsn = SentryConfig.dsn,
  SentryInit init = SentryFlutter.init,
}) async {
  if (dsn.isEmpty) {
    await appRunner();
    return;
  }
  await init((options) {
    options.dsn = dsn;
    options.environment = SentryConfig.environment;
    if (SentryConfig.release.isNotEmpty) options.release = SentryConfig.release;
    options.sendDefaultPii = false;
    options.tracesSampleRate = 0.1;
  }, appRunner: appRunner);
}
