import 'package:flutter/widgets.dart';

import 'breakpoints.dart';

/// How wide a screen's content may get before it is centred with margins.
enum ContentWidth {
  /// Feeds, detail pages, lists (1200).
  browse(Breakpoints.browseMaxWidth),

  /// Forms, auth, checkout, wallet, settings (560).
  form(Breakpoints.formMaxWidth),

  /// Edge to edge (maps, full-bleed heroes).
  full(double.infinity);

  const ContentWidth(this.maxWidth);

  final double maxWidth;
}

/// Centres [child] and caps its width. Backgrounds painted by an ancestor
/// (the Scaffold) stay full-bleed; only the content is framed.
class ContentFrame extends StatelessWidget {
  const ContentFrame({
    super.key,
    required this.child,
    this.width = ContentWidth.browse,
    this.maxWidth,
    this.alignment = Alignment.topCenter,
  });

  final Widget child;
  final ContentWidth width;

  /// Overrides [width] with an explicit cap.
  final double? maxWidth;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    final cap = maxWidth ?? width.maxWidth;
    if (cap.isInfinite) return child;
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: cap),
        child: child,
      ),
    );
  }
}

/// Drop-in for a `Scaffold.body` that should not stretch on wide windows.
/// Phones are unaffected because the cap is wider than any phone.
class AdaptiveScaffoldBody extends StatelessWidget {
  const AdaptiveScaffoldBody({
    super.key,
    required this.child,
    this.width = ContentWidth.browse,
  });

  final Widget child;
  final ContentWidth width;

  @override
  Widget build(BuildContext context) =>
      ContentFrame(width: width, child: child);
}
