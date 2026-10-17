import 'package:flutter/material.dart';

import 'empty_error_state.dart';

/// Inline error with a retry button, for async screens. Kept for existing call
/// sites; see [ErrorState].
class ErrorRetry extends StatelessWidget {
  const ErrorRetry({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) =>
      ErrorState(message: message, onRetry: onRetry);
}
