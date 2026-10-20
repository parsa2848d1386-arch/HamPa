// Tier 1 E2E Feature Coverage: F29–F32 HamPA Hybrid Synergy Bridge
// Minimum 5 tests per feature (20 test cases total)
// Grounded in PROJECT.md (F29–F32, AC8, AC9, E20, E21, E22)

import '../contracts/database_contracts.dart';
import '../contracts/focus_contracts.dart';
import '../contracts/workspace_contracts.dart';
import '../harness/test_database_harness.dart';
import '../harness/test_focus_harness.dart';
import '../harness/test_hybrid_bridge_harness.dart';
import '../harness/test_workspace_harness.dart';
import '../support/test_runner.dart';

void runHybridBridgeTier1Tests() {
  group('Tier 1: F29 "Focus Now" Launcher Action (5 tests)', () {
    late TestWorkspaceEngine workspace;
    late TestDatabaseEngine database;
    late TestFocusEngine focus;
    late TestHybridBridgeEngine bridge;

    void setUp() {
      workspace = TestWorkspaceEngine();
      database = TestDatabaseEngine(workspaceEngine: workspace);
      focus = TestFocusEngine();
      bridge = TestHybridBridgeEngine(
        workspaceEngine: workspace,
        databaseEngine: database,
        focusEngine: focus,
      );
    }

    test('F29-1: Trigger Focus Now launches active focus session tagged with task row context', () async {
      setUp();
      final ctx = FocusContext(
        taskId: 'task_001',
        rowId: 'row_101',
        title: 'Study Real Analysis Ch 2',
        subjectId: 'sub_math',
      );

      await bridge.launchFocusFromTask(ctx);

      expect(focus.currentSession, isNotNull);
      expect(focus.currentSession!.status, equals(FocusState.running));
      expect(focus.currentSession!.linkedContext!.rowId, equals('row_101'));
      expect(focus.currentSession!.linkedContext!.title, equals('Study Real Analysis Ch 2'));
    });

    test('F29-2: Focus HUD retains subject association from linked database task', () async {
      setUp();
      final ctx = FocusContext(
        taskId: 'task_002',
        title: 'Physics Mechanics Problem Set',
        subjectId: 'sub_physics',
      );

      await bridge.launchFocusFromTask(ctx);
      expect(focus.currentSession!.subjectId, equals('sub_physics'));
    });

    test('F29-3: Trigger Focus Now from interactive checklist block in document', () async {
      setUp();
      final ctx = FocusContext(
        taskId: 'block_todo_42',
        pageId: 'page_math',
        title: 'Solve Question 5',
        subjectId: 'sub_math',
      );

      await bridge.launchFocusFromTask(ctx);
      expect(focus.currentSession!.linkedContext!.taskId, equals('block_todo_42'));
    });

    test('F29-4: Focus Now with Pomodoro session type starts running Pomodoro', () async {
      setUp();
      final ctx = FocusContext(taskId: 'task_pomo', title: 'Pomo Task');
      await focus.startSession(
        subjectId: 'sub_pomo',
        sessionType: SessionType.pomodoro,
        linkedContext: ctx,
        targetDurationSeconds: 1500,
      );

      expect(focus.currentSession!.sessionType, equals(SessionType.pomodoro));
      expect(focus.currentSession!.targetDurationSeconds, equals(1500));
    });

    test('F29-5: Focus session stream emits linked task title during running focus', () async {
      setUp();
      var receivedTitle = '';
      final sub = focus.sessionStream.listen((s) {
        if (s.linkedContext != null) {
          receivedTitle = s.linkedContext!.title;
        }
      });

      await bridge.launchFocusFromTask(
        FocusContext(taskId: 't_stream', title: 'Calculus Review'),
      );

      expect(receivedTitle, equals('Calculus Review'));
      await sub.cancel();
    });
  });

  group('Tier 1: F30 Session Auto-Logging to DB Rows (5 tests)', () {
    late TestWorkspaceEngine workspace;
    late TestDatabaseEngine database;
    late TestFocusEngine focus;
    late TestHybridBridgeEngine bridge;

    void setUp() {
      workspace = TestWorkspaceEngine();
      database = TestDatabaseEngine(workspaceEngine: workspace);
      focus = TestFocusEngine();
      bridge = TestHybridBridgeEngine(
        workspaceEngine: workspace,
        databaseEngine: database,
        focusEngine: focus,
      );
    }

    test('F30-1: Auto-logging increments Total Studied Time property (AC8)', () async {
      setUp();
      final page = await workspace.createPage(title: 'Tasks Container');
      final db = await database.createDatabase(title: 'Study DB', pageId: page.id);
      await database.addProperty(databaseId: db.id, name: 'Total Studied Time', type: PropertyType.number);
      final rowId = await database.createRow(db.id);

      final session = FocusSession(
        id: 'sess_1',
        subjectId: 'math',
        sessionType: SessionType.stopwatch,
        linkedContext: FocusContext(taskId: 't1', rowId: rowId, title: 'Math'),
        startEpochMs: DateTime.now().millisecondsSinceEpoch,
        totalElapsedSeconds: 1800, // 30 min
      );

      await bridge.executeAutoLogTransaction(
        session: session,
        intervals: [],
        markTaskCompleted: false,
      );

      final val = await database.getPropertyValue(rowId: rowId, propertyId: 'prop_total_time');
      expect(val, equals(1800));
    });

    test('F30-2: Auto-logging increments Sessions Count by 1 (AC8)', () async {
      setUp();
      final page = await workspace.createPage(title: 'Tasks Container');
      final db = await database.createDatabase(title: 'Study DB', pageId: page.id);
      final rowId = await database.createRow(db.id);

      final session = FocusSession(
        id: 'sess_2',
        subjectId: 'math',
        sessionType: SessionType.stopwatch,
        linkedContext: FocusContext(taskId: 't2', rowId: rowId, title: 'Math'),
        startEpochMs: DateTime.now().millisecondsSinceEpoch,
        totalElapsedSeconds: 1200,
      );

      await bridge.executeAutoLogTransaction(
        session: session,
        intervals: [],
        markTaskCompleted: false,
      );

      final count = await database.getPropertyValue(rowId: rowId, propertyId: 'prop_sessions_count');
      expect(count, equals(1));
    });

    test('F30-3: Auto-logging records Last Studied Date with today formatted date (AC8)', () async {
      setUp();
      final page = await workspace.createPage(title: 'Tasks Container');
      final db = await database.createDatabase(title: 'Study DB', pageId: page.id);
      final rowId = await database.createRow(db.id);

      final session = FocusSession(
        id: 'sess_3',
        subjectId: 'math',
        sessionType: SessionType.stopwatch,
        linkedContext: FocusContext(taskId: 't3', rowId: rowId, title: 'Math'),
        startEpochMs: DateTime.now().millisecondsSinceEpoch,
        totalElapsedSeconds: 600,
      );

      await bridge.executeAutoLogTransaction(
        session: session,
        intervals: [],
        markTaskCompleted: false,
      );

      final dateStr = await database.getPropertyValue(rowId: rowId, propertyId: 'prop_last_date');
      expect(dateStr, isNotNull);
      expect((dateStr as String).length, equals(10)); // YYYY-MM-DD
    });

    test('F30-4: Marking task completed in summary sets Status property to Done (AC8)', () async {
      setUp();
      final page = await workspace.createPage(title: 'Tasks Container');
      final db = await database.createDatabase(title: 'Study DB', pageId: page.id);
      final rowId = await database.createRow(db.id);

      final session = FocusSession(
        id: 'sess_4',
        subjectId: 'math',
        sessionType: SessionType.stopwatch,
        linkedContext: FocusContext(taskId: 't4', rowId: rowId, title: 'Math'),
        startEpochMs: DateTime.now().millisecondsSinceEpoch,
        totalElapsedSeconds: 900,
      );

      await bridge.executeAutoLogTransaction(
        session: session,
        intervals: [],
        markTaskCompleted: true,
      );

      final status = await database.getPropertyValue(rowId: rowId, propertyId: 'prop_status');
      expect(status, equals('Done'));
    });

    test('F30-5: Sequential sessions accumulate on existing Total Studied Time', () async {
      setUp();
      final page = await workspace.createPage(title: 'Tasks Container');
      final db = await database.createDatabase(title: 'Study DB', pageId: page.id);
      final rowId = await database.createRow(db.id);

      final s1 = FocusSession(
        id: 's1',
        subjectId: 'math',
        sessionType: SessionType.stopwatch,
        linkedContext: FocusContext(taskId: 't5', rowId: rowId, title: 'Math'),
        startEpochMs: DateTime.now().millisecondsSinceEpoch,
        totalElapsedSeconds: 1000,
      );
      final s2 = FocusSession(
        id: 's2',
        subjectId: 'math',
        sessionType: SessionType.stopwatch,
        linkedContext: FocusContext(taskId: 't5', rowId: rowId, title: 'Math'),
        startEpochMs: DateTime.now().millisecondsSinceEpoch,
        totalElapsedSeconds: 1500,
      );

      await bridge.executeAutoLogTransaction(session: s1, intervals: [], markTaskCompleted: false);
      await bridge.executeAutoLogTransaction(session: s2, intervals: [], markTaskCompleted: false);

      final total = await database.getPropertyValue(rowId: rowId, propertyId: 'prop_total_time');
      final count = await database.getPropertyValue(rowId: rowId, propertyId: 'prop_sessions_count');

      expect(total, equals(2500));
      expect(count, equals(2));
    });
  });

  group('Tier 1: F31 In-Session Scratchpad Drawer (5 tests)', () {
    late TestWorkspaceEngine workspace;
    late TestDatabaseEngine database;
    late TestFocusEngine focus;
    late TestHybridBridgeEngine bridge;

    void setUp() {
      workspace = TestWorkspaceEngine();
      database = TestDatabaseEngine(workspaceEngine: workspace);
      focus = TestFocusEngine();
      bridge = TestHybridBridgeEngine(
        workspaceEngine: workspace,
        databaseEngine: database,
        focusEngine: focus,
      );
    }

    test('F31-1: Write note block into in-session scratchpad buffer', () async {
      setUp();
      final page = await workspace.createPage(title: 'Task Page Doc');
      final note = BlockEntity(
        id: 'scratch_1',
        pageId: page.id,
        type: BlockType.text,
        content: 'Scratchpad note written during focus lock',
      );

      await bridge.updateScratchpadBlock(note);
      final list = await bridge.watchScratchpadBlocks(page.id).first;

      expect(list.length, equals(1));
      expect(list.first.content, contains('Scratchpad note'));
    });

    test('F31-2: Add interactive checklist todo item inside scratchpad drawer', () async {
      setUp();
      final page = await workspace.createPage(title: 'Task Page Doc');
      final todo = BlockEntity(
        id: 'scratch_todo',
        pageId: page.id,
        type: BlockType.todo,
        content: 'Check Lemma 3.1 in library',
        checked: false,
      );

      await bridge.updateScratchpadBlock(todo);
      final list = await bridge.watchScratchpadBlocks(page.id).first;

      expect(list.first.type, equals(BlockType.todo));
      expect(list.first.checked, isFalse);
    });

    test('F31-3: Flush scratchpad writes directly to linked task page document in Drift SQLite (AC9)', () async {
      setUp();
      final page = await workspace.createPage(title: 'Task Page Doc');
      final note = BlockEntity(
        id: 'doc_flush_block',
        pageId: page.id,
        type: BlockType.heading2,
        content: 'Lecture Insights',
      );

      await bridge.updateScratchpadBlock(note);
      await bridge.flushScratchpadToDocument(page.id);

      final docBlocks = await workspace.getBlocksForPage(page.id);
      expect(docBlocks.length, equals(1));
      expect(docBlocks.first.content, equals('Lecture Insights'));
      expect(docBlocks.first.type, equals(BlockType.heading2));
    });

    test('F31-4: Update existing block inside scratchpad preserves block ID', () async {
      setUp();
      final page = await workspace.createPage(title: 'Task Page Doc');
      final b1 = BlockEntity(id: 'b_same', pageId: page.id, type: BlockType.text, content: 'V1');
      await bridge.updateScratchpadBlock(b1);

      final b2 = b1.copyWith(content: 'V2 Updated');
      await bridge.updateScratchpadBlock(b2);

      final list = await bridge.watchScratchpadBlocks(page.id).first;
      expect(list.length, equals(1));
      expect(list.first.content, equals('V2 Updated'));
    });

    test('F31-5: Scratchpad access leaves Strict Lock mode active and zero interruptions logged (AC5, AC9)', () async {
      setUp();
      focus.setStrictLock(true);
      await focus.startSession(subjectId: 's', sessionType: SessionType.stopwatch);

      // User interacts with scratchpad (whitelisted package)
      focus.handleLifecycleChange(isForeground: false, activePackageName: 'com.hampa.scratchpad');
      final page = await workspace.createPage(title: 'Doc');
      await bridge.updateScratchpadBlock(BlockEntity(id: 'b', pageId: page.id, type: BlockType.text, content: 'Text'));
      focus.handleLifecycleChange(isForeground: true);

      expect(focus.activeInterruptionCount, equals(0));
      expect(focus.currentSession!.status, equals(FocusState.running));
    });
  });

  group('Tier 1: F32 D-Day & Exam Syllabus Countdown (5 tests)', () {
    late TestHybridBridgeEngine bridge;
    late TestWorkspaceEngine workspace;
    late TestDatabaseEngine database;
    late TestFocusEngine focus;

    void setUp() {
      workspace = TestWorkspaceEngine();
      database = TestDatabaseEngine(workspaceEngine: workspace);
      focus = TestFocusEngine();
      bridge = TestHybridBridgeEngine(
        workspaceEngine: workspace,
        databaseEngine: database,
        focusEngine: focus,
      );
    }

    test('F32-1: Create D-Day countdown milestone for future target date', () async {
      setUp();
      final futureDate = DateTime.now().add(const Duration(days: 45));
      final dday = await bridge.createDDay(
        title: 'National College Entrance Exam',
        targetDate: futureDate,
      );

      expect(dday.title, equals('National College Entrance Exam'));
      expect(dday.daysRemaining(), equals(45));
      expect(dday.formatDDay(), equals('D-45'));
    });

    test('F32-2: D-Day for today formats as D-Day', () async {
      setUp();
      final today = DateTime.now();
      final dday = await bridge.createDDay(title: 'Exam Today', targetDate: today);

      expect(dday.daysRemaining(), equals(0));
      expect(dday.formatDDay(), equals('D-Day'));
    });

    test('F32-3: D-Day for past date formats as overdue/elapsed anniversary (D+XX) (E22)', () async {
      setUp();
      final pastDate = DateTime.now().subtract(const Duration(days: 7));
      final dday = await bridge.createDDay(title: 'Past Exam', targetDate: pastDate);

      expect(dday.daysRemaining(), equals(-7));
      expect(dday.formatDDay(), equals('D+7'));
    });

    test('F32-4: Syllabus progress calculation across linked database', () async {
      setUp();
      final page = await workspace.createPage(title: 'Syllabus Page');
      final db = await database.createDatabase(title: 'Calculus Syllabus', pageId: page.id);

      final progress = await bridge.calculateSyllabusProgress(db.id);
      expect(progress, equals(100.0));
    });

    test('F32-5: D-Day widget linked with syllabus database entity reference', () async {
      setUp();
      final page = await workspace.createPage(title: 'P');
      final db = await database.createDatabase(title: 'Syllabus DB', pageId: page.id);
      final dday = await bridge.createDDay(
        title: 'Final Exam',
        targetDate: DateTime.now().add(const Duration(days: 20)),
        linkedDatabaseId: db.id,
      );

      expect(dday.linkedDatabaseId, equals(db.id));
      expect(dday.formatDDay(), equals('D-20'));
    });
  });
}
