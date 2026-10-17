import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/widgets/widgets.dart';
import 'upload_flow_controller.dart';
import 'upload_flow_state.dart';
import 'widgets/details_step.dart';
import 'widgets/form_widgets.dart';
import 'widgets/pricing_step.dart';
import 'widgets/publish_status_view.dart';
import 'widgets/review_step.dart';
import 'widgets/sheets_step.dart';

/// Multi-step upload flow (details → sheets → pricing → review & publish).
/// [draftId] resumes a specific server draft (e.g. from Manage drawings).
class UploadScreen extends ConsumerStatefulWidget {
  const UploadScreen({super.key, this.draftId});

  final String? draftId;

  @override
  ConsumerState<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends ConsumerState<UploadScreen> {
  // Bumped whenever the flow is reloaded so text fields re-seed from state.
  int _epoch = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  @override
  void didUpdateWidget(UploadScreen old) {
    super.didUpdateWidget(old);
    if (old.draftId != widget.draftId) Future.microtask(_load);
  }

  Future<void> _load() async {
    if (!mounted) return;
    await ref
        .read(uploadFlowProvider.notifier)
        .ensureLoaded(resumeDraftId: widget.draftId);
    if (mounted) setState(() => _epoch++);
  }

  Future<void> _startNew() async {
    await ref.read(uploadFlowProvider.notifier).startNew();
    if (mounted) setState(() => _epoch++);
  }

  Future<void> _saveDraft() async {
    final result = await ref.read(uploadFlowProvider.notifier).saveDraft();
    if (!mounted) return;
    final message = switch (result) {
      DraftSaveResult.synced => 'Draft saved',
      DraftSaveResult.localOnly =>
        'Saved on this device. Complete the details to sync it.',
      DraftSaveResult.failed => null,
    };
    if (message != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(uploadFlowProvider);
    final c = ref.read(uploadFlowProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload'),
        actions: [
          if (s.loaded)
            IconButton(
              key: const ValueKey('open-manage'),
              tooltip: 'Manage drawings',
              icon: const Icon(Icons.inventory_2_outlined),
              onPressed: () => context.push(AppRoutes.manageDrawings),
            ),
          if (s.loaded && !s.locked)
            TextButton.icon(
              key: const ValueKey('save-draft'),
              onPressed: s.saving ? null : _saveDraft,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save draft'),
            ),
        ],
      ),
      body:
          !s.loaded
              ? const _LoadingSkeleton()
              : s.phase != PublishPhase.idle
              ? Column(
                children: [
                  if (s.error != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.gutter,
                        AppSpacing.sm,
                        AppSpacing.gutter,
                        0,
                      ),
                      child: MessageBanner(
                        message: s.error!,
                        onDismiss: c.dismissError,
                      ),
                    ),
                  Expanded(child: PublishStatusView(onStartNew: _startNew)),
                ],
              )
              : Column(
                children: [
                  _StepHeader(current: s.step, onTap: c.goToStep),
                  if (s.error != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.gutter,
                        AppSpacing.sm,
                        AppSpacing.gutter,
                        0,
                      ),
                      child: MessageBanner(
                        message: s.error!,
                        onDismiss: c.dismissError,
                      ),
                    ),
                  Expanded(
                    child: SingleChildScrollView(
                      key: ValueKey('step-scroll-${s.step.name}'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.gutter,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 640),
                          child: KeyedSubtree(
                            key: ValueKey('step-$_epoch-${s.step.name}'),
                            child: switch (s.step) {
                              UploadStep.details => const DetailsStep(),
                              UploadStep.sheets => const SheetsStep(),
                              UploadStep.pricing => const PricingStep(),
                              UploadStep.review => const ReviewStep(),
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  _BottomBar(state: s),
                ],
              ),
    );
  }
}

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.gutter),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: const [
            ShimmerBox(height: 36, radius: AppRadius.md),
            SizedBox(height: AppSpacing.xl),
            Align(
              alignment: Alignment.centerLeft,
              child: ShimmerBox(width: 90, height: 12),
            ),
            SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: ShimmerBox(width: 220, height: 24),
            ),
            SizedBox(height: AppSpacing.xl),
            ShimmerBox(height: 220, radius: AppRadius.lg),
            SizedBox(height: AppSpacing.lg),
            ShimmerBox(height: 160, radius: AppRadius.lg),
          ],
        ),
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.current, required this.onTap});

  final UploadStep current;
  final ValueChanged<UploadStep> onTap;

  static const _node = 28.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    const steps = UploadStep.values;

    Widget node(UploadStep step) {
      final done = step.index < current.index;
      final isCurrent = step == current;
      final filled = done || isCurrent;
      return AnimatedContainer(
        duration: AppMotion.base,
        curve: AppMotion.curve,
        width: _node,
        height: _node,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled ? scheme.primary : scheme.surface,
          border: Border.all(
            color: filled ? scheme.primary : scheme.outline,
            width: 1.5,
          ),
          boxShadow:
              isCurrent
                  ? [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.22),
                      spreadRadius: 4,
                    ),
                  ]
                  : null,
        ),
        alignment: Alignment.center,
        child:
            done
                ? Icon(Icons.check, size: 16, color: scheme.onPrimary)
                : Text(
                  '${step.index + 1}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: filled ? scheme.onPrimary : scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
      );
    }

    Widget connector(bool active) => Expanded(
      child: AnimatedContainer(
        duration: AppMotion.base,
        height: 2,
        color: active ? scheme.primary : scheme.outlineVariant,
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        child: Row(
          children: [
            for (final step in steps)
              Expanded(
                child: Semantics(
                  button: true,
                  selected: step == current,
                  label:
                      'Step ${step.index + 1} of ${steps.length}: '
                      '${step.label}',
                  excludeSemantics: true,
                  child: InkWell(
                    key: ValueKey('step-tab-${step.name}'),
                    onTap: () => onTap(step),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 64),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              height: _node + 8,
                              child: Row(
                                children: [
                                  step.index == 0
                                      ? const Spacer()
                                      : connector(step.index <= current.index),
                                  node(step),
                                  step.index == steps.length - 1
                                      ? const Spacer()
                                      : connector(step.index < current.index),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              step.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight:
                                    step == current
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                color:
                                    step == current
                                        ? scheme.onSurface
                                        : scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BottomBar extends ConsumerWidget {
  const _BottomBar({required this.state});

  final UploadFlowState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.read(uploadFlowProvider.notifier);
    final scheme = Theme.of(context).colorScheme;
    final isReview = state.step == UploadStep.review;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            AppSpacing.md,
            AppSpacing.gutter,
            AppSpacing.md,
          ),
          child: Row(
            children: [
              if (state.step != UploadStep.details) ...[
                SecondaryButton(
                  key: const ValueKey('back'),
                  label: 'Back',
                  expand: false,
                  onPressed: state.saving ? null : c.back,
                ),
                const SizedBox(width: AppSpacing.md),
              ],
              Expanded(
                child: PrimaryButton(
                  key: ValueKey(isReview ? 'publish' : 'continue'),
                  label: isReview ? 'Publish' : 'Continue',
                  icon: isReview ? Icons.rocket_launch_outlined : null,
                  loading: state.saving,
                  onPressed:
                      state.saving ? null : (isReview ? c.publish : c.next),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
