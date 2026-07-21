import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import '../logic/level_generator.dart';
import '../models/level.dart';
import 'daily_service.dart';
import 'levels_data.dart';

/// Source of truth for the full level set.
///
/// The first [kCuratedLevels] are hand-authored (they form the gentle tutorial
/// curve); the remainder are procedurally generated once, verified solvable, and
/// cached to disk so later launches are instant. Endless levels are generated
/// on demand with ever-increasing difficulty.
class LevelRepository extends ChangeNotifier {
  LevelRepository._();
  static final LevelRepository instance = LevelRepository._();

  /// Total number of levels in the main campaign (>= 80 as required).
  static const int totalLevels = 80;

  /// Only the first few curated levels are used, as the gentle tutorial. Every
  /// level from here on is generated with a steep difficulty ramp.
  static const int _tutorialCount = 3;

  // Bump this key whenever the generated difficulty curve changes so cached
  // levels from older builds are discarded and regenerated.
  static const String _cacheKey = 'generated_levels_v4';

  List<Level> _levels = const [];
  bool _loaded = false;

  List<Level> get levels => _levels;
  int get levelCount => _levels.length;
  bool get isLoaded => _loaded;

  /// Ensure the full campaign is available. Safe to call repeatedly.
  ///
  /// The generated levels (4..80) are pre-built at development time by
  /// `tool/generate_levels.dart` and shipped as a bundled asset, so first
  /// launch is instant. If that asset is ever missing/corrupt we fall back to
  /// generating them in a background isolate and caching the result.
  Future<void> ensureLoaded() async {
    if (_loaded) return;

    final generatedCount = totalLevels - _tutorialCount;

    List<Level>? generated = await _loadBundled(generatedCount);
    generated ??= await _generateAndCache(generatedCount);

    _levels = [...kCuratedLevels.take(_tutorialCount), ...generated];
    _loaded = true;
    notifyListeners();
  }

  /// Load the pre-generated campaign from the shipped asset. Returns null if the
  /// asset is missing or doesn't match the expected count.
  Future<List<Level>?> _loadBundled(int expectedCount) async {
    try {
      final json = await rootBundle.loadString('assets/data/campaign_levels.json');
      final decoded = (jsonDecode(json) as List)
          .map((e) => Level.fromJson(e as Map<String, dynamic>))
          .toList();
      return decoded.length == expectedCount ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  /// Fallback: generate the campaign in a background isolate and cache it.
  Future<List<Level>> _generateAndCache(int expectedCount) async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_cacheKey);
    if (cached != null) {
      try {
        final decoded = (jsonDecode(cached) as List)
            .map((e) => Level.fromJson(e as Map<String, dynamic>))
            .toList();
        if (decoded.length == expectedCount) return decoded;
      } catch (_) {
        // Corrupt cache — regenerate below.
      }
    }

    final json = await compute(
      _generateMainSetJson,
      [_tutorialCount, totalLevels],
    );
    await prefs.setString(_cacheKey, json);
    return (jsonDecode(json) as List)
        .map((e) => Level.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Generate the daily-challenge level for the given [date]. Deterministic per
  /// calendar day (same board for everyone on that date) and a satisfying
  /// mid-tier difficulty. Verified solvable by the generator.
  Level dailyLevel(DateTime date) {
    final seed = DailyService.dailySeed(date);
    return LevelGenerator.generate(
      number: seed,
      rng: Random(seed),
      targetBlocks: 9,
      minSteps: 8,
      maxSteps: 11,
      minPar: 8,
      maxPar: 16,
    );
  }

  /// Generate an endless-mode level for the given 0-based [index]. Difficulty
  /// scales indefinitely with the index. Deterministic per index.
  ///
  /// Like the campaign, the curve is driven by solver *step* count rather than
  /// par — see [LevelGenerator.campaignParams]. Endless opens around mid-campaign
  /// difficulty (7 decisions) and climbs from there.
  Level endlessLevel(int index) {
    final targetBlocks = min(13, 8 + index ~/ 3);
    final minSteps = min(15, 7 + index ~/ 2);
    final rng = Random(500000 + index);
    return LevelGenerator.generate(
      number: index + 1,
      rng: rng,
      targetBlocks: targetBlocks,
      minSteps: minSteps,
      maxSteps: minSteps + 3,
      minPar: minSteps,
      maxPar: minSteps + 8,
    );
  }
}

/// Top-level entry point run inside a background isolate via [compute].
/// Returns the generated levels encoded as a JSON string.
String _generateMainSetJson(List<int> args) {
  final startCount = args[0];
  final total = args[1];
  final count = total - startCount;
  final list = <Level>[];

  for (int i = 0; i < count; i++) {
    final number = startCount + i + 1; // levels 4..80
    final p = LevelGenerator.campaignParams(number);
    list.add(LevelGenerator.generate(
      number: number,
      rng: Random(1000 + number),
      targetBlocks: p.targetBlocks,
      minPar: p.minPar,
      maxPar: p.maxPar,
      minSteps: p.minSteps,
      maxSteps: p.maxSteps,
    ));
  }

  return jsonEncode(list.map((e) => e.toJson()).toList());
}
