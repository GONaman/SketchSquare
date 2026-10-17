import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/widgets/widgets.dart';
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
  late final _name = TextEditingController(
    text: ref.read(currentUserProvider)?.fullName,
  );
  late final _address = TextEditingController(
    text: ref.read(currentUserProvider)?.address,
  );
  bool _saving = false;
  String? _error;
  Map<String, String> _fieldErrors = const {};

  @override
  void dispose() {
    _phone.dispose();
    _city.dispose();
    _name.dispose();
    _address.dispose();
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
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            AppSpacing.sm,
            AppSpacing.gutter,
            AppSpacing.xl,
          ),
          children: [
            const FormSectionLabel(
              'Verified details',
              icon: Icons.lock_outline,
            ),
            AppTextField(
              key: const Key('field-name'),
              controller: _name,
              enabled: false,
              label: 'Full name',
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              key: const Key('field-address'),
              controller: _address,
              enabled: false,
              maxLines: null,
              label: 'Address',
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Name and address match your verification and can only be '
                    'changed by contacting support.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            const FormSectionLabel('Contact', icon: Icons.call_outlined),
            AppTextField(
              key: const Key('field-phone'),
              controller: _phone,
              enabled: !_saving,
              keyboardType: TextInputType.phone,
              label: 'Phone',
              prefixIcon: Icons.phone_outlined,
              validator:
                  (v) => AuthValidators.phone(v) ?? _fieldErrors['phone'],
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              key: const Key('field-city'),
              controller: _city,
              enabled: !_saving,
              textCapitalization: TextCapitalization.words,
              label: 'City',
              prefixIcon: Icons.location_city_outlined,
              validator: (v) => AuthValidators.city(v) ?? _fieldErrors['city'],
            ),
            const SizedBox(height: AppSpacing.xl),
            if (_error != null) ...[
              FormErrorBanner(_error!),
              const SizedBox(height: AppSpacing.md),
            ],
            PrimaryButton(
              label: 'Save',
              loading: _saving,
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
