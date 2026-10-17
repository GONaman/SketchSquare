import 'package:flutter/material.dart';

import '../../../core/widgets/widgets.dart';
import 'widgets/auth_form_scaffold.dart' show FadeSlideIn;

/// Shown while stored tokens are validated at startup.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sem = AppSemanticColors.of(context);
    return Scaffold(
      backgroundColor: sem.ink,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const BlueprintGrid(color: Colors.white, child: SizedBox.expand()),
          Center(
            child: FadeSlideIn(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const BrandMark(size: 72),
                  const SizedBox(height: AppSpacing.lg),
                  const Wordmark(onDark: true),
                  const SizedBox(height: AppSpacing.xl),
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white70,
                      semanticsLabel: 'Loading',
                    ),
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
