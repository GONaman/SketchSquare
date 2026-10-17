import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/theme_mode_provider.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/presentation/auth_controller.dart';
import 'settings_list.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Sign out?'),
            content: const Text(
              'You will need to sign in again to buy or sell.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                key: const Key('confirm-sign-out'),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Sign out'),
              ),
            ],
          ),
    );
    if (ok ?? false) {
      await ref.read(authControllerProvider.notifier).signOut();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(appThemeModeProvider);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter,
          0,
          AppSpacing.gutter,
          AppSpacing.xl,
        ),
        children: [
          SettingsGroup(
            title: 'Appearance',
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Theme', style: theme.textTheme.titleSmall),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<ThemeMode>(
                        key: const Key('theme-toggle'),
                        segments: const [
                          ButtonSegment(
                            value: ThemeMode.system,
                            label: Text('System'),
                            icon: Icon(Icons.brightness_auto),
                          ),
                          ButtonSegment(
                            value: ThemeMode.light,
                            label: Text('Light'),
                            icon: Icon(Icons.light_mode_outlined),
                          ),
                          ButtonSegment(
                            value: ThemeMode.dark,
                            label: Text('Dark'),
                            icon: Icon(Icons.dark_mode_outlined),
                          ),
                        ],
                        selected: {mode},
                        onSelectionChanged:
                            (s) => ref
                                .read(appThemeModeProvider.notifier)
                                .set(s.first),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SettingsGroup(
            title: 'Legal',
            children: [
              SettingsTile(
                key: const Key('settings-terms'),
                icon: Icons.description_outlined,
                title: 'Terms of Service',
                onTap: () => context.push(AppRoutes.terms),
              ),
              SettingsTile(
                key: const Key('settings-privacy'),
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                onTap: () => context.push(AppRoutes.privacy),
              ),
            ],
          ),
          SettingsGroup(
            children: [
              SettingsTile(
                key: const Key('sign-out'),
                icon: Icons.logout_rounded,
                title: 'Sign out',
                destructive: true,
                showChevron: false,
                onTap: () => _confirmSignOut(context, ref),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
