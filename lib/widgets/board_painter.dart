import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import '../models/block.dart';
import '../theme/app_colors.dart';
import '../data/constants.dart';

class BoardPainter extends CustomPainter {
  final List<Block> blocks;
  final double cellSize;
  final int? draggingId;
  final int? hintBlockId;
  final double exitPulse; // 0.0–1.0 animation value

  /// Artwork drawn on the goal block, from [EggSprites]. Null before the
  /// sprites finish decoding; the block then renders without it rather than
  /// blocking the first frame.
  final ui.Image? eggSprite;

  BoardPainter({
    required this.blocks,
    required this.cellSize,
    this.draggingId,
    this.hintBlockId,
    this.exitPulse = 0.0,
    this.eggSprite,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawBoard(canvas, size);
    _drawExit(canvas);
    _drawBlocks(canvas);
  }

  void _drawBoard(Canvas canvas, Size size) {
    final boardPaint = Paint()
      ..color = AppColors.boardBg
      ..style = PaintingStyle.fill;
    final boardRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(12),
    );
    canvas.drawRRect(boardRect, boardPaint);

    final linePaint = Paint()
      ..color = AppColors.gridLine
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (int i = 1; i < kGridSize; i++) {
      final x = i * cellSize;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
      final y = i * cellSize;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    final borderPaint = Paint()
      ..color = AppColors.gridLine.withOpacity(0.6)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(boardRect, borderPaint);
  }

  void _drawExit(Canvas canvas) {
    const exitRow = 2;
    final glow = 0.5 + exitPulse * 0.5;
    final arrowPaint = Paint()
      ..color = AppColors.exitGlow.withOpacity(glow)
      ..style = PaintingStyle.fill;

    final top = exitRow * cellSize + cellSize * 0.3;
    final bottom = exitRow * cellSize + cellSize * 0.7;
    final right = kGridSize * cellSize + 18.0;
    final mid = exitRow * cellSize + cellSize * 0.5;
    final left = kGridSize * cellSize + 4.0;

    final path = Path()
      ..moveTo(left, top)
      ..lineTo(right - 6, top)
      ..lineTo(right - 6, mid - cellSize * 0.2)
      ..lineTo(right, mid)
      ..lineTo(right - 6, mid + cellSize * 0.2)
      ..lineTo(right - 6, bottom)
      ..lineTo(left, bottom)
      ..close();

    canvas.drawPath(path, arrowPaint);
  }

  void _drawBlocks(Canvas canvas) {
    // Draw non-dragging blocks first, then dragging on top
    final sorted = [...blocks]
      ..sort((a, b) => (a.id == draggingId ? 1 : 0) - (b.id == draggingId ? 1 : 0));

    for (final block in sorted) {
      _drawBlock(canvas, block, block.id == draggingId);
    }
  }

  void _drawBlock(Canvas canvas, Block block, bool isDragging) {
    final pad = cellSize * 0.06;
    final left = block.col * cellSize + pad;
    final top = block.row * cellSize + pad;
    final width = (block.isHorizontal ? block.length : 1) * cellSize - pad * 2;
    final height = (block.isHorizontal ? 1 : block.length) * cellSize - pad * 2;

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, width, height),
      Radius.circular(cellSize * 0.15),
    );

