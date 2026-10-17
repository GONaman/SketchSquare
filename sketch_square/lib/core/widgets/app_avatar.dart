import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Circular avatar: network image when [url] loads, otherwise the initials on
/// a deterministic blueprint-toned background.
class AppAvatar extends StatelessWidget {
  const AppAvatar({super.key, required this.name, this.url, this.size = 44});

  final String name;
  final String? url;
  final double size;

  String get _initials {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fallback = DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primaryContainer,
            Color.lerp(scheme.primaryContainer, scheme.primary, 0.25)!,
          ],
        ),
      ),
      child: Center(
        child: Text(
          _initials,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: scheme.onPrimaryContainer,
            fontSize: size * 0.36,
          ),
          textScaler: TextScaler.noScaling,
        ),
      ),
    );
    final u = url;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: ClipOval(
          child:
              u == null
                  ? fallback
                  : CachedNetworkImage(
                    imageUrl: u,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => fallback,
                    errorWidget: (_, __, ___) => fallback,
                  ),
        ),
      ),
    );
  }
}
