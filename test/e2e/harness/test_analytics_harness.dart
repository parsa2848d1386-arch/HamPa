// Test Reference Harness: Analytics, Heatmaps & Streak Engine
// Grounded in PROJECT.md (F33–F35, AC10, E02, E23, E25)

import '../contracts/analytics_contracts.dart';

class TestAnalyticsStreakEngine implements IStreakEngine, IAnalyticsService {
  @override
  StreakResult calculateStreak({
    required List<DateTime> studySessionTimestamps,
    DateTime? relativeTo,
    int cutoffHour = 5,
  }) {
    if (studySessionTimestamps.isEmpty) {
      return StreakResult(currentStreak: 0, longestStreak: 0);
    }

    // Map each session timestamp to its study day date using the cutoff hour
    final studyDays = <DateTime>{};
    for (final ts in studySessionTimestamps) {
      DateTime studyDate;
      if (ts.hour < cutoffHour) {
        // Night-owl session between midnight and cutoff: belongs to previous calendar day
        final prevDay = ts.subtract(const Duration(days: 1));
        studyDate = DateTime(prevDay.year, prevDay.month, prevDay.day);
      } else {
        studyDate = DateTime(ts.year, ts.month, ts.day);
      }
      studyDays.add(studyDate);
    }

    final sortedDays = studyDays.toList()..sort((a, b) => a.compareTo(b));
    if (sortedDays.isEmpty) {
      return StreakResult(currentStreak: 0, longestStreak: 0);
    }

    // Determine current streak relative to reference date
    final ref = relativeTo ?? DateTime.now();
    DateTime refStudyDate;
    if (ref.hour < cutoffHour) {
      final prev = ref.subtract(const Duration(days: 1));
      refStudyDate = DateTime(prev.year, prev.month, prev.day);
    } else {
      refStudyDate = DateTime(ref.year, ref.month, ref.day);
    }

    var currentStreak = 0;
    var checkDate = refStudyDate;

    // If today hasn't been studied yet, check if yesterday was studied to keep streak alive
    if (!studyDays.contains(checkDate)) {
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    while (studyDays.contains(checkDate)) {
      currentStreak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    // Calculate longest historical streak
    var longestStreak = 0;
    var streakRun = 0;
    DateTime? previousDay;

    for (final day in sortedDays) {
      if (previousDay == null) {
        streakRun = 1;
      } else {
        final diff = day.difference(previousDay).inDays;
        if (diff == 1) {
          streakRun++;
        } else if (diff > 1) {
          streakRun = 1;
        }
      }
      if (streakRun > longestStreak) {
        longestStreak = streakRun;
      }
      previousDay = day;
    }

    return StreakResult(
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      lastStudyDate: sortedDays.last,
    );
  }

  @override
  List<HeatmapDay> generateAnnualHeatmap({
    required int year,
    required Map<DateTime, int> dailySecondsMap,
  }) {
    // Check leap year
    final isLeapYear = (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
    final totalDays = isLeapYear ? 366 : 365;

    final result = <HeatmapDay>[];
    final startDate = DateTime(year, 1, 1);

    for (var i = 0; i < totalDays; i++) {
      final date = startDate.add(Duration(days: i));
      final dateKey = DateTime(date.year, date.month, date.day);
      final seconds = dailySecondsMap[dateKey] ?? 0;
      final intensity = HeatmapDay.calculateIntensity(seconds);

      result.add(HeatmapDay(
        date: dateKey,
        totalSeconds: seconds,
        intensityLevel: intensity,
      ));
    }

    return result;
  }

  @override
  List<LeaderboardEntry> generateLeaderboard({
    required List<Map<String, dynamic>> rawUserStats,
    bool anonymizedMode = false,
  }) {
    final list = List<Map<String, dynamic>>.from(rawUserStats)
      ..sort((a, b) => (b['totalSeconds'] as int).compareTo(a['totalSeconds'] as int));

    return List.generate(list.length, (index) {
      final item = list[index];
      final isAnon = anonymizedMode || (item['isAnonymous'] as bool? ?? false);
      final userId = item['userId'] as String;
      final displayName = isAnon ? 'Anonymous #${userId.hashCode.abs().toString().padLeft(4, '0').substring(0, 4)}' : (item['displayName'] as String);
      final subjectName = isAnon ? 'General Study' : (item['subjectName'] as String?);

      return LeaderboardEntry(
        rank: index + 1,
        userId: userId,
        displayName: displayName,
        totalSeconds: item['totalSeconds'] as int,
        isAnonymous: isAnon,
        subjectName: subjectName,
      );
    });
  }
}