    // Shadow for dragging
    if (isDragging) {
      final shadowPaint = Paint()
        ..color = AppColors.shadow
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left + 4, top + 4, width, height),
          Radius.circular(cellSize * 0.15),
        ),
        shadowPaint,
      );
    }

    // The goal block has no fill — the egg sprite is the block. Only the
    // obstacles are solid pieces.
    if (!block.isKey) {
      _drawBrickwork(canvas, block, rect);
    }

    // Border. The goal keeps a faint outline even without a fill: its two-cell
    // footprint is what tells the player how much room the egg needs to leave.
    final borderPaint = Paint()
      ..color = block.isKey
          ? Colors.white.withOpacity(0.12)
          : Colors.black.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(rect, borderPaint);

    // Hint highlight: a pulsing bright outline around the suggested block.
    if (block.id == hintBlockId) {
      final hintPaint = Paint()
        ..color = AppColors.exitGlow.withOpacity(0.6 + exitPulse * 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0 + exitPulse * 1.5;
      canvas.drawRRect(rect, hintPaint);
    }

    // Egg artwork on the goal block
    if (block.isKey) {
      _drawEgg(canvas, left, top, width, height);
    }

    // Direction arrows on blocks
    if (!block.isKey) {
      _drawDirectionHint(canvas, block, left, top, width, height);
    }
  }

  /// Paint an obstacle block as a little brick wall: mortar underneath, then
  /// running-bond courses laid over it and clipped to the block's rounded rect.
  ///
  /// Brick size is derived from [cellSize], not from the block, so a 2-cell and
  /// a 3-cell block show bricks of the same physical size and the board reads as
  /// one wall rather than a set of differently-scaled tiles. The per-brick tone
  /// jitter is hashed from the block id and the brick's course/index so it is
  /// stable across repaints — a random jitter would shimmer while dragging.
  void _drawBrickwork(Canvas canvas, Block block, RRect rect) {
    final bounds = rect.outerRect;

    // Mortar bed.
    canvas.drawRRect(
      rect,
      Paint()
        ..color = Color.lerp(AppColors.mortar, block.color, 0.25)!
        ..style = PaintingStyle.fill,
    );

    canvas.save();
    canvas.clipRRect(rect);

    final courseHeight = cellSize * 0.26;
    final brickWidth = cellSize * 0.52;
    final joint = cellSize * 0.035;
    final radius = Radius.circular(cellSize * 0.03);

    final courses = (bounds.height / courseHeight).ceil();
    for (int c = 0; c < courses; c++) {
      final y = bounds.top + c * courseHeight;
      // Running bond: every other course is offset by half a brick.
      final offset = c.isEven ? 0.0 : -brickWidth / 2;
      var x = bounds.left + offset;
      int i = 0;
      while (x < bounds.right) {
        final brick = Rect.fromLTWH(
          x + joint / 2,
          y + joint / 2,
          brickWidth - joint,
          courseHeight - joint,
        );
        // Deterministic tone jitter, roughly -8%..+8% brightness.
        final h = (block.id * 73856093) ^ (c * 19349663) ^ (i * 83492791);
        final t = ((h.abs() % 100) / 100.0 - 0.5) * 0.16;
        final tone = t >= 0
            ? Color.lerp(block.color, Colors.white, t)!
            : Color.lerp(block.color, Colors.black, -t)!;

        canvas.drawRRect(
          RRect.fromRectAndRadius(brick, radius),
          Paint()..color = tone,
        );

        // Bevel: light along the top edge, shade along the bottom, so the
        // bricks sit proud of the mortar instead of looking printed on.
        canvas.drawLine(
          Offset(brick.left, brick.top + 0.75),
          Offset(brick.right, brick.top + 0.75),
          Paint()
            ..color = Colors.white.withOpacity(0.16)
            ..strokeWidth = 1.5,
        );
        canvas.drawLine(
          Offset(brick.left, brick.bottom - 0.75),
          Offset(brick.right, brick.bottom - 0.75),
          Paint()
            ..color = Colors.black.withOpacity(0.22)
            ..strokeWidth = 1.5,
        );

        x += brickWidth;
        i++;
      }
    }

    // Soft top-left lighting over the whole wall, so blocks still have the
    // rounded, lit look the rest of the board uses.
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.10),
            Colors.transparent,
            Colors.black.withOpacity(0.18),
          ],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(bounds),
    );

    canvas.restore();
  }

  /// Draw the egg centred on the goal block, scaled to fit while keeping its
  /// aspect ratio. There is no fill behind it, so it is sized against the whole
  /// block rather than the shorter axis — it just has to stay inside the faint
  /// outline that marks the two-cell footprint.
  void _drawEgg(Canvas canvas, double left, double top, double w, double h) {
    final sprite = eggSprite;
    if (sprite == null) return;

    final src = Rect.fromLTWH(
      0,
      0,
      sprite.width.toDouble(),
      sprite.height.toDouble(),
    );

    // Contain within the block, inset so the egg never touches the edge.
    final scale = min(
      (w * 0.9) / sprite.width,
      (h * 0.9) / sprite.height,
    );
    final dw = sprite.width * scale;
    final dh = sprite.height * scale;
    final dst = Rect.fromLTWH(
      left + (w - dw) / 2,
      top + (h - dh) / 2,
      dw,
      dh,
    );

    // The source art is small (24px), so it is always being scaled up here;
    // medium filtering upsamples noticeably better than the default.
    canvas.drawImageRect(
      sprite,
      src,
      dst,
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  void _drawDirectionHint(
      Canvas canvas, Block block, double left, double top, double w, double h) {
    final cx = left + w / 2;
    final cy = top + h / 2;
    final arrowSize = (block.isHorizontal ? h : w) * 0.18;
    // Brighter than it was over the old flat fills: the arrows now sit on top
    // of textured brick and get lost at 0.3.
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.55)
      ..style = PaintingStyle.fill;

    if (block.isHorizontal) {
      // Left arrow
      final lp = Path()
        ..moveTo(cx - w * 0.3, cy)
        ..lineTo(cx - w * 0.3 + arrowSize, cy - arrowSize * 0.7)
        ..lineTo(cx - w * 0.3 + arrowSize, cy + arrowSize * 0.7)
        ..close();
      canvas.drawPath(lp, paint);
      // Right arrow
      final rp = Path()
        ..moveTo(cx + w * 0.3, cy)
        ..lineTo(cx + w * 0.3 - arrowSize, cy - arrowSize * 0.7)
        ..lineTo(cx + w * 0.3 - arrowSize, cy + arrowSize * 0.7)
        ..close();
      canvas.drawPath(rp, paint);
    } else {
      // Up arrow
      final up = Path()
        ..moveTo(cx, cy - h * 0.3)
        ..lineTo(cx - arrowSize * 0.7, cy - h * 0.3 + arrowSize)
        ..lineTo(cx + arrowSize * 0.7, cy - h * 0.3 + arrowSize)
        ..close();
      canvas.drawPath(up, paint);
      // Down arrow
      final dp = Path()
        ..moveTo(cx, cy + h * 0.3)
        ..lineTo(cx - arrowSize * 0.7, cy + h * 0.3 - arrowSize)
        ..lineTo(cx + arrowSize * 0.7, cy + h * 0.3 - arrowSize)
        ..close();
      canvas.drawPath(dp, paint);
    }
  }

  @override
  bool shouldRepaint(BoardPainter old) =>
      old.blocks != blocks ||
      old.draggingId != draggingId ||
      old.hintBlockId != hintBlockId ||
      old.exitPulse != exitPulse ||
      // Without this the board keeps painting eggless if the sprites finish
      // decoding after the first frame.
      old.eggSprite != eggSprite;
}
