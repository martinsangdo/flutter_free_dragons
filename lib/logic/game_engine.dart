import 'package:flutter/material.dart';
import '../models/block.dart';
import '../models/level.dart';
import '../theme/app_colors.dart';
import '../data/constants.dart';
import 'solver.dart';

class GameEngine extends ChangeNotifier {
  final Level level;
  late List<Block> blocks;
  int moves = 0;
  bool isWon = false;
  int? _draggingId;
  int? get draggingId => _draggingId;

  // Solver-backed hint: the block the player should move next and in which
  // direction. Cleared as soon as any move is made.
  int? hintBlockId;
  int hintDelta = 0;

  void setDragging(int? id) {
    _draggingId = id;
    notifyListeners();
  }

  GameEngine(this.level) {
    _initBlocks();
  }

  void _initBlocks() {
    int colorIndex = 0;
    int idCounter = 0;
    blocks = level.blocks.map((cfg) {
      final color = cfg.isKey
          ? AppColors.keyBlock
          : AppColors.blockColors[colorIndex++ % AppColors.blockColors.length];
      return Block(
        id: idCounter++,
        row: cfg.row,
        col: cfg.col,
        length: cfg.length,
        isHorizontal: cfg.isHorizontal,
        isKey: cfg.isKey,
        color: color,
      );
    }).toList();
  }

  void reset() {
    moves = 0;
    isWon = false;
    _draggingId = null;
    hintBlockId = null;
    hintDelta = 0;
    _initBlocks();
    notifyListeners();
  }

  /// Runs the solver on the *current* board and marks the next optimal move as
  /// a hint. Returns false if there is no move to suggest (already won or, in
  /// theory, stuck). The board itself is not changed — the player still makes
  /// the move.
  bool computeHint() {
    if (isWon) return false;
    final configs = blocks
        .map((b) => BlockConfig(
              row: b.row,
              col: b.col,
              length: b.length,
              isHorizontal: b.isHorizontal,
              isKey: b.isKey,
            ))
        .toList();
    final result = RushHourSolver(configs).solve(configs);
    if (!result.solvable || result.path.isEmpty) {
      hintBlockId = null;
      return false;
    }
    final move = result.path.first;
    hintBlockId = blocks[move.blockIndex].id;
    hintDelta = move.delta;
    notifyListeners();
    return true;
  }

  void clearHint() {
    if (hintBlockId != null) {
      hintBlockId = null;
      notifyListeners();
    }
  }

  Set<(int, int)> _occupiedCells({int? excludeId}) {
    final occupied = <(int, int)>{};
    for (final b in blocks) {
      if (b.id == excludeId) continue;
      for (final cell in b.cells) {
        occupied.add(cell);
      }
    }
    return occupied;
  }

  // Returns max cells the block can move forward (+) or backward (-).
  // For horizontal: forward=right, backward=left.
  // For vertical:   forward=down,  backward=up.
  (int fwd, int bwd) movementRange(Block block) {
    final occupied = _occupiedCells(excludeId: block.id);

    int fwd = 0;
    int bwd = 0;

    if (block.isHorizontal) {
      // forward = right
      for (int dc = 1; dc <= kGridSize; dc++) {
        final newRightEdge = block.col + block.length - 1 + dc;
        if (newRightEdge >= kGridSize) {
          // Key can exit the board
          if (block.isKey) fwd = dc;
          break;
        }
        if (occupied.contains((block.row, newRightEdge))) break;
        fwd = dc;
      }
      // backward = left
      for (int dc = 1; dc <= block.col; dc++) {
        final newLeftEdge = block.col - dc;
        if (newLeftEdge < 0) break;
        if (occupied.contains((block.row, newLeftEdge))) break;
        bwd = dc;
      }
    } else {
      // forward = down
      for (int dr = 1; dr <= kGridSize; dr++) {
        final newBottom = block.row + block.length - 1 + dr;
        if (newBottom >= kGridSize) break;
        if (occupied.contains((newBottom, block.col))) break;
        fwd = dr;
      }
      // backward = up
      for (int dr = 1; dr <= block.row; dr++) {
        final newTop = block.row - dr;
        if (newTop < 0) break;
        if (occupied.contains((newTop, block.col))) break;
        bwd = dr;
      }
    }

    return (fwd, bwd);
  }

  // Move block by delta cells (positive = right/down, negative = left/up).
  // Returns true if move was made.
  bool moveBlock(int id, int delta) {
    if (isWon || delta == 0) return false;
    final idx = blocks.indexWhere((b) => b.id == id);
    if (idx == -1) return false;

    final block = blocks[idx];
    final (fwd, bwd) = movementRange(block);

    int clampedDelta;
    if (delta > 0) {
      clampedDelta = delta.clamp(0, fwd);
    } else {
      clampedDelta = (-(-delta).clamp(0, bwd));
    }

    if (clampedDelta == 0) return false;

    // A move invalidates any showing hint.
    hintBlockId = null;

    if (block.isHorizontal) {
      blocks[idx].col += clampedDelta;
    } else {
      blocks[idx].row += clampedDelta;
    }

    // Win: key moved past right edge
    if (block.isKey) {
      final keyBlock = blocks[idx];
      if (keyBlock.col + keyBlock.length > kGridSize) {
        isWon = true;
      }
    }

    // Only count moves of non-key blocks toward par
    if (!block.isKey) moves++;

    notifyListeners();
    return true;
  }

  Block? blockAt(int row, int col) {
    for (final b in blocks) {
      for (final cell in b.cells) {
        if (cell.$1 == row && cell.$2 == col) return b;
      }
    }
    return null;
  }

  Block? get keyBlock => blocks.where((b) => b.isKey).firstOrNull;

  int get starRating {
    if (!isWon) return 0;
    if (moves <= level.par) return 3;
    if (moves <= level.par + 3) return 2;
    return 1;
  }
}
