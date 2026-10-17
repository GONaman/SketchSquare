import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_exception.dart';
import '../../auth/domain/auth_state.dart';
import '../../auth/domain/user.dart';
import '../../auth/presentation/auth_controller.dart';
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
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _StatusHeader(rejected: rejected),
                    if (_refreshError != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _refreshError!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    ...request.when(
                      loading:
                          () => const [
                            Center(child: CircularProgressIndicator()),
                          ],
                      error:
                          (e, _) => [
                            Text(toApiException(e).message),
                            TextButton(
                              onPressed:
                                  () => ref.invalidate(myVerificationProvider),
                              child: const Text('Retry'),
                            ),
                          ],
                      data: (r) => _content(r, rejected),
                    ),
                    const SizedBox(height: 32),
                    TextButton(
                      onPressed:
                          () =>
                              ref
                                  .read(authControllerProvider.notifier)
                                  .signOut(),
                      child: const Text('Sign out'),
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
        const SizedBox(height: 4),
        const Text(
          'We could not find a verification request for your account yet.',
        ),
        const SizedBox(height: 16),
        VerificationForm(submitLabel: 'Submit for review', onSubmit: _submit),
      ];
    }
    return [
      _RequestDetails(r),
      if (rejected && (r.reviewNote?.isNotEmpty ?? false)) ...[
        const SizedBox(height: 16),
        _RejectionReason(r.reviewNote!),
      ],
      const SizedBox(height: 24),
      if (rejected) ...[
        Text('Submit again', style: text.titleMedium),
        const SizedBox(height: 12),
        VerificationForm(
          submitLabel: 'Resubmit for review',
          initialCoaNumber: r.coaRegistrationNumber,
          onSubmit: _submit,
        ),
      ] else
        ExpansionTile(
          title: const Text('Wrong document? Replace it'),
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(top: 8),
          children: [
            VerificationForm(
              submitLabel: 'Replace submission',
              initialCoaNumber: r.coaRegistrationNumber,
              onSubmit: _submit,
            ),
          ],
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
        Icon(
          rejected ? Icons.error_outline : Icons.hourglass_top,
          size: 56,
          color: rejected ? scheme.error : scheme.primary,
        ),
        const SizedBox(height: 16),
        Text(
          rejected
              ? 'We could not verify you'
              : 'Your verification is under review',
          style: text.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          rejected
              ? 'Fix the issue below and submit again.'
              : "We'll email you within 24 hours.",
          style: text.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _RequestDetails extends StatelessWidget {
  const _RequestDetails(this.request);

  final VerificationRequest request;

  @override
  Widget build(BuildContext context) {
    Widget row(String label, String value) => ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      trailing: Text(value),
    );
    return Column(
      children: [
        row('COA registration number', request.coaRegistrationNumber),
        row(
          'Submitted',
          DateFormat.yMMMd().format(request.submittedAt.toLocal()),
        ),
      ],
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reason from the reviewer',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: scheme.onErrorContainer),
          ),
          const SizedBox(height: 4),
          Text(reason, style: TextStyle(color: scheme.onErrorContainer)),
        ],
      ),
    );
  }
}
