import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sketch_square/core/network/connectivity_status.dart';
import 'package:sketch_square/core/network/dio_client.dart';
import 'package:sketch_square/core/providers.dart';
import 'package:sketch_square/core/storage/secure_storage.dart';
import 'package:sketch_square/core/storage/token_store.dart';
import 'package:sketch_square/core/theme/theme_mode_provider.dart';
import 'package:sketch_square/core/widgets/offline_banner.dart';

import '../helpers/scripted_adapter.dart';

void main() {
  group('theme mode persistence', () {
    test('defaults to system and restores the stored choice', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      ProviderContainer make() => ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );

      final first = make();
      addTearDown(first.dispose);
      expect(first.read(appThemeModeProvider), ThemeMode.system);
      await first.read(appThemeModeProvider.notifier).set(ThemeMode.dark);
      expect(first.read(appThemeModeProvider), ThemeMode.dark);

      final second = make();
      addTearDown(second.dispose);
      expect(second.read(appThemeModeProvider), ThemeMode.dark);
    });

    test('ignores an unknown stored value', () async {
      SharedPreferences.setMockInitialValues({AppThemeMode.prefsKey: 'sepia'});
      final prefs = await SharedPreferences.getInstance();
      final c = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(c.dispose);
      expect(c.read(appThemeModeProvider), ThemeMode.system);
    });
  });

  group('ConnectivityInterceptor', () {
    Dio dioWith(AdapterHandler handler, List<bool> events) => createDio(
      tokenStore: SecureTokenStore(InMemorySecureStorage()),
      baseUrl: 'http://test',
      httpClientAdapter: ScriptedAdapter(handler),
      onConnectivityChanged: events.add,
    );

    test(
      'connection failure reports offline, a response reports online',
      () async {
        final events = <bool>[];
        var fail = true;
        final dio = dioWith((o) {
          if (fail) {
            throw DioException(
              requestOptions: o,
              type: DioExceptionType.connectionError,
            );
          }
          return jsonResponse({'ok': true});
        }, events);

        await expectLater(dio.get<Object?>('/x'), throwsA(isA<DioException>()));
        expect(events, [false]);

        fail = false;
        await dio.get<Object?>('/x');
        expect(events, [false, true]);
      },
    );

    test('a server error status still means the API is reachable', () async {
      final events = <bool>[];
      final dio = dioWith(
        (o) => jsonResponse({
          'error': {'code': 'INTERNAL', 'message': 'boom'},
        }, 500),
        events,
      );
      await expectLater(dio.get<Object?>('/x'), throwsA(isA<DioException>()));
      expect(events, [true]);
    });
  });

  group('OfflineBanner', () {
    testWidgets('shows while offline, hides after a successful probe', (
      tester,
    ) async {
      var reachable = false;
      final adapter = ScriptedAdapter((o) {
        if (!reachable) {
          throw DioException(
            requestOptions: o,
            type: DioExceptionType.connectionError,
          );
        }
        return jsonResponse({'status': 'ok'});
      });
      final dio = Dio(BaseOptions(baseUrl: 'http://test'))
        ..httpClientAdapter = adapter;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [dioProvider.overrideWithValue(dio)],
          child: const MaterialApp(
            home: OfflineBanner(child: Scaffold(body: Text('content'))),
          ),
        ),
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(OfflineBanner)),
      );
      expect(find.textContaining('No connection'), findsNothing);

      container.read(connectivityStatusProvider.notifier).reportOffline();
      await tester.pump();
      expect(find.textContaining('No connection'), findsOneWidget);
      expect(find.text('content'), findsOneWidget);

      // Still unreachable: banner stays after the periodic probe.
      await tester.pump(ConnectivityStatus.probeInterval);
      expect(find.textContaining('No connection'), findsOneWidget);

      reachable = true;
      await tester.pump(ConnectivityStatus.probeInterval);
      await tester.pump();
      expect(find.textContaining('No connection'), findsNothing);
      expect(find.text('content'), findsOneWidget);
    });
  });
}
