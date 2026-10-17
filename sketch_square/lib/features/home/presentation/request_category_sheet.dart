import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../drawings/data/drawings_providers.dart';

/// Bottom sheet to suggest a new category (`POST /category-requests`).
/// Resolves to true once the request was sent.
Future<bool?> showRequestCategorySheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _RequestCategorySheet(),
  );
}

String? validateCategoryName(String value) {
  final name = value.trim();
  if (name.length < 2) return 'Enter at least 2 characters';
  if (name.length > 50) return 'Keep it under 50 characters';
  return null;
}

class _RequestCategorySheet extends ConsumerStatefulWidget {
  const _RequestCategorySheet();

  @override
  ConsumerState<_RequestCategorySheet> createState() =>
      _RequestCategorySheetState();
}

class _RequestCategorySheetState extends ConsumerState<_RequestCategorySheet> {
  final _name = TextEditingController();
  String? _error;
  bool _sending = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final invalid = validateCategoryName(_name.text);
    if (invalid != null) {
      setState(() => _error = invalid);
      return;
    }
    setState(() {
      _error = null;
      _sending = true;
    });
    try {
      await ref
          .read(drawingsRepositoryProvider)
          .requestCategory(_name.text.trim());
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = toApiException(e).message;
          _sending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Request a category',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            'Can’t find the right category? Suggest one and we’ll review it.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('category-request-name'),
            controller: _name,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _send(),
            decoration: InputDecoration(
              labelText: 'Category name',
              errorText: _error,
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              key: const Key('category-request-send'),
              onPressed: _sending ? null : _send,
              child: Text(_sending ? 'Sending…' : 'Send request'),
            ),
          ),
        ],
      ),
    );
  }
}
