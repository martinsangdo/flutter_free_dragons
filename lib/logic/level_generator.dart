import 'dart:math';

import '../data/constants.dart';
import '../models/level.dart';
import 'solver.dart';

/// Procedurally generates "Free The Eggs" boards that are guaranteed solvable.
///
/// Every candidate board is checked with [RushHourSolver] before being returned;
/// unsolvable or trivially-solved boards are rejected and regenerated. Because
/// generation is seeded, the same seed always yields the same board, so the
/// hand-off level set and endless levels are stable across launches.
class LevelGenerator {
  static const _keyLength = 2;

  /// The campaign difficulty curve, keyed on the level [number] (4..80 for the
  /// generated levels; 1..3 are the curated tutorial and never pass through
  /// here). Returns the generator targets for that level.
  ///
  /// **The curve is driven by `minSteps`, not by par.** `par` counts individual
  /// cell slides, so it inflates when a block simply has to travel further —
  /// which is not what makes a board hard. `minSteps` is the length of the
  /// solver's optimal path, i.e. the number of *decisions* the player has to
  /// get right. Gating on par produced levels like the old L5: par 6, but only
  /// three block-moves, with no wrong line available.
  ///
  /// Three segments, joined continuously:
  ///  - **L4–L20:** 5 → 8 decisions, 6 → 9 blocks. Short on-ramp; the curated
  ///    L1–L3 already teach the mechanic, so this segment adds pressure early.
  ///  - **L21–L40:** 8 → 10 decisions, 9 → 11 blocks.
  ///  - **L41–L80:** 10 → 13 decisions, 11 → 13 blocks (board saturation).
  ///
  /// The par window is derived from `minSteps` and deliberately loose: par is
  /// always >= steps, and capping it tightly would just reject boards for
  /// having a block that travels far. It exists only to keep the star target
  /// from landing somewhere absurd.
  ///
  /// This is the single source of truth for the curve — both the build-time
  /// `tool/generate_levels.dart` and `LevelRepository`'s runtime fallback call
  /// it, so they can never drift apart.
  static ({int targetBlocks, int minSteps, int maxSteps, int minPar, int maxPar})
      campaignParams(int number) {
    final int steps;
    final int blocks;
    if (number <= 20) {
      final u = ((number - 4) / 16.0).clamp(0.0, 1.0); // 0 at L4, 1 at L20
      steps = (5 + u * 3).round(); // 5..8
      blocks = (6 + u * 3).round(); // 6..9
    } else if (number <= 40) {
      final u = ((number - 20) / 20.0).clamp(0.0, 1.0); // 0 at L20, 1 at L40
      steps = (8 + u * 2).round(); // 8..10
      blocks = (9 + u * 2).round(); // 9..11
    } else {
      final u = ((number - 40) / 40.0).clamp(0.0, 1.0); // 0 at L40, 1 at L80
      steps = (10 + u * 3).round(); // 10..13
      blocks = (11 + u * 2).round(); // 11..13
    }
    return (
      targetBlocks: blocks,
      minSteps: steps,
      // A ceiling as well as a floor: block density alone pushes step count
      // well past the floor, which is what made the old curve spiky. Without
      // this, L23 came out at 12 steps against a target of 8.
      maxSteps: steps + 2,
      minPar: steps,
      maxPar: steps + 8,
    );
  }

  /// Generate a single solvable level.
  ///
  /// A board is accepted when the solver's optimal path is at least [minSteps]
  /// block-moves long and its par lands in `[minPar, maxPar]`. [minSteps] is
  /// the real difficulty knob — see [campaignParams] for why par alone is not
  /// enough. If nothing qualifies within [maxAttempts] the closest solvable
  /// board found is returned, so a level is always produced.
  static Level generate({
    required int number,
    required Random rng,
    required int targetBlocks,
    required int minPar,
    required int maxPar,
    int minSteps = 0,
    int maxSteps = 1 << 30,
    int maxAttempts = 600,
  }) {
    Level? best;
    int bestDistance = 1 << 30;

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      final blocks = _randomBoard(rng, targetBlocks);
      if (blocks == null) continue;

      final result = RushHourSolver(blocks).solve(blocks);
      // Require a genuine puzzle: solvable and not already solved.
      if (!result.solvable || result.minMoves < 2) continue;

      final par = result.minMoves;
      final steps = result.path.length;
      if (steps >= minSteps &&
          steps <= maxSteps &&
          par >= minPar &&
          par <= maxPar) {
        return Level(
          number: number,
          difficulty: _difficultyFor(steps),
          blocks: blocks,
          par: par,
        );
      }

      // Track the closest-to-target fallback. Missing the step floor is the
      // more serious miss (that board is genuinely too easy), so weight it
      // above a par-window miss.
      final stepMiss = steps < minSteps
          ? (minSteps - steps) * 4
          : steps > maxSteps
              ? (steps - maxSteps) * 4
              : 0;
      final parMiss = par < minPar
          ? minPar - par
          : par > maxPar
              ? par - maxPar
              : 0;
      final distance = stepMiss + parMiss;
      if (distance < bestDistance) {
        bestDistance = distance;
        best = Level(
          number: number,
          difficulty: _difficultyFor(steps),
          blocks: blocks,
          par: par,
        );
      }
    }

