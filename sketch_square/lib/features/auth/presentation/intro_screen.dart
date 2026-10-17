import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          video(context, _muted),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black45, Colors.transparent, Colors.black87],
                stops: [0, 0.4, 1],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        tooltip: _muted ? 'Unmute' : 'Mute',
                        color: Colors.white,
                        icon: Icon(_muted ? Icons.volume_off : Icons.volume_up),
                        onPressed: () => setState(() => _muted = !_muted),
                      ),
                      const Spacer(),
                      if (_canSkip)
                        TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                          ),
                          onPressed:
                              () => _leave(AppRoutes.signIn, push: false),
                          child: const Text('Skip'),
                        ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    'Drawings by architects,\nfor architects.',
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.headlineSmall?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => _leave(AppRoutes.signUp, push: false),
                    child: const Text('Create account'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white70),
                    ),
                    onPressed: () => _leave(AppRoutes.signIn),
                    child: const Text('Sign in'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
