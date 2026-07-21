import 'package:shared_preferences/shared_preferences.dart';

class ProgressService {
  static const _unlockedKey = 'highest_unlocked_level';
  static const _starsPrefix = 'level_stars_';

  static Future<int> getHighestUnlocked() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_unlockedKey) ?? 0;
  }

  static Future<Map<int, int>> getAllStars(int levelCount) async {
    final prefs = await SharedPreferences.getInstance();
    final result = <int, int>{};
    for (int i = 0; i < levelCount; i++) {
      final s = prefs.getInt('$_starsPrefix$i');
      if (s != null) result[i] = s;
    }
    return result;
  }

  static Future<void> markCompleted(int levelIndex, int stars) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_unlockedKey) ?? 0;
    if (levelIndex >= current) {
      await prefs.setInt(_unlockedKey, levelIndex + 1);
    }
    final prevStars = prefs.getInt('$_starsPrefix$levelIndex') ?? 0;
    if (stars > prevStars) {
      await prefs.setInt('$_starsPrefix$levelIndex', stars);
    }
  }

  static bool isUnlocked(int levelIndex, int highestUnlocked) {
    return levelIndex <= highestUnlocked;
  }

  /// Wipe all campaign progress (unlock state + stars). Used by Settings.
  static Future<void> resetProgress(int levelCount) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_unlockedKey);
    for (int i = 0; i < levelCount; i++) {
      await prefs.remove('$_starsPrefix$i');
    }
  }
}
