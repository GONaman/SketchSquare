import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../providers.dart';

part 'theme_mode_provider.g.dart';

/// User-selected theme mode, persisted in SharedPreferences.
@Riverpod(keepAlive: true)
class AppThemeMode extends _$AppThemeMode {
  static const prefsKey = 'settings.theme_mode';

  @override
  ThemeMode build() {
    final stored = ref.watch(sharedPreferencesProvider).getString(prefsKey);
    return ThemeMode.values.firstWhere(
      (m) => m.name == stored,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await ref.read(sharedPreferencesProvider).setString(prefsKey, mode.name);
  }
}
