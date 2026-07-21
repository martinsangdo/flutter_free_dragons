import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:free_the_key/logic/level_generator.dart';
import 'package:free_the_key/logic/solver.dart';
import 'package:free_the_key/models/level.dart';

/// Guards the shipped campaign against difficulty drift.
///
/// The bundled asset is generated offline by `tool/generate_levels.dart`, so
/// nothing at runtime would notice if the curve regressed — a level could go
/// back to being a three-mover and only a player would find out.
void main() {
  final levels = (jsonDecode(
              File('assets/data/campaign_levels.json').readAsStringSync())
          as List)
      .map((e) => Level.fromJson(e as Map<String, dynamic>))
      .toList();

  test('shipped campaign matches the generated asset count', () {
    expect(levels.length, 77); // levels 4..80
  });

  test('every level lands inside its difficulty band', () {
    final offenders = <String>[];
    for (final level in levels) {
      final p = LevelGenerator.campaignParams(level.number);
      final steps =
          RushHourSolver(level.blocks).solve(level.blocks).path.length;
      if (steps < p.minSteps || steps > p.maxSteps) {
        offenders
            .add('L${level.number}: $steps steps, want ${p.minSteps}..${p.maxSteps}');
      }
    }
    expect(offenders, isEmpty,
        reason: 'Re-run `dart run tool/generate_levels.dart`.');
  });

  test('no level is trivially short', () {
    // The old curve shipped a 3-move level 5. Nothing past the tutorial should
    // ever be solvable in fewer than 5 decisions again.
    for (final level in levels) {
      final steps =
          RushHourSolver(level.blocks).solve(level.blocks).path.length;
      expect(steps, greaterThanOrEqualTo(5),
          reason: 'L${level.number} is solvable in $steps moves');
    }
  });

  test('par is always achievable and at least the step count', () {
    for (final level in levels) {
      final result = RushHourSolver(level.blocks).solve(level.blocks);
      expect(result.solvable, isTrue, reason: 'L${level.number} unsolvable');
      expect(level.par, result.minMoves, reason: 'L${level.number} par drift');
      expect(level.par, greaterThanOrEqualTo(result.path.length));
    }
  });
}
