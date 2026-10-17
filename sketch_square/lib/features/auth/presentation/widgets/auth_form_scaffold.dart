import 'package:flutter/material.dart';

import '../../../../core/widgets/widgets.dart';

/// Scrollable, keyboard-safe page shell shared by the logged-out auth screens:
/// an ink "hero" with kicker, heading and subtitle on top of the form.
class AuthFormScaffold extends StatelessWidget {
  const AuthFormScaffold({
    super.key,
    required this.title,
    required this.children,
    this.showBack = false,
    this.onBack,
    this.heading,
    this.subtitle,
    this.kicker,
    this.showBrand = false,
  });

  final String title;
  final String? heading;
  final String? subtitle;

  /// Small copper label above the heading.
  final String? kicker;

  /// Shows the SketchSquare lock-up in the hero (sign-in).
  final bool showBrand;
  final bool showBack;

  /// Overrides the default pop; needed when the screen was reached with `go`.
  final VoidCallback? onBack;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        automaticallyImplyLeading: false,
        leading: showBack ? BackButton(onPressed: onBack) : null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            AppSpacing.sm,
            AppSpacing.gutter,
            AppSpacing.xxl,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (heading != null) ...[
                    FadeSlideIn(
                      child: AuthHero(
                        heading: heading!,
                        subtitle: subtitle,
                        kicker: kicker,
                        showBrand: showBrand,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
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

/// Ink gradient + blueprint grid header card (same recipe as Home's hero).
class AuthHero extends StatelessWidget {
  const AuthHero({
    super.key,
    required this.heading,
    this.subtitle,
    this.kicker,
    this.showBrand = false,
  });

  final String heading;
  final String? subtitle;
  final String? kicker;
  final bool showBrand;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sem = AppSemanticColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(sem.ink, AppColors.blueprintBlue, 0.55)!,
            sem.ink,
          ],
        ),
        boxShadow: AppElevation.level2(theme.colorScheme.brightness),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Stack(
          children: [
            const Positioned.fill(
              child: CustomPaint(
                painter: BlueprintGridPainter(
                  color: Colors.white,
                  spacing: 22,
                  majorEvery: 4,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showBrand) ...[
                    const Wordmark(onDark: true),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                  if (kicker != null) ...[
                    Text(
                      kicker!.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.copperLight,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  Semantics(
                    header: true,
                    child: Text(
                      heading,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.78),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One-shot fade + short rise on first build; static when animations are off.
class FadeSlideIn extends StatelessWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = 14,
  });

  final Widget child;
  final Duration delay;
  final double offset;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return child;
    final total = AppMotion.slow + delay;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      curve: Interval(
        delay.inMilliseconds / total.inMilliseconds,
        1,
        curve: AppMotion.curve,
      ),
      builder:
          (context, t, child) => Opacity(
            opacity: t,
            child: Transform.translate(
              offset: Offset(0, (1 - t) * offset),
              child: child,
            ),
          ),
      child: child,
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
    this.enabled = true,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final String? forceErrorText;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final Iterable<String>? autofillHints;
  final bool enabled;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: widget.controller,
      label: widget.label,
      enabled: widget.enabled,
      prefixIcon: Icons.lock_outline_rounded,
      obscureText: _obscure,
      validator: widget.validator,
      forceErrorText: widget.forceErrorText,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      textInputAction: widget.textInputAction,
      onSubmitted: widget.onSubmitted,
      onChanged: widget.onChanged,
      autofillHints: widget.autofillHints,
      suffix: IconButton(
        tooltip: _obscure ? 'Show password' : 'Hide password',
        icon: Icon(
          _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        ),
        onPressed: () => setState(() => _obscure = !_obscure),
      ),
    );
  }
}
