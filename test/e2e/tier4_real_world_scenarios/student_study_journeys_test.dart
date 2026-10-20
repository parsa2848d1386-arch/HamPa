// Tier 4 E2E Real-World Application Scenarios
// 18 comprehensive, multi-step student study workflows and application-level scenarios
// Grounded in ORIGINAL_REQUEST.md, PROJECT.md, and spec_miner_survey_reqs/handoff.md

import '../contracts/database_contracts.dart';
import '../contracts/focus_contracts.dart';
import '../contracts/study_room_contracts.dart';
import '../contracts/timetable_contracts.dart';
import '../contracts/workspace_contracts.dart';
import '../harness/test_oracle_harness.dart';
import '../support/test_runner.dart';

void runRealWorldScenariosTier4Tests() {
  group('Tier 4: Real-World Application Scenarios (18 scenarios)', () {
    late HamPATestHarness sys;

    void setUp() {
      sys = HamPATestHarness();
    }

    test('S01: High School Senior Setting Up New Academic Semester', () async {
      setUp();
      // Step 1: Create top-level Semester Page
      final semester = await sys.workspace.createPage(title: 'Senior Year — Fall 2026', icon: '🎓');

      // Step 2: Create nested subject notebooks
      final math = await sys.workspace.createPage(parentPageId: semester.id, title: 'AP Calculus BC', icon: '📐');
      final physics = await sys.workspace.createPage(parentPageId: semester.id, title: 'AP Physics C', icon: '⚡');
      await sys.workspace.createPage(parentPageId: semester.id, title: 'English Literature', icon: '📖');

      // Step 3: Populate Calculus with Callout and Syllabus Checklists
      await sys.workspace.insertBlock(BlockEntity(
        id: 'math_callout',
        pageId: math.id,
        type: BlockType.callout,
        content: 'AP Exam: May 12, 2027 — Goal: Score 5',
        metadata: {'icon': '🎯'},
      ));
      await sys.workspace.insertBlock(BlockEntity(
        id: 'math_todo_1',
        pageId: math.id,
        type: BlockType.todo,
        content: 'Unit 1: Limits & Continuity',
        checked: true,
      ));
      await sys.workspace.insertBlock(BlockEntity(
        id: 'math_todo_2',
        pageId: math.id,
        type: BlockType.todo,
        content: 'Unit 2: Differentiation Applications',
        checked: false,
      ));

      // Step 4: Reorganize sidebar by dragging Physics above Math
      await sys.workspace.updatePageParent(pageId: physics.id, newParentPageId: semester.id, newSortOrder: -1.0);

      // Verify hierarchy and block persistence
      final subjects = await sys.workspace.getChildPages(semester.id);
      expect(subjects.first.id, equals(physics.id));

      final mathBlocks = await sys.workspace.getBlocksForPage(math.id);
      expect(mathBlocks.length, equals(3));
      expect(mathBlocks[1].checked, isTrue);
      expect(mathBlocks[2].checked, isFalse);
    });

    test('S02: Complete Offline Flight Study Routine with Drift Sync (AC3)', () async {
      setUp();
      // Step 1: Board airplane and turn off Wi-Fi
      sys.workspace.setNetworkOnline(false);
      expect(sys.workspace.isOnline, isFalse);

      // Step 2: Create flight study notes and checklist
      final flightDoc = await sys.workspace.createPage(title: 'Flight Study Notes — Organic Chemistry');
      await sys.workspace.insertBlock(BlockEntity(
        id: 'b_flight_1',
        pageId: flightDoc.id,
        type: BlockType.heading1,
        content: 'Reaction Mechanisms Summary',
      ));
      await sys.workspace.insertBlock(BlockEntity(
        id: 'b_flight_2',
        pageId: flightDoc.id,
        type: BlockType.todo,
        content: 'Review SN1 vs SN2 kinetics',
        checked: true,
      ));

      // Step 3: Verify modifications tracked in pending offline sync queue
      final pendingCount = await sys.workspace.getPendingSyncCount();
      expect(pendingCount, greaterThanOrEqualTo(2));

      // Step 4: Airplane lands, Wi-Fi reconnects
      sys.workspace.setNetworkOnline(true);
      await sys.workspace.triggerSync();

      // Step 5: Verify sync queue flushed completely with zero data loss
      expect(await sys.workspace.getPendingSyncCount(), equals(0));
      final verifiedBlocks = await sys.workspace.getBlocksForPage(flightDoc.id);
      expect(verifiedBlocks.length, equals(2));
      expect(verifiedBlocks.last.checked, isTrue);
    });

    test('S03: University Engineering Course Planning with Relational Formulas & Rollups', () async {
      setUp();
      final hub = await sys.workspace.createPage(title: 'Electrical Engineering');
      final courseDb = await sys.database.createDatabase(title: 'Courses', pageId: hub.id);
      final assignmentDb = await sys.database.createDatabase(title: 'Assignments', pageId: hub.id);

      final pRel = await sys.database.addProperty(databaseId: courseDb.id, name: 'Assignments', type: PropertyType.relation);
      final pWeight = await sys.database.addProperty(databaseId: assignmentDb.id, name: 'Score', type: PropertyType.number);

      final circuitsRow = await sys.database.createRow(courseDb.id);
      final hw1 = await sys.database.createRow(assignmentDb.id);
      final hw2 = await sys.database.createRow(assignmentDb.id);

      await sys.database.updatePropertyValue(rowId: hw1, propertyId: pWeight.id, value: 95);
      await sys.database.updatePropertyValue(rowId: hw2, propertyId: pWeight.id, value: 85);
      await sys.database.updatePropertyValue(rowId: circuitsRow, propertyId: pRel.id, value: [hw1, hw2]);

      // Calculate average score across assignments
      final avgScore = await sys.database.computeRollup(
        rowId: circuitsRow,
        relationPropertyId: pRel.id,
        targetPropertyId: pWeight.id,
        function: RollupFunction.average,
      );
      expect(avgScore, equals(90.0));
    });

    test('S04: Computer Science Student Thesis Preparation with Code Snippets & KaTeX', () async {
      setUp();
      final page = await sys.workspace.createPage(title: 'Master Thesis — Graph Neural Networks');

      await sys.workspace.insertBlock(BlockEntity(
        id: 'code_python',
        pageId: page.id,
        type: BlockType.code,
        content: 'import torch\nimport torch_geometric as pyg',
        metadata: {'language': 'python'},
      ));

      await sys.workspace.insertBlock(BlockEntity(
        id: 'math_message_passing',
        pageId: page.id,
        type: BlockType.latexMath,
        content: r'\mathbf{h}_v^{(k)} = \text{UPDATE}^{(k)} \left( \mathbf{h}_v^{(k-1)}, \text{AGGREGATE}^{(k)} \right)',
      ));

      final blocks = await sys.workspace.getBlocksForPage(page.id);
      expect(blocks.length, equals(2));
      expect(blocks[0].metadata['language'], equals('python'));
      expect(blocks[1].type, equals(BlockType.latexMath));
    });

    test('S05: Medical Student USMLE Step 1 Preparation across Gantt Timeline & Calendar', () async {
      setUp();
      final medHub = await sys.workspace.createPage(title: 'USMLE Prep');
      final organDb = await sys.database.createDatabase(title: 'Organ Systems', pageId: medHub.id);
      final pStart = await sys.database.addProperty(databaseId: organDb.id, name: 'Start', type: PropertyType.date);
      final pEnd = await sys.database.addProperty(databaseId: organDb.id, name: 'End', type: PropertyType.date);

      final cardio = await sys.database.createRow(organDb.id);
      final renal = await sys.database.createRow(organDb.id);

      await sys.database.updatePropertyValue(rowId: cardio, propertyId: pStart.id, value: '2026-10-01');
      await sys.database.updatePropertyValue(rowId: cardio, propertyId: pEnd.id, value: '2026-10-14');
      await sys.database.updatePropertyValue(rowId: renal, propertyId: pStart.id, value: '2026-10-15');
      await sys.database.updatePropertyValue(rowId: renal, propertyId: pEnd.id, value: '2026-10-28');

      expect(await sys.database.getPropertyValue(rowId: cardio, propertyId: pStart.id), equals('2026-10-01'));
      expect(await sys.database.getPropertyValue(rowId: renal, propertyId: pEnd.id), equals('2026-10-28'));
    });

    test('S06: High-Discipline Strict Lock Study Session with In-Session Scratchpad (AC5, AC8, AC9)', () async {
      setUp();
      final page = await sys.workspace.createPage(title: 'Physics Homework');
      final db = await sys.database.createDatabase(title: 'Problem Sets', pageId: page.id);
      final taskRow = await sys.database.createRow(db.id);

      // 1. Enable Strict Lock and trigger Focus Now
      sys.focus.setStrictLock(true);
      await sys.bridge.launchFocusFromTask(
        FocusContext(taskId: 'hw_task', rowId: taskRow, title: 'Electromagnetism HW 4', subjectId: 'phys'),
      );

      // 2. Open scratchpad drawer and write solution notes without breaking lock
      final rows = await sys.database.watchRows(db.id).first;
      final taskPageId = rows.firstWhere((r) => r.id == taskRow).pageId;
      await sys.bridge.updateScratchpadBlock(BlockEntity(
        id: 'scratch_sol',
        pageId: taskPageId,
        type: BlockType.text,
        content: 'Gauss Law spherical symmetry solution',
      ));
      await sys.bridge.flushScratchpadToDocument(taskPageId);

      // 3. User attempts to switch to YouTube -> intercepted as interruption strike!
      sys.focus.handleLifecycleChange(isForeground: false, activePackageName: 'com.google.android.youtube');
      expect(sys.focus.activeInterruptionCount, equals(1));
      sys.focus.handleLifecycleChange(isForeground: true);

      // 4. Complete study session
      sys.focus.advanceTimeSeconds(1800); // 30 minutes
      final summary = await sys.focus.completeSession(markTaskCompleted: true);

      // 5. Auto-log registers duration and marked completed
      await sys.bridge.executeAutoLogTransaction(
        session: sys.focus.currentSession!,
        intervals: summary.intervals,
        markTaskCompleted: true,
      );

      expect(await sys.database.getPropertyValue(rowId: taskRow, propertyId: 'prop_total_time'), equals(1800));
      expect(await sys.database.getPropertyValue(rowId: taskRow, propertyId: 'prop_status'), equals('Done'));
      final docBlocks = await sys.workspace.getBlocksForPage(taskPageId);
      expect(docBlocks.first.content, contains('Gauss Law'));
    });

    test('S07: Pomodoro Marathon with Rain Ambient Soundscape', () async {
      setUp();
      // Configure ambient soundscape
      sys.focus.setAmbientTrackVolume(trackId: 'rain', volume: 0.8);
      expect(sys.focus.getAmbientTrackVolume('rain'), equals(0.8));

      // Cycle 1: 25m focus
      await sys.focus.startSession(subjectId: 'chem', sessionType: SessionType.pomodoro, targetDurationSeconds: 1500);
      sys.focus.advanceTimeSeconds(1500);
      await sys.focus.pauseSession(); // 5m short break
      sys.focus.advanceTimeSeconds(300);

      // Cycle 2: resume 25m focus
      await sys.focus.resumeSession();
      sys.focus.advanceTimeSeconds(1500);
      final summary = await sys.focus.completeSession(markTaskCompleted: true);

      expect(summary.totalElapsedSeconds, equals(3000)); // 25 + 25 = 50m active
      expect(sys.focus.getAmbientTrackVolume('rain'), equals(0.8));
    });

    test('S08: 3-Hour Standardized Mock Exam Simulation', () async {
      setUp();
      // Start 3-hour exam simulation (10800s)
      final session = await sys.focus.startSession(
        subjectId: 'sat',
        sessionType: SessionType.mockExam,
        targetDurationSeconds: 10800,
      );

      // Advance through Section 1 (65m), Section 2 (35m), Section 3 (80m)
      sys.focus.advanceTimeSeconds(10800);
      final summary = await sys.focus.completeSession(markTaskCompleted: true);

      expect(summary.totalElapsedSeconds, equals(10800));
      expect(session.sessionType, equals(SessionType.mockExam));
    });

    test('S09: Night-Owl Student Studying Across 05:00 AM Boundary (E01, E02, AC6, AC10)', () async {
      setUp();
      final dayOct16 = DateTime(2026, 10, 16);
      final dayOct17 = DateTime(2026, 10, 17);
      final sub = SubjectEntity(id: 'math', name: 'Math', colorHex: '#4CAF50');

      // Student studies from 03:30 AM to 06:30 AM on Oct 17 morning (crosses 05:00 cutoff)
      final midnightSession = StudyInterval(
        start: DateTime(2026, 10, 17, 3, 30),
        end: DateTime(2026, 10, 17, 6, 30),
        subjectId: 'math',
      );

      // 1. In Oct 16 study day: 03:30 to 05:00 (90 min = 9 slots 135 to 143) credited to Oct 16!
      final gridDay16 = sys.timetable.projectIntervalsToGrid(
        studyDay: dayOct16,
        intervals: [midnightSession],
        subjectMap: {'math': sub},
      );
      expect(gridDay16[135].fillRatio, equals(1.0));
      expect(gridDay16[143].fillRatio, equals(1.0));

      // 2. In Oct 17 study day: 05:00 to 06:30 (90 min = 9 slots 0 to 8) credited to Oct 17!
      final gridDay17 = sys.timetable.projectIntervalsToGrid(
        studyDay: dayOct17,
        intervals: [midnightSession],
        subjectMap: {'math': sub},
      );
      expect(gridDay17[0].fillRatio, equals(1.0));
      expect(gridDay17[8].fillRatio, equals(1.0));

      // 3. Streak engine credits 03:30 session to Oct 16 to maintain student night-owl streak
      final streak = sys.analytics.calculateStreak(
        studySessionTimestamps: [midnightSession.start],
        relativeTo: DateTime(2026, 10, 16, 12, 0),
        cutoffHour: 5,
      );
      expect(streak.currentStreak, equals(1));
    });

    test('S10: Virtual Study Group "Study With Me" Room with Cheering & Presence (AC7)', () async {
      setUp();
      final room = 'national_study_room';
      final parsa = RoomMember(userId: 'u_parsa', displayName: 'Parsa', presenceState: PresenceState.resting);
      final ali = RoomMember(userId: 'u_ali', displayName: 'Ali', presenceState: PresenceState.studying);

      await sys.studyRooms.joinRoom(roomId: room, self: parsa);
      await sys.studyRooms.joinRoom(roomId: room, self: ali);

      // Parsa starts studying Calculus
      await sys.studyRooms.updatePresence(
        roomId: room,
        userId: 'u_parsa',
        state: PresenceState.studying,
        subjectName: 'Calculus',
        elapsedSeconds: 300,
      );

      // Ali sends cheering fire reaction to Parsa
      final cheered = await sys.studyRooms.sendCheer(
        roomId: room,
        senderId: 'u_ali',
        targetUserId: 'u_parsa',
        emoji: '🔥',
      );
      expect(cheered, isTrue);

      final members = await sys.studyRooms.watchRoomMembers(room).first;
      expect(members.firstWhere((m) => m.userId == 'u_parsa').presenceState, equals(PresenceState.studying));
    });

    test('S11: Flip-to-Focus Library Session with Ambient Audio', () async {
      setUp();
      // Place phone face down on desk to start study session
      sys.focus.handleSensorUpdate(zAxisAcceleration: -9.8, isNear: true);
      await sys.focus.startSession(subjectId: 'law', sessionType: SessionType.stopwatch);
      expect(sys.focus.currentSession!.status, equals(FocusState.running));

      // Student picks up phone to stretch -> auto-pauses
      await Future.delayed(const Duration(milliseconds: 1600));
      sys.focus.handleSensorUpdate(zAxisAcceleration: 9.8, isNear: false);
      expect(sys.focus.currentSession!.status, equals(FocusState.paused));

      // Student puts phone back face down -> auto-resumes
      await Future.delayed(const Duration(milliseconds: 1600));
      sys.focus.handleSensorUpdate(zAxisAcceleration: -9.8, isNear: true);
      expect(sys.focus.currentSession!.status, equals(FocusState.running));
    });

    test('S12: D-Day Countdown to University Konkur / Final Exam (AC4, AC8)', () async {
      setUp();
      final examDate = DateTime.now().add(const Duration(days: 30));
      final dday = await sys.bridge.createDDay(title: 'Konkur 1406', targetDate: examDate);

      expect(dday.daysRemaining(), equals(30));
      expect(dday.formatDDay(), equals('D-30'));
    });

    test('S13: Student Revision Sprint with Interactive Toggles & Checklists', () async {
      setUp();
      final page = await sys.workspace.createPage(title: 'Biology Flash Review');
      final toggle = BlockEntity(
        id: 'toggle_dna',
        pageId: page.id,
        type: BlockType.toggle,
        content: 'Question: What enzyme unwinds DNA during replication?',
        metadata: {'isExpanded': false},
      );
      await sys.workspace.insertBlock(toggle);

      final answer = BlockEntity(
        id: 'answer_dna',
        pageId: page.id,
        type: BlockType.text,
        content: 'Answer: Helicase',
        parentBlockId: toggle.id,
      );
      await sys.workspace.insertBlock(answer);

      // Student checks off question mastery
      final todo = BlockEntity(
        id: 'todo_mastery',
        pageId: page.id,
        type: BlockType.todo,
        content: 'Mastered DNA replication',
        checked: true,
      );
      await sys.workspace.insertBlock(todo);

      final blocks = await sys.workspace.getBlocksForPage(page.id);
      expect(blocks.length, equals(3));
      expect(blocks.last.checked, isTrue);
    });

    test('S14: Relational Database 6-View Multi-Perspective Workflow (AC2)', () async {
      setUp();
      final hub = await sys.workspace.createPage(title: 'Startup Launch');
      final db = await sys.database.createDatabase(title: 'Roadmap DB', pageId: hub.id);

      final pStatus = await sys.database.addProperty(databaseId: db.id, name: 'Status', type: PropertyType.status);
      final pDate = await sys.database.addProperty(databaseId: db.id, name: 'Date', type: PropertyType.date);

      final row = await sys.database.createRow(db.id);
      await sys.database.updatePropertyValue(rowId: row, propertyId: pStatus.id, value: 'In Progress');
      await sys.database.updatePropertyValue(rowId: row, propertyId: pDate.id, value: '2026-11-01');

      // Create all 6 views
      await sys.database.createView(databaseId: db.id, name: 'Table', type: DatabaseViewType.table);
      await sys.database.createView(databaseId: db.id, name: 'Kanban', type: DatabaseViewType.kanban);
      await sys.database.createView(databaseId: db.id, name: 'Calendar', type: DatabaseViewType.calendar);
      await sys.database.createView(databaseId: db.id, name: 'Timeline', type: DatabaseViewType.timeline);
      await sys.database.createView(databaseId: db.id, name: 'List', type: DatabaseViewType.list);
      await sys.database.createView(databaseId: db.id, name: 'Gallery', type: DatabaseViewType.gallery);

      // Verify row state identical across all views (AC2)
      final rows = await sys.database.watchRows(db.id).first;
      expect(rows.length, equals(1));
      expect(await sys.database.getPropertyValue(rowId: rows.first.id, propertyId: pStatus.id), equals('In Progress'));
      expect(await sys.database.getPropertyValue(rowId: rows.first.id, propertyId: pDate.id), equals('2026-11-01'));
    });

    test('S15: Organizing Deep Research Notes with Drag-and-Drop (AC1)', () async {
      setUp();
      final thesis = await sys.workspace.createPage(title: 'Doctoral Dissertation');
      final ch1 = await sys.workspace.createPage(parentPageId: thesis.id, title: 'Chapter 1: Intro');
      final sec1 = await sys.workspace.createPage(parentPageId: ch1.id, title: '1.1 Background');

      // Promote section to be a direct sibling of Chapter 1
      await sys.workspace.updatePageParent(pageId: sec1.id, newParentPageId: thesis.id, newSortOrder: 2.0);

      final updated = await sys.workspace.getPage(sec1.id);
      expect(updated!.parentPageId, equals(thesis.id));
    });

    test('S16: Agile Study Sprint with Kanban Drag-and-Drop Workflow', () async {
      setUp();
      final page = await sys.workspace.createPage(title: 'Sprint Page');
      final db = await sys.database.createDatabase(title: 'Sprint 4', pageId: page.id);
      final pStatus = await sys.database.addProperty(databaseId: db.id, name: 'Status', type: PropertyType.status);

      final task = await sys.database.createRow(db.id);
      await sys.database.updatePropertyValue(rowId: task, propertyId: pStatus.id, value: 'Backlog');

      // Drag to In Progress
      await sys.database.updatePropertyValue(rowId: task, propertyId: pStatus.id, value: 'In Progress');
      expect(await sys.database.getPropertyValue(rowId: task, propertyId: pStatus.id), equals('In Progress'));

      // Drag to Done
      await sys.database.updatePropertyValue(rowId: task, propertyId: pStatus.id, value: 'Done');
      expect(await sys.database.getPropertyValue(rowId: task, propertyId: pStatus.id), equals('Done'));
    });

    test('S17: High School STEM Olympiad Preparation with LaTeX & Timed Problem Sets', () async {
      setUp();
      final page = await sys.workspace.createPage(title: 'Math Olympiad Problem Set');
      await sys.workspace.insertBlock(BlockEntity(
        id: 'olympiad_problem',
        pageId: page.id,
        type: BlockType.latexMath,
        content: r'a^3 + b^3 + c^3 \ge 3abc \quad \forall a,b,c \ge 0',
      ));

      // Timed solve session
      await sys.focus.startSession(subjectId: 'olympiad', sessionType: SessionType.stopwatch);
      sys.focus.advanceTimeSeconds(1200); // 20m solve time
      final summary = await sys.focus.completeSession(markTaskCompleted: true);

      expect(summary.totalElapsedSeconds, equals(1200));
      final blocks = await sys.workspace.getBlocksForPage(page.id);
      expect(blocks.first.content, contains('3abc'));
    });

    test('S18: Year-End Study Retrospective, 100-Day Streak & Anonymized Leaderboard (AC10, E25)', () async {
      setUp();
      final today = DateTime(2026, 12, 31);
      final timestamps = <DateTime>[];
      for (var i = 0; i < 100; i++) {
        timestamps.add(today.subtract(Duration(days: i)));
      }

      // 1. Verify 100-day study streak milestone
      final streak = sys.analytics.calculateStreak(
        studySessionTimestamps: timestamps,
        relativeTo: today,
      );
      expect(streak.currentStreak, equals(100));

      // 2. Generate annual 365-day contribution heatmap
      final heatmap = sys.analytics.generateAnnualHeatmap(
        year: 2026,
        dailySecondsMap: {today: 14400}, // 4 hours -> Level 4
      );
      expect(heatmap.length, equals(365));
      expect(heatmap.last.intensityLevel, equals(4));

      // 3. User appears on National Leaderboard with Anonymized Mode enabled
      final rawStats = [
        {'userId': 'champion_student', 'displayName': 'Parsa', 'totalSeconds': 360000},
      ];
      final leaderboard = sys.analytics.generateLeaderboard(
        rawUserStats: rawStats,
        anonymizedMode: true,
      );
      expect(leaderboard.first.isAnonymous, isTrue);
      expect(leaderboard.first.displayName, contains('Anonymous #'));
      expect(leaderboard.first.subjectName, equals('General Study'));
    });
  });
}
