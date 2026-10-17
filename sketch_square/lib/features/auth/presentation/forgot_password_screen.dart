import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/router/routes.dart';
import '../domain/auth_validators.dart';
import 'auth_repository_provider.dart';
import 'widgets/auth_form_scaffold.dart';
import 'widgets/form_widgets.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _busy = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).forgotPassword(_email.text.trim());
      if (mounted) setState(() => _sent = true);
    } catch (e) {
      if (mounted) setState(() => _error = toApiException(e).message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_sent) {
      return AuthFormScaffold(
        title: 'Forgot password',
        showBack: true,
        heading: 'Check your email',
        subtitle:
            'If an account exists for ${_email.text.trim()}, we have sent '
            'instructions to reset your password.',
        children: [
          FilledButton(
            onPressed: () => context.push(AppRoutes.resetPassword),
            child: const Text('I have a reset code'),
          ),
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Back to sign in'),
          ),
        ],
      );
    }
    return AuthFormScaffold(
      title: 'Forgot password',
      showBack: true,
      heading: 'Reset your password',
      subtitle: 'Enter your email and we will send you a link to reset it.',
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _email,
                enabled: !_busy,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                validator: AuthValidators.email,
                onFieldSubmitted: (_) => _busy ? null : _submit(),
                decoration: const InputDecoration(labelText: 'Email'),
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
                        : const Text('Send reset link'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
