import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Text field that owns its controller (seeded once from [initialText]) and
/// reports changes upward; the screen re-keys it when the flow is reloaded.
class FormTextField extends StatefulWidget {
  const FormTextField({
    super.key,
    required this.label,
    required this.initialText,
    required this.onChanged,
    this.errorText,
    this.helperText,
    this.keyboardType,
    this.inputFormatters,
    this.maxLines = 1,
    this.maxLength,
    this.prefixText,
    this.enabled = true,
    this.textInputAction,
  });

  final String label;
  final String initialText;
  final ValueChanged<String> onChanged;
  final String? errorText;
  final String? helperText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final int? maxLength;
  final String? prefixText;
  final bool enabled;
  final TextInputAction? textInputAction;

  @override
  State<FormTextField> createState() => _FormTextFieldState();
}

class _FormTextFieldState extends State<FormTextField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialText,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
    controller: _controller,
    enabled: widget.enabled,
    onChanged: widget.onChanged,
    keyboardType: widget.keyboardType,
    inputFormatters: widget.inputFormatters,
    maxLines: widget.maxLines,
    maxLength: widget.maxLength,
    textInputAction: widget.textInputAction,
    decoration: InputDecoration(
      labelText: widget.label,
      errorText: widget.errorText,
      helperText: widget.helperText,
      prefixText: widget.prefixText,
      border: const OutlineInputBorder(),
      counterText: '',
    ),
  );
}

final decimalFormatter = FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'));
final digitsFormatter = FilteringTextInputFormatter.digitsOnly;

/// Inline error / info banner with an optional dismiss action.
class MessageBanner extends StatelessWidget {
  const MessageBanner({
    super.key,
    required this.message,
    this.onDismiss,
    this.isError = true,
  });

  final String message;
  final VoidCallback? onDismiss;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = isError ? scheme.errorContainer : scheme.secondaryContainer;
    final fg = isError ? scheme.onErrorContainer : scheme.onSecondaryContainer;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.info_outline,
            size: 18,
            color: fg,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: TextStyle(color: fg))),
          if (onDismiss != null)
            IconButton(
              tooltip: 'Dismiss',
              icon: Icon(Icons.close, size: 18, color: fg),
              onPressed: onDismiss,
            ),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 8),
    child: Text(text, style: Theme.of(context).textTheme.titleMedium),
  );
}

String formatBytes(int bytes) {
  if (bytes >= 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  if (bytes >= 1024) return '${(bytes / 1024).round()} KB';
  return '$bytes B';
}
