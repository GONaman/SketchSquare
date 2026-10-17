import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/router/routes.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/auth_validators.dart';
import 'auth_repository_provider.dart';
import 'widgets/auth_form_scaffold.dart';
import 'widgets/form_widgets.dart';
import 'widgets/password_strength_meter.dart';

/// Reached from the emailed link (`/reset-password?token=...`) or manually
/// after "I have a reset code".
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, this.token});

  final String? token;

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _token = TextEditingController(text: widget.token);
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _token.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .resetPassword(
            token: _token.text.trim(),
            newPassword: _password.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated. Please sign in.')),
      );
      context.go(AppRoutes.signIn);
    } catch (e) {
      final api = toApiException(e);
      if (mounted) {
        setState(
          () =>
              _error =
                  api.code == ApiErrorCodes.validation ||
                          api.code == ApiErrorCodes.unauthorized
                      ? 'This reset code is invalid or has expired. '
                          'Request a new one from the sign-in screen.'
                      : api.message,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthFormScaffold(
      title: 'Reset password',
      showBack: true,
      kicker: 'New password',
      heading: 'Choose a new password',
      subtitle: 'Use at least ${AuthValidators.minPasswordLength} characters.',
      children: [
        Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.token == null) ...[
                AppTextField(
                  controller: _token,
                  label: 'Reset code',
                  helper: 'Paste the code from the email we sent you.',
                  prefixIcon: Icons.vpn_key_outlined,
                  enabled: !_busy,
                  textInputAction: TextInputAction.next,
                  validator: AuthValidators.resetToken,
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              PasswordField(
                controller: _password,
                label: 'New password',
                enabled: !_busy,
                validator: AuthValidators.password,
                textInputAction: TextInputAction.next,
              ),
              PasswordStrengthMeter(controller: _password),
              const SizedBox(height: AppSpacing.lg),
              PasswordField(
                controller: _confirm,
                label: 'Confirm new password',
                enabled: !_busy,
                validator: AuthValidators.confirmPassword(() => _password.text),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _busy ? null : _submit(),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.lg),
                FormErrorBanner(_error!),
              ],
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: 'Update password',
                loading: _busy,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
