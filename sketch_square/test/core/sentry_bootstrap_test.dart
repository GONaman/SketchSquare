import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sketch_square/core/observability/sentry_bootstrap.dart';

void main() {
  test('without a DSN Sentry is never initialised', () async {
    var initCalled = false;
    var ran = false;
    await runWithSentry(
      () async => ran = true,
      dsn: '',
      init: (configure, {appRunner}) async => initCalled = true,
    );
    expect(ran, isTrue);
    expect(initCalled, isFalse);
  });

  test('with a DSN the app runs inside Sentry init, PII off', () async {
    var ran = false;
    String? seenDsn;
    bool? seenPii;
    await runWithSentry(
      () async => ran = true,
      dsn: 'https://key@example.ingest.sentry.io/1',
      init: (configure, {appRunner}) async {
        final options = SentryFlutterOptions();
        await configure(options);
        seenDsn = options.dsn;
        seenPii = options.sendDefaultPii;
        await appRunner?.call();
      },
    );
    expect(ran, isTrue);
    expect(seenDsn, 'https://key@example.ingest.sentry.io/1');
    expect(seenPii, isFalse);
  });
}
