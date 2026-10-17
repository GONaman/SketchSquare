import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// True when [path] resolves to a registered route.
bool isRouteRegistered(GoRouter router, String path) =>
    !router.configuration.findMatch(Uri.parse(path)).isError;

/// Pushes [path] if some feature has registered it, otherwise tells the user
/// it is not available yet. Lets screens link to routes owned by features
/// that may not have landed.
void pushIfRegistered(BuildContext context, String path) {
  final router = GoRouter.of(context);
  if (isRouteRegistered(router, path)) {
    router.push(path);
  } else {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Coming soon')));
  }
}
