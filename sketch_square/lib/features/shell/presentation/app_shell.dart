import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_tokens.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _items = <_NavItem>[
    _NavItem(Icons.home_outlined, Icons.home_rounded, 'Home'),
    _NavItem(Icons.star_outline_rounded, Icons.star_rounded, 'Featured'),
    _NavItem(Icons.add_box_outlined, Icons.add_box_rounded, 'Upload'),
    _NavItem(
      Icons.shopping_basket_outlined,
      Icons.shopping_basket_rounded,
      'Basket',
    ),
    _NavItem(Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLowest,
          border: Border(top: BorderSide(color: scheme.outlineVariant)),
        ),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          destinations: [
            for (var i = 0; i < _items.length; i++)
              NavigationDestination(
                icon: _items[i].icon(false),
                selectedIcon: _items[i].icon(true),
                label: _items[i].label,
              ),
          ],
          onDestinationSelected:
              (index) => navigationShell.goBranch(
                index,
                // Re-tapping the active tab pops it back to its root.
                initialLocation: index == navigationShell.currentIndex,
              ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.outlined, this.filled, this.label);

  final IconData outlined;
  final IconData filled;
  final String label;

  /// The selected icon pops in with a small overshoot.
  Widget icon(bool selected) =>
      selected
          ? TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.8, end: 1),
            duration: AppMotion.slow,
            curve: Curves.elasticOut,
            builder: (_, v, child) => Transform.scale(scale: v, child: child),
            child: Icon(filled),
          )
          : Icon(outlined);
}
