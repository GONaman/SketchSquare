import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/providers.dart';

part 'intro_seen_provider.g.dart';

/// Whether the onboarding video has been dealt with (watched, skipped, or the
/// user signed in) on this device. Drives where logged-out users land.
@Riverpod(keepAlive: true)
class IntroSeen extends _$IntroSeen {
  static const prefsKey = 'onboarding.intro_seen';

  @override
  bool build() =>
      ref.watch(sharedPreferencesProvider).getBool(prefsKey) ?? false;

  Future<void> markSeen() async {
    if (state) return;
    state = true;
    await ref.read(sharedPreferencesProvider).setBool(prefsKey, true);
  }
}
