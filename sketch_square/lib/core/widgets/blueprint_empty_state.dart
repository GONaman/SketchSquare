import 'package:flutter/material.dart';

import 'empty_error_state.dart';

/// Empty/placeholder state with the blueprint illustration. Kept for existing
/// call sites; new code can use [EmptyState] directly.
class BlueprintEmptyState extends StatelessWidget {
  const BlueprintEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) =>
      EmptyState(icon: icon, title: title, message: message, action: action);
}