    // Guaranteed non-null in practice; fall back to a trivial hand board if the
    // RNG was pathologically unlucky so we never crash a build/launch.
    return best ?? _fallbackLevel(number);
  }

  /// Attempt to lay out a random, non-overlapping board. Returns null if the
  /// random placement failed to produce a usable board (caller retries).
  static List<BlockConfig>? _randomBoard(Random rng, int targetBlocks) {
    final occupied = List<bool>.filled(kGridSize * kGridSize, false);
    final blocks = <BlockConfig>[];

    bool fits(int row, int col, int len, bool horizontal) {
      for (int i = 0; i < len; i++) {
        final r = horizontal ? row : row + i;
        final c = horizontal ? col + i : col;
        if (r < 0 || r >= kGridSize || c < 0 || c >= kGridSize) return false;
        if (occupied[r * kGridSize + c]) return false;
      }
      return true;
    }

    void mark(int row, int col, int len, bool horizontal) {
      for (int i = 0; i < len; i++) {
        final r = horizontal ? row : row + i;
        final c = horizontal ? col + i : col;
        occupied[r * kGridSize + c] = true;
      }
    }

    // 1. Place the key on the exit row.
    final keyCol = rng.nextInt(2); // 0 or 1
    if (!fits(kExitRow, keyCol, _keyLength, true)) return null;
    mark(kExitRow, keyCol, _keyLength, true);
    blocks.add(BlockConfig(
      row: kExitRow,
      col: keyCol,
      length: _keyLength,
      isHorizontal: true,
      isKey: true,
    ));

    // 2. Force at least one vertical blocker crossing the exit row to the right
    //    of the key, so the board is never pre-solved.
    bool placedBlocker = false;
    for (int tries = 0; tries < 20 && !placedBlocker; tries++) {
      final len = 2 + rng.nextInt(2); // 2 or 3
      final col = keyCol + _keyLength + rng.nextInt(kGridSize - (keyCol + _keyLength));
      // Choose a top row such that the block spans the exit row.
      final minTop = max(0, kExitRow - (len - 1));
      final maxTop = min(kExitRow, kGridSize - len);
      if (minTop > maxTop) continue;
      final top = minTop + rng.nextInt(maxTop - minTop + 1);
      if (fits(top, col, len, false)) {
        mark(top, col, len, false);
        blocks.add(BlockConfig(
            row: top, col: col, length: len, isHorizontal: false));
        placedBlocker = true;
      }
    }
    if (!placedBlocker) return null;

    // 3. Fill in the remaining blocks at random.
    int guard = 0;
    while (blocks.length < targetBlocks && guard < 200) {
      guard++;
      final horizontal = rng.nextBool();
      final len = 2 + rng.nextInt(2); // 2 or 3
      final row = rng.nextInt(kGridSize);
      final col = rng.nextInt(kGridSize);

      // Never put a non-key horizontal block on the exit row — it would form an
      // immovable wall across the key's lane.
      if (horizontal && row == kExitRow) continue;
      if (!fits(row, col, len, horizontal)) continue;

      mark(row, col, len, horizontal);
      blocks.add(BlockConfig(
          row: row, col: col, length: len, isHorizontal: horizontal));
    }

    return blocks;
  }

  /// Label a board by how many decisions its optimal solution takes. Keyed on
  /// solver step count rather than par, so a board isn't badged "Hard" just
  /// because one block has to slide the width of the grid.
  static String _difficultyFor(int steps) {
    if (steps <= 4) return 'Easy';
    if (steps <= 6) return 'Medium';
    if (steps <= 8) return 'Hard';
    if (steps <= 11) return 'Expert';
    return 'Master';
  }

  /// A tiny always-solvable board, used only as a last-resort fallback.
  static Level _fallbackLevel(int number) => Level(
        number: number,
        difficulty: 'Easy',
        par: 2,
        blocks: const [
          BlockConfig(
              row: kExitRow, col: 0, length: 2, isHorizontal: true, isKey: true),
          BlockConfig(row: 1, col: 3, length: 2, isHorizontal: false),
        ],
      );
}
