import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/presentation/widgets/form_widgets.dart';
import '../../upload/domain/money.dart' show parseRupeesToPaise;
import '../domain/wallet_models.dart';
import '../domain/wallet_validators.dart';
import 'wallet_controllers.dart';

/// Bottom sheet to request a payout; resolves to the created [Withdrawal].
Future<Withdrawal?> showWithdrawSheet(
  BuildContext context,
  WalletSummary wallet,
) => showModalBottomSheet<Withdrawal>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => WithdrawSheet(wallet: wallet),
);

class WithdrawSheet extends ConsumerStatefulWidget {
  const WithdrawSheet({super.key, required this.wallet});
  final WalletSummary wallet;

  @override
  ConsumerState<WithdrawSheet> createState() => _WithdrawSheetState();
}

class _WithdrawSheetState extends ConsumerState<WithdrawSheet> {
  final _form = GlobalKey<FormState>();
  final _amount = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final paise = parseRupeesToPaise(_amount.text)!;
    setState(() {
      _submitting = true;
      _error = null;
    });
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final withdrawal = await ref
          .read(walletControllerProvider.notifier)
          .withdraw(paise);
      messenger.showSnackBar(
        SnackBar(
          content: Text('Withdrawal of ${formatPaise(paise)} requested'),
        ),
      );
      navigator.pop(withdrawal);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = WalletValidators.messageFor(toApiException(e));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final wallet = widget.wallet;
    final bank = wallet.bankAccount;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        0,
        AppSpacing.gutter,
        AppSpacing.gutter + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Withdraw to bank', style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.md),
            if (bank != null)
              AppCard(
                style: AppCardStyle.tonal,
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Icon(Icons.account_balance_outlined, color: scheme.primary),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bank.holderName,
                            style: theme.textTheme.titleSmall,
                          ),
                          Text(
                            bank.maskedNumber,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              key: const Key('withdraw-amount'),
              controller: _amount,
              enabled: !_submitting,
              autofocus: true,
              tabularFigures: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              label: 'Amount (₹)',
              prefixIcon: Icons.currency_rupee_rounded,
              helper:
                  'Available ${formatPaise(wallet.balancePaise)} · '
                  'minimum ${formatPaise(wallet.minWithdrawalPaise)}',
              validator: (v) => WalletValidators.withdrawalAmount(v, wallet),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_error != null) ...[
              FormErrorBanner(_error!),
              const SizedBox(height: AppSpacing.md),
            ],
            PrimaryButton(
              key: const Key('withdraw-submit'),
              label: 'Request withdrawal',
              loading: _submitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
