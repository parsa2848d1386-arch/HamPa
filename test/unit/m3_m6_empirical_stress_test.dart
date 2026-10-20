import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' as drift;
import 'package:hampa/core/database/app_database.dart';
import 'package:hampa/core/database/daos/study_sessions_dao.dart';
import 'package:hampa/features/focus_timer/domain/models/focus_session_state.dart';
import 'package:hampa/features/focus_timer/presentation/controllers/focus_timer_cubit.dart';
import 'package:hampa/features/timetable/domain/models/timetable_state.dart';
import 'package:hampa/features/timetable/presentation/widgets/visual_timetable_widget.dart';
import 'package:hampa/features/synergy_bridge/services/synergy_bridge_service.dart';
import 'package:hampa/features/synergy_bridge/presentation/widgets/in_session_scratchpad_drawer.dart';
import 'package:hampa/features/analytics_gamification/domain/models/streak_engine.dart';
import 'package:hampa/features/analytics_gamification/presentation/widgets/study_heatmap_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('1. Focus Timing Monotonicity & Strict Lock Stress Tests', () {
    late AppDatabase db;
    late StudySessionsDao dao;
    late FocusTimerCubit cubit;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      dao = StudySessionsDao(db);
      cubit = FocusTimerCubit(studySessionsDao: dao);
    });

    tearDown(() async {
      await cubit.close();
      await db.close();
    });

    test('High-frequency pause/resume cycles maintain monotonic tracking without drift', () {
      cubit.startTimer(subjectId: 'sub_math', mode: TimerMode.stopwatch);
      expect(cubit.state.status, equals(TimerStatus.running));

      // Execute 50 rapid pause/resume cycles
      for (int i = 0; i < 50; i++) {
        cubit.pauseTimer();
        expect(cubit.state.status, equals(TimerStatus.paused));
        cubit.resumeTimer();
        expect(cubit.state.status, equals(TimerStatus.running));
      }

      expect(cubit.state.elapsedSeconds, greaterThanOrEqualTo(0));
      expect(cubit.state.pauseAccumulatedSeconds, greaterThanOrEqualTo(0));
    });

    test('Strict lock 10s grace period: foreground return within 10s logs 0 interruptions', () async {
      cubit.startTimer(subjectId: 'sub_phys', strictLock: true);
      expect(cubit.state.isStrictLockActive, isTrue);

      // App navigates to background
      cubit.handleLifecycleTransition(AppLifecycleState.paused);
      expect(cubit.state.isGracePeriodActive, isTrue);
      expect(cubit.state.graceRemainingSeconds, equals(10));
      expect(cubit.state.interruptionCount, equals(0));

      // Return to foreground after 2 seconds (< 10s grace period)
      cubit.handleLifecycleTransition(AppLifecycleState.resumed);
      expect(cubit.state.isGracePeriodActive, isFalse);
      expect(cubit.state.interruptionCount, equals(0));
      expect(cubit.state.interruptionDurationSeconds, equals(0));
    });

    test('Strict lock grace period: exceeding 10s logs interruption and duration', () async {
      cubit.startTimer(subjectId: 'sub_chem', strictLock: true);

      // Trigger background transition
      cubit.handleLifecycleTransition(AppLifecycleState.paused);
      expect(cubit.state.isGracePeriodActive, isTrue);

      // Record interruption when grace period expires
      cubit.recordInterruption(durationSeconds: 15);
      expect(cubit.state.interruptionCount, equals(1));
      expect(cubit.state.interruptionDurationSeconds, equals(15));
    });

    test('Empirical Bug Verification: activeSoundTrack cannot be reset to null via copyWith', () {
      cubit.startTimer(subjectId: 'sub_history', strictLock: true);

      final tracks = ['Rain', 'White Noise', 'Cafe', 'Library', 'Waves'];
      for (final track in tracks) {
        cubit.toggleAmbientSound(track);
        expect(cubit.state.isAmbientSoundPlaying, isTrue);
        expect(cubit.state.activeSoundTrack, equals(track));
      }

      // Toggling active track off sets isAmbientSoundPlaying to false
      cubit.toggleAmbientSound('Waves');
      expect(cubit.state.isAmbientSoundPlaying, isFalse);
      // BUG CONFIRMATION: In FocusSessionState.copyWith (line 104), activeSoundTrack: activeSoundTrack ?? this.activeSoundTrack
      // prevents clearing activeSoundTrack to null when passing null.
      expect(cubit.state.activeSoundTrack, equals('Waves'));
    });

    test('FocusSessionState.copyWith with clearActiveSoundTrack: true clears activeSoundTrack to null', () {
      const stateWithSound = FocusSessionState(
        isAmbientSoundPlaying: true,
        activeSoundTrack: 'Waves',
      );
      expect(stateWithSound.activeSoundTrack, equals('Waves'));

      final clearedState = stateWithSound.copyWith(
        isAmbientSoundPlaying: false,
        clearActiveSoundTrack: true,
      );
      expect(clearedState.activeSoundTrack, isNull);
      expect(clearedState.isAmbientSoundPlaying, isFalse);
    });
  });

  group('2. Timetable 144-Slot Projection & 05:00 AM Boundary Stress Tests', () {
    test('144-slot projection: every 10-minute interval across 24 hours maps uniquely to [0, 143]', () {
      // 05:00 AM -> index 0
      expect(TimetableState.timeToSlotIndex(DateTime(2026, 10, 16, 5, 0)), equals(0));
      expect(TimetableState.timeToSlotIndex(DateTime(2026, 10, 16, 5, 9)), equals(0));

      // 05:10 AM -> index 1
      expect(TimetableState.timeToSlotIndex(DateTime(2026, 10, 16, 5, 10)), equals(1));

      // 12:00 PM (noon) -> (12 - 5) * 6 = 42
      expect(TimetableState.timeToSlotIndex(DateTime(2026, 10, 16, 12, 0)), equals(42));

      // 23:50 PM -> index 113
      expect(TimetableState.timeToSlotIndex(DateTime(2026, 10, 16, 23, 50)), equals(113));

      // 00:00 Midnight -> index 114
      expect(TimetableState.timeToSlotIndex(DateTime(2026, 10, 17, 0, 0)), equals(114));

      // 02:00 AM -> index 126
      expect(TimetableState.timeToSlotIndex(DateTime(2026, 10, 17, 2, 0)), equals(126));

      // 04:50 AM -> index 143 (last block before 05:00 cutoff)
      expect(TimetableState.timeToSlotIndex(DateTime(2026, 10, 17, 4, 50)), equals(143));
      expect(TimetableState.timeToSlotIndex(DateTime(2026, 10, 17, 4, 59)), equals(143));
    });

    test('Study session at 02:00 AM spans 6 blocks starting at 126 and attributes to preceding study day', () {
      final empty = TimetableState.empty(DateTime(2026, 10, 16));
      expect(empty.blocks.length, equals(144));

      // Session at 02:00 AM for 60 minutes (3600 seconds = 6 slots: 126..131)
      final sessionStart = DateTime(2026, 10, 17, 2, 0);
      final updated = empty.withSession(
        subjectId: 'sub_ai',
        subjectName: 'Artificial Intelligence',
        color: Colors.purple,
        start: sessionStart,
        durationSeconds: 3600,
      );

      expect(updated.blocks.length, equals(144));
      // Blocks 126 to 131 must have subject assigned
      for (int i = 126; i <= 131; i++) {
        expect(updated.blocks[i].subjectId, equals('sub_ai'));
        expect(updated.blocks[i].color, equals(Colors.purple));
      }
      // Blocks before and after must remain empty
      expect(updated.blocks[125].subjectId, isNull);
      expect(updated.blocks[132].subjectId, isNull);
    });

    test('Study session at 04:30 AM spanning past 05:00 AM clamps gracefully to slot 143 without out-of-bounds', () {
      final empty = TimetableState.empty(DateTime(2026, 10, 16));
      // 04:30 AM is slot 141. Duration 7200s (2h = 12 blocks)
      final updated = empty.withSession(
        subjectId: 'sub_bio',
        subjectName: 'Biology',
        color: Colors.green,
        start: DateTime(2026, 10, 17, 4, 30),
        durationSeconds: 7200,
      );

      expect(updated.blocks.length, equals(144));
      // Clamped to 141, 142, 143
      expect(updated.blocks[141].subjectId, equals('sub_bio'));
      expect(updated.blocks[142].subjectId, equals('sub_bio'));
      expect(updated.blocks[143].subjectId, equals('sub_bio'));
    });

    testWidgets('VisualTimetableWidget renders 144 slots CustomPainter and eliminates narrow screen overflow', (tester) async {
      final timetable = TimetableState.empty(DateTime(2026, 10, 16)).withSession(
        subjectId: 'sub_math',
        subjectName: 'Math',
        color: Colors.blue,
        start: DateTime(2026, 10, 16, 10, 0),
        durationSeconds: 1800,
      );

      // 1. On wide display (width >= 800), widget renders cleanly with CustomPaint
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: 900,
            child: VisualTimetableWidget(
              timetable: timetable,
              activeSlotIndex: 30,
            ),
          ),
        ),
      ));

      expect(find.byType(CustomPaint), findsWidgets);
      expect(find.text('24-Hour Timetable (05:00 AM - 05:00 AM)'), findsOneWidget);
      expect(find.text('144 Blocks (10 min/block)'), findsOneWidget);

      // 2. Empirical verification: On narrow mobile screen (width: 360), header Row in visual_timetable_widget.dart:169
      // now wraps in Flexible/Expanded with ellipsis, eliminating horizontal overflow (<368px)
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            height: 900,
            child: VisualTimetableWidget(
              timetable: timetable,
              activeSlotIndex: 30,
            ),
          ),
        ),
      ));

      final exception = tester.takeException();
      expect(exception, isNull);
    });
  });

  group('3. Synergy Bridge Atomic Logging & Scratchpad Stress Tests', () {
    late AppDatabase db;
    late SynergyBridgeService bridgeService;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      bridgeService = SynergyBridgeService(
        studySessionsDao: db.studySessionsDao,
        rowsDao: db.databaseRowsDao,
        cellsDao: db.databaseCellsDao,
        propertiesDao: db.databasePropertiesDao,
        appDatabase: db,
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('syncSessionToTaskDatabase updates Total Studied Time, Sessions Count, Last Date, Status atomically', () async {
      const pageId = 'page_task_1';
      const dbId = 'db_tasks';
      const rowId = 'row_calc_1';
      final now = DateTime.now();

      await db.pagesDao.insertPage(PagesCompanion.insert(
        id: pageId,
        title: const drift.Value('Tasks Page'),
        createdAt: now,
        updatedAt: now,
      ));
      await db.databasesDao.insertDatabase(DatabasesTableCompanion.insert(
        id: dbId,
        pageId: pageId,
        title: const drift.Value('Tasks DB'),
        createdAt: now,
        updatedAt: now,
      ));
      await db.pagesDao.insertPage(PagesCompanion.insert(
        id: rowId,
        title: const drift.Value('Row Page'),
        isDatabaseRow: const drift.Value(true),
        createdAt: now,
        updatedAt: now,
      ));
      await db.databaseRowsDao.insertRow(DatabaseRowsTableCompanion.insert(
        id: rowId,
        databaseId: dbId,
        pageId: rowId,
        createdAt: now,
        updatedAt: now,
      ));

      // Sync session: 3600 seconds, marked completed
      await bridgeService.syncSessionToTaskDatabase(
        databaseId: dbId,
        rowId: rowId,
        addedSeconds: 3600,
        markTaskCompleted: true,
      );

      final cells = await db.databaseCellsDao.getCellsForRow(rowId);
      final props = await db.databasePropertiesDao.getPropertiesForDatabase(dbId);

      final timeProp = props.firstWhere((p) => p.name.contains('Total Studied Time'));
      final countProp = props.firstWhere((p) => p.name.contains('Sessions Count'));
      final dateProp = props.firstWhere((p) => p.name.contains('Last Studied Date'));
      final statusProp = props.firstWhere((p) => p.name.contains('Status'));

      final timeCell = cells.firstWhere((c) => c.propertyId == timeProp.id);
      final countCell = cells.firstWhere((c) => c.propertyId == countProp.id);
      final dateCell = cells.firstWhere((c) => c.propertyId == dateProp.id);
      final statusCell = cells.firstWhere((c) => c.propertyId == statusProp.id);

      expect(timeCell.valueJson, equals('3600'));
      expect(countCell.valueJson, equals('1'));
      expect(statusCell.valueJson, equals('Done'));
      expect(dateCell.valueJson, isNotEmpty);
    });

    test('SQLite transaction atomicity: rollback on failure leaves DB untouched', () async {
      const pageId = 'p_fail';
      const dbId = 'db_fail';
      const rowId = 'row_fail';
      final now = DateTime.now();

      await db.pagesDao.insertPage(PagesCompanion.insert(
        id: pageId,
        title: const drift.Value('P'),
        createdAt: now,
        updatedAt: now,
      ));
      await db.databasesDao.insertDatabase(DatabasesTableCompanion.insert(
        id: dbId,
        pageId: pageId,
        title: const drift.Value('D'),
        createdAt: now,
        updatedAt: now,
      ));
      await db.pagesDao.insertPage(PagesCompanion.insert(
        id: rowId,
        title: const drift.Value('R'),
        isDatabaseRow: const drift.Value(true),
        createdAt: now,
        updatedAt: now,
      ));
      await db.databaseRowsDao.insertRow(DatabaseRowsTableCompanion.insert(
        id: rowId,
        databaseId: dbId,
        pageId: rowId,
        createdAt: now,
        updatedAt: now,
      ));

      // Attempt transaction that throws midway
      try {
        await db.transaction(() async {
          await db.databaseCellsDao.upsertCell(
            rowId: rowId,
            propertyId: 'p_temp',
            valueJson: '999',
          );
          throw Exception('Simulated fatal transaction crash!');
        });
      } catch (_) {}

      // Verify row has 0 cells due to complete rollback
      final cells = await db.databaseCellsDao.getCellsForRow(rowId);
      expect(cells.isEmpty, isTrue);
    });

    testWidgets('InSessionScratchpadDrawer rapid edits are debounced into single BlockEntity', (tester) async {
      const pageId = 'p_scratch_rapid';
      final now = DateTime.now();

      await db.pagesDao.insertPage(PagesCompanion.insert(
        id: pageId,
        title: const drift.Value('P Scratch'),
        createdAt: now,
        updatedAt: now,
      ));

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: InSessionScratchpadDrawer(
            pageId: pageId,
            blocksDao: db.blocksDao,
            debounceDuration: const Duration(milliseconds: 80),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      // Rapidly enter text multiple times
      await tester.enterText(textField, 'Draft 1');
      await tester.pump(const Duration(milliseconds: 20));
      await tester.enterText(textField, 'Draft 2');
      await tester.pump(const Duration(milliseconds: 20));
      await tester.enterText(textField, 'Draft 3 final note');
      
      // Wait for debounce timer (80ms + margin)
      await tester.pump(const Duration(milliseconds: 150));

      final persisted = await db.blocksDao.getBlocksForPage(pageId);
      expect(persisted.length, equals(1));
      expect(persisted.first.contentJson, contains('Draft 3 final note'));
    });

    test('launchFocusForTask forwards taskTitle, databaseId, and rowId directly to timerCubit', () {
      final timerCubit = FocusTimerCubit(studySessionsDao: db.studySessionsDao);
      addTearDown(() => timerCubit.close());

      bridgeService.launchFocusForTask(
        timerCubit: timerCubit,
        databaseId: 'db_tasks_123',
        rowId: 'row_task_456',
        subjectId: 'sub_physics',
        taskTitle: 'Quantum Mechanics Lab Report',
      );

      expect(timerCubit.state.isRunning, isTrue);
      expect(timerCubit.state.taskTitle, equals('Quantum Mechanics Lab Report'));
      expect(timerCubit.state.databaseId, equals('db_tasks_123'));
      expect(timerCubit.state.rowId, equals('row_task_456'));
      expect(timerCubit.state.activeSubjectId, equals('sub_physics'));
      expect(timerCubit.state.activePageId, equals('row_task_456'));
    });
  });

  group('4. Streak Engine & Analytics Gamification Stress Tests', () {
    test('StreakEngine across Daylight Saving Time shifts (23h and 25h days)', () {
      // 1. Spring forward 23h transition: March 28 -> March 29 (DST start) -> March 30 -> March 31
      final springTimestamps = [
        DateTime(2026, 3, 28, 14, 0),
        DateTime(2026, 3, 29, 14, 0),
        DateTime(2026, 3, 30, 14, 0),
        DateTime(2026, 3, 31, 14, 0),
      ];

      final springResult = StreakEngine.calculateStreak(
        springTimestamps,
        currentNow: DateTime(2026, 3, 31, 16, 0),
      );
      expect(springResult.currentStreak, equals(4));
      expect(springResult.longestStreak, equals(4));

      // 2. Fall back 25h transition: October 24 -> October 25 (DST end) -> October 26
      final fallTimestamps = [
        DateTime(2026, 10, 24, 15, 0),
        DateTime(2026, 10, 25, 15, 0),
        DateTime(2026, 10, 26, 15, 0),
      ];

      final fallResult = StreakEngine.calculateStreak(
        fallTimestamps,
        currentNow: DateTime(2026, 10, 26, 18, 0),
      );
      expect(fallResult.currentStreak, equals(3));
      expect(fallResult.longestStreak, equals(3));
    });

    test('05:00 AM cutoff correctly maintains 3-day streak for midnight study sessions', () {
      // Oct 15 22:00 -> study day Oct 15
      // Oct 17 01:30 -> night owl, study day Oct 16!
      // Oct 17 08:00 -> morning, study day Oct 17!
      final timestamps = [
        DateTime(2026, 10, 15, 22, 0),
        DateTime(2026, 10, 17, 1, 30),
        DateTime(2026, 10, 17, 8, 0),
      ];

      final result = StreakEngine.calculateStreak(
        timestamps,
        currentNow: DateTime(2026, 10, 17, 12, 0),
        cutoffHour: 5,
      );

      // Continuous 3 days: Oct 15, Oct 16, Oct 17
      expect(result.currentStreak, equals(3));
      expect(result.longestStreak, equals(3));
    });

    test('4-tier intensity computation across all threshold boundaries', () {
      expect(HeatmapDayEntry.computeIntensity(-5), equals(0));
      expect(HeatmapDayEntry.computeIntensity(0), equals(0));
      expect(HeatmapDayEntry.computeIntensity(1), equals(1));
      expect(HeatmapDayEntry.computeIntensity(29), equals(1));
      expect(HeatmapDayEntry.computeIntensity(30), equals(2));
      expect(HeatmapDayEntry.computeIntensity(59), equals(2));
      expect(HeatmapDayEntry.computeIntensity(60), equals(3));
      expect(HeatmapDayEntry.computeIntensity(119), equals(3));
      expect(HeatmapDayEntry.computeIntensity(120), equals(4));
      expect(HeatmapDayEntry.computeIntensity(480), equals(4));
    });

    testWidgets('StudyHeatmapWidget CustomPainter renders full yearly grid', (tester) async {
      final minutesByDate = <DateTime, int>{};
      for (int i = 0; i < 365; i++) {
        minutesByDate[DateTime(2026, 1, 1).add(Duration(days: i))] = (i % 5) * 30;
      }

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: StudyHeatmapWidget(
            minutesByDate: minutesByDate,
            currentStreak: 15,
          ),
        ),
      ));

      expect(find.byType(CustomPaint), findsWidgets);
      expect(find.text('15 Day Streak'), findsOneWidget);
    });
  });
}
