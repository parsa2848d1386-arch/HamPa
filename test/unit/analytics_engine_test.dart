import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hampa/features/analytics_gamification/domain/models/streak_engine.dart';
import 'package:hampa/features/analytics_gamification/presentation/widgets/leaderboard_view.dart';
import 'package:hampa/features/analytics_gamification/presentation/widgets/study_heatmap_widget.dart';
import 'package:hampa/features/analytics_gamification/services/leaderboard_service.dart';

void main() {
  group('StreakEngine Unit Tests', () {
    test('calculateStreak computes continuous current and longest streak', () {
      final timestamps = [
        DateTime(2026, 10, 12, 10, 0),
        DateTime(2026, 10, 13, 14, 0),
        DateTime(2026, 10, 14, 18, 0),
        DateTime(2026, 10, 15, 20, 0),
        DateTime(2026, 10, 16, 11, 0),
      ];

      final result = StreakEngine.calculateStreak(
        timestamps,
        currentNow: DateTime(2026, 10, 16, 12, 0),
      );

      expect(result.currentStreak, equals(5));
      expect(result.longestStreak, equals(5));
      expect(result.lastStudyDate, isNotNull);
    });

    test('Night-owl session between 00:00 and 05:00 AM credited to preceding calendar day', () {
      final timestamps = [
        DateTime(2026, 10, 14, 15, 0), // Day 1
        DateTime(2026, 10, 16, 2, 30),  // 02:30 AM on Oct 16 -> credited to Oct 15!
        DateTime(2026, 10, 16, 10, 0),  // Day 3 (Oct 16 morning)
      ];

      final result = StreakEngine.calculateStreak(
        timestamps,
        currentNow: DateTime(2026, 10, 16, 12, 0),
        cutoffHour: 5,
      );

      // Oct 14, Oct 15 (night session at 02:30), Oct 16 = 3 continuous days
      expect(result.currentStreak, equals(3));
      expect(result.longestStreak, equals(3));
    });

    test('DST Bug Fix: Calendar day calculation DateTime(y, m, d - 1) preserves streak across daylight transitions', () {
      // Simulating timestamps spanning a date boundary where Duration(days: 1) would suffer from DST drift
      final timestamps = [
        DateTime(2026, 3, 28, 14, 0),
        DateTime(2026, 3, 29, 14, 0),
        DateTime(2026, 3, 30, 14, 0),
        DateTime(2026, 3, 31, 14, 0),
      ];

      final result = StreakEngine.calculateStreak(
        timestamps,
        currentNow: DateTime(2026, 3, 31, 18, 0),
      );

      expect(result.currentStreak, equals(4));
      expect(result.longestStreak, equals(4));
    });

    test('Gap day breaks current streak while preserving longest historical streak', () {
      final timestamps = [
        DateTime(2026, 10, 10, 10, 0),
        DateTime(2026, 10, 11, 10, 0),
        DateTime(2026, 10, 12, 10, 0),
        // Oct 13 missed!
        DateTime(2026, 10, 14, 10, 0),
      ];

      final result = StreakEngine.calculateStreak(
        timestamps,
        currentNow: DateTime(2026, 10, 14, 12, 0),
      );

      expect(result.currentStreak, equals(1));
      expect(result.longestStreak, equals(3));
    });

    test('Streak is kept alive if yesterday was studied and today has no session yet', () {
      final timestamps = [
        DateTime(2026, 10, 14, 10, 0),
        DateTime(2026, 10, 15, 10, 0),
      ];

      final resBefore = StreakEngine.calculateStreak(
        timestamps,
        currentNow: DateTime(2026, 10, 16, 8, 0), // Today Oct 16, not studied yet
      );
      expect(resBefore.currentStreak, equals(2)); // Keeps alive from yesterday

      // Now session finished today on Oct 16
      final updated = List<DateTime>.from(timestamps)..add(DateTime(2026, 10, 16, 9, 0));
      final resAfter = StreakEngine.calculateStreak(
        updated,
        currentNow: DateTime(2026, 10, 16, 10, 0),
      );
      expect(resAfter.currentStreak, equals(3));
    });

    test('Empty timestamps list returns 0 streak', () {
      final result = StreakEngine.calculateStreak([]);
      expect(result.currentStreak, equals(0));
      expect(result.longestStreak, equals(0));
      expect(result.lastStudyDate, isNull);
    });

    test('Custom cutoff hour configures day boundary', () {
      final timestamps = [
        DateTime(2026, 10, 15, 20, 0),
        DateTime(2026, 10, 16, 5, 30), // With cutoffHour = 6, 05:30 AM counts towards Oct 15!
      ];

      final result = StreakEngine.calculateStreak(
        timestamps,
        currentNow: DateTime(2026, 10, 16, 12, 0),
        cutoffHour: 6,
      );

      // Both belong to Oct 15 logical day
      expect(result.currentStreak, equals(1));
      expect(result.longestStreak, equals(1));
    });
  });

  group('StudyHeatmapWidget & CustomPainter Tests', () {
    test('Intensity thresholds correctly map minutes to 4 discrete levels', () {
      expect(HeatmapDayEntry.computeIntensity(0), equals(0));
      expect(HeatmapDayEntry.computeIntensity(15), equals(1)); // 1-29m -> 1
      expect(HeatmapDayEntry.computeIntensity(45), equals(2)); // 30-59m -> 2
      expect(HeatmapDayEntry.computeIntensity(90), equals(3)); // 60-119m -> 3
      expect(HeatmapDayEntry.computeIntensity(150), equals(4)); // 120m+ -> 4
    });

    testWidgets('StudyHeatmapWidget renders with CustomPainter and toggles Annual/Monthly view', (tester) async {
      final now = DateTime.now();
      final minutesByDate = {
        DateTime(now.year, now.month, now.day): 45, // level 2
        DateTime(now.year, now.month, now.day - 1): 120, // level 4
      };

      HeatmapViewMode? toggledMode;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: StudyHeatmapWidget(
            minutesByDate: minutesByDate,
            currentStreak: 7,
            onViewModeChanged: (mode) => toggledMode = mode,
          ),
        ),
      ));

      expect(find.text('7 Day Streak'), findsOneWidget);
      expect(find.text('Annual'), findsOneWidget);
      expect(find.text('Monthly'), findsOneWidget);

      // Verify CustomPaint with HeatmapPainter is used
      final customPaintFinder = find.byType(CustomPaint);
      expect(customPaintFinder, findsWidgets);

      // Tap Monthly toggle
      await tester.tap(find.text('Monthly'));
      await tester.pumpAndSettle();

      expect(toggledMode, equals(HeatmapViewMode.monthly));
    });
  });

  group('LeaderboardService & LeaderboardView Tests', () {
    final rawStats = [
      {'userId': 'u1', 'displayName': 'Alice', 'totalSeconds': 15000, 'subjectName': 'Math'},
      {'userId': 'u2', 'displayName': 'Bob', 'totalSeconds': 24000, 'subjectName': 'Physics'},
      {'userId': 'u3', 'displayName': 'Charlie', 'totalSeconds': 18000, 'subjectName': 'Biology'},
    ];

    test('LeaderboardService sorts descending by totalSeconds and assigns sequential ranks', () {
      final service = LeaderboardService();
      final list = service.generateLeaderboard(rawUserStats: rawStats);

      expect(list.length, equals(3));
      expect(list[0].displayName, equals('Bob'));
      expect(list[0].rank, equals(1));
      expect(list[0].totalSeconds, equals(24000));
      expect(list[0].formattedDuration, equals('6h 40m'));

      expect(list[1].displayName, equals('Charlie'));
      expect(list[1].rank, equals(2));

      expect(list[2].displayName, equals('Alice'));
      expect(list[2].rank, equals(3));
    });

    test('Anonymized Mode masks username to Anonymous #Hash and subject to General Study', () {
      final service = LeaderboardService();
      final list = service.generateLeaderboard(
        rawUserStats: rawStats,
        anonymizedMode: true,
      );

      for (final item in list) {
        expect(item.isAnonymous, isTrue);
        expect(item.displayName, startsWith('Anonymous #'));
        expect(item.subjectName, equals('General Study'));
      }
    });

    test('Per-user isAnonymous flag overrides global mode when true', () {
      final statsWithFlag = [
        {'userId': 'u_flag', 'displayName': 'SecretAgent', 'totalSeconds': 5000, 'isAnonymous': true},
      ];
      final service = LeaderboardService();
      final list = service.generateLeaderboard(rawUserStats: statsWithFlag, anonymizedMode: false);

      expect(list.first.isAnonymous, isTrue);
      expect(list.first.displayName, startsWith('Anonymous #'));
    });

    testWidgets('LeaderboardView renders Multi-Tier tabs and handles Anonymized switch', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: LeaderboardView(
            rawUserStats: rawStats,
          ),
        ),
      ));

      expect(find.text('National'), findsOneWidget);
      expect(find.text('Group'), findsOneWidget);
      expect(find.text('Peer'), findsOneWidget);
      expect(find.text('Anonymized Mode'), findsOneWidget);

      // Verify top ranks rendered
      expect(find.text('🥇'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);

      // Toggle Anonymized Mode switch
      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      // Bob should now be masked
      expect(find.text('Bob'), findsNothing);
      expect(find.textContaining('Anonymous #'), findsWidgets);
    });
  });
}
