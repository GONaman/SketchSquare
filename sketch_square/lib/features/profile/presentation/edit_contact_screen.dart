import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../auth/domain/auth_validators.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/presentation/current_user_provider.dart';
import '../../auth/presentation/widgets/form_widgets.dart';
import '../data/profile_providers.dart';

/// Phone and city are editable; name and address are locked to the
/// verification record (`PATCH /me` rejects them).
class EditContactScreen extends ConsumerStatefulWidget {
  const EditContactScreen({super.key});

  @override
  ConsumerState<EditContactScreen> createState() => _EditContactScreenState();
}

class _EditContactScreenState extends ConsumerState<EditContactScreen> {
  final _form = GlobalKey<FormState>();
  late final _phone = TextEditingController(
    text: ref.read(currentUserProvider)?.phone,
  );
  late final _city = TextEditingController(
    text: ref.read(currentUserProvider)?.city,
  );
  bool _saving = false;
  String? _error;
  Map<String, String> _fieldErrors = const {};

  @override
  void dispose() {
    _phone.dispose();
    _city.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final user = ref.read(currentUserProvider)!;
    final phone = AuthValidators.normalizePhone(_phone.text);
    final city = _city.text.trim();
    final phoneChanged = phone != user.phone;
    final cityChanged = city != user.city;
    if (!phoneChanged && !cityChanged) {
      context.pop();
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
      _fieldErrors = const {};
    });
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    try {
      await ref
          .read(profileRepositoryProvider)
          .updateContact(
            phone: phoneChanged ? phone : null,
            city: cityChanged ? city : null,
          );
      await ref.read(authControllerProvider.notifier).refreshUser();
      messenger.showSnackBar(const SnackBar(content: Text('Details saved')));
      router.pop();
    } catch (e) {
      final error = toApiException(e);
      if (mounted) {
        setState(() {
          _saving = false;
          _fieldErrors = serverFieldErrors(error);
          _error = _fieldErrors.isEmpty ? error.message : null;
        });
        _form.currentState!.validate();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();
    return Scaffold(
      appBar: AppBar(title: const Text('Edit contact details')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              key: const Key('field-name'),
              initialValue: user.fullName,
              enabled: false,
              decoration: const InputDecoration(labelText: 'Full name'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('field-address'),
              initialValue: user.address,
              enabled: false,
              maxLines: null,
              decoration: const InputDecoration(
                labelText: 'Address',
                helperText:
                    'Name and address match your verification and can only be '
                    'changed by contacting support.',
                helperMaxLines: 3,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('field-phone'),
              controller: _phone,
              enabled: !_saving,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone'),
              validator:
                  (v) => AuthValidators.phone(v) ?? _fieldErrors['phone'],
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('field-city'),
              controller: _city,
              enabled: !_saving,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'City'),
              validator: (v) => AuthValidators.city(v) ?? _fieldErrors['city'],
            ),
            const SizedBox(height: 16),
            if (_error != null) ...[
              FormErrorBanner(_error!),
              const SizedBox(height: 12),
            ],
            FilledButton(
              onPressed: _saving ? null : _save,
              child:
                  _saving
                      ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
