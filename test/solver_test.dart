import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:free_the_key/data/levels_data.dart';
import 'package:free_the_key/logic/level_generator.dart';
import 'package:free_the_key/logic/solver.dart';
import 'package:free_the_key/models/level.dart';

void main() {
  group('RushHourSolver', () {
    test('every curated level is solvable with a positive par', () {
      for (final level in kCuratedLevels) {
        final result = RushHourSolver(level.blocks).solve(level.blocks);
        expect(result.solvable, isTrue,
            reason: 'Level ${level.number} should be solvable');
        expect(result.minMoves, greaterThan(0),
            reason: 'Level ${level.number} needs at least one move');
      }
    });

    test('an already-clear board is solvable in zero moves', () {
      // Key on the exit row with nothing to its right.
      const blocks = [
        BlockConfig(row: 2, col: 0, length: 2, isHorizontal: true, isKey: true),
      ];
      final result = RushHourSolver(blocks).solve(blocks);
      expect(result.solvable, isTrue);
      expect(result.minMoves, 0);
    });

    test('a permanently walled-in key is reported unsolvable', () {
      // Two stacked vertical blocks fill columns to the right of the key across
      // its whole span and cannot move out of the exit row.
      const blocks = [
        BlockConfig(row: 2, col: 0, length: 2, isHorizontal: true, isKey: true),
        // Column 2 fully occupied top-to-bottom (rows 0-5) by two blocks:
        BlockConfig(row: 0, col: 2, length: 3, isHorizontal: false),
        BlockConfig(row: 3, col: 2, length: 3, isHorizontal: false),
      ];
      final result = RushHourSolver(blocks).solve(blocks);
      expect(result.solvable, isFalse);
    });

    test('reported path actually frees the key', () {
      final level = kCuratedLevels[5]; // a medium level
      final result = RushHourSolver(level.blocks).solve(level.blocks);
      expect(result.solvable, isTrue);
      // The path length in cell-steps of non-key blocks equals minMoves.
      final cost = result.path
          .where((m) => !level.blocks[m.blockIndex].isKey)
          .fold<int>(0, (sum, m) => sum + m.delta.abs());
      expect(cost, result.minMoves);
    });
  });

  group('LevelGenerator', () {
    test('generated levels are always solvable', () {
      for (int i = 0; i < 15; i++) {
        final level = LevelGenerator.generate(
          number: i + 1,
          rng: Random(1000 + i),
          targetBlocks: 6 + i % 6,
          minPar: 4 + i % 6,
          maxPar: 10 + i % 6,
        );
        final result = RushHourSolver(level.blocks).solve(level.blocks);
        expect(result.solvable, isTrue,
            reason: 'Generated level $i must be solvable');
        expect(result.minMoves, result.solvable ? level.par : anything);
      }
    });
  });
}
