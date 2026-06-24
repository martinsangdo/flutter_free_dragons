import 'package:flutter/material.dart';
import '../models/block.dart';
import '../theme/app_colors.dart';
import '../data/constants.dart';

class BoardPainter extends CustomPainter {
  final List<Block> blocks;
  final double cellSize;
  final int? draggingId;
  final double exitPulse; // 0.0–1.0 animation value

  BoardPainter({
    required this.blocks,
    required this.cellSize,
    this.draggingId,
    this.exitPulse = 0.0,
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

    // Key icon on key block
    if (block.isKey) {
      _drawKeyIcon(canvas, left, top, width, height);
    }

    // Direction arrows on blocks
    if (!block.isKey) {
      _drawDirectionHint(canvas, block, left, top, width, height);
    }
  }

  void _drawKeyIcon(Canvas canvas, double left, double top, double w, double h) {
    final cx = left + w / 2;
    final cy = top + h / 2;
    final r = h * 0.28;

    final ringPaint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = h * 0.1
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(Offset(cx - w * 0.15, cy), r, ringPaint);

    final stemPaint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = h * 0.1
      ..strokeCap = StrokeCap.round;

    final stemPath = Path()
      ..moveTo(cx - w * 0.15 + r, cy)
      ..lineTo(cx + w * 0.28, cy)
      ..moveTo(cx + w * 0.18, cy)
      ..lineTo(cx + w * 0.18, cy + h * 0.18)
      ..moveTo(cx + w * 0.28, cy)
      ..lineTo(cx + w * 0.28, cy + h * 0.15);

    canvas.drawPath(stemPath, stemPaint);
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
      old.exitPulse != exitPulse;
}
