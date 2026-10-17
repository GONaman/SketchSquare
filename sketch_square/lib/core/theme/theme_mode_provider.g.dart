// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_mode_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$appThemeModeHash() => r'329e73c2882e34d679000b8c352d178fa86ecd73';

/// User-selected theme mode, persisted in SharedPreferences.
///
/// Copied from [AppThemeMode].
@ProviderFor(AppThemeMode)
final appThemeModeProvider = NotifierProvider<AppThemeMode, ThemeMode>.internal(
  AppThemeMode.new,
  name: r'appThemeModeProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$appThemeModeHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AppThemeMode = Notifier<ThemeMode>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
