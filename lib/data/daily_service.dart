import 'dart:math' as math;

import 'package:shared_preferences/shared_preferences.dart';

/// Snapshot of the player's daily-challenge state.
class DailyStatus {
  /// Whether today's challenge has already been completed.
  final bool completedToday;

  /// Current *live* streak: consecutive days completed up to today. Resets to 0
  /// once a day is missed (i.e. the last completion is older than yesterday).
  final int streak;

  /// The best streak ever reached.
  final int longest;

  const DailyStatus({
    required this.completedToday,
    required this.streak,
    required this.longest,
  });
}

/// Handles the once-a-day challenge and its streak — the core "come back
/// tomorrow" retention loop. All state is persisted via [SharedPreferences].
///
/// The daily puzzle itself is deterministic per calendar day (see [dailySeed]),
/// so everyone playing on the same date gets the same board and it can't be
/// re-rolled by restarting the app.
class DailyService {
  static const _lastKey = 'daily_last_completed'; // 'YYYY-MM-DD'
  static const _streakKey = 'daily_streak';
  static const _longestKey = 'daily_longest';

  /// Deterministic seed for a given day.
  static int dailySeed(DateTime date) =>
      date.year * 10000 + date.month * 100 + date.day;

  static String _key(DateTime d) => '${d.year}-${d.month}-${d.day}';

  static DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  /// Read the current daily state without changing anything.
  static Future<DailyStatus> status() async {
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getString(_lastKey);
    final stored = prefs.getInt(_streakKey) ?? 0;
    final longest = prefs.getInt(_longestKey) ?? 0;

    final today = _today();
    final todayKey = _key(today);
    final yesterdayKey = _key(today.subtract(const Duration(days: 1)));

    final completedToday = last == todayKey;
    // A streak only counts as "live" if the last completion was today or
    // yesterday; otherwise it has been broken and shows as 0.
    final live = (last == todayKey || last == yesterdayKey) ? stored : 0;

    return DailyStatus(
      completedToday: completedToday,
      streak: live,
      longest: longest,
    );
  }

  /// Mark today's challenge complete and advance the streak. Idempotent: calling
  /// it again on the same day does not double-count.
  static Future<DailyStatus> markComplete() async {
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getString(_lastKey);
    var streak = prefs.getInt(_streakKey) ?? 0;
    var longest = prefs.getInt(_longestKey) ?? 0;

    final today = _today();
    final todayKey = _key(today);
    final yesterdayKey = _key(today.subtract(const Duration(days: 1)));

    if (last == todayKey) {
      // Already done today — nothing to advance.
      return DailyStatus(
          completedToday: true, streak: streak, longest: longest);
    }

    if (last == yesterdayKey) {
      streak += 1; // continued the run
    } else {
      streak = 1; // first day, or streak was broken
    }
    longest = math.max(longest, streak);

    await prefs.setString(_lastKey, todayKey);
    await prefs.setInt(_streakKey, streak);
    await prefs.setInt(_longestKey, longest);

    return DailyStatus(completedToday: true, streak: streak, longest: longest);
  }
}
