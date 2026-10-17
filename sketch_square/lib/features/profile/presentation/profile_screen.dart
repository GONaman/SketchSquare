import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/router/route_utils.dart';
import '../../../core/router/routes.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/domain/user.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/presentation/current_user_provider.dart';
import '../../notifications/presentation/notifications_controller.dart';
import '../../purchases/presentation/purchases_screen.dart';
import '../data/profile_providers.dart';
import 'settings_list.dart';

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
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.gutter,
                  AppSpacing.sm,
                  AppSpacing.gutter,
                  AppSpacing.xl,
                ),
                children: [
                  ProfileHeader(user: user),
                  const _StatsRow(),
                  const Padding(
                    padding: EdgeInsets.only(top: AppSpacing.lg),
                    child: FreeQuotaBanner(),
                  ),
                  SettingsGroup(
                    title: 'Your work',
                    children: [
                      SettingsTile(
                        key: const Key('tile-my-drawings'),
                        icon: Icons.architecture,
                        title: 'My drawings',
                        subtitle: 'Stats, prices, buyers and reviews',
                        onTap:
                            () => pushIfRegistered(
                              context,
                              AppRoutes.manageDrawings,
                            ),
                      ),
                      SettingsTile(
                        key: const Key('tile-purchases'),
                        icon: Icons.folder_open_outlined,
                        title: 'My purchases',
                        subtitle: 'Download and rate drawings you own',
                        onTap: () => context.push(AppRoutes.purchases),
                      ),
                      SettingsTile(
                        key: const Key('tile-favorites'),
                        icon: Icons.favorite_border_rounded,
                        title: 'Favorites',
                        subtitle: 'Drawings you saved',
                        onTap: () => context.push(AppRoutes.favorites),
                      ),
                    ],
                  ),
                  SettingsGroup(
                    title: 'Account',
                    children: [
                      SettingsTile(
                        key: const Key('tile-notifications'),
                        icon: Icons.notifications_none_rounded,
                        title: 'Notifications',
                        subtitle: 'Sales, reviews, payouts and approvals',
                        badgeCount: ref.watch(unreadNotificationCountProvider),
                        onTap: () => context.push(AppRoutes.notifications),
                      ),
                      SettingsTile(
                        key: const Key('tile-wallet'),
                        icon: Icons.account_balance_wallet_outlined,
                        title: 'Wallet',
                        subtitle: 'Balance, payouts and bank account',
                        onTap: () => context.push(AppRoutes.wallet),
                      ),
                      SettingsTile(
                        key: const Key('tile-edit'),
                        icon: Icons.edit_outlined,
                        title: 'Edit contact details',
                        onTap: () => context.push(AppRoutes.profileEdit),
                      ),
                      SettingsTile(
                        key: const Key('tile-settings'),
                        icon: Icons.settings_outlined,
                        title: 'Settings',
                        subtitle: 'Theme and legal',
                        onTap: () => context.push(AppRoutes.settings),
                      ),
                    ],
                  ),
                  if (user.role == UserRole.admin)
                    SettingsGroup(
                      title: 'Administration',
                      children: [
                        SettingsTile(
                          key: const Key('tile-admin'),
                          icon: Icons.admin_panel_settings_outlined,
                          title: 'Admin',
                          subtitle: 'Verifications, refunds and moderation',
                          onTap: () => context.push(AppRoutes.admin),
                        ),
                      ],
                    ),
                  SettingsGroup(
                    children: [
                      SettingsTile(
                        key: const Key('tile-sign-out'),
                        icon: Icons.logout_rounded,
                        title: 'Sign out',
                        destructive: true,
                        showChevron: false,
                        onTap:
                            () =>
                                ref
                                    .read(authControllerProvider.notifier)
                                    .signOut(),
                      ),
                    ],
                  ),
                ],
              ),
    );
  }
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
    return InkHeroCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Semantics(
                  label: 'Profile photo',
                  image: true,
                  excludeSemantics: true,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24, width: 3),
                    ),
                    child: AppAvatar(
                      key: const Key('profile-avatar'),
                      name: user.fullName,
                      url: user.avatarUrl,
                      size: 92,
                    ),
                  ),
                ),
                if (_uploading)
                  const Positioned.fill(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                Positioned(
                  right: -12,
                  bottom: -12,
                  child: IconButton.filledTonal(
                    key: const Key('change-avatar'),
                    tooltip: 'Change photo',
                    icon: const Icon(Icons.photo_camera_outlined, size: 18),
                    onPressed: _uploading ? null : _changeAvatar,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              user.fullName,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              user.email,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.place_outlined,
                  size: 16,
                  color: Colors.white70,
                ),
                const SizedBox(width: AppSpacing.xs),
                Flexible(
                  child: Text(
                    user.city,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
            if (user.verificationStatus == VerificationStatus.approved) ...[
              const SizedBox(height: AppSpacing.md),
              const StatusPill(
                label: 'Verified architect',
                tone: StatusTone.success,
                icon: Icons.verified_rounded,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Rating and drawing count. Shows nothing while loading or on error so the
/// profile never blocks on stats.
class _StatsRow extends ConsumerWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(profileStatsProvider).valueOrNull;
    if (stats == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: StatTile(
              key: const Key('stat-rating'),
              icon: Icons.star_rounded,
              label: 'Rating',
              value:
                  stats.ratingCount == 0
                      ? '—'
                      : '${stats.rating.toStringAsFixed(1)} ★',
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: StatTile(
              key: const Key('stat-reviews'),
              icon: Icons.rate_review_outlined,
              label: 'Reviews',
              value: '${stats.ratingCount}',
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: StatTile(
              key: const Key('stat-drawings'),
              icon: Icons.architecture,
              label: 'Drawings',
              value: stats.drawingsLabel,
            ),
          ),
        ],
      ),
    );
  }
}
