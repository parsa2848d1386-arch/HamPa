// Tier 2 E2E Boundary & Corner Cases: F29–F32 HamPA Hybrid Synergy Bridge
// Minimum 5 tests per feature (20 test cases total)
// Grounded in PROJECT.md (F29–F32, AC8, AC9, E20, E21, E22)

import '../contracts/focus_contracts.dart';
import '../contracts/hybrid_bridge_contracts.dart';
import '../contracts/workspace_contracts.dart';
import '../harness/test_database_harness.dart';
import '../harness/test_focus_harness.dart';
import '../harness/test_hybrid_bridge_harness.dart';
import '../harness/test_workspace_harness.dart';
import '../support/test_runner.dart';

void runHybridBridgeTier2Tests() {
  group('Tier 2: F29 "Focus Now" Launcher Action Boundaries (5 tests)', () {
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

    test('F29-B1: Task deleted from workspace while timer is running keeps timer alive (E20)', () async {
      setUp();
      final page = await workspace.createPage(title: 'Tasks P');
      final db = await database.createDatabase(title: 'DB', pageId: page.id);
      final row = await database.createRow(db.id);

      await bridge.launchFocusFromTask(
        FocusContext(taskId: 't_del', rowId: row, title: 'Ephemeral Task'),
      );

      // Task row deleted while focus runs
      await database.deleteRow(row);

      // Timer remains running and completes safely
      expect(focus.currentSession!.status, equals(FocusState.running));
      focus.advanceTimeSeconds(300);
      final summary = await focus.completeSession(markTaskCompleted: false);
      expect(summary.totalElapsedSeconds, equals(300));
    });

    test('F29-B2: Launching focus with null subjectId defaults to default_subject', () async {
      setUp();
      await bridge.launchFocusFromTask(
        FocusContext(taskId: 't_nosub', title: 'Task without subject', subjectId: null),
      );
      expect(focus.currentSession!.subjectId, equals('default_subject'));
    });

    test('F29-B3: Launching focus with empty title handled cleanly', () async {
      setUp();
      await bridge.launchFocusFromTask(FocusContext(taskId: 't_empty', title: ''));
      expect(focus.currentSession!.linkedContext!.title, equals(''));
    });

    test('F29-B4: Rapid consecutive Focus Now calls updates active session context', () async {
      setUp();
      await bridge.launchFocusFromTask(FocusContext(taskId: 't1', title: 'T1'));
      await bridge.launchFocusFromTask(FocusContext(taskId: 't2', title: 'T2'));

      expect(focus.currentSession!.linkedContext!.taskId, equals('t2'));
    });

    test('F29-B5: Focus session with null rowId operates as pure unlinked study session', () async {
      setUp();
      await bridge.launchFocusFromTask(FocusContext(taskId: 't_unlinked', title: 'Unlinked'));
      expect(focus.currentSession!.linkedContext!.rowId, isNull);
    });
  });

  group('Tier 2: F30 Session Auto-Logging Boundaries (5 tests)', () {
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

    test('F30-B1: Auto-logging session with 0 seconds elapsed handled cleanly', () async {
      setUp();
      final page = await workspace.createPage(title: 'Tasks P');
      final db = await database.createDatabase(title: 'DB', pageId: page.id);
      final row = await database.createRow(db.id);

      final session = FocusSession(
        id: 's_zero',
        subjectId: 'math',
        sessionType: SessionType.stopwatch,
        linkedContext: FocusContext(taskId: 't', rowId: row, title: 'Zero Duration'),
        startEpochMs: DateTime.now().millisecondsSinceEpoch,
        totalElapsedSeconds: 0,
      );

      await bridge.executeAutoLogTransaction(session: session, intervals: [], markTaskCompleted: false);
      final total = await database.getPropertyValue(rowId: row, propertyId: 'prop_total_time');
      expect(total, equals(0));
    });

    test('F30-B2: Auto-logging session without linked context exits without error', () async {
      setUp();
      final session = FocusSession(
        id: 's_unlinked',
        subjectId: 'math',
        sessionType: SessionType.stopwatch,
        linkedContext: null, // no linked task
        startEpochMs: DateTime.now().millisecondsSinceEpoch,
        totalElapsedSeconds: 500,
      );

      // Should complete gracefully
      await bridge.executeAutoLogTransaction(session: session, intervals: [], markTaskCompleted: false);
    });

    test('F30-B3: Auto-logging session with extreme duration (100,000 seconds)', () async {
      setUp();
      final page = await workspace.createPage(title: 'Tasks P');
      final db = await database.createDatabase(title: 'DB', pageId: page.id);
      final row = await database.createRow(db.id);

      final session = FocusSession(
        id: 's_huge',
        subjectId: 'math',
        sessionType: SessionType.stopwatch,
        linkedContext: FocusContext(taskId: 't', rowId: row, title: 'Huge'),
        startEpochMs: DateTime.now().millisecondsSinceEpoch,
        totalElapsedSeconds: 100000,
      );

      await bridge.executeAutoLogTransaction(session: session, intervals: [], markTaskCompleted: false);
      final total = await database.getPropertyValue(rowId: row, propertyId: 'prop_total_time');
      expect(total, equals(100000));
    });

    test('F30-B4: Auto-logging with markTaskCompleted true on already Done task is idempotent', () async {
      setUp();
      final page = await workspace.createPage(title: 'Tasks P');
      final db = await database.createDatabase(title: 'DB', pageId: page.id);
      final row = await database.createRow(db.id);

      await database.updatePropertyValue(rowId: row, propertyId: 'prop_status', value: 'Done');

      final session = FocusSession(
        id: 's_done',
        subjectId: 'math',
        sessionType: SessionType.stopwatch,
        linkedContext: FocusContext(taskId: 't', rowId: row, title: 'Done'),
        startEpochMs: DateTime.now().millisecondsSinceEpoch,
        totalElapsedSeconds: 300,
      );

      await bridge.executeAutoLogTransaction(session: session, intervals: [], markTaskCompleted: true);
      final status = await database.getPropertyValue(rowId: row, propertyId: 'prop_status');
      expect(status, equals('Done'));
    });

    test('F30-B5: Auto-logging multiple sequential sessions accumulates session count accurately', () async {
      setUp();
      final page = await workspace.createPage(title: 'Tasks P');
      final db = await database.createDatabase(title: 'DB', pageId: page.id);
      final row = await database.createRow(db.id);

      for (var i = 0; i < 5; i++) {
        final session = FocusSession(
          id: 's_$i',
          subjectId: 'math',
          sessionType: SessionType.stopwatch,
          linkedContext: FocusContext(taskId: 't', rowId: row, title: 'Multi'),
          startEpochMs: DateTime.now().millisecondsSinceEpoch,
          totalElapsedSeconds: 100,
        );
        await bridge.executeAutoLogTransaction(session: session, intervals: [], markTaskCompleted: false);
      }

      final count = await database.getPropertyValue(rowId: row, propertyId: 'prop_sessions_count');
      final total = await database.getPropertyValue(rowId: row, propertyId: 'prop_total_time');
      expect(count, equals(5));
      expect(total, equals(500));
    });
  });

  group('Tier 2: F31 In-Session Scratchpad Drawer Boundaries (5 tests)', () {
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

    test('F31-B1: Flushing empty scratchpad buffer leaves document unchanged', () async {
      setUp();
      final page = await workspace.createPage(title: 'Doc');
      await bridge.flushScratchpadToDocument(page.id);

      final blocks = await workspace.getBlocksForPage(page.id);
      expect(blocks.isEmpty, isTrue);
    });

    test('F31-B2: Flushing scratchpad with 20 blocks appends all blocks to document', () async {
      setUp();
      final page = await workspace.createPage(title: 'Doc');
      for (var i = 0; i < 20; i++) {
        await bridge.updateScratchpadBlock(BlockEntity(
          id: 'scratch_$i',
          pageId: page.id,
          type: BlockType.text,
          content: 'Note $i',
        ));
      }

      await bridge.flushScratchpadToDocument(page.id);
      final blocks = await workspace.getBlocksForPage(page.id);
      expect(blocks.length, equals(20));
    });

    test('F31-B3: Scratchpad block with KaTeX math equation flushes to document', () async {
      setUp();
      final page = await workspace.createPage(title: 'Doc');
      final mathBlock = BlockEntity(
        id: 's_math',
        pageId: page.id,
        type: BlockType.latexMath,
        content: r'\nabla \cdot \mathbf{B} = 0',
      );

      await bridge.updateScratchpadBlock(mathBlock);
      await bridge.flushScratchpadToDocument(page.id);

      final blocks = await workspace.getBlocksForPage(page.id);
      expect(blocks.first.type, equals(BlockType.latexMath));
      expect(blocks.first.content, equals(r'\nabla \cdot \mathbf{B} = 0'));
    });

    test('F31-B4: Scratchpad block with code block snippet flushes to document', () async {
      setUp();
      final page = await workspace.createPage(title: 'Doc');
      final codeBlock = BlockEntity(
        id: 's_code',
        pageId: page.id,
        type: BlockType.code,
        content: 'def solve(): return 42',
        metadata: {'language': 'python'},
      );

      await bridge.updateScratchpadBlock(codeBlock);
      await bridge.flushScratchpadToDocument(page.id);

      final blocks = await workspace.getBlocksForPage(page.id);
      expect(blocks.first.type, equals(BlockType.code));
      expect(blocks.first.metadata['language'], equals('python'));
    });

    test('F31-B5: Updating block in scratchpad after flush updates existing document block', () async {
      setUp();
      final page = await workspace.createPage(title: 'Doc');
      final block = BlockEntity(id: 's_rev', pageId: page.id, type: BlockType.text, content: 'Initial');

      await bridge.updateScratchpadBlock(block);
      await bridge.flushScratchpadToDocument(page.id);

      // Second edit
      await bridge.updateScratchpadBlock(block.copyWith(content: 'Revised'));
      await bridge.flushScratchpadToDocument(page.id);

      final blocks = await workspace.getBlocksForPage(page.id);
      expect(blocks.length, equals(1));
      expect(blocks.first.content, equals('Revised'));
    });
  });

  group('Tier 2: F32 D-Day & Exam Syllabus Countdown Boundaries (5 tests)', () {
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

    test('F32-B1: Target date 100 days in the past formats as D+100 (E22)', () async {
      setUp();
      final dday = DDayEntity(
        id: 'd1',
        title: 'Old Exam',
        targetDate: DateTime(2026, 1, 1),
      );
      final ref = DateTime(2026, 4, 11); // 100 days later

      expect(dday.daysRemaining(referenceDate: ref), equals(-100));
      expect(dday.formatDDay(referenceDate: ref), equals('D+100'));
    });

    test('F32-B2: Target date 1 day in the future formats as D-1', () async {
      setUp();
      final target = DateTime(2026, 10, 17);
      final ref = DateTime(2026, 10, 16);
      final dday = DDayEntity(id: 'd2', title: 'Tomorrow', targetDate: target);

      expect(dday.daysRemaining(referenceDate: ref), equals(1));
      expect(dday.formatDDay(referenceDate: ref), equals('D-1'));
    });

    test('F32-B3: Target date 1 day in the past formats as D+1', () async {
      setUp();
      final target = DateTime(2026, 10, 15);
      final ref = DateTime(2026, 10, 16);
      final dday = DDayEntity(id: 'd3', title: 'Yesterday', targetDate: target);

      expect(dday.daysRemaining(referenceDate: ref), equals(-1));
      expect(dday.formatDDay(referenceDate: ref), equals('D+1'));
    });

    test('F32-B4: Extreme future date (year 2035 = 3000+ days) formats accurately', () async {
      setUp();
      final target = DateTime(2035, 1, 1);
      final ref = DateTime(2026, 1, 1);
      final dday = DDayEntity(id: 'd_future', title: 'Far Target', targetDate: target);

      final days = dday.daysRemaining(referenceDate: ref);
      expect(days, greaterThan(3000));
      expect(dday.formatDDay(referenceDate: ref), equals('D-$days'));
    });

    test('F32-B5: Syllabus progress calculation on empty database returns 100.0 without errors', () async {
      setUp();
      final page = await workspace.createPage(title: 'P');
      final db = await database.createDatabase(title: 'Empty Syllabus', pageId: page.id);

      final progress = await bridge.calculateSyllabusProgress(db.id);
      expect(progress, equals(100.0));
    });
  });
}
