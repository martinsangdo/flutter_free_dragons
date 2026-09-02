import 'package:shared_preferences/shared_preferences.dart';

/// Miscellaneous persisted app preferences and stats that survive restarts:
/// the "how to play" seen flag.
class AppPrefs {
  static const _howToPlaySeenKey = 'how_to_play_seen';

  static Future<bool> hasSeenHowToPlay() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_howToPlaySeenKey) ?? false;
  }

  static Future<void> setHowToPlaySeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_howToPlaySeenKey, true);
  }
}
