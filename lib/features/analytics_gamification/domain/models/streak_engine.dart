import 'streak_result.dart';
export 'streak_result.dart';

class HeatmapDayEntry {
  final DateTime date;
  final int totalMinutes;
  final int intensityLevel; // 0 (none), 1 (light), 2 (medium), 3 (high), 4 (max)

  const HeatmapDayEntry({
    required this.date,
    required this.totalMinutes,
    required this.intensityLevel,
  });

  /// Computes intensity level based on 4 thresholds:
  /// 0 = empty (0m)
  /// 1 = 1-29m
  /// 2 = 30-59m
  /// 3 = 60-119m
  /// 4 = 120m+
  static int computeIntensity(int minutes) {
    if (minutes <= 0) return 0;
    if (minutes < 30) return 1;
    if (minutes < 60) return 2;
    if (minutes < 120) return 3;
    return 4;
  }

  static int computeIntensityFromSeconds(int seconds) {
    return computeIntensity((seconds / 60).floor());
  }
}

class StreakEngine {
  /// Computes active study streak taking into account customizable day cutoff (default 05:00 AM).
  /// A study session before cutoff hour counts towards the previous calendar day.
  /// Uses calendar day arithmetic (DateTime(y, m, d - 1)) to prevent DST bugs.
  static StreakResult calculateStreak(
    List<DateTime> studySessionDates, {
    DateTime? currentNow,
    int cutoffHour = 5,
  }) {
    if (studySessionDates.isEmpty) {
      return const StreakResult(currentStreak: 0, longestStreak: 0);
    }

    final now = currentNow ?? DateTime.now();

    // Normalize dates using cutoffHour and calendar day calculation
    final studyDays = <DateTime>{};
    for (final dt in studySessionDates) {
      studyDays.add(_normalizeToLogicalDate(dt, cutoffHour: cutoffHour));
    }

    if (studyDays.isEmpty) {
      return const StreakResult(currentStreak: 0, longestStreak: 0);
    }

    final sortedDays = studyDays.toList()..sort((a, b) => a.compareTo(b));

    // Determine current streak relative to reference date
    final todayNormalized = _normalizeToLogicalDate(now, cutoffHour: cutoffHour);
    final yesterdayNormalized = DateTime(todayNormalized.year, todayNormalized.month, todayNormalized.day - 1);

    int currentStreak = 0;
    DateTime? checkDate;

    if (studyDays.contains(todayNormalized)) {
      checkDate = todayNormalized;
    } else if (studyDays.contains(yesterdayNormalized)) {
      checkDate = yesterdayNormalized;
    }

    if (checkDate != null) {
      while (studyDays.contains(checkDate!)) {
        currentStreak++;
        checkDate = DateTime(checkDate.year, checkDate.month, checkDate.day - 1);
      }
    }

    // Calculate longest historical streak using calendar day difference
    int longestStreak = 0;
    int currentRun = 0;
    DateTime? prevDay;

    for (final day in sortedDays) {
      if (prevDay == null) {
        currentRun = 1;
      } else {
        final expectedNext = DateTime(prevDay.year, prevDay.month, prevDay.day + 1);
        if (day.year == expectedNext.year &&
            day.month == expectedNext.month &&
            day.day == expectedNext.day) {
          currentRun++;
        } else {
          currentRun = 1;
        }
      }
      if (currentRun > longestStreak) {
        longestStreak = currentRun;
      }
      prevDay = day;
    }

    return StreakResult(
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      lastStudyDate: sortedDays.last,
    );
  }

  static DateTime _normalizeToLogicalDate(DateTime dt, {int cutoffHour = 5}) {
    if (dt.hour < cutoffHour) {
      // Midnight sessions before cutoff belong to previous calendar day
      return DateTime(dt.year, dt.month, dt.day - 1);
    }
    return DateTime(dt.year, dt.month, dt.day);
  }
}
