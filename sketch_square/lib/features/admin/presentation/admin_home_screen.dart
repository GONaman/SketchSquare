import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/widgets/widgets.dart';
import '../../profile/presentation/settings_list.dart';
import 'admin_providers.dart';
import 'plagiarism_providers.dart';

const adminVerificationsPath = '${AppRoutes.admin}/verifications';
const adminPlagiarismPath = '${AppRoutes.admin}/plagiarism';
const adminRefundsPath = '${AppRoutes.admin}/refunds';

/// ADMIN only: dashboard with the size of each review queue.
class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  Future<void> _open(BuildContext context, WidgetRef ref, String path) async {
    await context.push<void>(path);
    ref.invalidate(pendingVerificationsProvider);
    ref.invalidate(pendingPlagiarismCountProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final verifications = ref.watch(pendingVerificationsProvider);
    final plagiarism = ref.watch(pendingPlagiarismCountProvider);
    final vCount = verifications.valueOrNull;
    final pCount = plagiarism.valueOrNull;
    final vNumber = vCount?.items.length;
    final pNumber = pCount?.count;
    final vLabel =
        vCount == null
            ? '–'
            : '${vCount.items.length}${vCount.hasMore ? '+' : ''}';
    final pLabel =
        pCount == null ? '–' : '${pCount.count}${pCount.more ? '+' : ''}';
    final loading = verifications.isLoading || plagiarism.isLoading;
    final total = (vNumber ?? 0) + (pNumber ?? 0);
    final sem = AppSemanticColors.of(context);
    final theme = Theme.of(context);

    Future<void> refresh() async {
      ref.invalidate(pendingVerificationsProvider);
      ref.invalidate(pendingPlagiarismCountProvider);
      await Future.wait([
        ref.read(pendingVerificationsProvider.future),
        ref.read(pendingPlagiarismCountProvider.future),
      ]).then((_) {}, onError: (_) {});
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Administration')),
      body: RefreshIndicator(
        onRefresh: refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            AppSpacing.sm,
            AppSpacing.gutter,
            AppSpacing.xxl,
          ),
          children: [
            InkHeroCard(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'REVIEW QUEUE',
                          style: theme.textTheme.labelSmall?.copyWith(
                            letterSpacing: 1.2,
                            color: sem.onInk.withValues(alpha: 0.72),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          loading
                              ? 'Checking queues…'
                              : total == 0
                              ? 'All caught up'
                              : '$total waiting for review',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: sem.onInk,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Verifications and plagiarism flags need a decision.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: sem.onInk.withValues(alpha: 0.72),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Icon(
                    total == 0 && !loading
                        ? Icons.verified_outlined
                        : Icons.admin_panel_settings_outlined,
                    size: 44,
                    color: sem.onInk.withValues(alpha: 0.9),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: StatTile(
                      key: const Key('stat-verifications'),
                      icon: Icons.badge_outlined,
                      value: vLabel,
                      label: 'Verifications',
                      onTap: () => _open(context, ref, adminVerificationsPath),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: StatTile(
                      key: const Key('stat-plagiarism'),
                      icon: Icons.fact_check_outlined,
                      value: pLabel,
                      label: 'Plagiarism flags',
                      onTap: () => _open(context, ref, adminPlagiarismPath),
                    ),
                  ),
                ],
              ),
            ),
            SettingsGroup(
              title: 'Queues and tools',
              children: [
                SettingsTile(
                  key: const Key('open-verifications'),
                  icon: Icons.badge_outlined,
                  title: 'Pending verifications',
                  subtitle: 'Review architect COA documents',
                  badgeCount: vNumber ?? 0,
                  onTap: () => _open(context, ref, adminVerificationsPath),
                ),
                SettingsTile(
                  key: const Key('open-plagiarism'),
                  icon: Icons.fact_check_outlined,
                  title: 'Plagiarism review',
                  subtitle: 'Compare held uploads with existing drawings',
                  badgeCount: pNumber ?? 0,
                  onTap: () => _open(context, ref, adminPlagiarismPath),
                ),
                SettingsTile(
                  key: const Key('open-refunds'),
                  icon: Icons.receipt_long_outlined,
                  title: 'Refunds',
                  subtitle: 'Search purchases and refund a buyer',
                  onTap: () => _open(context, ref, adminRefundsPath),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
