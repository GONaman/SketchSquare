import 'package:flutter/material.dart';

import '../../../../core/network/api_exception.dart';

/// Inline error shown above a form's submit button.
class FormErrorBanner extends StatelessWidget {
  const FormErrorBanner(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, size: 20, color: scheme.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: scheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}

/// Per-field messages from a `VALIDATION_ERROR` (`details.fields`, see the
/// contract), keyed by field name. Empty for any other error.
Map<String, String> serverFieldErrors(ApiException e) {
  final details = e.details;
  if (e.code != ApiErrorCodes.validation || details is! Map) return const {};
  final fields = details['fields'];
  if (fields is! Map) return const {};
  return {
    for (final entry in fields.entries)
      entry.key.toString():
          entry.value is List
              ? (entry.value as List).join('\n')
              : entry.value.toString(),
  };
}
