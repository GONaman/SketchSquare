import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../auth/presentation/widgets/form_widgets.dart';
import '../../upload/domain/money.dart';
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
    final wallet = widget.wallet;
    final bank = wallet.bankAccount;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Withdraw to bank',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              bank == null ? '' : '${bank.holderName} · ${bank.maskedNumber}',
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('withdraw-amount'),
              controller: _amount,
              enabled: !_submitting,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Amount (₹)',
                helperText:
                    'Available ${formatPaise(wallet.balancePaise)} · '
                    'minimum ${formatPaise(wallet.minWithdrawalPaise)}',
              ),
              validator: (v) => WalletValidators.withdrawalAmount(v, wallet),
            ),
            const SizedBox(height: 16),
            if (_error != null) ...[
              FormErrorBanner(_error!),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('withdraw-submit'),
                onPressed: _submitting ? null : _submit,
                child:
                    _submitting
                        ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Text('Request withdrawal'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
