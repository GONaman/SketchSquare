import 'package:flutter/material.dart';

import 'legal_content.dart';

class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({
    super.key,
    required this.title,
    required this.sections,
  });

  const LegalDocumentScreen.terms({super.key})
    : title = LegalContent.termsTitle,
      sections = LegalContent.terms;

  const LegalDocumentScreen.privacy({super.key})
    : title = LegalContent.privacyTitle,
      sections = LegalContent.privacy;

  final String title;
  final List<LegalSection> sections;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            LegalContent.placeholderNotice,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
          for (final s in sections) ...[
            const SizedBox(height: 20),
            Semantics(
              header: true,
              child: Text(s.heading, style: theme.textTheme.titleMedium),
            ),
            const SizedBox(height: 6),
            Text(s.body, style: theme.textTheme.bodyMedium),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
