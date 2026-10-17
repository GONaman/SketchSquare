import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/layout/layout.dart';
import '../../../core/router/route_content_width.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/brand_mark.dart';
import '../../drawings/presentation/discovery_paths.dart';

/// Adaptive app chrome around the tab branches: a bottom [NavigationBar] on
/// phones, a [NavigationRail] on tablets / narrow windows and a top navigation
/// bar (brand, tabs, search, basket, profile) on desktop/web. Branch order is
/// nav order.
class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.navigationShell,
    this.location = '',
  });

  final StatefulNavigationShell navigationShell;

  /// Current location path; picks the content width (see
  /// [contentWidthForPath]).
  final String location;

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

  void _select(int index) => navigationShell.goBranch(
    index,
    // Re-tapping the active tab pops it back to its root.
    initialLocation: index == navigationShell.currentIndex,
  );

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final screen = Breakpoints.of(size.width);
    final selected = navigationShell.currentIndex;

    if (screen.isCompact) {
      return Scaffold(
        body: navigationShell,
        bottomNavigationBar: _BottomBar(selected: selected, onSelect: _select),
      );
    }

    final body = ContentFrame(
      width: contentWidthForPath(location),
      child: navigationShell,
    );

    if (screen.isExpanded) {
      return Scaffold(
        body: Column(
          children: [
            _TopNavBar(
              selected: selected,
              onSelect: _select,
              onSearch:
                  () => context.go(
                    const DiscoveryPaths(AppRoutes.home).search(),
                    extra: true,
                  ),
            ),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          _Rail(
            selected: selected,
            onSelect: _select,
            compactHeight: size.height < 480,
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.selected, required this.onSelect});

  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: NavigationBar(
        selectedIndex: selected,
        destinations: [
          for (final item in AppShell._items)
            NavigationDestination(
              icon: item.icon(false),
              selectedIcon: item.icon(true),
              label: item.label,
            ),
        ],
        onDestinationSelected: onSelect,
      ),
    );
  }
}

class _Rail extends StatelessWidget {
  const _Rail({
    required this.selected,
    required this.onSelect,
    required this.compactHeight,
  });

  final int selected;
  final ValueChanged<int> onSelect;

  /// Short windows (landscape phones) drop labels and the brand mark so the
  /// five destinations still fit.
  final bool compactHeight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        border: Border(right: BorderSide(color: scheme.outlineVariant)),
      ),
      child: NavigationRail(
        key: const Key('nav-rail'),
        selectedIndex: selected,
        backgroundColor: Colors.transparent,
        labelType:
            compactHeight
                ? NavigationRailLabelType.none
                : NavigationRailLabelType.all,
        indicatorColor: scheme.primaryContainer,
        leading:
            compactHeight
                ? null
                : const Padding(
                  padding: EdgeInsets.only(
                    top: AppSpacing.sm,
                    bottom: AppSpacing.lg,
                  ),
                  child: BrandMark(size: 36),
                ),
        destinations: [
          for (final item in AppShell._items)
            NavigationRailDestination(
              icon: item.icon(false),
              selectedIcon: item.icon(true),
              label: Text(item.label),
            ),
        ],
        onDestinationSelected: onSelect,
      ),
    );
  }
}

class _TopNavBar extends StatelessWidget {
  const _TopNavBar({
    required this.selected,
    required this.onSelect,
    required this.onSearch,
  });

  final int selected;
  final ValueChanged<int> onSelect;
  final VoidCallback onSearch;

  static const _tabIndexes = [0, 1, 2];
  static const _basket = 3;
  static const _profile = 4;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      key: const Key('top-nav'),
      color: scheme.surfaceContainerLowest,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
        ),
        child: SizedBox(
          height: 64,
          child: ContentFrame(
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.gutter,
              ),
              child: Row(
                children: [
                  _Brand(onTap: () => onSelect(0)),
                  const SizedBox(width: AppSpacing.xl),
                  for (final i in _tabIndexes)
                    _TopNavLink(
                      item: AppShell._items[i],
                      selected: selected == i,
                      onTap: () => onSelect(i),
                    ),
                  const Spacer(),
                  Flexible(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 300),
                      child: _TopSearch(onTap: onSearch),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  _TopIconButton(
                    key: const Key('top-nav-basket'),
                    item: AppShell._items[_basket],
                    selected: selected == _basket,
                    onTap: () => onSelect(_basket),
                  ),
                  _TopIconButton(
                    key: const Key('top-nav-profile'),
                    item: AppShell._items[_profile],
                    selected: selected == _profile,
                    onTap: () => onSelect(_profile),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'SketchSquare home',
      child: InkWell(
        key: const Key('top-nav-brand'),
        borderRadius: AppRadius.controlRadius,
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Wordmark(),
        ),
      ),
    );
  }
}

class _TopNavLink extends StatelessWidget {
  const _TopNavLink({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      excludeSemantics: true,
      child: InkWell(
        key: Key('top-nav-${item.label.toLowerCase()}'),
        onTap: onTap,
        borderRadius: AppRadius.controlRadius,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 4),
              SizedBox(
                height: 52,
                child: Center(
                  child: Text(
                    item.label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontSize: 15,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color:
                          selected ? scheme.primary : scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              AnimatedContainer(
                duration: AppMotion.base,
                height: 3,
                width: selected ? 24 : 0,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
              const SizedBox(height: 5),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopSearch extends StatelessWidget {
  const _TopSearch({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: 'Search drawings',
      excludeSemantics: true,
      child: Material(
        color: scheme.surfaceContainerHigh,
        shape: StadiumBorder(side: BorderSide(color: scheme.outlineVariant)),
        child: InkWell(
          key: const Key('top-nav-search'),
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: 10,
            ),
            child: Row(
              children: [
                Icon(Icons.search_rounded, size: 20, color: scheme.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Search drawings',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopIconButton extends StatelessWidget {
  const _TopIconButton({
    super.key,
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: item.label,
      isSelected: selected,
      icon: Icon(item.outlined),
      selectedIcon: Icon(item.filled),
      style:
          selected
              ? IconButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              )
              : null,
      onPressed: onTap,
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
