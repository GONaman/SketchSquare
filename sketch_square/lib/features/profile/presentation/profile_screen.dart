import 'package:flutter/material.dart';

import '../../../core/widgets/placeholder_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) => const PlaceholderScreen(
    title: 'Profile',
    icon: Icons.person_outline,
    message: 'Your drawings, purchases and wallet.',
  );
}
