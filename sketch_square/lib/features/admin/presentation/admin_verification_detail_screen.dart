import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/widgets/error_retry.dart';
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
    return Scaffold(
      appBar: AppBar(title: const Text('Verification request')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (e, _) => ErrorRetry(
              message: toApiException(e).message,
              onRetry:
                  () => ref.invalidate(adminVerificationProvider(widget.id)),
            ),
        data: _body,
      ),
    );
  }

  Widget _body(AdminVerification v) {
    final text = Theme.of(context).textTheme;
    final isPending = v.status == VerificationStatus.pending;
    Widget row(String label, String? value) =>
        value == null || value.isEmpty
            ? const SizedBox.shrink()
            : ListTile(
              dense: true,
              title: Text(label, style: text.labelMedium),
              subtitle: Text(value, style: text.bodyLarge),
            );
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        row('Name', v.user.fullName),
        row('Email', v.user.email),
        row('Phone', v.user.phone),
        row('City', v.user.city),
        row('Address', v.user.address),
        row('COA registration number', v.coaRegistrationNumber),
        row(
          'Submitted',
          DateFormat.yMMMd().add_jm().format(v.submittedAt.toLocal()),
        ),
        row('Status', v.status.name.toUpperCase()),
        row('Review note', v.reviewNote),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OutlinedButton.icon(
                onPressed:
                    v.documentUrl == null
                        ? null
                        : () => _openDocument(v.documentUrl!),
                icon: const Icon(Icons.description_outlined),
                label: const Text('Open document'),
              ),
              if (isPending) ...[
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _busy ? null : () => _approve(v),
                  child: const Text('Approve'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                  onPressed: _busy ? null : () => _reject(v),
                  child: const Text('Reject'),
                ),
              ],
            ],
          ),
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
