import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/widgets/blueprint_empty_state.dart';
import '../../auth/domain/auth_state.dart';
import '../../auth/domain/user.dart';
import '../../auth/presentation/auth_controller.dart';

/// Placeholder body until Phase 6; already hosts the ADMIN entry and sign out.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final isAdmin = auth is Authenticated && auth.user.role == UserRole.admin;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Column(
        children: [
          const Expanded(
            child: BlueprintEmptyState(
              icon: Icons.person_outline,
              title: 'Profile',
              message: 'Your drawings, purchases and wallet.',
            ),
          ),
          if (isAdmin)
            ListTile(
              leading: const Icon(Icons.admin_panel_settings_outlined),
              title: const Text('Admin'),
              subtitle: const Text('Review architect verifications'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(AppRoutes.admin),
            ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign out'),
            onTap: () => ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      ),
    );
  }
}
