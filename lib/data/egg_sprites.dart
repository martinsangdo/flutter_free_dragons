import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/services.dart' show rootBundle;

/// The egg artwork drawn on the goal block.
///
/// [BoardPainter] is a `CustomPainter`, so it needs decoded `ui.Image`s rather
/// than `AssetImage`s — those can't be handed to `Canvas.drawImageRect`. This
/// decodes all of them once at startup (from the splash screen, alongside the
/// other precaching) and hands out the result synchronously afterwards, so
/// painting never has to await anything.
class EggSprites {
  EggSprites._();

  static const int count = 8;

  static List<ui.Image> _images = const [];
  static Future<void>? _loading;

  /// True once [load] has completed and [forLevel] can return artwork.
  static bool get isLoaded => _images.isNotEmpty;

  /// Decode every egg sprite. Safe to call repeatedly — concurrent callers
  /// share the same future, and later calls are a no-op.
  static Future<void> load() {
    if (isLoaded) return Future.value();
    return _loading ??= _load();
  }

  static Future<void> _load() async {
    final decoded = <ui.Image>[];
    for (int i = 1; i <= count; i++) {
      final data = await rootBundle.load('assets/images/eggs/$i.png');
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      decoded.add((await codec.getNextFrame()).image);
    }
    _images = decoded;
  }

  /// The egg for a given level, chosen pseudo-randomly but *deterministically*
  /// so that retrying or reopening a level shows the same egg — a board whose
  /// goal block changed colour on every restart would read as a glitch.
  ///
  /// Returns null if [load] hasn't finished, in which case the painter falls
  /// back to drawing the goal block without artwork.
  static ui.Image? forLevel(int levelNumber) {
    if (!isLoaded) return null;
    return _images[Random(levelNumber).nextInt(_images.length)];
  }

  /// A stable sprite for non-gameplay surfaces (the how-to-play diagrams).
  static ui.Image? get sample => isLoaded ? _images.first : null;
}
