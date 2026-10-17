import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/routes.dart';
import '../../../core/widgets/widgets.dart';
import 'checkout_controller.dart';

enum _Outcome { success, pending, failure, none }

/// Result of the last checkout: success, failure, or "still confirming".
class OrderResultScreen extends ConsumerWidget {
  const OrderResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(checkoutControllerProvider);
    final controller = ref.read(checkoutControllerProvider.notifier);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final sem = AppSemanticColors.of(context);

    void backToBasket() {
      controller.reset();
      context.go(AppRoutes.basket);
    }

    final (outcome, title, message, actions) = switch (state) {
      CheckoutSuccess(:final amountPaise) => (
        _Outcome.success,
        'Payment successful',
        amountPaise == null
            ? 'Your drawings are ready to download.'
            : '${formatPaise(amountPaise)} paid. Your drawings are ready to download.',
        <Widget>[
          PrimaryButton(
            label: 'View my purchases',
            icon: Icons.download_rounded,
            onPressed: () {
              controller.reset();
              context.go(AppRoutes.purchases);
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: () {
              controller.reset();
              context.go(AppRoutes.home);
            },
            child: const Text('Continue browsing'),
          ),
        ],
      ),
      CheckoutPending() => (
        _Outcome.pending,
        'Confirming payment',
        'We have not received confirmation yet. If money was deducted, your '
            'drawings will appear in My purchases shortly.',
        <Widget>[
          PrimaryButton(
            label: 'Check status',
            icon: Icons.refresh_rounded,
            onPressed: controller.resumePending,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: backToBasket,
            child: const Text('Back to basket'),
          ),
        ],
      ),
      CheckoutFailure(:final message) => (
        _Outcome.failure,
        'Payment failed',
        message,
        <Widget>[
          PrimaryButton(
            label: 'Try again',
            icon: Icons.refresh_rounded,
            onPressed: () {
              controller.reset();
              context.go(AppRoutes.basketCheckout);
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: backToBasket,
            child: const Text('Back to basket'),
          ),
        ],
      ),
      _ => (
        _Outcome.none,
        'Nothing to show',
        'There is no recent order.',
        <Widget>[
          PrimaryButton(label: 'Back to basket', onPressed: backToBasket),
        ],
      ),
    };

    final (orderId, amountPaise) = switch (state) {
      CheckoutSuccess(:final orderId, :final amountPaise) => (
        orderId,
        amountPaise,
      ),
      CheckoutPending(:final orderId, :final amountPaise) => (
        orderId,
        amountPaise,
      ),
      CheckoutFailure(:final orderId) => (orderId, null),
      _ => (null, null),
    };

    final tone = switch (outcome) {
      _Outcome.success => sem.success,
      _Outcome.pending => sem.warning,
      _Outcome.failure => scheme.error,
      _Outcome.none => scheme.primary,
    };
    final icon = switch (outcome) {
      _Outcome.success => Icons.check_rounded,
      _Outcome.pending => Icons.hourglass_top_rounded,
      _Outcome.failure => Icons.priority_high_rounded,
      _Outcome.none => Icons.shopping_basket_outlined,
    };

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) backToBasket();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Order'),
          automaticallyImplyLeading: false,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            AppSpacing.sm,
            AppSpacing.gutter,
            AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InkHeroCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.xl,
                ),
                child: Column(
                  children: [
                    _ResultBadge(
                      key: ValueKey(outcome),
                      icon: icon,
                      color: tone,
                      checkmark: outcome == _Outcome.success,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Semantics(
                      header: true,
                      liveRegion: true,
                      child: Text(
                        title,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.82),
                      ),
                    ),
                  ],
                ),
              ),
              if (orderId != null) ...[
                const SizedBox(height: AppSpacing.lg),
                _Receipt(
                  orderId: orderId,
                  amountPaise: amountPaise,
                  outcome: outcome,
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              ...actions,
            ],
          ),
        ),
      ),
    );
  }
}

class _Receipt extends StatelessWidget {
  const _Receipt({
    required this.orderId,
    required this.amountPaise,
    required this.outcome,
  });

  final String orderId;
  final int? amountPaise;
  final _Outcome outcome;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shortId =
        orderId.length > 8
            ? orderId.substring(orderId.length - 8).toUpperCase()
            : orderId.toUpperCase();
    final (statusLabel, tone) = switch (outcome) {
      _Outcome.success => ('Paid', StatusTone.success),
      _Outcome.pending => ('Confirming', StatusTone.warning),
      _ => ('Not completed', StatusTone.danger),
    };
    return AppCard(
      style: AppCardStyle.outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Receipt', style: theme.textTheme.titleMedium),
              ),
              StatusPill(label: statusLabel, tone: tone, dense: true),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SummaryRow(label: 'Order', value: '#$shortId'),
          SummaryRow(
            label: 'Date',
            value: DateFormat('d MMM yyyy, h:mm a').format(DateTime.now()),
          ),
          if (amountPaise != null) ...[
            const Divider(height: AppSpacing.lg),
            SummaryRow(
              label: outcome == _Outcome.success ? 'Amount paid' : 'Amount',
              value: formatPaise(amountPaise!),
              emphasis: true,
            ),
          ],
          if (outcome == _Outcome.success) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.workspace_premium_outlined,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Each download is licensed to you for your own projects '
                    'and carries your licence footer.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Round status medallion that pops in; the success check draws itself.
class _ResultBadge extends StatelessWidget {
  const _ResultBadge({
    super.key,
    required this.icon,
    required this.color,
    required this.checkmark,
  });

  final IconData icon;
  final Color color;
  final bool checkmark;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.of(context).disableAnimations;
    final duration = reduce ? Duration.zero : AppMotion.slow * 2;
    return ExcludeSemantics(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: duration,
        curve: Curves.easeOutCubic,
        builder: (context, t, _) {
          final pop = Curves.elasticOut.transform(math.min(1, t * 1.4));
          return Transform.scale(
            scale: 0.4 + 0.6 * pop,
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.45),
                    blurRadius: 28 * t,
                    spreadRadius: 4 * t,
                  ),
                ],
              ),
              child:
                  checkmark
                      ? CustomPaint(painter: _CheckPainter(progress: t))
                      : Icon(icon, size: 40, color: Colors.white),
            ),
          );
        },
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  const _CheckPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path =
        Path()
          ..moveTo(w * 0.29, h * 0.53)
          ..lineTo(w * 0.44, h * 0.67)
          ..lineTo(w * 0.72, h * 0.37);
    final p = ((progress - 0.25) / 0.6).clamp(0.0, 1.0);
    final paint =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
    for (final m in path.computeMetrics()) {
      canvas.drawPath(m.extractPath(0, m.length * p), paint);
    }
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.progress != progress;
}
