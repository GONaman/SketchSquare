import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';

/// Material scrolling plus mouse/trackpad dragging so carousels and the
/// drawing gallery can be dragged with a pointer on desktop web. Desktop
/// platforms already get a [Scrollbar] from the base behaviour.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    ...super.dragDevices,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
  };
}
