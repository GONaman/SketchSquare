import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'upload_flow_controller.dart';
import 'upload_flow_state.dart';
import 'widgets/details_step.dart';
import 'widgets/form_widgets.dart';
import 'widgets/pricing_step.dart';
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
              ? const Center(child: CircularProgressIndicator())
              : s.phase != PublishPhase.idle
              ? Column(
                children: [
                  if (s.error != null)
                    MessageBanner(message: s.error!, onDismiss: c.dismissError),
                  Expanded(child: PublishStatusView(onStartNew: _startNew)),
                ],
              )
              : Column(
                children: [
                  _StepHeader(current: s.step, onTap: c.goToStep),
                  if (s.error != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: MessageBanner(
                        message: s.error!,
                        onDismiss: c.dismissError,
                      ),
                    ),
                  Expanded(
                    child: SingleChildScrollView(
                      key: ValueKey('step-scroll-${s.step.name}'),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
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
                  _BottomBar(state: s),
                ],
              ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.current, required this.onTap});

  final UploadStep current;
  final ValueChanged<UploadStep> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: [
          for (final step in UploadStep.values)
            Expanded(
              child: InkWell(
                key: ValueKey('step-tab-${step.name}'),
                onTap: () => onTap(step),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor:
                            step.index <= current.index
                                ? theme.colorScheme.primary
                                : theme.colorScheme.surfaceContainerHighest,
                        foregroundColor:
                            step.index <= current.index
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurfaceVariant,
                        child: Text(
                          '${step.index + 1}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        step.label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight:
                              step == current
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
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
    final isReview = state.step == UploadStep.review;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            if (state.step != UploadStep.details)
              OutlinedButton(
                key: const ValueKey('back'),
                onPressed: state.saving ? null : c.back,
                child: const Text('Back'),
              ),
            const Spacer(),
            FilledButton(
              key: ValueKey(isReview ? 'publish' : 'continue'),
              onPressed: state.saving ? null : (isReview ? c.publish : c.next),
              child:
                  state.saving
                      ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : Text(isReview ? 'Publish' : 'Continue'),
            ),
          ],
        ),
      ),
    );
  }
}
