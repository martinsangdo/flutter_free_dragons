// Build-time generator for the campaign level set.
//
// Run with:  dart run tool/generate_levels.dart
//
// It generates the procedural levels (numbers 4..80) with the steep difficulty
// ramp, verifies each is solvable, and writes them to
// assets/data/campaign_levels.json which the app ships and loads at startup —
// so players never wait for generation on first launch. The parameters here
// MUST match LevelRepository's fallback generator.

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:free_the_key/logic/level_generator.dart';
import 'package:free_the_key/logic/solver.dart';
import 'package:free_the_key/models/level.dart';

const int tutorialCount = 3;
const int totalLevels = 80;

void main() {
  final count = totalLevels - tutorialCount;
  final levels = <Level>[];
  final steps = <int>[];
  int unsolvable = 0;
  final outOfBand = <String>[];

  for (int i = 0; i < count; i++) {
    final number = tutorialCount + i + 1; // 4..80
    final p = LevelGenerator.campaignParams(number);
    final level = LevelGenerator.generate(
      number: number,
      rng: Random(1000 + number),
      targetBlocks: p.targetBlocks,
      minPar: p.minPar,
      maxPar: p.maxPar,
      minSteps: p.minSteps,
      maxSteps: p.maxSteps,
    );
    final result = RushHourSolver(level.blocks).solve(level.blocks);
    if (!result.solvable) unsolvable++;

    // The difficulty band is the whole point of the curve, so a level that
    // fell back outside it is worth shouting about rather than shipping quietly.
    final n = result.path.length;
    steps.add(n);
    if (n < p.minSteps || n > p.maxSteps) {
      outOfBand.add('L$number: $n steps (want ${p.minSteps}..${p.maxSteps})');
    }
    levels.add(level);
  }

  if (unsolvable != 0) {
    stderr.writeln('ERROR: $unsolvable generated levels are unsolvable.');
    exit(1);
  }

  final json = jsonEncode(levels.map((e) => e.toJson()).toList());
  final file = File('assets/data/campaign_levels.json');
  file.writeAsStringSync(json);

  final pars = levels.map((e) => e.par).toList();
  stdout.writeln('Wrote ${levels.length} levels to ${file.path}');
  stdout.writeln('Par range:   ${pars.reduce(min)}..${pars.reduce(max)} '
      '(level 4 = ${pars.first}, level 80 = ${pars.last})');
  stdout.writeln('Step range:  ${steps.reduce(min)}..${steps.reduce(max)} '
      '(level 4 = ${steps.first}, level 80 = ${steps.last})');
  if (outOfBand.isEmpty) {
    stdout.writeln('All levels landed inside their difficulty band.');
  } else {
    stdout.writeln('${outOfBand.length} level(s) outside their band:');
    for (final m in outOfBand) {
      stdout.writeln('  $m');
    }
  }
}
