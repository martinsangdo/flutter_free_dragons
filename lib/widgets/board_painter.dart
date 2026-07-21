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

    // Glow for key block
    if (block.isKey) {
      final glowPaint = Paint()
        ..color = AppColors.keyGlow.withOpacity(0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawRRect(rect, glowPaint);
    }

    // Main block fill
    final fillPaint = Paint()
      ..color = block.color
      ..style = PaintingStyle.fill;

    if (block.isKey) {
      final gradient = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.keyBlock,
          AppColors.keyGlow,
        ],
      );
      fillPaint.shader = gradient.createShader(
        Rect.fromLTWH(left, top, width, height),
      );
    } else {
      final lighter = Color.lerp(block.color, Colors.white, 0.3)!;
      final gradient = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [lighter, block.color],
      );
      fillPaint.shader = gradient.createShader(
        Rect.fromLTWH(left, top, width, height),
      );
    }

    canvas.drawRRect(rect, fillPaint);

    // Highlight stripe
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..style = PaintingStyle.fill;
    final hlRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left + pad, top + pad, width - pad * 2, (height - pad * 2) * 0.4),
      Radius.circular(cellSize * 0.1),
    );
    canvas.drawRRect(hlRect, highlightPaint);

    // Border
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
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

  /// Draw the egg centred on the goal block, scaled to fit while keeping its
  /// aspect ratio. The gold block is deliberately left visible around it: its
  /// two-cell footprint is what tells the player how much room the goal needs,
  /// so the artwork must not swallow the silhouette.
  void _drawEgg(Canvas canvas, double left, double top, double w, double h) {
    final sprite = eggSprite;
    if (sprite == null) return;

    final src = Rect.fromLTWH(
      0,
      0,
      sprite.width.toDouble(),
      sprite.height.toDouble(),
    );

    // Contain within the shorter axis, inset so the egg never touches the edge.
    final box = min(w, h) * 0.72;
    final scale = min(box / sprite.width, box / sprite.height);
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
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
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
