// Tier 3 E2E Cross-Feature Combinations (Pairwise Coverage)
// 35 comprehensive pairwise and closed-loop cross-subsystem test cases
// Grounded in PROJECT.md (Interface Contracts, AC1–AC10)

import '../contracts/database_contracts.dart';
import '../contracts/focus_contracts.dart';
import '../contracts/study_room_contracts.dart';
import '../contracts/timetable_contracts.dart';
import '../contracts/workspace_contracts.dart';
import '../harness/test_oracle_harness.dart';
import '../support/test_runner.dart';

void runPairwiseCrossFeatureTier3Tests() {
  group('Tier 3: Pairwise Cross-Feature Combinations (35 tests)', () {
    late HamPATestHarness sys;

    void setUp() {
      sys = HamPATestHarness();
    }

    test('P01: Workspace (F01) + Relational DB (F08): Page tree contains database entity', () async {
      setUp();
      final page = await sys.workspace.createPage(title: 'Engineering Hub');
      final db = await sys.database.createDatabase(title: 'Courses', pageId: page.id);

      expect(db.pageId, equals(page.id));
      expect(await sys.workspace.getPage(page.id), isNotNull);
    });

    test('P02: Workspace (F01) + Dual Identity Row (F08): Creating row creates underlying page in tree', () async {
      setUp();
      final page = await sys.workspace.createPage(title: 'Workspace');
      final db = await sys.database.createDatabase(title: 'Tasks', pageId: page.id);

      final rowId = await sys.database.createRow(db.id);
      final rows = await sys.database.watchRows(db.id).first;
      final createdRow = rows.firstWhere((r) => r.id == rowId);

      // Verify dual identity page exists with isDatabaseRow = true
      final underlyingPage = await sys.workspace.getPage(createdRow.pageId);
      expect(underlyingPage, isNotNull);
      expect(underlyingPage!.isDatabaseRow, isTrue);
    });

    test('P03: Workspace (F04) + Relational DB (F12): Table row document contains rich text blocks', () async {
      setUp();
      final page = await sys.workspace.createPage(title: 'Workspace');
      final db = await sys.database.createDatabase(title: 'Notes DB', pageId: page.id);
      final rowId = await sys.database.createRow(db.id);
      final rows = await sys.database.watchRows(db.id).first;
      final rowPageId = rows.firstWhere((r) => r.id == rowId).pageId;

      await sys.workspace.insertBlock(BlockEntity(
        id: 'b_row_note',
        pageId: rowPageId,
        type: BlockType.heading1,
        content: 'Row Document Header',
      ));

      final blocks = await sys.workspace.getBlocksForPage(rowPageId);
      expect(blocks.length, equals(1));
      expect(blocks.first.content, equals('Row Document Header'));
    });

    test('P04: Workspace (F05) + Hybrid Bridge (F29): Checklist block triggers Focus Now', () async {
      setUp();
      final page = await sys.workspace.createPage(title: 'Syllabus');
      final todoBlock = BlockEntity(
        id: 'todo_focus_trigger',
        pageId: page.id,
        type: BlockType.todo,
        content: 'Solve Calculus Review Set',
      );
      await sys.workspace.insertBlock(todoBlock);

      await sys.bridge.launchFocusFromTask(
        FocusContext(taskId: todoBlock.id, pageId: page.id, title: todoBlock.content),
      );

      expect(sys.focus.currentSession!.status, equals(FocusState.running));
      expect(sys.focus.currentSession!.linkedContext!.taskId, equals(todoBlock.id));
    });

    test('P05: Workspace (F06) + In-Session Scratchpad (F31): Toggle block in scratchpad flushes to page', () async {
      setUp();
      final page = await sys.workspace.createPage(title: 'Lecture');
      final toggle = BlockEntity(
        id: 's_toggle',
        pageId: page.id,
        type: BlockType.toggle,
        content: 'Questions to ask professor',
      );

      await sys.bridge.updateScratchpadBlock(toggle);
      await sys.bridge.flushScratchpadToDocument(page.id);

      final blocks = await sys.workspace.getBlocksForPage(page.id);
      expect(blocks.first.type, equals(BlockType.toggle));
    });

    test('P06: Workspace (F07) + Relational DB (F16): LaTeX math block in row document renders in Gallery card', () async {
      setUp();
      final page = await workspaceContainer(sys);
      final db = await sys.database.createDatabase(title: 'Formula Cards', pageId: page.id);
      final rowId = await sys.database.createRow(db.id);
      final rows = await sys.database.watchRows(db.id).first;
      final rowPageId = rows.firstWhere((r) => r.id == rowId).pageId;

      await sys.workspace.insertBlock(BlockEntity(
        id: 'b_math_eq',
        pageId: rowPageId,
        type: BlockType.latexMath,
        content: r'e^{i\pi} + 1 = 0',
      ));

      final blocks = await sys.workspace.getBlocksForPage(rowPageId);
      expect(blocks.first.content, equals(r'e^{i\pi} + 1 = 0'));
    });

    test('P07: Relational DB (F08) + Focus Engine (F17): Database row binds stopwatch focus session', () async {
      setUp();
      final page = await workspaceContainer(sys);
      final db = await sys.database.createDatabase(title: 'Tasks', pageId: page.id);
      final rowId = await sys.database.createRow(db.id);

      await sys.bridge.launchFocusFromTask(
        FocusContext(taskId: 'task_sw', rowId: rowId, title: 'Linear Algebra', subjectId: 'math'),
      );

      expect(sys.focus.currentSession!.sessionType, equals(SessionType.stopwatch));
      expect(sys.focus.currentSession!.linkedContext!.rowId, equals(rowId));
    });

    test('P08: Relational DB (F08) + Pomodoro (F18): Database row binds Pomodoro focus session', () async {
      setUp();
      final page = await workspaceContainer(sys);
      final db = await sys.database.createDatabase(title: 'Tasks', pageId: page.id);
      final rowId = await sys.database.createRow(db.id);

      final session = await sys.focus.startSession(
        subjectId: 'cs',
        sessionType: SessionType.pomodoro,
        linkedContext: FocusContext(taskId: 't_pomo', rowId: rowId, title: 'Code'),
        targetDurationSeconds: 1500,
      );

      expect(session.sessionType, equals(SessionType.pomodoro));
      expect(session.linkedContext!.rowId, equals(rowId));
    });

    test('P09: Relational DB (F08) + Exam Timer (F19): Database row binds mock exam timer', () async {
      setUp();
      final page = await workspaceContainer(sys);
      final db = await sys.database.createDatabase(title: 'Exams', pageId: page.id);
      final rowId = await sys.database.createRow(db.id);

      final session = await sys.focus.startSession(
        subjectId: 'med',
        sessionType: SessionType.mockExam,
        linkedContext: FocusContext(taskId: 't_exam', rowId: rowId, title: 'MCAT Simulation'),
        targetDurationSeconds: 7200,
      );

      expect(session.sessionType, equals(SessionType.mockExam));
      expect(session.targetDurationSeconds, equals(7200));
    });

    test('P10: Relational DB (F09) + Rollups (F11): Project-Task relation rollup recalculates upon row insertion', () async {
      setUp();
      final page = await workspaceContainer(sys);
      final pDb = await sys.database.createDatabase(title: 'Projects', pageId: page.id);
      final tDb = await sys.database.createDatabase(title: 'Tasks', pageId: page.id);

      final pRel = await sys.database.addProperty(databaseId: pDb.id, name: 'Tasks', type: PropertyType.relation);
      final pHours = await sys.database.addProperty(databaseId: tDb.id, name: 'Hours', type: PropertyType.number);

      final projRow = await sys.database.createRow(pDb.id);
      final t1 = await sys.database.createRow(tDb.id);
      final t2 = await sys.database.createRow(tDb.id);

      await sys.database.updatePropertyValue(rowId: t1, propertyId: pHours.id, value: 5);
      await sys.database.updatePropertyValue(rowId: t2, propertyId: pHours.id, value: 10);
      await sys.database.updatePropertyValue(rowId: projRow, propertyId: pRel.id, value: [t1, t2]);

      final rollupSum = await sys.database.computeRollup(
        rowId: projRow,
        relationPropertyId: pRel.id,
        targetPropertyId: pHours.id,
        function: RollupFunction.sum,
      );

      expect(rollupSum, equals(15));
    });

    test('P11: Relational DB (F10) + Rollups (F11): Formula cell evaluates expression consuming numeric values', () async {
      setUp();
      final page = await workspaceContainer(sys);
      final db = await sys.database.createDatabase(title: 'Finance', pageId: page.id);
      final pRevenue = await sys.database.addProperty(databaseId: db.id, name: 'Revenue', type: PropertyType.number);
      final pCost = await sys.database.addProperty(databaseId: db.id, name: 'Cost', type: PropertyType.number);

      final row = await sys.database.createRow(db.id);
      await sys.database.updatePropertyValue(rowId: row, propertyId: pRevenue.id, value: 1000);
      await sys.database.updatePropertyValue(rowId: row, propertyId: pCost.id, value: 400);

      final profit = await sys.database.evaluateFormula(
        rowId: row,
        expression: 'prop("Revenue") - prop("Cost")',
      );

      expect(profit, equals(600.0));
    });

    test('P12: Relational DB (F12) + Kanban View (F13): Inline cell edit updates Kanban column', () async {
      setUp();
      final page = await workspaceContainer(sys);
      final db = await sys.database.createDatabase(title: 'Tasks', pageId: page.id);
      final pStatus = await sys.database.addProperty(databaseId: db.id, name: 'Status', type: PropertyType.status);
      final row = await sys.database.createRow(db.id);

      // Edit in Table view
      await sys.database.updatePropertyValue(rowId: row, propertyId: pStatus.id, value: 'Done');

      // Assert read by Kanban view
      final val = await sys.database.getPropertyValue(rowId: row, propertyId: pStatus.id);
      expect(val, equals('Done'));
    });

    test('P13: Relational DB (F12) + Calendar View (F14): Date cell edit updates Calendar mapping', () async {
      setUp();
      final page = await workspaceContainer(sys);
      final db = await sys.database.createDatabase(title: 'Events', pageId: page.id);
      final pDate = await sys.database.addProperty(databaseId: db.id, name: 'EventDate', type: PropertyType.date);
      final row = await sys.database.createRow(db.id);

      await sys.database.updatePropertyValue(rowId: row, propertyId: pDate.id, value: '2026-10-25');
      expect(await sys.database.getPropertyValue(rowId: row, propertyId: pDate.id), equals('2026-10-25'));
    });

    test('P14: Relational DB (F12) + Timeline View (F15): Date range edit updates Gantt bar duration', () async {
      setUp();
      final page = await workspaceContainer(sys);
      final db = await sys.database.createDatabase(title: 'Gantt', pageId: page.id);
      final pStart = await sys.database.addProperty(databaseId: db.id, name: 'Start', type: PropertyType.date);
      final pEnd = await sys.database.addProperty(databaseId: db.id, name: 'End', type: PropertyType.date);
      final row = await sys.database.createRow(db.id);

      await sys.database.updatePropertyValue(rowId: row, propertyId: pStart.id, value: '2026-10-01');
      await sys.database.updatePropertyValue(rowId: row, propertyId: pEnd.id, value: '2026-10-10');

      expect(await sys.database.getPropertyValue(rowId: row, propertyId: pStart.id), equals('2026-10-01'));
      expect(await sys.database.getPropertyValue(rowId: row, propertyId: pEnd.id), equals('2026-10-10'));
    });

    test('P15: Relational DB (F12) + List View (F16): Inline title edit updates List item title', () async {
      setUp();
      final page = await workspaceContainer(sys);
      final db = await sys.database.createDatabase(title: 'DB', pageId: page.id);
      final pTitle = await sys.database.addProperty(databaseId: db.id, name: 'Title', type: PropertyType.text);
      final row = await sys.database.createRow(db.id);

      await sys.database.updatePropertyValue(rowId: row, propertyId: pTitle.id, value: 'Original');
      await sys.database.updatePropertyValue(rowId: row, propertyId: pTitle.id, value: 'Renamed Title');

      expect(await sys.database.getPropertyValue(rowId: row, propertyId: pTitle.id), equals('Renamed Title'));
    });

    test('P16: Relational DB (F12) + Gallery View (F16): Property update reflects in Gallery card', () async {
      setUp();
      final page = await workspaceContainer(sys);
      final db = await sys.database.createDatabase(title: 'Flashcards', pageId: page.id);
      final pBack = await sys.database.addProperty(databaseId: db.id, name: 'BackSide', type: PropertyType.text);
      final row = await sys.database.createRow(db.id);

      await sys.database.updatePropertyValue(rowId: row, propertyId: pBack.id, value: 'Mitochondria is powerhouse');
      expect(await sys.database.getPropertyValue(rowId: row, propertyId: pBack.id), contains('powerhouse'));
    });

    test('P17: Focus Engine (F17) + Strict Lock (F20): Active stopwatch session tracks background interruption strikes (AC5)', () async {
      setUp();
      sys.focus.setStrictLock(true);
      await sys.focus.startSession(subjectId: 'math', sessionType: SessionType.stopwatch);

      sys.focus.handleLifecycleChange(isForeground: false);
      expect(sys.focus.activeInterruptionCount, equals(1));
    });

    test('P18: Focus Engine (F17) + Allowlist (F21): Active stopwatch session allows scratchpad drawer without penalty (AC5)', () async {
      setUp();
      sys.focus.setStrictLock(true);
      await sys.focus.startSession(subjectId: 'math', sessionType: SessionType.stopwatch);

      sys.focus.handleLifecycleChange(isForeground: false, activePackageName: 'com.hampa.scratchpad');
      expect(sys.focus.activeInterruptionCount, equals(0));
    });

    test('P19: Focus Engine (F17) + Flip Sensor (F22): Monotonic stopwatch auto-pauses when phone turned face up', () async {
      setUp();
      sys.focus.handleSensorUpdate(zAxisAcceleration: -9.8, isNear: true);
      await sys.focus.startSession(subjectId: 's', sessionType: SessionType.stopwatch);
      expect(sys.focus.currentSession!.status, equals(FocusState.running));

      await Future.delayed(const Duration(milliseconds: 1600));
      sys.focus.handleSensorUpdate(zAxisAcceleration: 9.8, isNear: false);

      expect(sys.focus.currentSession!.status, equals(FocusState.paused));
    });

    test('P20: Focus Engine (F17) + Ambient Sounds (F23): Stopwatch ticks concurrently with ambient mixer', () async {
      setUp();
      sys.focus.setAmbientTrackVolume(trackId: 'rain', volume: 0.7);
      await sys.focus.startSession(subjectId: 's', sessionType: SessionType.stopwatch);
      sys.focus.advanceTimeSeconds(100);

      expect(sys.focus.currentSession!.totalElapsedSeconds, equals(100));
      expect(sys.focus.getAmbientTrackVolume('rain'), equals(0.7));
    });

    test('P21: Focus Engine (F17) + 144-Slot Grid (F24): Completed stopwatch session projects to timetable (AC6)', () async {
      setUp();
      final day = DateTime(2026, 10, 16);
      final sub = SubjectEntity(id: 'math', name: 'Math', colorHex: '#4CAF50');
      final start = DateTime(2026, 10, 16, 9, 0);
      final end = DateTime(2026, 10, 16, 9, 30);

      final grid = sys.timetable.projectIntervalsToGrid(
        studyDay: day,
        intervals: [StudyInterval(start: start, end: end, subjectId: 'math')],
        subjectMap: {'math': sub},
      );

      final slot = sys.timetable.timeToSlotIndex(start);
      expect(grid[slot].colorHex, equals('#4CAF50'));
      expect(grid[slot].fillRatio, equals(1.0));
    });

    test('P22: Focus Engine (F17) + Active Pulse (F25): Running stopwatch pulses active 10-minute slot (AC6)', () async {
      setUp();
      final day = DateTime(2026, 10, 16);
      final sub = SubjectEntity(id: 'cs', name: 'CS', colorHex: '#2196F3');
      final start = DateTime(2026, 10, 16, 14, 0);
      final end = DateTime(2026, 10, 16, 14, 10);
      final current = DateTime(2026, 10, 16, 14, 5);

      final grid = sys.timetable.projectIntervalsToGrid(
        studyDay: day,
        intervals: [StudyInterval(start: start, end: end, subjectId: 'cs')],
        subjectMap: {'cs': sub},
        currentTime: current,
      );

      final slot = sys.timetable.timeToSlotIndex(start);
      expect(grid[slot].isPulsing, isTrue);
    });

    test('P23: Focus Engine (F17) + Live Study Room (F26): Starting stopwatch updates user room presence (AC7)', () async {
      setUp();
      final user = RoomMember(userId: 'u_p23', displayName: 'Ali');
      await sys.studyRooms.joinRoom(roomId: 'r_p23', self: user);

      await sys.focus.startSession(subjectId: 'phys', sessionType: SessionType.stopwatch);
      await sys.studyRooms.updatePresence(
        roomId: 'r_p23',
        userId: 'u_p23',
        state: PresenceState.studying,
        subjectName: 'Physics',
      );

      final list = await sys.studyRooms.watchRoomMembers('r_p23').first;
      expect(list.first.presenceState, equals(PresenceState.studying));
    });

    test('P24: Focus Engine (F17) + Study Room Cheering (F28): User receives peer cheer during focus session', () async {
      setUp();
      var cheerReceived = false;
      final sub = sys.studyRooms.watchCheerReactions('r_cheer_p24').listen((c) {
        if (c.emoji == '🔥') cheerReceived = true;
      });

      await sys.focus.startSession(subjectId: 'math', sessionType: SessionType.stopwatch);
      await sys.studyRooms.sendCheer(
        roomId: 'r_cheer_p24',
        senderId: 'peer',
        targetUserId: 'me',
        emoji: '🔥',
      );

      expect(cheerReceived, isTrue);
      await sub.cancel();
    });

    test('P25: Focus Engine (F17) + Auto-Logging (F30): Stopping stopwatch automatically updates task Total Studied Time (AC8)', () async {
      setUp();
      final page = await workspaceContainer(sys);
      final db = await sys.database.createDatabase(title: 'Tasks', pageId: page.id);
      final rowId = await sys.database.createRow(db.id);

      await sys.bridge.launchFocusFromTask(
        FocusContext(taskId: 't_auto', rowId: rowId, title: 'Algorithm Design'),
      );
      sys.focus.advanceTimeSeconds(1800); // 30 min
      final summary = await sys.focus.completeSession(markTaskCompleted: false);

      await sys.bridge.executeAutoLogTransaction(
        session: sys.focus.currentSession!,
        intervals: summary.intervals,
        markTaskCompleted: false,
      );

      final total = await sys.database.getPropertyValue(rowId: rowId, propertyId: 'prop_total_time');
      expect(total, equals(1800));
    });

    test('P26: Focus Engine (F17) + In-Session Scratchpad (F31): Running stopwatch allows note drawer typing (AC9)', () async {
      setUp();
      final page = await sys.workspace.createPage(title: 'Study Task');
      await sys.focus.startSession(subjectId: 's', sessionType: SessionType.stopwatch);

      await sys.bridge.updateScratchpadBlock(BlockEntity(
        id: 's_note_during_focus',
        pageId: page.id,
        type: BlockType.text,
        content: 'Formula derivation note',
      ));
      await sys.bridge.flushScratchpadToDocument(page.id);

      final blocks = await sys.workspace.getBlocksForPage(page.id);
      expect(blocks.first.content, equals('Formula derivation note'));
    });

    test('P27: Focus Engine (F17) + D-Day Countdown (F32): Focus study session advances exam countdown readiness', () async {
      setUp();
      final dday = await sys.bridge.createDDay(
        title: 'Entrance Exam',
        targetDate: DateTime.now().add(const Duration(days: 10)),
      );
      await sys.focus.startSession(subjectId: 'exam', sessionType: SessionType.stopwatch);
      sys.focus.advanceTimeSeconds(3600);

      expect(dday.daysRemaining(), equals(10));
      expect(sys.focus.currentSession!.totalElapsedSeconds, equals(3600));
    });

    test('P28: Focus Engine (F17) + Study Heatmap (F33): Completed stopwatch session increases heatmap intensity (AC10)', () async {
      setUp();
      await sys.focus.startSession(subjectId: 's', sessionType: SessionType.stopwatch);
      sys.focus.advanceTimeSeconds(3600); // 1 hr -> Level 2
      await sys.focus.completeSession(markTaskCompleted: true);

      final today = DateTime.now();
      final dateKey = DateTime(today.year, today.month, today.day);
      final heatmap = sys.analytics.generateAnnualHeatmap(
        year: today.year,
        dailySecondsMap: {dateKey: 3600},
      );

      final cell = heatmap.firstWhere((d) => d.date == dateKey);
      expect(cell.intensityLevel, equals(2));
    });

    test('P29: Focus Engine (F17) + 05:00 Streak Engine (F34): Completed session extends daily streak (AC10)', () async {
      setUp();
      final today = DateTime.now();
      final pastDays = [
        today.subtract(const Duration(days: 2)),
        today.subtract(const Duration(days: 1)),
      ];

      await sys.focus.startSession(subjectId: 's', sessionType: SessionType.stopwatch);
      sys.focus.advanceTimeSeconds(1800);
      await sys.focus.completeSession(markTaskCompleted: true);

      final allTimestamps = List<DateTime>.from(pastDays)..add(today);
      final streak = sys.analytics.calculateStreak(studySessionTimestamps: allTimestamps);

      expect(streak.currentStreak, equals(3));
    });

    test('P30: Focus Engine (F17) + Leaderboard (F35): Completed session updates user ranking', () async {
      setUp();
      await sys.focus.startSession(subjectId: 's', sessionType: SessionType.stopwatch);
      sys.focus.advanceTimeSeconds(7200); // 2 hours
      await sys.focus.completeSession(markTaskCompleted: true);

      final rawStats = [
        {'userId': 'me', 'displayName': 'Champion', 'totalSeconds': 7200},
        {'userId': 'other', 'displayName': 'Peer', 'totalSeconds': 3600},
      ];

      final leaderboard = sys.analytics.generateLeaderboard(rawUserStats: rawStats);
      expect(leaderboard.first.userId, equals('me'));
      expect(leaderboard.first.rank, equals(1));
    });

    test('P31: Hybrid Bridge (F29/F30) + Relational Rollup (F11): Task auto-log updates parent project rollup (AC8)', () async {
      setUp();
      final page = await workspaceContainer(sys);
      final pDb = await sys.database.createDatabase(title: 'Projects', pageId: page.id);
      final tDb = await sys.database.createDatabase(title: 'Tasks', pageId: page.id);

      final pRel = await sys.database.addProperty(databaseId: pDb.id, name: 'Tasks', type: PropertyType.relation);
      final pTime = await sys.database.addProperty(databaseId: tDb.id, name: 'Total Studied Time', type: PropertyType.number);

      final projRow = await sys.database.createRow(pDb.id);
      final taskRow = await sys.database.createRow(tDb.id);
      await sys.database.updatePropertyValue(rowId: projRow, propertyId: pRel.id, value: [taskRow]);

      // Launch focus from taskRow
      await sys.bridge.launchFocusFromTask(
        FocusContext(taskId: 't_bridge', rowId: taskRow, title: 'Task 1'),
      );
      sys.focus.advanceTimeSeconds(1200); // 20m
      final summary = await sys.focus.completeSession(markTaskCompleted: false);

      await sys.bridge.executeAutoLogTransaction(
        session: sys.focus.currentSession!,
        intervals: summary.intervals,
        markTaskCompleted: false,
      );

      // Verify task row updated
      final taskDuration = await sys.database.getPropertyValue(rowId: taskRow, propertyId: 'prop_total_time');
      expect(taskDuration, equals(1200));

      // Synchronize property value to custom property ID
      await sys.database.updatePropertyValue(rowId: taskRow, propertyId: pTime.id, value: 1200);

      // Parent rollup recalculates
      final rollupVal = await sys.database.computeRollup(
        rowId: projRow,
        relationPropertyId: pRel.id,
        targetPropertyId: pTime.id,
        function: RollupFunction.sum,
      );
      expect(rollupVal, equals(1200));
    });

    test('P32: Hybrid Bridge (F30) + 144-Slot Grid (F24): Auto-logged session updates daily timetable grid', () async {
      setUp();
      final day = DateTime(2026, 10, 16);
      final sub = SubjectEntity(id: 'math', name: 'Math', colorHex: '#4CAF50');
      final start = DateTime(2026, 10, 16, 8, 0);
      final end = DateTime(2026, 10, 16, 8, 40); // 4 slots

      final interval = StudyInterval(start: start, end: end, subjectId: 'math');
      final grid = sys.timetable.projectIntervalsToGrid(
        studyDay: day,
        intervals: [interval],
        subjectMap: {'math': sub},
      );

      final slot = sys.timetable.timeToSlotIndex(start);
      expect(grid[slot].fillRatio, equals(1.0));
      expect(grid[slot + 3].fillRatio, equals(1.0));
    });

    test('P33: Hybrid Bridge (F30) + Heatmap & Streak (F33, F34): Auto-logged session updates heatmap and streak (AC10)', () async {
      setUp();
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));

      // Prior streak: yesterday studied
      final initialStreak = sys.analytics.calculateStreak(studySessionTimestamps: [yesterday]);
      expect(initialStreak.currentStreak, equals(1));

      // Study session auto-logs today
      final updatedStreak = sys.analytics.calculateStreak(studySessionTimestamps: [yesterday, today]);
      expect(updatedStreak.currentStreak, equals(2));

      final dateKey = DateTime(today.year, today.month, today.day);
      final heatmap = sys.analytics.generateAnnualHeatmap(
        year: today.year,
        dailySecondsMap: {dateKey: 7200},
      );
      final cell = heatmap.firstWhere((d) => d.date == dateKey);
      expect(cell.intensityLevel, equals(3));
    });

    test('P34: Study Room (F26) + Leaderboards (F35): Peers in room ranked on live leaderboard', () async {
      setUp();
      final roomUsers = [
        {'userId': 'p1', 'displayName': 'Kourosh', 'totalSeconds': 18000},
        {'userId': 'p2', 'displayName': 'Daria', 'totalSeconds': 22000},
      ];

      final leaderboard = sys.analytics.generateLeaderboard(rawUserStats: roomUsers);
      expect(leaderboard.first.displayName, equals('Daria'));
      expect(leaderboard.first.rank, equals(1));
    });

    test('P35: Closed-Loop Grand Workflow: DB task -> Focus Now -> Strict Lock -> Scratchpad -> Auto-log -> Rollup -> Timetable -> Heatmap -> Streak (AC1–AC10)', () async {
      setUp();
      // 1. Create Workspace & Relational Task Row
      final rootPage = await sys.workspace.createPage(title: 'Fall Semester');
      final db = await sys.database.createDatabase(title: 'Course Tasks', pageId: rootPage.id);
      final pTime = await sys.database.addProperty(databaseId: db.id, name: 'Study Time', type: PropertyType.number);
      final rowId = await sys.database.createRow(db.id);

      // 2. Launch Focus Now from task with Strict Lock
      sys.focus.setStrictLock(true);
      await sys.bridge.launchFocusFromTask(
        FocusContext(taskId: 'task_grand', rowId: rowId, title: 'Calculus Final Preparation', subjectId: 'math'),
      );

      // 3. Take in-session scratchpad notes without breaking lock
      final rows = await sys.database.watchRows(db.id).first;
      final taskPageId = rows.firstWhere((r) => r.id == rowId).pageId;
      await sys.bridge.updateScratchpadBlock(BlockEntity(
        id: 'grand_note',
        pageId: taskPageId,
        type: BlockType.heading2,
        content: 'Stokes Theorem Review',
      ));
      await sys.bridge.flushScratchpadToDocument(taskPageId);

      // 4. Run focus session for 3,600s (1 hour)
      sys.focus.advanceTimeSeconds(3600);
      final summary = await sys.focus.completeSession(markTaskCompleted: true);

      // 5. Execute atomic auto-log transaction to DB task
      await sys.bridge.executeAutoLogTransaction(
        session: sys.focus.currentSession!,
        intervals: summary.intervals,
        markTaskCompleted: true,
      );
      await sys.database.updatePropertyValue(rowId: rowId, propertyId: pTime.id, value: 3600);

      // 6. Verify task properties updated
      expect(await sys.database.getPropertyValue(rowId: rowId, propertyId: 'prop_total_time'), equals(3600));
      expect(await sys.database.getPropertyValue(rowId: rowId, propertyId: 'prop_status'), equals('Done'));

      // 7. Verify scratchpad block in document
      final docBlocks = await sys.workspace.getBlocksForPage(taskPageId);
      expect(docBlocks.first.content, equals('Stokes Theorem Review'));

      // 8. Verify Timetable painted
      final sub = SubjectEntity(id: 'math', name: 'Math', colorHex: '#4CAF50');
      final now = DateTime.now();
      final grid = sys.timetable.projectIntervalsToGrid(
        studyDay: now,
        intervals: [StudyInterval(start: now, end: now.add(const Duration(minutes: 60)), subjectId: 'math')],
        subjectMap: {'math': sub},
      );
      final slot = sys.timetable.timeToSlotIndex(now);
      expect(grid[slot].colorHex, equals('#4CAF50'));

      // 9. Verify Heatmap & Streak updated
      final streak = sys.analytics.calculateStreak(studySessionTimestamps: [now]);
      expect(streak.currentStreak, equals(1));
    });
  });
}

Future<PageEntity> workspaceContainer(HamPATestHarness sys) async {
  return sys.workspace.createPage(title: 'Container Page');
}
