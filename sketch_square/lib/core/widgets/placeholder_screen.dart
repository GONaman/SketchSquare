import 'package:flutter/material.dart';

import 'blueprint_empty_state.dart';

/// Generic placeholder used by tab screens and auth stubs until their phase.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    super.key,
    required this.title,
    required this.icon,
    this.message = 'Coming soon.',
  });

  final String title;
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: BlueprintEmptyState(icon: icon, title: title, message: message),
    );
  }
}
