import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/widgets/widgets.dart';
import '../upload_flow_controller.dart';
import '../upload_flow_state.dart';
import 'listing_preview.dart';

/// Shown instead of the steps once the drawing is being processed or finished.
class PublishStatusView extends ConsumerWidget {
  const PublishStatusView({super.key, required this.onStartNew});

  final VoidCallback onStartNew;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(uploadFlowProvider);
    final c = ref.read(uploadFlowProvider.notifier);
    final scheme = Theme.of(context).colorScheme;
    final sem = AppSemanticColors.of(context);

    Widget layout({
      required Widget hero,
      required String title,
      String? message,
      Widget? body,
      required List<Widget> actions,
    }) {
      final theme = Theme.of(context);
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            AppSpacing.xl,
            AppSpacing.gutter,
            AppSpacing.xl,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                hero,
                const SizedBox(height: AppSpacing.xl),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall,
                ),
                if (message != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (body != null) ...[
                  const SizedBox(height: AppSpacing.xl),
                  body,
                ],
                const SizedBox(height: AppSpacing.xl),
                ...actions,
              ],
            ),
          ),
        ),
      );
    }

    switch (s.phase) {
      case PublishPhase.idle:
        return const SizedBox.shrink();
      case PublishPhase.publishing:
      case PublishPhase.processing:
        return layout(
          hero:
              s.pollStalled
                  ? _HeroBadge(
                    icon: Icons.hourglass_bottom,
                    color: sem.warning,
                    onColor: sem.onWarning,
                  )
                  : const _ProcessingHero(),
          title:
              s.pollStalled ? 'Still processing…' : 'Generating your previews…',
          message:
              s.pollStalled
                  ? "We couldn't get an update. Your drawing is safe and "
                      'processing continues on our side.'
                  : 'Watermarking and rendering your sheets. You can leave '
                      'this screen; your drawing will be here when you return.',
          body: _Pipeline(stalled: s.pollStalled),
          actions: [
            if (s.pollStalled)
              PrimaryButton(
                key: const ValueKey('check-again'),
                label: 'Check again',
                icon: Icons.refresh,
                onPressed: c.resumePolling,
              ),
          ],
        );
      case PublishPhase.published:
        return layout(
          hero: const _CelebrationHero(),
          title: 'Your drawing is live',
          message: '${s.form.title} is now visible in the marketplace.',
          body: const ListingPreview(),
          actions: _finishedActions(context, onStartNew),
        );
      case PublishPhase.underReview:
        return layout(
          hero: _HeroBadge(
            icon: Icons.fact_check_outlined,
            color: scheme.primary,
            onColor: scheme.onPrimary,
          ),
          title: 'Under review by admins',
          message:
              '${s.form.title} looks similar to an existing drawing, so our '
              'team will review it before it goes live. It is not visible to '
              "others until then, and you'll be emailed the decision.",
          actions: _finishedActions(context, onStartNew),
        );
      case PublishPhase.failed:
        return layout(
          hero: _HeroBadge(
            icon: Icons.error_outline,
            color: scheme.error,
            onColor: scheme.onError,
          ),
          title: "We couldn't process this drawing",
          message: s.failureReason ?? 'Something went wrong while processing.',
          actions: [
            PrimaryButton(
              key: const ValueKey('retry-publish'),
              label: 'Try again',
              icon: Icons.refresh,
              onPressed: c.retryPublish,
            ),
            const SizedBox(height: AppSpacing.sm),
            SecondaryButton(
              key: const ValueKey('edit-after-failure'),
              label: 'Edit drawing',
              icon: Icons.edit_outlined,
              onPressed: c.editAfterFailure,
            ),
          ],
        );
    }
  }
}

