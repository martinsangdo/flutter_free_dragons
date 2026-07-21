import 'package:shared_preferences/shared_preferences.dart';

/// Miscellaneous persisted app preferences and stats that survive restarts:
/// the "how to play" seen flag and the best endless streak.
class AppPrefs {
  static const _howToPlaySeenKey = 'how_to_play_seen';
  static const _endlessBestKey = 'endless_best';

  static Future<bool> hasSeenHowToPlay() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_howToPlaySeenKey) ?? false;
  }

  static Future<void> setHowToPlaySeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_howToPlaySeenKey, true);
  }

  static Future<int> getEndlessBest() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_endlessBestKey) ?? 0;
  }

  /// Records a new endless best if [reached] beats the stored value.
  static Future<void> recordEndless(int reached) async {
    final prefs = await SharedPreferences.getInstance();
    final best = prefs.getInt(_endlessBestKey) ?? 0;
    if (reached > best) await prefs.setInt(_endlessBestKey, reached);
  }

  static Future<void> resetEndless() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_endlessBestKey);
  }
}
