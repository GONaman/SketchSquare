import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/router/routes.dart';
import '../../verification/domain/verification_request.dart';
import '../../verification/presentation/verification_form.dart';
import '../../verification/presentation/verification_providers.dart';
import '../domain/auth_state.dart';
import '../domain/auth_validators.dart';
import 'auth_controller.dart';
import 'widgets/auth_form_scaffold.dart';
import 'widgets/form_widgets.dart';

/// Two steps: (1) basic details, (2) architect verification (COA number +
/// document). The account is created when step 2 is submitted, then the
/// document is uploaded with the fresh tokens.
class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  int _step = 0;
  String? _error;
  Map<String, String> _serverErrors = {};

  @override
  void initState() {
    super.initState();
    // Account already created (e.g. the upload failed earlier): stay on step 2.
    if (ref.read(authControllerProvider) is Authenticated) _step = 1;
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _email,
      _phone,
      _address,
      _city,
      _password,
      _confirm,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _accountCreated => ref.read(authControllerProvider) is Authenticated;

  void _next() {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _step = 1;
      _error = null;
    });
  }

  void _clearServerError(String field) {
    if (_serverErrors.containsKey(field)) {
      setState(() => _serverErrors = {..._serverErrors}..remove(field));
    }
  }

  Future<void> _createAccountAndUpload(
    String coa,
    VerificationDocument document,
  ) async {
    if (!_accountCreated) {
      try {
        await ref
            .read(authControllerProvider.notifier)
            .signUp(
              email: _email.text.trim(),
              password: _password.text,
              fullName: _name.text.trim(),
              phone: AuthValidators.normalizePhone(_phone.text),
              address: _address.text.trim(),
              city: _city.text.trim(),
            );
      } catch (e) {
        // Most signup failures (taken email, weak field) belong to step 1.
        final api = toApiException(e);
        if (mounted) {
          setState(() {
            _step = 0;
            _serverErrors = {
              if (api.code == ApiErrorCodes.conflict) 'email': api.message,
              ...serverFieldErrors(api),
            };
            _error = _serverErrors.isEmpty ? api.message : null;
          });
        }
        return;
      }
    }
    await ref
        .read(verificationRepositoryProvider)
        .submit(coaRegistrationNumber: coa, document: document);
    if (mounted) context.go(AppRoutes.verificationPending);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(authControllerProvider); // rebuild once the account exists
    return AuthFormScaffold(
      title: 'Create account',
      showBack: !_accountCreated,
      // Reached with `go` (see A7), so there is no route to pop.
      onBack: () => context.go(AppRoutes.signIn),
      heading: _step == 0 ? 'Your details' : 'Verify you are an architect',
      subtitle:
          _step == 0
              ? 'Step 1 of 2. Name and address cannot be changed later.'
              : 'Step 2 of 2. We review every architect, usually within 24 hours.',
      children: [if (_step == 0) _detailsStep() else _verificationStep()],
    );
  }

  Widget _detailsStep() {
    String? server(String f) => _serverErrors[f];
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            validator: AuthValidators.fullName,
            forceErrorText: server('fullName'),
            onChanged: (_) => _clearServerError('fullName'),
            decoration: const InputDecoration(labelText: 'Full name'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: AuthValidators.email,
            forceErrorText: server('email'),
            onChanged: (_) => _clearServerError('email'),
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            validator: AuthValidators.phone,
            forceErrorText: server('phone'),
            onChanged: (_) => _clearServerError('phone'),
            decoration: const InputDecoration(
              labelText: 'Phone',
              hintText: '+91 98765 43210',
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _address,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            maxLines: 2,
            validator: AuthValidators.address,
            forceErrorText: server('address'),
            onChanged: (_) => _clearServerError('address'),
            decoration: const InputDecoration(labelText: 'Office address'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _city,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            validator: AuthValidators.city,
            forceErrorText: server('city'),
            onChanged: (_) => _clearServerError('city'),
            decoration: const InputDecoration(labelText: 'City'),
          ),
          const SizedBox(height: 16),
          PasswordField(
            controller: _password,
            label: 'Password',
            validator: AuthValidators.password,
            forceErrorText: server('password'),
            textInputAction: TextInputAction.next,
            onChanged: (_) => _clearServerError('password'),
          ),
          const SizedBox(height: 16),
          PasswordField(
            controller: _confirm,
            label: 'Confirm password',
            validator: AuthValidators.confirmPassword(() => _password.text),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _next(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            FormErrorBanner(_error!),
          ],
          const SizedBox(height: 24),
          FilledButton(onPressed: _next, child: const Text('Next')),
        ],
      ),
    );
  }

  Widget _verificationStep() {
    return VerificationForm(
      submitLabel: _accountCreated ? 'Upload document' : 'Create account',
      onSubmit: _createAccountAndUpload,
      extraActions: [
        const SizedBox(height: 8),
        if (!_accountCreated)
          TextButton(
            onPressed: () => setState(() => _step = 0),
            child: const Text('Back'),
          )
        else
          TextButton(
            onPressed: () => context.go(AppRoutes.verificationPending),
            child: const Text('Skip for now'),
          ),
      ],
    );
  }
}
