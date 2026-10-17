import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/widgets/widgets.dart';
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
    final theme = Theme.of(context);
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            controller: _coa,
            label: 'COA registration number',
            hint: 'e.g. CA/2015/12345',
            prefixIcon: Icons.verified_user_outlined,
            enabled: !_busy,
            textCapitalization: TextCapitalization.characters,
            validator: AuthValidators.coaNumber,
            forceErrorText: _coaServerError,
            onChanged: (_) {
              if (_coaServerError != null) {
                setState(() => _coaServerError = null);
              }
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          _DocumentTile(
            fileName: _document?.fileName,
            error: _documentError,
            onTap: _busy ? null : _pick,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Stored privately. Only our reviewers can see your document.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.lg),
            FormErrorBanner(_error!),
          ],
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            label: widget.submitLabel,
            loading: _busy,
            onPressed: _submit,
          ),
          ...widget.extraActions,
        ],
      ),
    );
  }
}

/// Upload target: shows the prompt, the chosen file, or a validation error.
class _DocumentTile extends StatelessWidget {
  const _DocumentTile({
    required this.fileName,
    required this.error,
    required this.onTap,
  });

  final String? fileName;
  final String? error;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final sem = AppSemanticColors.of(context);
    final picked = fileName != null;
    final hasError = error != null;
    final accent =
        hasError ? scheme.error : (picked ? sem.success : scheme.primary);
    final radius = BorderRadius.circular(AppRadius.md);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          child: Material(
            color:
                picked
                    ? sem.successContainer.withValues(alpha: 0.5)
                    : scheme.surfaceContainerLowest,
            shape: RoundedRectangleBorder(
              borderRadius: radius,
              side: BorderSide(
                color: hasError ? scheme.error : scheme.outline,
                width: hasError ? 1.5 : 1,
              ),
            ),
            child: InkWell(
              onTap: onTap,
              borderRadius: radius,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: AppMotion.base,
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent.withValues(alpha: 0.12),
                      ),
                      child: Icon(
                        picked
                            ? Icons.check_circle_outline_rounded
                            : Icons.upload_file_rounded,
                        color: accent,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            picked ? fileName! : 'Attach COA certificate or ID',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall,
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            picked
                                ? 'Tap to choose a different file'
                                : 'PDF, JPG or PNG',
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
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: AppSpacing.md),
            child: Text(
              error!,
              style: theme.textTheme.bodySmall?.copyWith(color: scheme.error),
            ),
          ),
      ],
    );
  }
}
