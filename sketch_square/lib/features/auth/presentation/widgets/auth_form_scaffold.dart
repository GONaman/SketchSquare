import 'package:flutter/material.dart';

/// Scrollable, width-constrained body shared by the logged-out auth screens.
class AuthFormScaffold extends StatelessWidget {
  const AuthFormScaffold({
    super.key,
    required this.title,
    required this.children,
    this.showBack = false,
    this.onBack,
    this.heading,
    this.subtitle,
  });

  final String title;
  final String? heading;
  final String? subtitle;
  final bool showBack;

  /// Overrides the default pop; needed when the screen was reached with `go`.
  final VoidCallback? onBack;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        automaticallyImplyLeading: false,
        leading: showBack ? BackButton(onPressed: onBack) : null,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (heading != null)
                    Text(heading!, style: text.headlineSmall),
                  if (subtitle != null) ...[
                    const SizedBox(height: 8),
                    Text(subtitle!, style: text.bodyMedium),
                  ],
                  if (heading != null || subtitle != null)
                    const SizedBox(height: 24),
                  ...children,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Password field with a show/hide toggle.
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    required this.label,
    this.validator,
    this.forceErrorText,
    this.textInputAction,
    this.onSubmitted,
    this.onChanged,
    this.autofillHints,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final String? forceErrorText;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final Iterable<String>? autofillHints;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscure,
      validator: widget.validator,
      forceErrorText: widget.forceErrorText,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onSubmitted,
      onChanged: widget.onChanged,
      autofillHints: widget.autofillHints,
      decoration: InputDecoration(
        labelText: widget.label,
        suffixIcon: IconButton(
          tooltip: _obscure ? 'Show password' : 'Hide password',
          icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
    );
  }
}
