import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/router/route_utils.dart';
import '../../../core/router/routes.dart';
import '../../auth/domain/user.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/presentation/current_user_provider.dart';
import '../../purchases/presentation/purchases_screen.dart';
import '../data/profile_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body:
          user == null
              ? const SizedBox.shrink()
              : ListView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                children: [
                  ProfileHeader(user: user),
                  const SizedBox(height: 16),
                  const _StatsRow(),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: FreeQuotaBanner(),
                  ),
                  const Divider(),
                  _NavTile(
                    key: const Key('tile-my-drawings'),
                    icon: Icons.architecture,
                    title: 'My drawings',
                    subtitle: 'Stats, prices, buyers and reviews',
                    onTap:
                        () =>
                            pushIfRegistered(context, AppRoutes.manageDrawings),
                  ),
                  _NavTile(
                    key: const Key('tile-purchases'),
                    icon: Icons.folder_open_outlined,
                    title: 'My purchases',
                    subtitle: 'Download and rate drawings you own',
                    onTap: () => context.push(AppRoutes.purchases),
                  ),
                  _NavTile(
                    key: const Key('tile-favorites'),
                    icon: Icons.favorite_border,
                    title: 'Favorites',
                    subtitle: 'Drawings you saved',
                    onTap: () => context.push(AppRoutes.favorites),
                  ),
                  _NavTile(
                    key: const Key('tile-wallet'),
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Wallet',
                    subtitle: 'Balance, payouts and bank account',
                    onTap: () => context.push(AppRoutes.wallet),
                  ),
                  _NavTile(
                    key: const Key('tile-edit'),
                    icon: Icons.edit_outlined,
                    title: 'Edit contact details',
                    onTap: () => context.push(AppRoutes.profileEdit),
                  ),
                  _NavTile(
                    key: const Key('tile-settings'),
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    subtitle: 'Theme and sign out',
                    onTap: () => context.push(AppRoutes.settings),
                  ),
                  if (user.role == UserRole.admin)
                    _NavTile(
                      key: const Key('tile-admin'),
                      icon: Icons.admin_panel_settings_outlined,
                      title: 'Admin',
                      onTap: () => context.push(AppRoutes.admin),
                    ),
                  _NavTile(
                    key: const Key('tile-sign-out'),
                    icon: Icons.logout,
                    title: 'Sign out',
                    onTap:
                        () =>
                            ref.read(authControllerProvider.notifier).signOut(),
                  ),
                ],
              ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon),
    title: Text(title),
    subtitle: subtitle == null ? null : Text(subtitle!),
    trailing: const Icon(Icons.chevron_right),
    onTap: onTap,
  );
}

class ProfileHeader extends ConsumerStatefulWidget {
  const ProfileHeader({super.key, required this.user});

  final User user;

  @override
  ConsumerState<ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends ConsumerState<ProfileHeader> {
  bool _uploading = false;

  Future<void> _changeAvatar() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _uploading = true);
    try {
      final image = await ref.read(avatarPickerProvider).pick();
      if (image == null) return;
      await ref.read(profileRepositoryProvider).uploadAvatar(image);
      await ref.read(authControllerProvider.notifier).refreshUser();
      messenger.showSnackBar(const SnackBar(content: Text('Photo updated')));
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(toApiException(e).message)),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final theme = Theme.of(context);
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Semantics(
              label: 'Profile photo',
              image: true,
              excludeSemantics: true,
              child: CircleAvatar(
                key: const Key('profile-avatar'),
                radius: 48,
                backgroundImage:
                    user.avatarUrl == null
                        ? null
                        : CachedNetworkImageProvider(user.avatarUrl!),
                onBackgroundImageError:
                    user.avatarUrl == null ? null : (_, __) {},
                child: Text(
                  _initials(user.fullName),
                  style: theme.textTheme.headlineMedium,
                ),
              ),
            ),
            if (_uploading)
              const Positioned.fill(
                child: Center(child: CircularProgressIndicator()),
              ),
            IconButton.filledTonal(
              key: const Key('change-avatar'),
              tooltip: 'Change photo',
              icon: const Icon(Icons.photo_camera_outlined, size: 18),
              onPressed: _uploading ? null : _changeAvatar,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(user.fullName, style: theme.textTheme.titleLarge),
        Text(user.email, style: theme.textTheme.bodySmall),
        Text(user.city, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 8),
        if (user.verificationStatus == VerificationStatus.approved)
          const Chip(
            avatar: Icon(Icons.verified, size: 18),
            label: Text('Verified architect'),
          ),
      ],
    );
  }
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
  return parts.take(2).map((p) => p[0].toUpperCase()).join();
}

/// Rating and drawing count. Shows nothing while loading or on error so the
/// profile never blocks on stats.
class _StatsRow extends ConsumerWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(profileStatsProvider).valueOrNull;
    if (stats == null) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _Stat(
          key: const Key('stat-rating'),
          label: 'Rating',
          value:
              stats.ratingCount == 0
                  ? '—'
                  : '${stats.rating.toStringAsFixed(1)} ★',
        ),
        _Stat(
          key: const Key('stat-reviews'),
          label: 'Reviews',
          value: '${stats.ratingCount}',
        ),
        _Stat(
          key: const Key('stat-drawings'),
          label: 'Drawings',
          value: stats.drawingsLabel,
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({super.key, required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(value, style: theme.textTheme.titleMedium),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}
