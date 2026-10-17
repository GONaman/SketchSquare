import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../auth/domain/auth_validators.dart';
import '../../auth/presentation/widgets/form_widgets.dart';
import '../domain/verification_request.dart';
import 'verification_providers.dart';

typedef VerificationSubmit =
    Future<void> Function(String coaNumber, VerificationDocument document);

/// COA registration number + identity document picker, shared by the sign-up
/// wizard and the verification screen. [onSubmit] may throw; failures are
/// shown inline.
class VerificationForm extends ConsumerStatefulWidget {
  const VerificationForm({
    super.key,
    required this.submitLabel,
    required this.onSubmit,
    this.initialCoaNumber,
    this.extraActions = const [],
  });

  final String submitLabel;
  final String? initialCoaNumber;
  final VerificationSubmit onSubmit;

  /// Rendered under the submit button (e.g. "Back", "Skip for now").
  final List<Widget> extraActions;

  @override
  ConsumerState<VerificationForm> createState() => _VerificationFormState();
}

class _VerificationFormState extends ConsumerState<VerificationForm> {
  final _formKey = GlobalKey<FormState>();
  late final _coa = TextEditingController(text: widget.initialCoaNumber);
  VerificationDocument? _document;
  String? _documentError;
  String? _coaServerError;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _coa.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final picked = await ref.read(documentPickerProvider).pick();
    if (picked == null || !mounted) return;
    setState(() {
      _document = picked.problem == null ? picked : null;
      _documentError = picked.problem;
    });
  }

  Future<void> _submit() async {
    final valid = _formKey.currentState!.validate();
    if (_document == null && _documentError == null) {
      setState(() => _documentError = 'Attach your COA certificate or ID.');
    }
    if (!valid || _document == null) return;

    setState(() {
      _busy = true;
      _error = null;
      _coaServerError = null;
    });
    try {
      await widget.onSubmit(_coa.text.trim(), _document!);
    } catch (e) {
      final api = toApiException(e);
      if (!mounted) return;
      setState(() {
        _coaServerError = serverFieldErrors(api)['coaRegistrationNumber'];
        _error = _coaServerError == null ? api.message : null;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _coa,
            enabled: !_busy,
            textCapitalization: TextCapitalization.characters,
            validator: AuthValidators.coaNumber,
            forceErrorText: _coaServerError,
            onChanged: (_) {
              if (_coaServerError != null) {
                setState(() => _coaServerError = null);
              }
            },
            decoration: const InputDecoration(
              labelText: 'COA registration number',
              hintText: 'e.g. CA/2015/12345',
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _busy ? null : _pick,
            icon: const Icon(Icons.attach_file),
            label: Text(
              _document == null
                  ? 'Attach COA certificate or ID (PDF, JPG, PNG)'
                  : _document!.fileName,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (_documentError != null)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 12),
              child: Text(
                _documentError!,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.error),
              ),
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
                    : Text(widget.submitLabel),
          ),
          ...widget.extraActions,
        ],
      ),
    );
  }
}
