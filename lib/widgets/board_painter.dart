import 'dart:math';

import 'package:flutter/material.dart';
import '../models/block.dart';
import '../theme/app_colors.dart';
import '../data/constants.dart';

/// Renders the board for the **Ancient Temple / Relic Vault** theme.
///
/// The board is a carved stone slab with a recessed socket per cell; obstacle
/// blocks are raised, bevelled stone monoliths with chiselled texture and
/// engraved rune arrows; the goal block is a relic egg resting on a glowing
/// golden plinth; and the exit is a radiant portal on the exit row. Everything
/// is drawn procedurally against [cellSize], so the look scales with the board.
class BoardPainter extends CustomPainter {
  final List<Block> blocks;
  final double cellSize;
  final int? draggingId;
  final int? hintBlockId;
  final double exitPulse; // 0.0–1.0 animation value

  /// Seed that picks which egg colourway the goal block wears. Deterministic
  /// per level (typically the level number), so retrying a level shows the same
  /// egg. The egg itself is drawn as vector art — see [_drawEgg] — so it stays
  /// razor-sharp at any board size or screen density.
  final int eggSeed;

  BoardPainter({
    required this.blocks,
    required this.cellSize,
    this.draggingId,
    this.hintBlockId,
    this.exitPulse = 0.0,
    this.eggSeed = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawBoard(canvas, size);
    _drawExit(canvas);
    _drawBlocks(canvas);
  }

  // ---------------------------------------------------------------------------
  // Board: a carved temple floor with recessed sockets and a torch-lit vignette.
  // ---------------------------------------------------------------------------
  void _drawBoard(Canvas canvas, Size size) {
    final boardRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(16),
    );

    // Stone slab, lit from above so the top reads brighter than the base.
    canvas.drawRRect(
      boardRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.templeFloor, AppColors.templeFloorDeep],
        ).createShader(Offset.zero & size),
    );

    canvas.save();
    canvas.clipRRect(boardRect);

    // A recessed socket per cell — this is the grid, carved rather than drawn
    // as bright lines. Shadow banks along the top/left, a faint light licks the
    // bottom/right, so each cell looks sunk into the slab.
    final inset = cellSize * 0.05;
    final slotRadius = Radius.circular(cellSize * 0.16);
    final slotFill = Paint()..color = AppColors.templeSlot;
    final slotShade = Paint()
      ..color = Colors.black.withOpacity(0.45)
      ..strokeWidth = 1.5;
    final slotLight = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 1.0;

    for (int r = 0; r < kGridSize; r++) {
      for (int c = 0; c < kGridSize; c++) {
        final cell = Rect.fromLTWH(
          c * cellSize + inset,
          r * cellSize + inset,
          cellSize - inset * 2,
          cellSize - inset * 2,
        );
        canvas.drawRRect(RRect.fromRectAndRadius(cell, slotRadius), slotFill);
        canvas.drawLine(cell.topLeft, cell.topRight, slotShade);
        canvas.drawLine(cell.topLeft, cell.bottomLeft, slotShade);
        canvas.drawLine(cell.bottomLeft, cell.bottomRight, slotLight);
        canvas.drawLine(cell.topRight, cell.bottomRight, slotLight);
      }
    }

    // Torch-lit vignette: warm light pools high on the board, corners fall away.
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.35),
          radius: 1.1,
          colors: [
            AppColors.torchGlow.withOpacity(0.10),
            Colors.transparent,
            Colors.black.withOpacity(0.38),
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(Offset.zero & size),
    );

    canvas.restore();

    // Carved frame: a dark outer cut and a faint warm inner chamfer.
    canvas.drawRRect(
      boardRect,
      Paint()
        ..color = Colors.black.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.drawRRect(
      boardRect.deflate(2.5),
      Paint()
        ..color = AppColors.torchGlow.withOpacity(0.10)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  // ---------------------------------------------------------------------------
  // Exit: a radiant portal on the exit row that the egg slides out through.
  // ---------------------------------------------------------------------------
  void _drawExit(Canvas canvas) {
    final cy = kExitRow * cellSize + cellSize * 0.5;
    final edgeX = kGridSize * cellSize;
    final pulse = 0.55 + exitPulse * 0.45;

    // Radiating magical glow just past the right edge, breathing with the pulse.
    final center = Offset(edgeX + 3, cy);
    final radius = cellSize * (0.55 + exitPulse * 0.12);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.exitGlow.withOpacity(0.55 * pulse),
            AppColors.exitGlow.withOpacity(0.0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );

    // A pair of bright chevrons leading out of the board.
    final chevron = Paint()
      ..color = AppColors.exitGlow.withOpacity(0.9 * pulse)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final h = cellSize * 0.2;
    final w = cellSize * 0.16;
    for (int i = 0; i < 2; i++) {
      final x = edgeX + 3 + i * cellSize * 0.16;
      canvas.drawPath(
        Path()
          ..moveTo(x, cy - h)
          ..lineTo(x + w, cy)
          ..lineTo(x, cy + h),
        chevron,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Blocks.
  // ---------------------------------------------------------------------------
  void _drawBlocks(Canvas canvas) {
    // Draw non-dragging blocks first, then the dragging one on top.
    final sorted = [...blocks]..sort(
        (a, b) => (a.id == draggingId ? 1 : 0) - (b.id == draggingId ? 1 : 0));
    for (final block in sorted) {
      _drawBlock(canvas, block, block.id == draggingId);
    }
  }

  void _drawBlock(Canvas canvas, Block block, bool isDragging) {
    final pad = cellSize * 0.08;
    final left = block.col * cellSize + pad;
    final top = block.row * cellSize + pad;
    final width = (block.isHorizontal ? block.length : 1) * cellSize - pad * 2;
    final height = (block.isHorizontal ? 1 : block.length) * cellSize - pad * 2;

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, width, height),
      Radius.circular(cellSize * 0.18),
    );

    // Every piece casts a soft shadow into its socket for depth; the shadow
    // deepens and lifts while the piece is being dragged.
    final lift = isDragging ? 7.0 : 3.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(left + 1.5, top + lift, width, height),
        Radius.circular(cellSize * 0.18),
      ),
      Paint()
        ..color = Colors.black.withOpacity(isDragging ? 0.55 : 0.4)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, isDragging ? 11 : 5),
    );

    if (block.isKey) {
      _drawRelicPlinth(canvas, rect);
    } else {
      _drawStoneMonolith(canvas, block, rect);
    }

    // Hint highlight: a pulsing bright rune-glow around the suggested block.
    if (block.id == hintBlockId) {
      canvas.drawRRect(
        rect,
        Paint()
          ..color = AppColors.exitGlow.withOpacity(0.6 + exitPulse * 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0 + exitPulse * 1.5,
      );
    }

    if (block.isKey) {
      _drawEgg(canvas, left, top, width, height);
    } else {
      _drawEngravedArrows(canvas, block, left, top, width, height);
    }
  }

  /// Paint an obstacle as a raised, carved stone monolith: a lit gradient body,
  /// deterministic chiselled speckle so the stone isn't flat, a bevel that
  /// makes it sit proud of its socket, and a carved outer edge.
  void _drawStoneMonolith(Canvas canvas, Block block, RRect rect) {
    final bounds = rect.outerRect;
    final base = block.color;

    // Stone body, lit from the top-left.
    canvas.drawRRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(base, Colors.white, 0.20)!,
            base,
            Color.lerp(base, Colors.black, 0.32)!,
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(bounds),
    );

    canvas.save();
    canvas.clipRRect(rect);

    // Chiselled grain: light and dark flecks, hashed from the block id so the
    // texture is stable across repaints instead of shimmering while dragging.
    final area = bounds.width * bounds.height;
    final flecks = (area / (cellSize * cellSize) * 16).round().clamp(6, 90);
    for (int i = 0; i < flecks; i++) {
      final hx = (block.id * 374761393 + i * 668265263) & 0x7fffffff;
      final hy = (block.id * 2246822519 + i * 3266489917) & 0x7fffffff;
      final px = bounds.left + (hx % 1000) / 1000.0 * bounds.width;
      final py = bounds.top + (hy % 1000) / 1000.0 * bounds.height;
      final light = (hx & 1) == 0;
      canvas.drawCircle(
        Offset(px, py),
        cellSize * (0.012 + (hx % 3) * 0.006),
        Paint()
          ..color = (light ? Colors.white : Colors.black)
              .withOpacity(light ? 0.06 : 0.10),
      );
    }

    // Glossy top band, as if torchlight rakes across the upper face.
    canvas.drawRect(
      Rect.fromLTWH(bounds.left, bounds.top, bounds.width, bounds.height * 0.45),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white.withOpacity(0.10), Colors.transparent],
        ).createShader(bounds),
    );

    // Bevel: bright inner top/left edge, dark inner bottom/right edge (clipped,
    // so the rounded corners stay clean).
    final b = bounds;
    final hl = Paint()
      ..color = Colors.white.withOpacity(0.22)
      ..strokeWidth = 2.0;
    final sh = Paint()
      ..color = Colors.black.withOpacity(0.33)
      ..strokeWidth = 2.0;
    canvas.drawLine(Offset(b.left + 1, b.top + 1), Offset(b.right - 1, b.top + 1), hl);
    canvas.drawLine(Offset(b.left + 1, b.top + 1), Offset(b.left + 1, b.bottom - 1), hl);
    canvas.drawLine(Offset(b.left + 1, b.bottom - 1), Offset(b.right - 1, b.bottom - 1), sh);
    canvas.drawLine(Offset(b.right - 1, b.top + 1), Offset(b.right - 1, b.bottom - 1), sh);

    canvas.restore();

    // Carved outer edge.
    canvas.drawRRect(
      rect,
      Paint()
        ..color = Colors.black.withOpacity(0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  /// Paint the goal block as a relic plinth: a pulsing warm halo, a golden bed,
  /// a radial core glow behind the egg, a carved double rim, and corner studs.
  void _drawRelicPlinth(Canvas canvas, RRect rect) {
    final bounds = rect.outerRect;
    final pulse = 0.7 + exitPulse * 0.3;

    // Warm halo bleeding past the edge, breathing with the pulse.
    canvas.drawRRect(
      rect.inflate(2),
      Paint()
        ..color = AppColors.keyGlow.withOpacity(0.32 * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    // Golden bed.
    canvas.drawRRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7A5416), Color(0xFF4A320C)],
        ).createShader(bounds),
    );

    // Radial core glow, brightest where the egg sits.
    canvas.drawRRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.keyBlock.withOpacity(0.5 * pulse),
            AppColors.keyGlow.withOpacity(0.14),
            Colors.transparent,
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(bounds),
    );

    // Carved double rim: bright gold outer, dark inner chamfer.
    canvas.drawRRect(
      rect,
      Paint()
        ..color = AppColors.keyBlock.withOpacity(0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );
    canvas.drawRRect(
      rect.deflate(3),
      Paint()
        ..color = Colors.black.withOpacity(0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // Gold corner studs.
    final inset = cellSize * 0.16;
    final studPaint = Paint()..color = AppColors.keyBlock.withOpacity(0.85);
    for (final o in [
      Offset(bounds.left + inset, bounds.top + inset),
      Offset(bounds.right - inset, bounds.top + inset),
      Offset(bounds.left + inset, bounds.bottom - inset),
      Offset(bounds.right - inset, bounds.bottom - inset),
    ]) {
      canvas.drawCircle(o, cellSize * 0.03, studPaint);
    }
  }

  /// A smooth egg silhouette (a proper ovoid): perfectly left–right symmetric,
  /// with the widest point just below centre and a gently longer top. Built
  /// from four Bézier quadrants with horizontal tangents at the tips and
  /// vertical tangents at the equator, so the outline is seamless. The overall
  /// bounding box is exactly [ew] × [eh], centred on ([cx], [cy]).
  Path _eggPath(double cx, double cy, double ew, double eh) {
    const k = 0.5523; // cubic-Bézier constant for a quarter ellipse
    final a = ew / 2; // half width at the equator
    final bTop = eh * 0.53; // top a touch longer than the bottom → egg, not oval
    final bBot = eh * 0.47;
    final ey = cy + (bTop - bBot) / 2; // equator, keeping the bbox centred on cy

    return Path()
      ..moveTo(cx, ey - bTop)
      // top-right quadrant
      ..cubicTo(cx + k * a, ey - bTop, cx + a, ey - k * bTop, cx + a, ey)
      // bottom-right quadrant
      ..cubicTo(cx + a, ey + k * bBot, cx + k * a, ey + bBot, cx, ey + bBot)
      // bottom-left quadrant
      ..cubicTo(cx - k * a, ey + bBot, cx - a, ey + k * bBot, cx - a, ey)
      // top-left quadrant
      ..cubicTo(cx - a, ey - k * bTop, cx - k * a, ey - bTop, cx, ey - bTop)
      ..close();
  }

  /// Draw the goal egg as vector art, centred on the plinth over a warm halo.
  ///
  /// It is rendered entirely from paths and gradients — a top-left-lit shell,
  /// a pattern, a glossy highlight and a rim — so it is crisp at any board size
  /// and screen density (the old 24px sprite blurred when scaled up to a full
  /// cell). [eggSeed] seeds both the colour (a random harmonious hue) and the
  /// pattern style deterministically, so every level wears a different egg but
  /// a retry always shows the same one.
  void _drawEgg(Canvas canvas, double left, double top, double w, double h) {
    final cx = left + w / 2;
    final cy = top + h / 2;

    // Warm relic halo behind the egg, so the plinth glows from within.
    final haloR = min(w, h) * (0.5 + exitPulse * 0.06);
    canvas.drawCircle(
      Offset(cx, cy),
      haloR,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.keyBlock.withOpacity(0.35 + exitPulse * 0.15),
            AppColors.keyBlock.withOpacity(0.0),
          ],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: haloR)),
    );

    // Colourway and pattern, both derived from the seed. The shell is a random
    // pastel hue; the pattern colour is the same hue shifted, deepened and
    // saturated so it reads clearly against the shell.
    final rng = Random(eggSeed);
    final hue = rng.nextDouble() * 360.0;
    final sat = 0.42 + rng.nextDouble() * 0.20;
    final val = 0.80 + rng.nextDouble() * 0.12;
    final base = HSVColor.fromAHSV(1, hue, sat, val).toColor();
    final hueShift = (rng.nextBool() ? 1 : -1) * (12 + rng.nextDouble() * 46);
    final pattern = HSVColor.fromAHSV(
      1,
      (hue + hueShift) % 360,
      (sat + 0.26).clamp(0.0, 1.0),
      (val - 0.34).clamp(0.0, 1.0),
    ).toColor();
    final light = Color.lerp(base, Colors.white, 0.40)!;
    final dark = Color.lerp(base, Colors.black, 0.34)!;
    final patternType = rng.nextInt(_eggPatternCount);

    // Upright ovoid sized to the block's short axis.
    final eh = min(w, h) * 0.78;
    final ew = eh * 0.72;
    final path = _eggPath(cx, cy, ew, eh);
    final bounds = path.getBounds();

    canvas.save();
    canvas.clipPath(path);

    // Rounded shell, lit from the upper-left.
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.5),
          radius: 1.1,
          colors: [light, base, dark],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(bounds),
    );

    _drawEggPattern(canvas, patternType, rng, cx, cy, ew, eh, pattern);

    // Ambient shade pooling at the base, for weight.
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.center,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withOpacity(0.22)],
        ).createShader(bounds),
    );

    // Glossy highlight near the top-left.
    final hlRect = Rect.fromCenter(
      center: Offset(cx - ew * 0.20, cy - eh * 0.26),
      width: ew * 0.5,
      height: eh * 0.42,
    );
    canvas.drawOval(
      hlRect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withOpacity(0.6),
            Colors.white.withOpacity(0.0),
          ],
        ).createShader(hlRect),
    );

    canvas.restore();

    // Crisp rim for definition.
    canvas.drawPath(
      path,
      Paint()
        ..color = dark.withOpacity(0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(1.0, ew * 0.022),
    );
  }

  /// Number of distinct egg pattern styles [_drawEggPattern] can render.
  static const int _eggPatternCount = 6;

  /// Draw one of several shell patterns, clipped to the egg by the caller.
  /// [type] selects the style; [rng] is the same seeded generator used for the
  /// colour, so a given [eggSeed] always yields the same pattern.
  void _drawEggPattern(Canvas canvas, int type, Random rng, double cx,
      double cy, double ew, double eh, Color color) {
    final left = cx - ew / 2;
    final top = cy - eh / 2;
    final fill = Paint()..color = color.withOpacity(0.5);

    switch (type) {
      case 0: // fine speckles
        final n = 8 + rng.nextInt(5);
        for (int i = 0; i < n; i++) {
          final ang = rng.nextDouble() * 2 * pi;
          final rad = sqrt(rng.nextDouble());
          final sx = cx + cos(ang) * rad * ew * 0.40;
          final sy = cy + sin(ang) * rad * eh * 0.40;
          final rr = ew * (0.045 + rng.nextDouble() * 0.055);
          canvas.drawOval(
            Rect.fromCenter(
                center: Offset(sx, sy), width: rr * 2, height: rr * 1.7),
            fill,
          );
        }
        break;
      case 1: // bold sparse spots
        final n = 4 + rng.nextInt(3);
        for (int i = 0; i < n; i++) {
          final ang = rng.nextDouble() * 2 * pi;
          final rad = sqrt(rng.nextDouble());
          final sx = cx + cos(ang) * rad * ew * 0.34;
          final sy = cy + sin(ang) * rad * eh * 0.34;
          final rr = ew * (0.11 + rng.nextDouble() * 0.07);
          canvas.drawCircle(Offset(sx, sy), rr, fill);
        }
        break;
      case 2: // horizontal bands
        final bands = 3 + rng.nextInt(3);
        final gap = eh / (bands * 2 + 1);
        for (int i = 0; i < bands; i++) {
          final y = top + gap * (2 * i + 1);
          canvas.drawRect(Rect.fromLTWH(left, y, ew, gap), fill);
        }
        break;
      case 3: // diagonal stripes
        final barW = ew * 0.14;
        final step = barW * 2.1;
        canvas.save();
        canvas.translate(cx, cy);
        canvas.rotate(-0.5); // ~ -28°
        for (double x = -eh; x < eh; x += step) {
          canvas.drawRect(Rect.fromLTWH(x, -eh, barW, eh * 2), fill);
        }
        canvas.restore();
        break;
      case 4: // zigzag bands
        final bands = 3 + rng.nextInt(2);
        final amp = eh * 0.055;
        final gap = eh / (bands + 1);
        final seg = ew / 4;
        final stroke = Paint()
          ..color = color.withOpacity(0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = eh * 0.04
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round;
        for (int b = 1; b <= bands; b++) {
          final y = top + gap * b;
          final path = Path();
          var x = left - seg;
          var up = true;
          path.moveTo(x, y + amp);
          while (x <= left + ew + seg) {
            x += seg;
            path.lineTo(x, y + (up ? -amp : amp));
            up = !up;
          }
          canvas.drawPath(path, stroke);
        }
        break;
      default: // polka dots
        final spacing = ew * 0.34;
        final r = ew * 0.06;
        var row = 0;
        for (double y = top; y <= top + eh; y += spacing) {
          final off = row.isEven ? 0.0 : spacing / 2;
          for (double x = left + off; x <= left + ew; x += spacing) {
            canvas.drawCircle(Offset(x, y), r, fill);
          }
          row++;
        }
        break;
    }
  }

  /// Directional runes engraved into the stone, showing the block's slide axis.
  /// Each chevron is a dark recessed cut with a lit face on top; the face glows
  /// warm normally and switches to the bright exit colour when this block is the
  /// current hint.
  void _drawEngravedArrows(
      Canvas canvas, Block block, double left, double top, double w, double h) {
    final cx = left + w / 2;
    final cy = top + h / 2;
    final s = (block.isHorizontal ? h : w) * 0.16;
    final glow = block.id == hintBlockId;
    final face = glow ? AppColors.exitGlow : AppColors.torchGlow.withOpacity(0.7);

    if (block.isHorizontal) {
      _chevron(canvas, Offset(cx - w * 0.28, cy), _Dir.left, s, face);
      _chevron(canvas, Offset(cx + w * 0.28, cy), _Dir.right, s, face);
    } else {
      _chevron(canvas, Offset(cx, cy - h * 0.28), _Dir.up, s, face);
      _chevron(canvas, Offset(cx, cy + h * 0.28), _Dir.down, s, face);
    }
  }

  void _chevron(Canvas canvas, Offset tip, _Dir dir, double s, Color face) {
    Path path(Offset o) {
      switch (dir) {
        case _Dir.left:
          return Path()
            ..moveTo(o.dx + s, o.dy - s)
            ..lineTo(o.dx, o.dy)
            ..lineTo(o.dx + s, o.dy + s);
        case _Dir.right:
          return Path()
            ..moveTo(o.dx - s, o.dy - s)
            ..lineTo(o.dx, o.dy)
            ..lineTo(o.dx - s, o.dy + s);
        case _Dir.up:
          return Path()
            ..moveTo(o.dx - s, o.dy + s)
            ..lineTo(o.dx, o.dy)
            ..lineTo(o.dx + s, o.dy + s);
        case _Dir.down:
          return Path()
            ..moveTo(o.dx - s, o.dy - s)
            ..lineTo(o.dx, o.dy)
            ..lineTo(o.dx + s, o.dy - s);
      }
    }

    // Engraved cut: a dark stroke offset down, then the lit face on top.
    canvas.drawPath(
      path(tip.translate(0, 1.2)),
      Paint()
        ..color = Colors.black.withOpacity(0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      path(tip),
      Paint()
        ..color = face
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(BoardPainter old) =>
      old.blocks != blocks ||
      old.draggingId != draggingId ||
      old.hintBlockId != hintBlockId ||
      old.exitPulse != exitPulse ||
      old.eggSeed != eggSeed;
}

enum _Dir { left, right, up, down }
