import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../core/widgets/blueprint_grid.dart';

/// Looping, muted-by-default intro clip (`assets/videos/intro.mp4`). Falls back
/// to the blueprint grid if the video cannot be played, so the intro screen
/// never blocks sign-in.
class IntroVideo extends StatefulWidget {
  const IntroVideo({super.key, required this.muted});

  static const asset = 'assets/videos/intro.mp4';

  final bool muted;

  @override
  State<IntroVideo> createState() => _IntroVideoState();
}

class _IntroVideoState extends State<IntroVideo> {
  late final VideoPlayerController _controller;
  bool _ready = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(IntroVideo.asset);
    _start();
  }

  Future<void> _start() async {
    try {
      await _controller.initialize();
      await _controller.setLooping(true);
      await _controller.setVolume(widget.muted ? 0 : 1);
      await _controller.play();
      if (mounted) setState(() => _ready = true);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void didUpdateWidget(IntroVideo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.muted != widget.muted && _ready) {
      _controller.setVolume(widget.muted ? 0 : 1);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_ready && !_failed) {
      return FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: _controller.value.size.width,
          height: _controller.value.size.height,
          child: VideoPlayer(_controller),
        ),
      );
    }
    return ColoredBox(
      color: Theme.of(context).colorScheme.primary,
      child: BlueprintGrid(
        color: Colors.white,
        child: Center(
          child:
              _failed
                  ? const Icon(
                    Icons.architecture,
                    size: 72,
                    color: Colors.white70,
                  )
                  : const SizedBox.shrink(),
        ),
      ),
    );
  }
}
