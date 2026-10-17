import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/domain/auth_state.dart';
import '../../auth/domain/user.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/presentation/widgets/auth_form_scaffold.dart'
    show FadeSlideIn;
import '../../auth/presentation/widgets/form_widgets.dart';
import '../domain/verification_request.dart';
import 'verification_form.dart';
import 'verification_providers.dart';

/// Shown to PENDING and REJECTED users instead of the app. Displays the
/// review status, lets them refresh it and (re)submit their document.
class VerificationStatusScreen extends ConsumerStatefulWidget {
  const VerificationStatusScreen({super.key});

  @override
  ConsumerState<VerificationStatusScreen> createState() =>
      _VerificationStatusScreenState();
}

class _VerificationStatusScreenState
    extends ConsumerState<VerificationStatusScreen> {
  bool _refreshing = false;
  String? _refreshError;

  Future<void> _refresh() async {
    setState(() {
      _refreshing = true;
      _refreshError = null;
    });
    try {
      // An approval flips the session user and the router moves us on.
      await ref.read(authControllerProvider.notifier).refreshUser();
      ref.invalidate(myVerificationProvider);
      await ref.read(myVerificationProvider.future);
    } catch (e) {
      if (mounted) setState(() => _refreshError = toApiException(e).message);
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  Future<void> _submit(String coa, VerificationDocument document) async {
    await ref
        .read(verificationRepositoryProvider)
        .submit(coaRegistrationNumber: coa, document: document);
    ref.invalidate(myVerificationProvider);
    try {
      await ref.read(authControllerProvider.notifier).refreshUser();
    } catch (_) {
      // The submission went through; the status can be refreshed later.
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Submitted. We will review it shortly.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final request = ref.watch(myVerificationProvider);
    final userStatus =
        auth is Authenticated
            ? auth.user.verificationStatus
            : VerificationStatus.pending;
    // The latest request is the most specific truth (the server may not flip
    // `user.verificationStatus` back to PENDING on resubmission).
    final status = request.valueOrNull?.status ?? userStatus;
    final rejected = status == VerificationStatus.rejected;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          rejected ? 'Verification rejected' : 'Verification pending',
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh status',
            onPressed: _refreshing ? null : _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FadeSlideIn(child: _StatusHeader(rejected: rejected)),
                    if (_refreshError != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      FormErrorBanner(_refreshError!),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    ...request.when(
                      loading:
                          () => const [
                            Center(child: CircularProgressIndicator()),
                          ],
                      error:
                          (e, _) => [
                            ErrorState(
                              message: toApiException(e).message,
                              onRetry:
                                  () => ref.invalidate(myVerificationProvider),
                            ),
                          ],
                      data: (r) => _content(r, rejected),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    TextButton.icon(
                      onPressed:
                          () =>
                              ref
                                  .read(authControllerProvider.notifier)
                                  .signOut(),
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: const Text('Sign out'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _content(VerificationRequest? r, bool rejected) {
    final text = Theme.of(context).textTheme;
    if (r == null) {
      return [
        Text('Submit your documents', style: text.titleMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'We could not find a verification request for your account yet.',
          style: text.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          child: VerificationForm(
            submitLabel: 'Submit for review',
            onSubmit: _submit,
          ),
        ),
      ];
    }
    return [
      FadeSlideIn(
        delay: const Duration(milliseconds: 100),
        child: _Timeline(rejected: rejected, submittedAt: r.submittedAt),
      ),
      const SizedBox(height: AppSpacing.lg),
      FadeSlideIn(
        delay: const Duration(milliseconds: 180),
        child: _RequestDetails(r, rejected: rejected),
      ),
      if (rejected && (r.reviewNote?.isNotEmpty ?? false)) ...[
        const SizedBox(height: AppSpacing.lg),
        _RejectionReason(r.reviewNote!),
      ],
      const SizedBox(height: AppSpacing.xl),
      if (rejected) ...[
        Text('Submit again', style: text.titleMedium),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: VerificationForm(
            submitLabel: 'Resubmit for review',
            initialCoaNumber: r.coaRegistrationNumber,
            onSubmit: _submit,
          ),
        ),
      ] else
        AppCard(
          style: AppCardStyle.outlined,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              title: const Text('Wrong document? Replace it'),
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: AppSpacing.lg),
              children: [
                VerificationForm(
                  submitLabel: 'Replace submission',
                  initialCoaNumber: r.coaRegistrationNumber,
                  onSubmit: _submit,
                ),
              ],
            ),
          ),
        ),
    ];
  }
}

class _StatusHeader extends StatelessWidget {
  const _StatusHeader({required this.rejected});

  final bool rejected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        BlueprintIllustration(
          icon: rejected ? Icons.report_gmailerrorred : Icons.hourglass_top,
          variant:
              rejected ? BlueprintArtVariant.broken : BlueprintArtVariant.plan,
          tone: rejected ? scheme.error : null,
          width: 200,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          rejected
              ? 'We could not verify you'
              : 'Your verification is under review',
          style: text.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          rejected
              ? 'Fix the issue below and submit again.'
              : "We'll email you within 24 hours.",
          style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

enum _StepState { done, current, upcoming, failed }

class _Timeline extends StatelessWidget {
  const _Timeline({required this.rejected, required this.submittedAt});

  final bool rejected;
  final DateTime submittedAt;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          _TimelineStep(
            title: 'Submitted',
            subtitle: DateFormat.yMMMd().format(submittedAt.toLocal()),
            state: _StepState.done,
          ),
          _TimelineStep(
            title: 'Under review',
            subtitle: 'A reviewer checks your COA details',
            state: rejected ? _StepState.done : _StepState.current,
          ),
          _TimelineStep(
            title: rejected ? 'Needs changes' : 'Decision',
            subtitle:
                rejected
                    ? 'See the note below, then resubmit'
                    : 'You will get an email either way',
            state: rejected ? _StepState.failed : _StepState.upcoming,
            last: true,
          ),
        ],
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.title,
    required this.subtitle,
    required this.state,
    this.last = false,
  });

  final String title;
  final String subtitle;
  final _StepState state;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final (fill, border, icon, iconColor) = switch (state) {
      _StepState.done => (
        scheme.primary,
        scheme.primary,
        Icons.check_rounded,
        scheme.onPrimary,
      ),
      _StepState.current => (
        scheme.primaryContainer,
        scheme.primary,
        Icons.more_horiz_rounded,
        scheme.primary,
      ),
      _StepState.failed => (
        scheme.error,
        scheme.error,
        Icons.priority_high_rounded,
        scheme.onError,
      ),
      _StepState.upcoming => (
        Colors.transparent,
        scheme.outline,
        null,
        scheme.outline,
      ),
    };
    final muted = state == _StepState.upcoming;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: fill,
                    border: Border.all(color: border, width: 1.5),
                  ),
                  child:
                      icon == null
                          ? null
                          : Icon(icon, size: 14, color: iconColor),
                ),
                if (!last)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color:
                          state == _StepState.done
                              ? scheme.primary
                              : scheme.outlineVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: muted ? scheme.onSurfaceVariant : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestDetails extends StatelessWidget {
  const _RequestDetails(this.request, {required this.rejected});

  final VerificationRequest request;
  final bool rejected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      style: AppCardStyle.tonal,
      child: Row(
        children: [
          Icon(Icons.badge_outlined, color: theme.colorScheme.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'COA registration number',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  request.coaRegistrationNumber,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          StatusPill(
            label: rejected ? 'Rejected' : 'In review',
            tone: rejected ? StatusTone.danger : StatusTone.warning,
            dense: true,
          ),
        ],
      ),
    );
  }
}

class _RejectionReason extends StatelessWidget {
  const _RejectionReason(this.reason);

  final String reason;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.comment_outlined,
            size: 20,
            color: scheme.onErrorContainer,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reason from the reviewer',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: scheme.onErrorContainer,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  reason,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onErrorContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
