import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/presentation/widgets/form_widgets.dart';
import '../domain/admin_purchase.dart';
import 'admin_refunds_screen.dart' show PurchaseStatusPill;
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
    final p = async.valueOrNull;
    return Scaffold(
      appBar: AppBar(title: const Text('Purchase')),
      body: async.when(
        loading: () => const ListRowSkeleton(count: 4),
        error:
            (e, _) => ErrorState(
              message: toApiException(e).message,
              onRetry: () => ref.invalidate(adminPurchaseProvider(widget.id)),
            ),
        data: _body,
      ),
      bottomNavigationBar:
          p != null && p.canRefund
              ? SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.gutter,
                    AppSpacing.sm,
                    AppSpacing.gutter,
                    AppSpacing.md,
                  ),
                  child: PrimaryButton(
                    key: const Key('refund-button'),
                    icon: Icons.undo,
                    label: 'Refund ${formatPaise(p.pricePaise)}',
                    loading: _busy,
                    onPressed: () => _refund(p),
                  ),
                ),
              )
              : null,
    );
  }

  Widget _body(AdminPurchase p) {
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final muted = theme.colorScheme.onSurfaceVariant;
    final date = DateFormat.yMMMd().add_jm();
    Widget field(String label, String? value, {Key? key}) =>
        value == null || value.isEmpty
            ? const SizedBox.shrink()
            : Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs + 1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: text.labelMedium?.copyWith(color: muted)),
                  const SizedBox(height: 2),
                  SelectableText(value, key: key, style: text.bodyLarge),
                ],
              ),
            );
    String person(AdminPerson x) =>
        x.email == null ? x.fullName : '${x.fullName} (${x.email})';
    final refund = p.refund;
    final balance = p.sellerBalancePaise;
    final afterBalance = balance == null ? null : balance - p.sellerNetPaise;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: Text(p.drawingTitle, style: text.titleLarge)),
                  const SizedBox(width: AppSpacing.md),
                  PurchaseStatusPill(p.status),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              field('Purchase id', p.id),
              field('Buyer', person(p.buyer)),
              field('Seller', person(p.seller)),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          style: AppCardStyle.outlined,
          child: Column(
            children: [
              SummaryRow(label: 'Price', value: formatPaise(p.pricePaise)),
              SummaryRow(
                label: 'Platform fee',
                value: formatPaise(p.platformFeePaise),
              ),
              const Divider(height: AppSpacing.xl),
              SummaryRow(
                label: 'Seller earnings',
                value: formatPaise(p.sellerNetPaise),
                emphasis: true,
              ),
              if (balance != null) ...[
                const SizedBox(height: AppSpacing.xs),
                SummaryRow(
                  label: "Seller's wallet balance",
                  value: formatPaise(balance),
                  valueKey: const Key('seller-balance'),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          style: AppCardStyle.outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              field('Created', date.format(p.createdAt.toLocal())),
              if (p.paidAt != null)
                field('Paid', date.format(p.paidAt!.toLocal())),
              field('Razorpay order', p.razorpayOrderId),
              field('Razorpay payment', p.razorpayPaymentId),
            ],
          ),
        ),
        if (refund != null) ...[
          const SizedBox(height: AppSpacing.md),
          AppCard(
            style: AppCardStyle.outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Refund', style: text.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                field('Refunded on', date.format(refund.refundedAt.toLocal())),
                field('Refunded by', refund.refundedBy.fullName),
                field('Reason', refund.reason, key: const Key('refund-reason')),
                field('Gateway refund', switch (refund.providerStatus) {
                  RefundProviderStatus.succeeded =>
                    'Succeeded${refund.providerRefundId == null ? '' : ' (${refund.providerRefundId})'}',
                  RefundProviderStatus.pending => 'In progress',
                  RefundProviderStatus.failed =>
                    'Failed${refund.providerError == null ? '' : ': ${refund.providerError}'}',
                }, key: const Key('refund-provider-status')),
                if (refund.providerStatus !=
                    RefundProviderStatus.succeeded) ...[
                  const SizedBox(height: AppSpacing.md),
                  SecondaryButton(
                    key: const Key('refund-retry'),
                    label: 'Retry gateway refund',
                    icon: Icons.refresh,
                    onPressed:
                        _busy
                            ? null
                            : () => _submit(p, refund.reason, retry: true),
                  ),
                ],
              ],
            ),
          ),
        ],
        if (p.canRefund && afterBalance != null && afterBalance < 0) ...[
          const SizedBox(height: AppSpacing.md),
          KeyedSubtree(
            key: const Key('negative-balance-warning'),
            child: FormErrorBanner(
              'The seller has already spent part of this sale. Their balance '
              'will become ${formatPaise(afterBalance)} and withdrawals stay '
              'blocked until it is positive again.',
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
            AppTextField(
              key: const Key('refund-reason-field'),
              controller: _reason,
              minLines: 2,
              maxLines: 4,
              autofocus: true,
              label: 'Reason',
              inputFormatters: [
                LengthLimitingTextInputFormatter(maxRefundReasonLength),
              ],
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
