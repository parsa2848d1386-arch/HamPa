import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' as drift;
import 'package:hampa/core/database/app_database.dart';
import 'package:hampa/features/focus_timer/domain/models/focus_session_state.dart';
import 'package:hampa/features/focus_timer/presentation/controllers/focus_timer_cubit.dart';
import 'package:hampa/features/synergy_bridge/domain/models/dday_entity.dart';
import 'package:hampa/features/synergy_bridge/presentation/widgets/dday_countdown_widget.dart';
import 'package:hampa/features/synergy_bridge/presentation/widgets/in_session_scratchpad_drawer.dart';
import 'package:hampa/features/synergy_bridge/services/synergy_bridge_service.dart';

void main() {
  late AppDatabase db;
  late SynergyBridgeService bridgeService;
  late FocusTimerCubit timerCubit;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    bridgeService = SynergyBridgeService(
      studySessionsDao: db.studySessionsDao,
      rowsDao: db.databaseRowsDao,
      cellsDao: db.databaseCellsDao,
      propertiesDao: db.databasePropertiesDao,
      appDatabase: db,
    );
    timerCubit = FocusTimerCubit(studySessionsDao: db.studySessionsDao);
  });

  tearDown(() async {
    await timerCubit.close();
    await db.close();
  });

  Future<void> seedDatabaseHierarchy({
    required String pageId,
    required String databaseId,
    required String rowId,
  }) async {
    final now = DateTime.now();
    await db.pagesDao.insertPage(PagesCompanion.insert(
      id: pageId,
      title: const drift.Value('Tasks Page'),
      createdAt: now,
      updatedAt: now,
    ));

    await db.databasesDao.insertDatabase(DatabasesTableCompanion.insert(
      id: databaseId,
      pageId: pageId,
      title: const drift.Value('Test Task Database'),
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
      databaseId: databaseId,
      pageId: rowId,
      createdAt: now,
      updatedAt: now,
    ));
  }

  group('SynergyBridgeService Focus Launch & Context Tracking', () {
    test('launchFocusForTask passes parameters, starts timer, and preserves context', () async {
      bridgeService.launchFocusForTask(
        timerCubit: timerCubit,
        databaseId: 'db_42',
        rowId: 'row_101',
        subjectId: 'sub_math',
        taskTitle: 'Calculus Ch 3 Homework',
        mode: TimerMode.pomodoro,
        targetSeconds: 1500,
      );

      expect(timerCubit.state.isRunning, isTrue);
      expect(timerCubit.state.activeSubjectId, equals('sub_math'));
      expect(timerCubit.state.activePageId, equals('row_101'));
      expect(timerCubit.state.mode, equals(TimerMode.pomodoro));
      expect(timerCubit.state.targetSeconds, equals(1500));

      expect(bridgeService.activeTaskTitle, equals('Calculus Ch 3 Homework'));
      expect(bridgeService.activeDatabaseId, equals('db_42'));
      expect(bridgeService.activeRowId, equals('row_101'));
      expect(bridgeService.activeSubjectId, equals('sub_math'));
    });
  });

  group('SynergyBridgeService Atomic Session Auto-Logging', () {
    test('syncSessionToTaskDatabase updates Total Studied Time, Sessions Count, Last Date, and Status atomically', () async {
      const pageId = 'p_test';
      const dbId = 'db_study';
      const rowId = 'row_math_1';

      await seedDatabaseHierarchy(pageId: pageId, databaseId: dbId, rowId: rowId);

      // 1. First study session: 1800 seconds (30m), not marked completed
      await bridgeService.syncSessionToTaskDatabase(
        databaseId: dbId,
        rowId: rowId,
        addedSeconds: 1800,
        markTaskCompleted: false,
      );

      final cells1 = await db.databaseCellsDao.getCellsForRow(rowId);
      final props1 = await db.databasePropertiesDao.getPropertiesForDatabase(dbId);

      final timeProp1 = props1.firstWhere((p) => p.name.contains('Total Studied Time'));
      final countProp1 = props1.firstWhere((p) => p.name.contains('Sessions Count'));
      final dateProp1 = props1.firstWhere((p) => p.name.contains('Last Studied Date'));

      final timeCell1 = cells1.firstWhere((c) => c.propertyId == timeProp1.id);
      final countCell1 = cells1.firstWhere((c) => c.propertyId == countProp1.id);
      final dateCell1 = cells1.firstWhere((c) => c.propertyId == dateProp1.id);

      expect(timeCell1.valueJson, equals('1800'));
      expect(countCell1.valueJson, equals('1'));

      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      expect(dateCell1.valueJson, equals(todayStr));

      // 2. Sequential session: 1200 seconds (20m), marked completed
      await bridgeService.syncSessionToTaskDatabase(
        databaseId: dbId,
        rowId: rowId,
        addedSeconds: 1200,
        markTaskCompleted: true,
      );

      final cells2 = await db.databaseCellsDao.getCellsForRow(rowId);
      final props2 = await db.databasePropertiesDao.getPropertiesForDatabase(dbId);

      final statusProp = props2.firstWhere((p) => p.name.contains('Status'));
      final timeCell2 = cells2.firstWhere((c) => c.propertyId == timeProp1.id);
      final countCell2 = cells2.firstWhere((c) => c.propertyId == countProp1.id);
      final statusCell = cells2.firstWhere((c) => c.propertyId == statusProp.id);

      expect(timeCell2.valueJson, equals('3000')); // 1800 + 1200 accumulated
      expect(countCell2.valueJson, equals('2'));    // 1 + 1 incremented
      expect(statusCell.valueJson, equals('Done')); // Status updated to Done
    });
  });

  group('SynergyBridgeService Syllabus Progress Calculation', () {
    test('calculateSyllabusProgress returns 100.0 for empty database', () async {
      const pageId = 'p_empty';
      const dbId = 'db_empty';
      final now = DateTime.now();

      await db.pagesDao.insertPage(PagesCompanion.insert(
        id: pageId,
        title: const drift.Value('Empty Page'),
        createdAt: now,
        updatedAt: now,
      ));
      await db.databasesDao.insertDatabase(DatabasesTableCompanion.insert(
        id: dbId,
        pageId: pageId,
        title: const drift.Value('Empty DB'),
        createdAt: now,
        updatedAt: now,
      ));

      final progress = await bridgeService.calculateSyllabusProgress(dbId);
      expect(progress, equals(100.0));
    });

    test('calculateSyllabusProgress calculates percentage of completed tasks', () async {
      const pageId = 'p_syll';
      const dbId = 'db_syll';
      const row1 = 'row_s1';
      const row2 = 'row_s2';
      const row3 = 'row_s3';
      const row4 = 'row_s4';

      final now = DateTime.now();
      await db.pagesDao.insertPage(PagesCompanion.insert(
        id: pageId,
        title: const drift.Value('Syllabus Page'),
        createdAt: now,
        updatedAt: now,
      ));
      await db.databasesDao.insertDatabase(DatabasesTableCompanion.insert(
        id: dbId,
        pageId: pageId,
        title: const drift.Value('Syllabus DB'),
        createdAt: now,
        updatedAt: now,
      ));

      const statusPropId = 'prop_status';
      await db.databasePropertiesDao.insertProperty(DatabasePropertiesTableCompanion.insert(
        id: statusPropId,
        databaseId: dbId,
        name: 'Status',
        propertyType: 'status',
        createdAt: now,
        updatedAt: now,
      ));

      for (final r in [row1, row2, row3, row4]) {
        await db.pagesDao.insertPage(PagesCompanion.insert(
          id: r,
          title: drift.Value('Row $r Page'),
          isDatabaseRow: const drift.Value(true),
          createdAt: now,
          updatedAt: now,
        ));
        await db.databaseRowsDao.insertRow(DatabaseRowsTableCompanion.insert(
          id: r,
          databaseId: dbId,
          pageId: r,
          createdAt: now,
          updatedAt: now,
        ));
      }

      // Mark row1 and row2 as Done (2 out of 4 = 50%)
      await db.databaseCellsDao.upsertCell(rowId: row1, propertyId: statusPropId, valueJson: 'Done');
      await db.databaseCellsDao.upsertCell(rowId: row2, propertyId: statusPropId, valueJson: 'Done');
      await db.databaseCellsDao.upsertCell(rowId: row3, propertyId: statusPropId, valueJson: 'In Progress');
      await db.databaseCellsDao.upsertCell(rowId: row4, propertyId: statusPropId, valueJson: 'To Do');

      final progress50 = await bridgeService.calculateSyllabusProgress(dbId);
      expect(progress50, equals(50.0));

      // Mark row3 as completed (3 out of 4 = 75%)
      await db.databaseCellsDao.upsertCell(rowId: row3, propertyId: statusPropId, valueJson: 'completed');
      final progress75 = await bridgeService.calculateSyllabusProgress(dbId);
      expect(progress75, equals(75.0));
    });
  });

  group('DDayEntity & DDayCountdownWidget', () {
    test('DDayEntity computes daysRemaining and formatDDay correctly', () async {
      final now = DateTime(2026, 10, 16);

      // Future milestone: +45 days
      final futureDDay = DDayEntity(
        id: 'd1',
        title: 'Entrance Exam',
        targetDate: DateTime(2026, 11, 30),
      );
      expect(futureDDay.daysRemaining(referenceDate: now), equals(45));
      expect(futureDDay.formatDDay(referenceDate: now), equals('D-45'));

      // Same day milestone
      final todayDDay = DDayEntity(
        id: 'd2',
        title: 'Exam Today',
        targetDate: DateTime(2026, 10, 16),
      );
      expect(todayDDay.daysRemaining(referenceDate: now), equals(0));
      expect(todayDDay.formatDDay(referenceDate: now), equals('D-Day'));

      // Past milestone: -7 days
      final pastDDay = DDayEntity(
        id: 'd3',
        title: 'Past Exam',
        targetDate: DateTime(2026, 10, 9),
      );
      expect(pastDDay.daysRemaining(referenceDate: now), equals(-7));
      expect(pastDDay.formatDDay(referenceDate: now), equals('D+7'));
    });

    testWidgets('DDayCountdownWidget renders badge, title and progress bar', (tester) async {
      final dday = DDayEntity(
        id: 'd_widget',
        title: 'Bar Exam',
        targetDate: DateTime.now().add(const Duration(days: 30)),
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: DDayCountdownWidget(
            dday: dday,
            syllabusProgress: 65.5,
          ),
        ),
      ));

      expect(find.text('Bar Exam'), findsOneWidget);
      expect(find.text('D-30'), findsOneWidget);
      expect(find.text('65.5%'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });
  });

  group('InSessionScratchpadDrawer SQLite Debounced Persistence', () {
    testWidgets('InSessionScratchpadDrawer loads existing blocks and flushes buffer to SQLite', (tester) async {
      const pageId = 'scratchpad_page_1';
      final now = DateTime.now();

      await db.pagesDao.insertPage(PagesCompanion.insert(
        id: pageId,
        title: const drift.Value('Linked Task Page'),
        createdAt: now,
        updatedAt: now,
      ));

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: InSessionScratchpadDrawer(
            pageId: pageId,
            blocksDao: db.blocksDao,
            debounceDuration: const Duration(milliseconds: 100),
          ),
        ),
      ));

      await tester.pumpAndSettle();

      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      await tester.enterText(textField, 'Formula to remember: E = mc^2');
      // Wait for debounce flush
      await tester.pump(const Duration(milliseconds: 200));

      final persistedBlocks = await db.blocksDao.getBlocksForPage(pageId);
      expect(persistedBlocks.length, equals(1));
      expect(persistedBlocks.first.contentJson, contains('Formula to remember: E = mc^2'));
      expect(persistedBlocks.first.blockType, equals('text'));
    });
  });
}
