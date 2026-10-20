// E2E Contract Definitions: Analytics, Heatmaps, Streaks & Gamification
// Grounded in PROJECT.md and ORIGINAL_REQUEST.md (R4, AC10)

class HeatmapDay {
  final DateTime date;
  final int totalSeconds;
  final int intensityLevel; // 0, 1, 2, 3, 4

  HeatmapDay({
    required this.date,
    required this.totalSeconds,
    required this.intensityLevel,
  });

  static int calculateIntensity(int totalSeconds) {
    if (totalSeconds <= 0) return 0;
    if (totalSeconds < 3600) return 1; // < 1 hour
    if (totalSeconds < 7200) return 2; // 1-2 hours
    if (totalSeconds < 14400) return 3; // 2-4 hours
    return 4; // 4+ hours
  }
}

class StreakResult {
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastStudyDate;
  final bool isFrozen;

  StreakResult({
    required this.currentStreak,
    required this.longestStreak,
    this.lastStudyDate,
    this.isFrozen = false,
  });
}

class LeaderboardEntry {
  final int rank;
  final String userId;
  final String displayName;
  final int totalSeconds;
  final bool isAnonymous;
  final String? subjectName;

  LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.displayName,
    required this.totalSeconds,
    this.isAnonymous = false,
    this.subjectName,
  });
}

abstract class IStreakEngine {
  /// Calculates consecutive daily streak using 05:00 AM cutoff rule.
  /// Sessions between 00:00 and 05:00 are credited to previous calendar day.
  StreakResult calculateStreak({
    required List<DateTime> studySessionTimestamps,
    DateTime? relativeTo,
    int cutoffHour = 5,
  });
}

abstract class IAnalyticsService {
  List<HeatmapDay> generateAnnualHeatmap({
    required int year,
    required Map<DateTime, int> dailySecondsMap,
  });

  List<LeaderboardEntry> generateLeaderboard({
    required List<Map<String, dynamic>> rawUserStats,
    bool anonymizedMode = false,
  });
}
