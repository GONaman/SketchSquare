import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/widgets/widgets.dart';
import 'widgets/auth_form_scaffold.dart' show FadeSlideIn;
import 'intro_seen_provider.dart';
import 'intro_video_provider.dart';

/// First-run onboarding: muted autoplay demo video with tap-to-unmute, a Skip
/// button after [skipDelay], and Sign in / Create account always visible.
class IntroScreen extends ConsumerStatefulWidget {
  const IntroScreen({super.key});

  static const skipDelay = Duration(seconds: 3);

  @override
  ConsumerState<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends ConsumerState<IntroScreen> {
  Timer? _skipTimer;
  bool _canSkip = false;
  bool _muted = true;

  @override
  void initState() {
    super.initState();
    _skipTimer = Timer(IntroScreen.skipDelay, () {
      if (mounted) setState(() => _canSkip = true);
    });
  }

  @override
  void dispose() {
    _skipTimer?.cancel();
    super.dispose();
  }

  Future<void> _leave(String route, {bool push = true}) async {
    await ref.read(introSeenProvider.notifier).markSeen();
    if (!mounted) return;
    push ? context.push(route) : context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    final video = ref.watch(introVideoBuilderProvider);
    final theme = Theme.of(context);
    final sem = AppSemanticColors.of(context);
    return Scaffold(
      backgroundColor: sem.ink,
      body: Stack(
        fit: StackFit.expand,
        children: [
          video(context, _muted),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  sem.ink.withValues(alpha: 0.65),
                  sem.ink.withValues(alpha: 0.05),
                  sem.ink.withValues(alpha: 0.35),
                  sem.ink.withValues(alpha: 0.95),
                ],
                stops: const [0, 0.3, 0.55, 1],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Wordmark(onDark: true),
                            ),
                          ),
                          if (_canSkip)
                            FadeSlideIn(
                              offset: 0,
                              child: _GlassButton(
                                onPressed:
                                    () => _leave(AppRoutes.signIn, push: false),
                                child: const Text('Skip'),
                              ),
                            ),
                          const SizedBox(width: AppSpacing.sm),
                          _GlassButton(
                            square: true,
                            tooltip: _muted ? 'Unmute' : 'Mute',
                            onPressed: () => setState(() => _muted = !_muted),
                            child: Icon(
                              _muted
                                  ? Icons.volume_off_rounded
                                  : Icons.volume_up_rounded,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                      Expanded(
                        child: LayoutBuilder(
                          builder:
                              (context, box) => SingleChildScrollView(
                                reverse: true,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minHeight: box.maxHeight,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      FadeSlideIn(
                                        delay: const Duration(
                                          milliseconds: 150,
                                        ),
                                        child: Text(
                                          'FOR VERIFIED ARCHITECTS',
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                                color: AppColors.copperLight,
                                                letterSpacing: 1.4,
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.sm),
                                      FadeSlideIn(
                                        delay: const Duration(
                                          milliseconds: 250,
                                        ),
                                        child: Text(
                                          'Drawings by architects,\nfor architects.',
                                          style: theme.textTheme.displaySmall
                                              ?.copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                                height: 1.1,
                                              ),
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.md),
                                      FadeSlideIn(
                                        delay: const Duration(
                                          milliseconds: 350,
                                        ),
                                        child: Text(
                                          'Search plans by plot size. Buy, sell and download '
                                          'licensed drawings from verified professionals.',
                                          style: theme.textTheme.bodyLarge
                                              ?.copyWith(color: Colors.white70),
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.xl),
                                      FadeSlideIn(
                                        delay: const Duration(
                                          milliseconds: 450,
                                        ),
                                        child: Column(
                                          children: [
                                            SizedBox(
                                              width: double.infinity,
                                              child: FilledButton(
                                                style: FilledButton.styleFrom(
                                                  backgroundColor: Colors.white,
                                                  foregroundColor: sem.ink,
                                                ),
                                                onPressed:
                                                    () => _leave(
                                                      AppRoutes.signUp,
                                                      push: false,
                                                    ),
                                                child: const Text(
                                                  'Create account',
                                                ),
                                              ),
                                            ),
                                            const SizedBox(
                                              height: AppSpacing.sm,
                                            ),
                                            SizedBox(
                                              width: double.infinity,
                                              child: OutlinedButton(
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: Colors.white,
                                                  side: const BorderSide(
                                                    color: Colors.white54,
                                                    width: 1.5,
                                                  ),
                                                ),
                                                onPressed:
                                                    () => _leave(
                                                      AppRoutes.signIn,
                                                    ),
                                                child: const Text('Sign in'),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Translucent pill/circle control that stays legible over any video frame.
class _GlassButton extends StatelessWidget {
  const _GlassButton({
    required this.onPressed,
    required this.child,
    this.tooltip,
    this.square = false,
  });

  final VoidCallback onPressed;
  final Widget child;
  final String? tooltip;
  final bool square;

  @override
  Widget build(BuildContext context) {
    final button = TextButton(
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.white.withValues(alpha: 0.16),
        minimumSize: const Size(48, 48),
        padding:
            square
                ? EdgeInsets.zero
                : const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        shape:
            square
                ? const CircleBorder()
                : RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
      ),
      onPressed: onPressed,
      child: child,
    );
    return tooltip == null ? button : Tooltip(message: tooltip, child: button);
  }
}
