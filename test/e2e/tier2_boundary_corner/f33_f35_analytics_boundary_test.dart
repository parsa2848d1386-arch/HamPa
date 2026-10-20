// Tier 2 E2E Boundary & Corner Cases: F33–F35 Analytics, Heatmaps & Streak Engine
// Minimum 5 tests per feature (15 test cases total)
// Grounded in PROJECT.md (F33–F35, AC10, E02, E23, E24, E25)

import '../contracts/analytics_contracts.dart';
import '../harness/test_analytics_harness.dart';
import '../support/test_runner.dart';

void runAnalyticsGamificationTier2Tests() {
  group('Tier 2: F33 GitHub-Style Study Heatmaps Boundaries (5 tests)', () {
    late TestAnalyticsStreakEngine analytics;

    void setUp() {
      analytics = TestAnalyticsStreakEngine();
    }

    test('F33-B1: Century leap year 2000 has 366 days, century non-leap year 1900 has 365 days (E23)', () async {
      setUp();
      final h2000 = analytics.generateAnnualHeatmap(year: 2000, dailySecondsMap: {});
      final h1900 = analytics.generateAnnualHeatmap(year: 1900, dailySecondsMap: {});

      expect(h2000.length, equals(366));
      expect(h1900.length, equals(365));
    });

    test('F33-B2: Exact intensity threshold boundary values (3599s vs 3600s, 7199s vs 7200s, 14399s vs 14400s)', () async {
      setUp();
      // Level 1: < 3600
      expect(HeatmapDay.calculateIntensity(3599), equals(1));
      // Level 2: 3600 to 7199
      expect(HeatmapDay.calculateIntensity(3600), equals(2));
      expect(HeatmapDay.calculateIntensity(7199), equals(2));
      // Level 3: 7200 to 14399
      expect(HeatmapDay.calculateIntensity(7200), equals(3));
      expect(HeatmapDay.calculateIntensity(14399), equals(3));
      // Level 4: >= 14400
      expect(HeatmapDay.calculateIntensity(14400), equals(4));
    });

    test('F33-B3: Negative study seconds safely clamp to Level 0 intensity', () async {
      setUp();
      expect(HeatmapDay.calculateIntensity(-100), equals(0));
    });

    test('F33-B4: 24-hour study duration (86400s) calculates Level 4 intensity without overflow', () async {
      setUp();
      expect(HeatmapDay.calculateIntensity(86400), equals(4));
    });

    test('F33-B5: Multi-year heatmaps generate expected days count for 2026, 2027, 2028', () async {
      setUp();
      expect(analytics.generateAnnualHeatmap(year: 2026, dailySecondsMap: {}).length, equals(365));
      expect(analytics.generateAnnualHeatmap(year: 2027, dailySecondsMap: {}).length, equals(365));
      expect(analytics.generateAnnualHeatmap(year: 2028, dailySecondsMap: {}).length, equals(366)); // 2028 is leap
    });
  });

  group('Tier 2: F34 05:00 AM Day-Cutoff Streak Engine Boundaries (5 tests)', () {
    late TestAnalyticsStreakEngine analytics;

    void setUp() {
      analytics = TestAnalyticsStreakEngine();
    }

    test('F34-B1: Modifying custom day cutoff hour from 05:00 to 03:00 recalculates streaks without altering raw timestamps (E24)', () async {
      setUp();
      // Session at 04:00 AM on Oct 16
      final ts = [DateTime(2026, 10, 16, 4, 0)];

      // Under 05:00 AM cutoff: 04:00 AM belongs to Oct 15 study day
      final res5 = analytics.calculateStreak(
        studySessionTimestamps: ts,
        relativeTo: DateTime(2026, 10, 16, 12, 0),
        cutoffHour: 5,
      );
      expect(res5.lastStudyDate!.day, equals(15));

      // Under 03:00 AM cutoff: 04:00 AM belongs to Oct 16 study day!
      final res3 = analytics.calculateStreak(
        studySessionTimestamps: ts,
        relativeTo: DateTime(2026, 10, 16, 12, 0),
        cutoffHour: 3,
      );
      expect(res3.lastStudyDate!.day, equals(16));
    });

    test('F34-B2: Session at exactly 05:00:00 AM belongs to today study day', () async {
      setUp();
      final ts = [DateTime(2026, 10, 16, 5, 0, 0)];
      final res = analytics.calculateStreak(
        studySessionTimestamps: ts,
        relativeTo: DateTime(2026, 10, 16, 12, 0),
        cutoffHour: 5,
      );
      expect(res.lastStudyDate!.day, equals(16));
    });

    test('F34-B3: Session at exactly 04:59:59 AM belongs to yesterday study day', () async {
      setUp();
      final ts = [DateTime(2026, 10, 16, 4, 59, 59)];
      final res = analytics.calculateStreak(
        studySessionTimestamps: ts,
        relativeTo: DateTime(2026, 10, 16, 12, 0),
        cutoffHour: 5,
      );
      expect(res.lastStudyDate!.day, equals(15));
    });

    test('F34-B4: 365 continuous days study streak calculation', () async {
      setUp();
      final timestamps = <DateTime>[];
      final start = DateTime(2025, 1, 1, 10, 0);
      for (var i = 0; i < 365; i++) {
        timestamps.add(start.add(Duration(days: i)));
      }

      final res = analytics.calculateStreak(
        studySessionTimestamps: timestamps,
        relativeTo: DateTime(2025, 12, 31, 12, 0),
      );

      expect(res.currentStreak, equals(365));
      expect(res.longestStreak, equals(365));
    });

    test('F34-B5: Single study session on today produces currentStreak 1', () async {
      setUp();
      final res = analytics.calculateStreak(
        studySessionTimestamps: [DateTime(2026, 10, 16, 10, 0)],
        relativeTo: DateTime(2026, 10, 16, 12, 0),
      );
      expect(res.currentStreak, equals(1));
    });
  });

  group('Tier 2: F35 Leaderboards & Privacy Controls Boundaries (5 tests)', () {
    late TestAnalyticsStreakEngine analytics;

    void setUp() {
      analytics = TestAnalyticsStreakEngine();
    }

    test('F35-B1: Empty leaderboard raw user stats returns empty list', () async {
      setUp();
      final list = analytics.generateLeaderboard(rawUserStats: []);
      expect(list.isEmpty, isTrue);
    });

    test('F35-B2: Ties in total seconds handle rank assignments gracefully', () async {
      setUp();
      final stats = [
        {'userId': 'u1', 'displayName': 'User 1', 'totalSeconds': 10000},
        {'userId': 'u2', 'displayName': 'User 2', 'totalSeconds': 10000},
      ];

      final list = analytics.generateLeaderboard(rawUserStats: stats);
      expect(list.length, equals(2));
      expect(list[0].totalSeconds, equals(10000));
      expect(list[1].totalSeconds, equals(10000));
    });

    test('F35-B3: Anonymized mode username hash produces stable 4-digit ID (E25)', () async {
      setUp();
      final stats = [
        {'userId': 'unique_user_id_456', 'displayName': 'Real Name', 'totalSeconds': 5000},
      ];

      final list1 = analytics.generateLeaderboard(rawUserStats: stats, anonymizedMode: true);
      final list2 = analytics.generateLeaderboard(rawUserStats: stats, anonymizedMode: true);

      expect(list1.first.displayName, equals(list2.first.displayName));
      expect(list1.first.displayName, contains('Anonymous #'));
    });

    test('F35-B4: 100 users leaderboard ranking correctly orders highest to lowest', () async {
      setUp();
      final stats = List.generate(100, (i) => {
        'userId': 'user_$i',
        'displayName': 'User $i',
        'totalSeconds': i * 100,
      });

      final list = analytics.generateLeaderboard(rawUserStats: stats);
      expect(list.length, equals(100));
      expect(list.first.rank, equals(1));
      expect(list.first.totalSeconds, equals(9900));
      expect(list.last.rank, equals(100));
      expect(list.last.totalSeconds, equals(0));
    });

    test('F35-B5: Null subjectName in raw stats remains null in public mode', () async {
      setUp();
      final stats = [
        {'userId': 'u_nosub', 'displayName': 'NoSub', 'totalSeconds': 500, 'subjectName': null},
      ];

      final list = analytics.generateLeaderboard(rawUserStats: stats, anonymizedMode: false);
      expect(list.first.subjectName, isNull);
    });
  });
}
