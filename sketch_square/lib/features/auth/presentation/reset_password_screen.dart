import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/router/routes.dart';
import '../domain/auth_validators.dart';
import 'auth_repository_provider.dart';
import 'widgets/auth_form_scaffold.dart';
import 'widgets/form_widgets.dart';

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
      heading: 'Choose a new password',
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.token == null) ...[
                TextFormField(
                  controller: _token,
                  enabled: !_busy,
                  textInputAction: TextInputAction.next,
                  validator: AuthValidators.resetToken,
                  decoration: const InputDecoration(labelText: 'Reset code'),
                ),
                const SizedBox(height: 16),
              ],
              PasswordField(
                controller: _password,
                label: 'New password',
                validator: AuthValidators.password,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              PasswordField(
                controller: _confirm,
                label: 'Confirm new password',
                validator: AuthValidators.confirmPassword(() => _password.text),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _busy ? null : _submit(),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                FormErrorBanner(_error!),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _busy ? null : _submit,
                child:
                    _busy
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Text('Update password'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
