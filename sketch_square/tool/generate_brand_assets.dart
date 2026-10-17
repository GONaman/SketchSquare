// Generates the brand source images under assets/branding/.
// Run from sketch_square/:  dart run tool/generate_brand_assets.dart
// Then:  dart run flutter_launcher_icons && dart run flutter_native_splash:create
import 'dart:io';

import 'package:image/image.dart' as img;

const _blue = 0xFF1F3A93;
const _size = 1024;

img.ColorRgba8 _c(int argb, [double opacity = 1]) => img.ColorRgba8(
  (argb >> 16) & 0xFF,
  (argb >> 8) & 0xFF,
  argb & 0xFF,
  (((argb >> 24) & 0xFF) * opacity).round(),
);

/// White at [opacity] pre-blended over the blue background (the grid is drawn
/// onto opaque canvases, where `fillRect` would overwrite instead of blend).
img.ColorRgba8 _gridColor(double opacity) {
  int mix(int bg) => (bg + (255 - bg) * opacity).round();
  return img.ColorRgba8(
    mix((_blue >> 16) & 0xFF),
    mix((_blue >> 8) & 0xFF),
    mix(_blue & 0xFF),
    255,
  );
}

/// Blueprint grid: fine lines every 64px, heavier every 256px.
void _grid(img.Image image) {
  for (var p = 0; p <= image.height; p += 64) {
    final major = p % 256 == 0;
    final color = _gridColor(major ? 0.22 : 0.10);
    final t = major ? 3 : 1;
    img.fillRect(image, x1: 0, y1: p, x2: image.width, y2: p + t, color: color);
  }
  for (var p = 0; p <= image.width; p += 64) {
    final major = p % 256 == 0;
    final color = _gridColor(major ? 0.22 : 0.10);
    final t = major ? 3 : 1;
    img.fillRect(
      image,
      x1: p,
      y1: 0,
      x2: p + t,
      y2: image.height,
      color: color,
    );
  }
}

/// A square drawn as a sketch: outline, diagonal, inner square and a
/// dimension line. [inset] is the margin to the canvas edge (keep >= 25% for
/// adaptive icons so the mark survives the circular mask).
void _mark(img.Image image, {required int inset, required img.Color color}) {
  final lo = inset;
  final hi = _size - inset;
  final w = ((hi - lo) * 0.045).round();
  void line(int x1, int y1, int x2, int y2) => img.drawLine(
    image,
    x1: x1,
    y1: y1,
    x2: x2,
    y2: y2,
    color: color,
    thickness: w,
  );

  line(lo, lo, hi, lo);
  line(hi, lo, hi, hi);
  line(hi, hi, lo, hi);
  line(lo, hi, lo, lo);
  line(lo, hi, hi, lo);
  final q = ((hi - lo) * 0.28).round();
  final c = (lo + hi) ~/ 2;
  img.drawRect(
    image,
    x1: c - q,
    y1: c - q,
    x2: c + q,
    y2: c + q,
    color: color,
    thickness: (w * 0.6).round(),
  );
  final dy = hi + ((_size - hi) * 0.45).round();
  if (dy + w * 2 < _size) {
    line(lo, dy, hi, dy);
    line(lo, dy - w * 2, lo, dy + w * 2);
    line(hi, dy - w * 2, hi, dy + w * 2);
  }
}

void _save(String path, img.Image image) {
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(img.encodePng(image));
  stdout.writeln('wrote $path');
}

void main() {
  // Full icon: blueprint background + grid + mark (iOS, legacy Android, web).
  final icon = img.Image(width: _size, height: _size, numChannels: 4);
  img.fill(icon, color: _c(_blue));
  _grid(icon);
  _mark(icon, inset: 230, color: _c(0xFFFFFFFF));
  _save('assets/branding/app_icon.png', icon);

  // Adaptive foreground: transparent, mark inside the 66% safe zone.
  final fg = img.Image(width: _size, height: _size, numChannels: 4);
  _mark(fg, inset: 300, color: _c(0xFFFFFFFF));
  _save('assets/branding/app_icon_foreground.png', fg);

  // Splash mark (shown on the blue splash background).
  final splash = img.Image(width: _size, height: _size, numChannels: 4);
  _mark(splash, inset: 280, color: _c(0xFFFFFFFF));
  _save('assets/branding/splash_logo.png', splash);

  // Static fallback for the intro screen when the video cannot play.
  final intro = img.Image(width: 1080, height: 1920, numChannels: 4);
  img.fill(intro, color: _c(_blue));
  _grid(intro);
  final mark = img.Image(width: _size, height: _size, numChannels: 4);
  _mark(mark, inset: 200, color: _c(0xFFFFFFFF));
  img.compositeImage(
    intro,
    img.copyResize(mark, width: 720),
    dstX: 180,
    dstY: 600,
  );
  _save('assets/branding/intro_fallback.png', intro);
}