List<Widget> _finishedActions(BuildContext context, VoidCallback onStartNew) =>
    [
      PrimaryButton(
        key: const ValueKey('start-new'),
        label: 'Upload another drawing',
        icon: Icons.add,
        onPressed: onStartNew,
      ),
      const SizedBox(height: AppSpacing.sm),
      SecondaryButton(
        key: const ValueKey('open-manage-drawings'),
        label: 'Manage drawings',
        icon: Icons.inventory_2_outlined,
        onPressed: () => context.push(AppRoutes.manageDrawings),
      ),
    ];

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({
    required this.icon,
    required this.color,
    required this.onColor,
  });

  final IconData icon;
  final Color color;
  final Color onColor;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.14),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: DecoratedBox(
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Icon(icon, size: 36, color: onColor),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProcessingHero extends StatelessWidget {
  const _ProcessingHero();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox.square(
      dimension: 112,
      child: Stack(
        alignment: Alignment.center,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scheme.primaryContainer,
            ),
            child: const SizedBox.expand(),
          ),
          Icon(Icons.architecture, size: 40, color: scheme.onPrimaryContainer),
          SizedBox.expand(
            child: CircularProgressIndicator(
              key: const ValueKey('processing-spinner'),
              strokeWidth: 4,
              strokeCap: StrokeCap.round,
              semanticsLabel: 'Processing your drawing',
            ),
          ),
        ],
      ),
    );
  }
}

/// What happens after Publish. Honest about stages we cannot observe: only
/// the upload is known to be finished.
class _Pipeline extends StatelessWidget {
  const _Pipeline({required this.stalled});

  final bool stalled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final steps = [
      ('Sheets uploaded', _StepState.done),
      ('Watermarking previews', _StepState.active),
      ('Quality checks', _StepState.pending),
      ('Going live', _StepState.pending),
    ];
    return AppCard(
      style: AppCardStyle.tonal,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Column(
        children: [
          for (final (label, state) in steps)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                children: [
                  switch (state) {
                    _StepState.done => Icon(
                      Icons.check_circle,
                      size: 22,
                      color: scheme.primary,
                    ),
                    _StepState.active => Icon(
                      stalled ? Icons.pause_circle_outline : Icons.timelapse,
                      size: 22,
                      color: scheme.primary,
                    ),
                    _StepState.pending => Icon(
                      Icons.radio_button_unchecked,
                      size: 22,
                      color: scheme.outline,
                    ),
                  },
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight:
                            state == _StepState.active
                                ? FontWeight.w700
                                : FontWeight.w400,
                        color:
                            state == _StepState.pending
                                ? scheme.onSurfaceVariant
                                : scheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

enum _StepState { done, active, pending }

/// Check badge that pops in with a one-shot confetti burst. Static when the
/// platform asks to reduce motion.
class _CelebrationHero extends StatefulWidget {
  const _CelebrationHero();

  @override
  State<_CelebrationHero> createState() => _CelebrationHeroState();
}

class _CelebrationHeroState extends State<_CelebrationHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.of(context).disableAnimations) {
      _c.value = 1;
    } else {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final sem = AppSemanticColors.of(context);
    final colors = [scheme.primary, sem.accent, sem.success, scheme.tertiary];
    return ExcludeSemantics(
      child: SizedBox(
        width: 220,
        height: 140,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final pop = Curves.elasticOut.transform(
              (_c.value / 0.5).clamp(0.0, 1.0),
            );
            return Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _ConfettiPainter(_c.value, colors),
                  ),
                ),
                Transform.scale(
                  scale: 0.4 + 0.6 * pop,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: sem.success.withValues(alpha: 0.16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: sem.success,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Icon(
                            Icons.check,
                            size: 40,
                            color: sem.onSuccess,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.t, this.colors);

  final double t;
  final List<Color> colors;

  static const _count = 26;

  @override
  void paint(Canvas canvas, Size size) {
    if (t >= 1) return;
    final centre = size.center(Offset.zero);
    final rnd = math.Random(7);
    final eased = Curves.easeOutCubic.transform(t);
    for (var i = 0; i < _count; i++) {
      final angle = (i / _count) * math.pi * 2 + rnd.nextDouble() * 0.4;
      final dist = 50 + rnd.nextDouble() * 60;
      final spin = rnd.nextDouble() * math.pi * 2;
      final w = 4.0 + rnd.nextDouble() * 4;
      final pos =
          centre +
          Offset(
            math.cos(angle) * dist * eased,
            math.sin(angle) * dist * eased,
          ) +
          Offset(0, 28 * t * t);
      canvas
        ..save()
        ..translate(pos.dx, pos.dy)
        ..rotate(spin + t * 6);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: w, height: w * 1.8),
          const Radius.circular(1.5),
        ),
        Paint()
          ..color = colors[i % colors.length].withValues(
            alpha: (1 - t).clamp(0.0, 1.0),
          ),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
