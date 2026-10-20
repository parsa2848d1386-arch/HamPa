// Tier 1 E2E Feature Coverage: F33–F35 Analytics, Heatmaps & Streak Engine
// Minimum 5 tests per feature (15 test cases total)
// Grounded in PROJECT.md (F33–F35, AC10, E02, E23, E24, E25)

import '../contracts/analytics_contracts.dart';
import '../harness/test_analytics_harness.dart';
import '../support/test_runner.dart';

void runAnalyticsGamificationTier1Tests() {
  group('Tier 1: F33 GitHub-Style Study Heatmaps (5 tests)', () {
    late TestAnalyticsStreakEngine analytics;

    void setUp() {
      analytics = TestAnalyticsStreakEngine();
    }

    test('F33-1: Generate 365 heatmap day cells for standard Gregorian year', () async {
      setUp();
      final heatmap = analytics.generateAnnualHeatmap(
        year: 2025, // Non-leap year
        dailySecondsMap: {},
      );

      expect(heatmap.length, equals(365));
      expect(heatmap.first.intensityLevel, equals(0));
    });

    test('F33-2: Generate 366 heatmap day cells for leap year without grid overflow (E23)', () async {
      setUp();
      final heatmap = analytics.generateAnnualHeatmap(
        year: 2024, // Leap year (366 days)
        dailySecondsMap: {},
      );

      expect(heatmap.length, equals(366));
      expect(heatmap[59].date.month, equals(2));
      expect(heatmap[59].date.day, equals(29)); // Feb 29 leap day
    });

    test('F33-3: Map daily study seconds to 4 discrete intensity levels', () async {
      setUp();
      expect(HeatmapDay.calculateIntensity(0), equals(0)); // 0s -> Level 0
      expect(HeatmapDay.calculateIntensity(1800), equals(1)); // 30m -> Level 1 (< 1h)
      expect(HeatmapDay.calculateIntensity(5400), equals(2)); // 1.5h -> Level 2 (1-2h)
      expect(HeatmapDay.calculateIntensity(10800), equals(3)); // 3h -> Level 3 (2-4h)
      expect(HeatmapDay.calculateIntensity(18000), equals(4)); // 5h -> Level 4 (4h+)
    });

    test('F33-4: Daily study seconds update sets corresponding day intensity level (AC10)', () async {
      setUp();
      final date = DateTime(2026, 10, 16);
      final heatmap = analytics.generateAnnualHeatmap(
        year: 2026,
        dailySecondsMap: {date: 7200}, // 2 hours -> Level 3
      );

      final dayCell = heatmap.firstWhere((d) => d.date == date);
      expect(dayCell.totalSeconds, equals(7200));
      expect(dayCell.intensityLevel, equals(3));
    });

    test('F33-5: Days without study render as baseline Level 0 empty cells', () async {
      setUp();
      final heatmap = analytics.generateAnnualHeatmap(year: 2026, dailySecondsMap: {});
      expect(heatmap.every((d) => d.intensityLevel == 0), isTrue);
    });
  });

  group('Tier 1: F34 05:00 AM Day-Cutoff Streak Engine (5 tests)', () {
    late TestAnalyticsStreakEngine analytics;

    void setUp() {
      analytics = TestAnalyticsStreakEngine();
    }

    test('F34-1: Consecutive daily study timestamps calculate continuous streak', () async {
      setUp();
      final timestamps = [
        DateTime(2026, 10, 12, 10, 0),
        DateTime(2026, 10, 13, 14, 0),
        DateTime(2026, 10, 14, 18, 0),
        DateTime(2026, 10, 15, 20, 0),
        DateTime(2026, 10, 16, 11, 0),
      ];

      final result = analytics.calculateStreak(
        studySessionTimestamps: timestamps,
        relativeTo: DateTime(2026, 10, 16, 12, 0),
      );

      expect(result.currentStreak, equals(5));
      expect(result.longestStreak, equals(5));
    });

    test('F34-2: Night-owl session between 00:00 and 05:00 AM credited to preceding calendar day (E02)', () async {
      setUp();
      final timestamps = [
        DateTime(2026, 10, 14, 15, 0), // Day 1
        DateTime(2026, 10, 16, 2, 30),  // 02:30 AM Oct 16 -> credited to Oct 15 study day!
        DateTime(2026, 10, 16, 10, 0),  // Day 3 (Oct 16 morning)
      ];

      final result = analytics.calculateStreak(
        studySessionTimestamps: timestamps,
        relativeTo: DateTime(2026, 10, 16, 12, 0),
        cutoffHour: 5,
      );

      // Oct 14, Oct 15 (night session at 02:30 on 16th), Oct 16 = 3 continuous days!
      expect(result.currentStreak, equals(3));
    });

    test('F34-3: Gap day breaks current streak while preserving longest streak', () async {
      setUp();
      final timestamps = [
        DateTime(2026, 10, 10, 10, 0),
        DateTime(2026, 10, 11, 10, 0),
        DateTime(2026, 10, 12, 10, 0),
        // Oct 13 missed!
        DateTime(2026, 10, 14, 10, 0),
      ];

      final result = analytics.calculateStreak(
        studySessionTimestamps: timestamps,
        relativeTo: DateTime(2026, 10, 14, 12, 0),
      );

      expect(result.currentStreak, equals(1));
      expect(result.longestStreak, equals(3));
    });

    test('F34-4: Session completed today updates active streak immediately (AC10)', () async {
      setUp();
      final timestampsBefore = [
        DateTime(2026, 10, 14, 10, 0),
        DateTime(2026, 10, 15, 10, 0),
      ];

      final resBefore = analytics.calculateStreak(
        studySessionTimestamps: timestampsBefore,
        relativeTo: DateTime(2026, 10, 16, 8, 0), // Today Oct 16, no session yet
      );
      expect(resBefore.currentStreak, equals(2)); // Keeps alive from yesterday

      // Session finishes today on Oct 16
      final timestampsAfter = List<DateTime>.from(timestampsBefore)..add(DateTime(2026, 10, 16, 9, 0));
      final resAfter = analytics.calculateStreak(
        studySessionTimestamps: timestampsAfter,
        relativeTo: DateTime(2026, 10, 16, 10, 0),
      );

      expect(resAfter.currentStreak, equals(3));
    });

    test('F34-5: Empty study sessions list returns 0 streak', () async {
      setUp();
      final result = analytics.calculateStreak(studySessionTimestamps: []);
      expect(result.currentStreak, equals(0));
      expect(result.longestStreak, equals(0));
    });
  });

  group('Tier 1: F35 Multi-Tier Leaderboards & Privacy Controls (5 tests)', () {
    late TestAnalyticsStreakEngine analytics;

    void setUp() {
      analytics = TestAnalyticsStreakEngine();
    }

    test('F35-1: Generate ranked leaderboard sorted descending by total seconds', () async {
      setUp();
      final rawStats = [
        {'userId': 'u1', 'displayName': 'Alice', 'totalSeconds': 15000},
        {'userId': 'u2', 'displayName': 'Bob', 'totalSeconds': 24000},
        {'userId': 'u3', 'displayName': 'Charlie', 'totalSeconds': 18000},
      ];

      final leaderboard = analytics.generateLeaderboard(rawUserStats: rawStats);

      expect(leaderboard[0].displayName, equals('Bob'));
      expect(leaderboard[0].rank, equals(1));
      expect(leaderboard[1].displayName, equals('Charlie'));
      expect(leaderboard[1].rank, equals(2));
      expect(leaderboard[2].displayName, equals('Alice'));
      expect(leaderboard[2].rank, equals(3));
    });

    test('F35-2: Anonymized Mode toggle masks username to Anonymous #Hash (E25)', () async {
      setUp();
      final rawStats = [
        {'userId': 'secret_user_99', 'displayName': 'Parsa', 'totalSeconds': 36000},
      ];

      final leaderboard = analytics.generateLeaderboard(
        rawUserStats: rawStats,
        anonymizedMode: true,
      );

      expect(leaderboard.first.isAnonymous, isTrue);
      expect(leaderboard.first.displayName, contains('Anonymous #'));
      expect(leaderboard.first.displayName.contains('Parsa'), isFalse);
    });

    test('F35-3: Anonymized Mode masks subject names to General Study (E25)', () async {
      setUp();
      final rawStats = [
        {'userId': 'u_priv', 'displayName': 'Sara', 'totalSeconds': 12000, 'subjectName': 'Organic Chemistry'},
      ];

      final leaderboard = analytics.generateLeaderboard(
        rawUserStats: rawStats,
        anonymizedMode: true,
      );

      expect(leaderboard.first.subjectName, equals('General Study'));
    });

    test('F35-4: Non-anonymized user displays original name and subject', () async {
      setUp();
      final rawStats = [
        {'userId': 'u_pub', 'displayName': 'Mina', 'totalSeconds': 8000, 'subjectName': 'Linear Algebra'},
      ];

      final leaderboard = analytics.generateLeaderboard(
        rawUserStats: rawStats,
        anonymizedMode: false,
      );

      expect(leaderboard.first.isAnonymous, isFalse);
      expect(leaderboard.first.displayName, equals('Mina'));
      expect(leaderboard.first.subjectName, equals('Linear Algebra'));
    });

    test('F35-5: Per-user privacy flag overrides global mode when true', () async {
      setUp();
      final rawStats = [
        {'userId': 'u_anon_flag', 'displayName': 'PrivatePerson', 'totalSeconds': 5000, 'isAnonymous': true},
      ];

      final leaderboard = analytics.generateLeaderboard(
        rawUserStats: rawStats,
        anonymizedMode: false, // global mode false, but user set isAnonymous true
      );

      expect(leaderboard.first.isAnonymous, isTrue);
      expect(leaderboard.first.displayName, contains('Anonymous #'));
    });
  });
}
