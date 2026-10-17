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
    final theme = Theme.of(context);
    if (_sent) {
      return AuthFormScaffold(
        title: 'Forgot password',
        showBack: true,
        kicker: 'Email sent',
        heading: 'Check your email',
        subtitle:
            'If an account exists for ${_email.text.trim()}, we have sent '
            'instructions to reset your password.',
        children: [
          const FadeSlideIn(
            delay: Duration(milliseconds: 80),
            child: Center(
              child: BlueprintIllustration(
                icon: Icons.mark_email_read_outlined,
                variant: BlueprintArtVariant.plot,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            onPressed: () => context.push(AppRoutes.resetPassword),
            label: 'I have a reset code',
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Back to sign in'),
          ),
          Text(
            'Nothing yet? Check your spam folder, or go back and try again.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }
    return AuthFormScaffold(
      title: 'Forgot password',
      showBack: true,
      kicker: 'Account recovery',
      heading: 'Reset your password',
      subtitle: 'Enter your email and we will send you a link to reset it.',
      children: [
        Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                controller: _email,
                label: 'Email',
                prefixIcon: Icons.mail_outline_rounded,
                enabled: !_busy,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.email],
                validator: AuthValidators.email,
                onSubmitted: (_) => _busy ? null : _submit(),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.lg),
                FormErrorBanner(_error!),
              ],
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: 'Send reset link',
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
