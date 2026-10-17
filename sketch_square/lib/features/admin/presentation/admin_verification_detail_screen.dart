import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/domain/user.dart' show VerificationStatus;
import '../domain/admin_verification.dart';
import 'admin_providers.dart';

class AdminVerificationDetailScreen extends ConsumerStatefulWidget {
  const AdminVerificationDetailScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<AdminVerificationDetailScreen> createState() =>
      _AdminVerificationDetailScreenState();
}

class _AdminVerificationDetailScreenState
    extends ConsumerState<AdminVerificationDetailScreen> {
  bool _busy = false;

  void _snack(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  Future<void> _openDocument(String url) async {
    final opened = await ref.read(documentLauncherProvider)(Uri.parse(url));
    if (!opened && mounted) _snack('Could not open the document.');
  }

  Future<void> _decide(
    Future<void> Function() action,
    String doneMessage,
  ) async {
    setState(() => _busy = true);
    try {
      await action();
      ref.read(pendingVerificationsProvider.notifier).remove(widget.id);
      if (!mounted) return;
      _snack(doneMessage);
      context.pop();
    } catch (e) {
      if (mounted) _snack(toApiException(e).message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _approve(AdminVerification v) async {
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Approve architect?'),
            content: Text(
              '${v.user.fullName} will get full access and a welcome email.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Approve'),
              ),
            ],
          ),
    );
    if (ok != true) return;
    await _decide(
      () => ref.read(adminRepositoryProvider).approve(v.id),
      '${v.user.fullName} approved.',
    );
  }

  Future<void> _reject(AdminVerification v) async {
    final note = await showDialog<String>(
      context: context,
      builder: (context) => const _RejectDialog(),
    );
    if (note == null) return;
    await _decide(
      () => ref.read(adminRepositoryProvider).reject(v.id, note: note),
      '${v.user.fullName} rejected.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(adminVerificationProvider(widget.id));
    final v = async.valueOrNull;
    final pending = v != null && v.status == VerificationStatus.pending;
    return Scaffold(
      appBar: AppBar(title: const Text('Verification request')),
      body: async.when(
        loading: () => const ListRowSkeleton(count: 4),
        error:
            (e, _) => ErrorState(
              message: toApiException(e).message,
              onRetry:
                  () => ref.invalidate(adminVerificationProvider(widget.id)),
            ),
        data: _body,
      ),
      bottomNavigationBar:
          pending
              ? SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.gutter,
                    AppSpacing.sm,
                    AppSpacing.gutter,
                    AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: SecondaryButton(
                          label: 'Reject',
                          onPressed: _busy ? null : () => _reject(v),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: PrimaryButton(
                          label: 'Approve',
                          loading: _busy,
                          onPressed: () => _approve(v),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              : null,
    );
  }

  Widget _body(AdminVerification v) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final (tone, label) = switch (v.status) {
      VerificationStatus.approved => (StatusTone.success, 'Approved'),
      VerificationStatus.rejected => (StatusTone.danger, 'Rejected'),
      _ => (StatusTone.warning, 'Pending'),
    };
    Widget row(String label, String? value) =>
        value == null || value.isEmpty
            ? const SizedBox.shrink()
            : Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.labelMedium?.copyWith(color: muted),
                  ),
                  const SizedBox(height: 2),
                  Text(value, style: theme.textTheme.bodyLarge),
                ],
              ),
            );
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      children: [
        AppCard(
          child: Column(
            children: [
              AppAvatar(name: v.user.fullName, size: 72),
              const SizedBox(height: AppSpacing.md),
              Text(
                v.user.fullName,
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                v.user.email,
                style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              StatusPill(label: label, tone: tone),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          style: AppCardStyle.outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              row('COA registration number', v.coaRegistrationNumber),
              row('Phone', v.user.phone),
              row('City', v.user.city),
              row('Address', v.user.address),
              row(
                'Submitted',
                DateFormat.yMMMd().add_jm().format(v.submittedAt.toLocal()),
              ),
              row('Review note', v.reviewNote),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SecondaryButton(
          label: 'Open document',
          icon: Icons.description_outlined,
          onPressed:
              v.documentUrl == null
                  ? null
                  : () => _openDocument(v.documentUrl!),
        ),
      ],
    );
  }
}

class _RejectDialog extends StatefulWidget {
  const _RejectDialog();

  @override
  State<_RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<_RejectDialog> {
  static const maxLength = 500;
  final _formKey = GlobalKey<FormState>();
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reject request'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _note,
          autofocus: true,
          maxLines: 4,
          maxLength: maxLength,
          validator:
              (v) =>
                  (v?.trim().isEmpty ?? true)
                      ? 'Explain why so the architect can fix it'
                      : null,
          decoration: const InputDecoration(
            labelText: 'Reason (sent to the architect)',
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, _note.text.trim());
            }
          },
          child: const Text('Reject'),
        ),
      ],
    );
  }
}
