import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/presentation/widgets/form_widgets.dart';
import '../domain/wallet_validators.dart';
import 'wallet_controllers.dart';

/// Add or replace the payout bank account. The full account number is never
/// returned by the API, so it must be re-entered (twice) on every edit.
class BankAccountScreen extends ConsumerStatefulWidget {
  const BankAccountScreen({super.key});

  @override
  ConsumerState<BankAccountScreen> createState() => _BankAccountScreenState();
}

class _BankAccountScreenState extends ConsumerState<BankAccountScreen> {
  final _form = GlobalKey<FormState>();
  final _holder = TextEditingController();
  final _ifsc = TextEditingController();
  final _number = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;
  String? _error;
  Map<String, String> _fieldErrors = const {};

  @override
  void initState() {
    super.initState();
    // Also covers opening the screen before the wallet has loaded.
    ref.read(walletControllerProvider.future).then((wallet) {
      final bank = wallet.bankAccount;
      if (!mounted || bank == null) return;
      if (_holder.text.isEmpty && _ifsc.text.isEmpty) {
        _holder.text = bank.holderName;
        _ifsc.text = bank.ifsc;
      }
    }, onError: (_) {});
  }

  @override
  void dispose() {
    _holder.dispose();
    _ifsc.dispose();
    _number.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
      _fieldErrors = const {};
    });
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    try {
      await ref
          .read(walletControllerProvider.notifier)
          .saveBankAccount(
            holderName: _holder.text.trim(),
            ifsc: WalletValidators.normalizeIfsc(_ifsc.text),
            accountNumber: WalletValidators.normalizeAccountNumber(
              _number.text,
            ),
          );
      messenger.showSnackBar(
        const SnackBar(content: Text('Bank account saved')),
      );
      router.pop();
    } catch (e) {
      final error = toApiException(e);
      if (!mounted) return;
      setState(() {
        _saving = false;
        _fieldErrors = serverFieldErrors(error);
        _error = _fieldErrors.isEmpty ? error.message : null;
      });
      _form.currentState!.validate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final existing =
        ref.watch(walletControllerProvider).valueOrNull?.bankAccount;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          existing == null ? 'Add bank account' : 'Edit bank account',
        ),
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.gutter),
          children: [
            AppCard(
              style: AppCardStyle.tonal,
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  const Expanded(
                    child: Text(
                      'Your earnings are paid out to this account. We only '
                      'store the last 4 digits of the number.',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              key: const Key('field-holder'),
              controller: _holder,
              enabled: !_saving,
              textCapitalization: TextCapitalization.words,
              label: 'Account holder name',
              prefixIcon: Icons.person_outline_rounded,
              validator:
                  (v) =>
                      WalletValidators.holderName(v) ??
                      _fieldErrors['holderName'],
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              key: const Key('field-ifsc'),
              controller: _ifsc,
              enabled: !_saving,
              textCapitalization: TextCapitalization.characters,
              label: 'IFSC code',
              prefixIcon: Icons.account_balance_outlined,
              validator:
                  (v) => WalletValidators.ifsc(v) ?? _fieldErrors['ifsc'],
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              key: const Key('field-account'),
              controller: _number,
              enabled: !_saving,
              keyboardType: TextInputType.number,
              obscureText: true,
              tabularFigures: true,
              label: 'Account number',
              prefixIcon: Icons.pin_outlined,
              helper:
                  existing == null
                      ? null
                      : 'Currently ${existing.maskedNumber}. Re-enter the '
                          'full number to save changes.',
              validator:
                  (v) =>
                      WalletValidators.accountNumber(v) ??
                      _fieldErrors['accountNumber'],
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              key: const Key('field-account-confirm'),
              controller: _confirm,
              enabled: !_saving,
              keyboardType: TextInputType.number,
              tabularFigures: true,
              label: 'Confirm account number',
              prefixIcon: Icons.pin_outlined,
              validator:
                  (v) =>
                      WalletValidators.normalizeAccountNumber(v ?? '') ==
                              WalletValidators.normalizeAccountNumber(
                                _number.text,
                              )
                          ? null
                          : 'Account numbers do not match',
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_error != null) ...[
              FormErrorBanner(_error!),
              const SizedBox(height: AppSpacing.md),
            ],
            PrimaryButton(
              key: const Key('bank-save'),
              label: 'Save',
              loading: _saving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
