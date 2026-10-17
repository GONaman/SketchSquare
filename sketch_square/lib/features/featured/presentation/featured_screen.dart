import 'package:flutter/material.dart';

import '../../../core/widgets/placeholder_screen.dart';

class FeaturedScreen extends StatelessWidget {
  const FeaturedScreen({super.key});

  @override
  Widget build(BuildContext context) => const PlaceholderScreen(
    title: 'Featured',
    icon: Icons.star_outline,
    message: 'Top architects and highest-rated drawings.',
  );
}
