import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'intro_video.dart';

part 'intro_video_provider.g.dart';

typedef IntroVideoBuilder = Widget Function(BuildContext context, bool muted);

/// Builds the intro video widget; tests override it (no video plugin in
/// `flutter test`).
@Riverpod(keepAlive: true)
IntroVideoBuilder introVideoBuilder(Ref ref) =>
    (context, muted) => IntroVideo(muted: muted);
