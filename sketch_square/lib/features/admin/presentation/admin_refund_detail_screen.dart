import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/widgets/error_retry.dart';
import '../../drawings/presentation/formatters.dart';
import '../domain/admin_purchase.dart';
import 'admin_refunds_screen.dart' show PurchaseStatusChip;
import 'refunds_providers.dart';

const minRefundReasonLength = 3;
const maxRefundReasonLength = 500;

/// Reason shown/validated the same way the server does (trimmed, 3–500).
String? validateRefundReason(String? value) {
  final reason = (value ?? '').trim();
  if (reason.length < minRefundReasonLength) {
    return 'Enter a reason (at least $minRefundReasonLength characters).';
  }
  if (reason.length > maxRefundReasonLength) {
    return 'Keep the reason under $maxRefundReasonLength characters.';
  }
  return null;
}

class AdminRefundDetailScreen extends ConsumerStatefulWidget {
  const AdminRefundDetailScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<AdminRefundDetailScreen> createState() =>
      _AdminRefundDetailScreenState();
}

class _AdminRefundDetailScreenState
    extends ConsumerState<AdminRefundDetailScreen> {
  bool _busy = false;

  void _snack(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  Future<void> _refund(AdminPurchase p) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => _RefundDialog(purchase: p),
    );
    if (reason == null) return;
    await _submit(p, reason, retry: false);
  }

  Future<void> _submit(
    AdminPurchase p,
    String reason, {
    required bool retry,
  }) async {
    setState(() => _busy = true);
    try {
      final result = await ref
          .read(adminRefundsRepositoryProvider)
          .refund(p.id, reason: reason);
      ref.read(refundsVersionProvider.notifier).state++;
      ref.invalidate(adminPurchaseProvider(p.id));
      if (!mounted) return;
      final failed =
          result.refund.providerStatus == RefundProviderStatus.failed;
      _snack(
        failed
            ? 'Refund recorded, but the payment gateway refund failed. '
                'You can retry it.'
            : retry
            ? 'Gateway refund retried.'
            : 'Refund of ${formatPaise(result.refund.amountPaise)} issued.',
      );
    } catch (e) {
      final err = toApiException(e);
      if (!mounted) return;
      _snack(err.message);
      if (err.code == ApiErrorCodes.conflict ||
          err.code == ApiErrorCodes.notFound) {
        ref.invalidate(adminPurchaseProvider(p.id));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(adminPurchaseProvider(widget.id));
    return Scaffold(
      appBar: AppBar(title: const Text('Purchase')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (e, _) => ErrorRetry(
              message: toApiException(e).message,
              onRetry: () => ref.invalidate(adminPurchaseProvider(widget.id)),
            ),
        data: _body,
      ),
    );
  }

  Widget _body(AdminPurchase p) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final date = DateFormat.yMMMd().add_jm();
    Widget row(String label, String? value, {Key? key}) =>
        value == null || value.isEmpty
            ? const SizedBox.shrink()
            : ListTile(
              key: key,
              dense: true,
              title: Text(label, style: text.labelMedium),
              subtitle: SelectableText(value, style: text.bodyLarge),
            );
    String person(AdminPerson x) =>
        x.email == null ? x.fullName : '${x.fullName} (${x.email})';
    final refund = p.refund;
    final balance = p.sellerBalancePaise;
    final afterBalance = balance == null ? null : balance - p.sellerNetPaise;
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        ListTile(
          title: Text(p.drawingTitle, style: text.titleMedium),
          trailing: PurchaseStatusChip(p.status),
        ),
        row('Purchase id', p.id),
        row('Buyer', person(p.buyer)),
        row('Seller', person(p.seller)),
        row('Price', formatPaise(p.pricePaise)),
        row('Platform fee', formatPaise(p.platformFeePaise)),
        row('Seller earnings', formatPaise(p.sellerNetPaise)),
        row('Created', date.format(p.createdAt.toLocal())),
        if (p.paidAt != null) row('Paid', date.format(p.paidAt!.toLocal())),
        row('Razorpay order', p.razorpayOrderId),
        row('Razorpay payment', p.razorpayPaymentId),
        if (balance != null)
          row(
            "Seller's wallet balance",
            formatPaise(balance),
            key: const Key('seller-balance'),
          ),
        if (refund != null) ...[
          const Divider(),
          row('Refunded', date.format(refund.refundedAt.toLocal())),
          row('Refunded by', refund.refundedBy.fullName),
          row('Reason', refund.reason, key: const Key('refund-reason')),
          row('Gateway refund', switch (refund.providerStatus) {
            RefundProviderStatus.succeeded =>
              'Succeeded${refund.providerRefundId == null ? '' : ' (${refund.providerRefundId})'}',
            RefundProviderStatus.pending => 'In progress',
            RefundProviderStatus.failed =>
              'Failed${refund.providerError == null ? '' : ': ${refund.providerError}'}',
          }, key: const Key('refund-provider-status')),
          if (refund.providerStatus != RefundProviderStatus.succeeded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: OutlinedButton(
                key: const Key('refund-retry'),
                onPressed:
                    _busy ? null : () => _submit(p, refund.reason, retry: true),
                child: const Text('Retry gateway refund'),
              ),
            ),
        ],
        if (p.canRefund) ...[
          if (afterBalance != null && afterBalance < 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Text(
                'The seller has already spent part of this sale. Their balance '
                'will become ${formatPaise(afterBalance)} and withdrawals stay '
                'blocked until it is positive again.',
                key: const Key('negative-balance-warning'),
                style: TextStyle(color: scheme.error),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              key: const Key('refund-button'),
              onPressed: _busy ? null : () => _refund(p),
              icon: const Icon(Icons.undo),
              label: Text('Refund ${formatPaise(p.pricePaise)}'),
            ),
          ),
        ],
      ],
    );
  }
}

class _RefundDialog extends StatefulWidget {
  const _RefundDialog({required this.purchase});

  final AdminPurchase purchase;

  @override
  State<_RefundDialog> createState() => _RefundDialogState();
}

class _RefundDialogState extends State<_RefundDialog> {
  final _form = GlobalKey<FormState>();
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.purchase;
    return AlertDialog(
      title: const Text('Refund this purchase?'),
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${formatPaise(p.pricePaise)} goes back to ${p.buyer.fullName} '
              'and they lose access to "${p.drawingTitle}". '
              '${p.seller.fullName} loses ${formatPaise(p.sellerNetPaise)}. '
              'This cannot be undone.',
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('refund-reason-field'),
              controller: _reason,
              minLines: 2,
              maxLines: 4,
              maxLength: maxRefundReasonLength,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Reason'),
              validator: validateRefundReason,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const Key('refund-cancel'),
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('refund-confirm'),
          onPressed: () {
            if (_form.currentState!.validate()) {
              Navigator.pop(context, _reason.text.trim());
            }
          },
          child: Text('Refund ${formatPaise(p.pricePaise)}'),
        ),
      ],
    );
  }
}
