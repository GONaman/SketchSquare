import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';

/// "By continuing you agree to the Terms and Privacy Policy" with links.
class LegalConsentText extends StatelessWidget {
  const LegalConsentText({
    super.key,
    this.prefix = 'By creating an account you agree to the ',
  });

  final String prefix;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(prefix, style: style),
        _link(context, 'Terms of Service', AppRoutes.terms, key: 'link-terms'),
        Text(' and ', style: style),
        _link(
          context,
          'Privacy Policy',
          AppRoutes.privacy,
          key: 'link-privacy',
        ),
        Text('.', style: style),
      ],
    );
  }

  Widget _link(
    BuildContext context,
    String label,
    String route, {
    required String key,
  }) {
    return TextButton(
      key: Key(key),
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        tapTargetSize: MaterialTapTargetSize.padded,
      ),
      onPressed: () => context.push(route),
      child: Text(label),
    );
  }
}
