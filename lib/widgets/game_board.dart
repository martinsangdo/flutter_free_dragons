import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/constants.dart';
import '../logic/game_engine.dart';
import '../models/block.dart';
import 'board_painter.dart';

class GameBoard extends StatefulWidget {
  final GameEngine engine;
  final VoidCallback? onWin;
  final VoidCallback? onMove;

  /// Seed picking the goal egg's colourway; see [BoardPainter.eggSeed].
  final int eggSeed;

  const GameBoard({
    super.key,
    required this.engine,
    this.onWin,
    this.onMove,
    this.eggSeed = 0,
  });

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard>
    with SingleTickerProviderStateMixin {
  Block? _draggingBlock;
  Offset? _dragStart;
  double _dragAccum = 0;

  late AnimationController _exitController;
  late Animation<double> _exitPulse;

  double get cellSize => _boardSize / kGridSize;
  double _boardSize = 300;

  @override
  void initState() {
    super.initState();
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _exitPulse = CurvedAnimation(
      parent: _exitController,
      curve: Curves.easeInOut,
    );
    _exitPulse.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      _boardSize = constraints.maxWidth.clamp(200.0, 420.0);
      return SizedBox(
        width: _boardSize + 24,
        height: _boardSize,
        child: GestureDetector(
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          child: AnimatedBuilder(
            animation: widget.engine,
            builder: (_, __) => CustomPaint(
              size: Size(_boardSize, _boardSize),
              painter: BoardPainter(
                blocks: widget.engine.blocks,
                cellSize: cellSize,
                draggingId: widget.engine.draggingId,
                hintBlockId: widget.engine.hintBlockId,
                exitPulse: _exitPulse.value,
                eggSeed: widget.eggSeed,
              ),
            ),
          ),
        ),
      );
    });
  }

  void _onPanStart(DragStartDetails d) {
    if (widget.engine.isWon) return;
    final col = (d.localPosition.dx / cellSize).floor();
    final row = (d.localPosition.dy / cellSize).floor();
    if (col < 0 || col >= kGridSize || row < 0 || row >= kGridSize) return;

    final block = widget.engine.blockAt(row, col);
    if (block == null) return;

    _draggingBlock = block;
    _dragStart = d.localPosition;
    _dragAccum = 0;
    widget.engine.setDragging(block.id);
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_draggingBlock == null || _dragStart == null) return;
    final block = _draggingBlock!;

    final delta = block.isHorizontal
        ? d.localPosition.dx - _dragStart!.dx
        : d.localPosition.dy - _dragStart!.dy;

    final wholeCells = delta / cellSize - _dragAccum;
    if (wholeCells.abs() >= 0.5) {
      final toMove = wholeCells > 0 ? 1 : -1;
      final moved = widget.engine.moveBlock(block.id, toMove);
      if (moved) {
        _dragAccum += toMove.toDouble();
        widget.onMove?.call();
        HapticFeedback.selectionClick();
        if (widget.engine.isWon) {
          HapticFeedback.heavyImpact();
          widget.onWin?.call();
        }
      }
    }
  }

  void _onPanEnd(DragEndDetails d) {
    widget.engine.setDragging(null);
    _draggingBlock = null;
    _dragStart = null;
    _dragAccum = 0;
  }
}
