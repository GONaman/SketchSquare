import 'package:flutter/material.dart';

import '../../../core/widgets/placeholder_screen.dart';

class BasketScreen extends StatelessWidget {
  const BasketScreen({super.key});

  @override
  Widget build(BuildContext context) => const PlaceholderScreen(
    title: 'Basket',
    icon: Icons.shopping_basket_outlined,
    message: 'Drawings you add will appear here.',
  );
}
