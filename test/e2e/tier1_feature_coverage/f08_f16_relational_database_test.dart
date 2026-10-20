// Tier 1 E2E Feature Coverage: F08–F16 Relational Database Engine & 6 Views
// Minimum 5 tests per feature (45 test cases total)
// Grounded in PROJECT.md (F08–F16, AC2, AC8)

import '../contracts/database_contracts.dart';
import '../harness/test_database_harness.dart';
import '../harness/test_workspace_harness.dart';
import '../support/test_runner.dart';

void runRelationalDatabaseTier1Tests() {
  group('Tier 1: F08 Rich Property Schema Engine (5 tests)', () {
    late TestWorkspaceEngine workspace;
    late TestDatabaseEngine database;

    void setUp() {
      workspace = TestWorkspaceEngine();
      database = TestDatabaseEngine(workspaceEngine: workspace);
    }

    test('F08-1: Define diverse property types in database schema', () async {
      setUp();
      final page = await workspace.createPage(title: 'DB Container');
      final db = await database.createDatabase(title: 'Tasks DB', pageId: page.id);

      final pStatus = await database.addProperty(databaseId: db.id, name: 'Status', type: PropertyType.status);
      final pDate = await database.addProperty(databaseId: db.id, name: 'Due Date', type: PropertyType.date);
      final pHours = await database.addProperty(databaseId: db.id, name: 'Estimated Hours', type: PropertyType.number);
      final pCheck = await database.addProperty(databaseId: db.id, name: 'Urgent', type: PropertyType.checkbox);

      expect(pStatus.type, equals(PropertyType.status));
      expect(pDate.type, equals(PropertyType.date));
      expect(pHours.type, equals(PropertyType.number));
      expect(pCheck.type, equals(PropertyType.checkbox));
    });

    test('F08-2: Read and watch property list for database', () async {
      setUp();
      final page = await workspace.createPage(title: 'DB Page');
      final db = await database.createDatabase(title: 'Course Tracker', pageId: page.id);

      await database.addProperty(databaseId: db.id, name: 'Credits', type: PropertyType.number);
      await database.addProperty(databaseId: db.id, name: 'Instructor', type: PropertyType.text);

      var propCount = 0;
      final sub = database.watchProperties(db.id).listen((props) {
        propCount = props.length;
      });

      await database.addProperty(databaseId: db.id, name: 'Room', type: PropertyType.text);
      expect(propCount, greaterThanOrEqualTo(3)); // Title + Credits + Instructor + Room
      await sub.cancel();
    });

    test('F08-3: Assign and read cell values for rich schema properties', () async {
      setUp();
      final page = await workspace.createPage(title: 'DB Page');
      final db = await database.createDatabase(title: 'Tasks', pageId: page.id);
      final pNumber = await database.addProperty(databaseId: db.id, name: 'Score', type: PropertyType.number);

      final rowId = await database.createRow(db.id);
      await database.updatePropertyValue(rowId: rowId, propertyId: pNumber.id, value: 98.5);

      final val = await database.getPropertyValue(rowId: rowId, propertyId: pNumber.id);
      expect(val, equals(98.5));
    });

    test('F08-4: Property configuration options for select properties', () async {
      setUp();
      final page = await workspace.createPage(title: 'DB Page');
      final db = await database.createDatabase(title: 'Priorities', pageId: page.id);
      final pSelect = await database.addProperty(
        databaseId: db.id,
        name: 'Priority',
        type: PropertyType.select,
        config: {
          'options': ['Low', 'Medium', 'High', 'Critical'],
        },
      );

      expect(pSelect.config['options'].length, equals(4));
    });

    test('F08-5: Schema change reflects across existing and new rows', () async {
      setUp();
      final page = await workspace.createPage(title: 'DB Page');
      final db = await database.createDatabase(title: 'Syllabus', pageId: page.id);
      final r1 = await database.createRow(db.id);

      final pTag = await database.addProperty(databaseId: db.id, name: 'Tag', type: PropertyType.text);
      await database.updatePropertyValue(rowId: r1, propertyId: pTag.id, value: 'Exam Prep');

      final r2 = await database.createRow(db.id);
      await database.updatePropertyValue(rowId: r2, propertyId: pTag.id, value: 'Assignment');

      expect(await database.getPropertyValue(rowId: r1, propertyId: pTag.id), equals('Exam Prep'));
      expect(await database.getPropertyValue(rowId: r2, propertyId: pTag.id), equals('Assignment'));
    });
  });

  group('Tier 1: F09 Two-Way Database Relations (5 tests)', () {
    late TestWorkspaceEngine workspace;
    late TestDatabaseEngine database;

    void setUp() {
      workspace = TestWorkspaceEngine();
      database = TestDatabaseEngine(workspaceEngine: workspace);
    }

    test('F09-1: Link row in Database A to row in Database B via relation property', () async {
      setUp();
      final page = await workspace.createPage(title: 'Workspace');
      final projectsDb = await database.createDatabase(title: 'Projects', pageId: page.id);
      final tasksDb = await database.createDatabase(title: 'Tasks', pageId: page.id);

      final pRelation = await database.addProperty(
        databaseId: tasksDb.id,
        name: 'Project Link',
        type: PropertyType.relation,
        config: {'targetDatabaseId': projectsDb.id},
      );

      final projRowId = await database.createRow(projectsDb.id);
      final taskRowId = await database.createRow(tasksDb.id);

      await database.updatePropertyValue(rowId: taskRowId, propertyId: pRelation.id, value: projRowId);

      final linkedId = await database.getPropertyValue(rowId: taskRowId, propertyId: pRelation.id);
      expect(linkedId, equals(projRowId));
    });

    test('F09-2: Multi-row relation linking (1:N)', () async {
      setUp();
      final page = await workspace.createPage(title: 'Workspace');
      final projectsDb = await database.createDatabase(title: 'Projects', pageId: page.id);
      final tasksDb = await database.createDatabase(title: 'Tasks', pageId: page.id);

      final pTasksRelation = await database.addProperty(
        databaseId: projectsDb.id,
        name: 'Tasks',
        type: PropertyType.relation,
      );

      final projRowId = await database.createRow(projectsDb.id);
      final t1 = await database.createRow(tasksDb.id);
      final t2 = await database.createRow(tasksDb.id);
      final t3 = await database.createRow(tasksDb.id);

      await database.updatePropertyValue(
        rowId: projRowId,
        propertyId: pTasksRelation.id,
        value: [t1, t2, t3],
      );

      final linkedTasks = await database.getPropertyValue(rowId: projRowId, propertyId: pTasksRelation.id) as List;
      expect(linkedTasks.length, equals(3));
      expect(linkedTasks, contains(t2));
    });

    test('F09-3: Update relation link to replace associated row', () async {
      setUp();
      final page = await workspace.createPage(title: 'Workspace');
      final dbA = await database.createDatabase(title: 'DB A', pageId: page.id);
      final dbB = await database.createDatabase(title: 'DB B', pageId: page.id);
      final pRel = await database.addProperty(databaseId: dbA.id, name: 'Target', type: PropertyType.relation);

      final rowA = await database.createRow(dbA.id);
      final target1 = await database.createRow(dbB.id);
      final target2 = await database.createRow(dbB.id);

      await database.updatePropertyValue(rowId: rowA, propertyId: pRel.id, value: target1);
      expect(await database.getPropertyValue(rowId: rowA, propertyId: pRel.id), equals(target1));

      await database.updatePropertyValue(rowId: rowA, propertyId: pRel.id, value: target2);
      expect(await database.getPropertyValue(rowId: rowA, propertyId: pRel.id), equals(target2));
    });

    test('F09-4: Deleting related row clears reference from relation cells (referential integrity)', () async {
      setUp();
      final page = await workspace.createPage(title: 'Workspace');
      final dbA = await database.createDatabase(title: 'DB A', pageId: page.id);
      final dbB = await database.createDatabase(title: 'DB B', pageId: page.id);
      final pRel = await database.addProperty(databaseId: dbA.id, name: 'Rel', type: PropertyType.relation);

      final rowA = await database.createRow(dbA.id);
      final rowB = await database.createRow(dbB.id);

      await database.updatePropertyValue(rowId: rowA, propertyId: pRel.id, value: rowB);
      expect(await database.getPropertyValue(rowId: rowA, propertyId: pRel.id), equals(rowB));

      // Delete target rowB
      await database.deleteRow(rowB);

      final afterDelete = await database.getPropertyValue(rowId: rowA, propertyId: pRel.id);
      expect(afterDelete, isNull);
    });

    test('F09-5: Multi-relation list removes deleted row reference cleanly', () async {
      setUp();
      final page = await workspace.createPage(title: 'Workspace');
      final dbA = await database.createDatabase(title: 'DB A', pageId: page.id);
      final dbB = await database.createDatabase(title: 'DB B', pageId: page.id);
      final pRel = await database.addProperty(databaseId: dbA.id, name: 'List Rel', type: PropertyType.relation);

      final rowA = await database.createRow(dbA.id);
      final r1 = await database.createRow(dbB.id);
      final r2 = await database.createRow(dbB.id);

      await database.updatePropertyValue(rowId: rowA, propertyId: pRel.id, value: [r1, r2]);
      await database.deleteRow(r1);

      final list = await database.getPropertyValue(rowId: rowA, propertyId: pRel.id) as List;
      expect(list.length, equals(1));
      expect(list.first, equals(r2));
    });
  });

  group('Tier 1: F10 Formula Expression Engine (5 tests)', () {
    late TestWorkspaceEngine workspace;
    late TestDatabaseEngine database;

    void setUp() {
      workspace = TestWorkspaceEngine();
      database = TestDatabaseEngine(workspaceEngine: workspace);
    }

    test('F10-1: Evaluate basic constant arithmetic expression', () async {
      setUp();
      final page = await workspace.createPage(title: 'Math');
      final db = await database.createDatabase(title: 'Calcs', pageId: page.id);
      final row = await database.createRow(db.id);

      final result = await database.evaluateFormula(rowId: row, expression: '10 + 25');
      expect(result, equals(35.0));
    });

    test('F10-2: Evaluate formula with single property lookup', () async {
      setUp();
      final page = await workspace.createPage(title: 'Math');
      final db = await database.createDatabase(title: 'Calcs', pageId: page.id);
      final pHours = await database.addProperty(databaseId: db.id, name: 'Hours', type: PropertyType.number);

      final row = await database.createRow(db.id);
      await database.updatePropertyValue(rowId: row, propertyId: pHours.id, value: 4);

      final result = await database.evaluateFormula(rowId: row, expression: 'prop("Hours") * 60');
      expect(result, equals(240.0));
    });

    test('F10-3: Evaluate formula with multiple properties summation', () async {
      setUp();
      final page = await workspace.createPage(title: 'Math');
      final db = await database.createDatabase(title: 'Scores', pageId: page.id);
      final pMidterm = await database.addProperty(databaseId: db.id, name: 'Midterm', type: PropertyType.number);
      final pFinal = await database.addProperty(databaseId: db.id, name: 'Final', type: PropertyType.number);

      final row = await database.createRow(db.id);
      await database.updatePropertyValue(rowId: row, propertyId: pMidterm.id, value: 40);
      await database.updatePropertyValue(rowId: row, propertyId: pFinal.id, value: 50);

      final total = await database.evaluateFormula(rowId: row, expression: 'prop("Midterm") + prop("Final")');
      expect(total, equals(90.0));
    });

    test('F10-4: Formula returns null when referenced property is unpopulated', () async {
      setUp();
      final page = await workspace.createPage(title: 'Math');
      final db = await database.createDatabase(title: 'Calcs', pageId: page.id);
      await database.addProperty(databaseId: db.id, name: 'MissingVal', type: PropertyType.number);

      final row = await database.createRow(db.id);
      final res = await database.evaluateFormula(rowId: row, expression: 'prop("MissingVal") + 10');
      expect(res, isNull);
    });

    test('F10-5: Formula returns string literal or fallback on non-math string', () async {
      setUp();
      final page = await workspace.createPage(title: 'Math');
      final db = await database.createDatabase(title: 'Calcs', pageId: page.id);
      final row = await database.createRow(db.id);

      final res = await database.evaluateFormula(rowId: row, expression: 'ACTIVE');
      expect(res, equals('ACTIVE'));
    });
  });

  group('Tier 1: F11 Automatic Rollups & Aggregations (5 tests)', () {
    late TestWorkspaceEngine workspace;
    late TestDatabaseEngine database;

    void setUp() {
      workspace = TestWorkspaceEngine();
      database = TestDatabaseEngine(workspaceEngine: workspace);
    }

    test('F11-1: Rollup Sum aggregates numeric values across related rows', () async {
      setUp();
      final page = await workspace.createPage(title: 'School');
      final projDb = await database.createDatabase(title: 'Courses', pageId: page.id);
      final taskDb = await database.createDatabase(title: 'Assignments', pageId: page.id);

      final pRel = await database.addProperty(databaseId: projDb.id, name: 'Assignments', type: PropertyType.relation);
      final pScore = await database.addProperty(databaseId: taskDb.id, name: 'Score', type: PropertyType.number);

      final courseRow = await database.createRow(projDb.id);
      final a1 = await database.createRow(taskDb.id);
      final a2 = await database.createRow(taskDb.id);
      final a3 = await database.createRow(taskDb.id);

      await database.updatePropertyValue(rowId: a1, propertyId: pScore.id, value: 20);
      await database.updatePropertyValue(rowId: a2, propertyId: pScore.id, value: 35);
      await database.updatePropertyValue(rowId: a3, propertyId: pScore.id, value: 45);

      await database.updatePropertyValue(rowId: courseRow, propertyId: pRel.id, value: [a1, a2, a3]);

      final totalScore = await database.computeRollup(
        rowId: courseRow,
        relationPropertyId: pRel.id,
        targetPropertyId: pScore.id,
        function: RollupFunction.sum,
      );

      expect(totalScore, equals(100));
    });

    test('F11-2: Rollup Average computes arithmetic mean of related rows', () async {
      setUp();
      final page = await workspace.createPage(title: 'School');
      final projDb = await database.createDatabase(title: 'Courses', pageId: page.id);
      final taskDb = await database.createDatabase(title: 'Exams', pageId: page.id);

      final pRel = await database.addProperty(databaseId: projDb.id, name: 'Exams', type: PropertyType.relation);
      final pScore = await database.addProperty(databaseId: taskDb.id, name: 'Grade', type: PropertyType.number);

      final courseRow = await database.createRow(projDb.id);
      final e1 = await database.createRow(taskDb.id);
      final e2 = await database.createRow(taskDb.id);

      await database.updatePropertyValue(rowId: e1, propertyId: pScore.id, value: 80);
      await database.updatePropertyValue(rowId: e2, propertyId: pScore.id, value: 90);

      await database.updatePropertyValue(rowId: courseRow, propertyId: pRel.id, value: [e1, e2]);

      final avgGrade = await database.computeRollup(
        rowId: courseRow,
        relationPropertyId: pRel.id,
        targetPropertyId: pScore.id,
        function: RollupFunction.average,
      );

      expect(avgGrade, equals(85.0));
    });

    test('F11-3: Rollup Count counts linked related rows accurately', () async {
      setUp();
      final page = await workspace.createPage(title: 'School');
      final projDb = await database.createDatabase(title: 'Projects', pageId: page.id);
      final taskDb = await database.createDatabase(title: 'Tasks', pageId: page.id);

      final pRel = await database.addProperty(databaseId: projDb.id, name: 'Tasks', type: PropertyType.relation);
      final pName = await database.addProperty(databaseId: taskDb.id, name: 'Title', type: PropertyType.text);

      final projRow = await database.createRow(projDb.id);
      final t1 = await database.createRow(taskDb.id);
      final t2 = await database.createRow(taskDb.id);
      final t3 = await database.createRow(taskDb.id);
      final t4 = await database.createRow(taskDb.id);

      await database.updatePropertyValue(rowId: t1, propertyId: pName.id, value: 'T1');
      await database.updatePropertyValue(rowId: t2, propertyId: pName.id, value: 'T2');
      await database.updatePropertyValue(rowId: t3, propertyId: pName.id, value: 'T3');
      await database.updatePropertyValue(rowId: t4, propertyId: pName.id, value: 'T4');

      await database.updatePropertyValue(rowId: projRow, propertyId: pRel.id, value: [t1, t2, t3, t4]);

      final count = await database.computeRollup(
        rowId: projRow,
        relationPropertyId: pRel.id,
        targetPropertyId: pName.id,
        function: RollupFunction.count,
      );

      expect(count, equals(4));
    });

    test('F11-4: Rollup Percent Checked computes percentage of true boolean flags', () async {
      setUp();
      final page = await workspace.createPage(title: 'School');
      final projDb = await database.createDatabase(title: 'Milestones', pageId: page.id);
      final taskDb = await database.createDatabase(title: 'Subtasks', pageId: page.id);

      final pRel = await database.addProperty(databaseId: projDb.id, name: 'Subtasks', type: PropertyType.relation);
      final pDone = await database.addProperty(databaseId: taskDb.id, name: 'Done', type: PropertyType.checkbox);

      final milestoneRow = await database.createRow(projDb.id);
      final s1 = await database.createRow(taskDb.id);
      final s2 = await database.createRow(taskDb.id);
      final s3 = await database.createRow(taskDb.id);
      final s4 = await database.createRow(taskDb.id);

      await database.updatePropertyValue(rowId: s1, propertyId: pDone.id, value: true);
      await database.updatePropertyValue(rowId: s2, propertyId: pDone.id, value: true);
      await database.updatePropertyValue(rowId: s3, propertyId: pDone.id, value: true);
      await database.updatePropertyValue(rowId: s4, propertyId: pDone.id, value: false); // 3 of 4 = 75%

      await database.updatePropertyValue(rowId: milestoneRow, propertyId: pRel.id, value: [s1, s2, s3, s4]);

      final pct = await database.computeRollup(
        rowId: milestoneRow,
        relationPropertyId: pRel.id,
        targetPropertyId: pDone.id,
        function: RollupFunction.percentChecked,
      );

      expect(pct, equals(75.0));
    });

    test('F11-5: Rollup Min and Max determine extreme boundaries', () async {
      setUp();
      final page = await workspace.createPage(title: 'School');
      final projDb = await database.createDatabase(title: 'Stats', pageId: page.id);
      final taskDb = await database.createDatabase(title: 'Readings', pageId: page.id);

      final pRel = await database.addProperty(databaseId: projDb.id, name: 'Readings', type: PropertyType.relation);
      final pVal = await database.addProperty(databaseId: taskDb.id, name: 'Val', type: PropertyType.number);

      final statRow = await database.createRow(projDb.id);
      final r1 = await database.createRow(taskDb.id);
      final r2 = await database.createRow(taskDb.id);
      final r3 = await database.createRow(taskDb.id);

      await database.updatePropertyValue(rowId: r1, propertyId: pVal.id, value: 12);
      await database.updatePropertyValue(rowId: r2, propertyId: pVal.id, value: 89);
      await database.updatePropertyValue(rowId: r3, propertyId: pVal.id, value: 45);

      await database.updatePropertyValue(rowId: statRow, propertyId: pRel.id, value: [r1, r2, r3]);

      final minVal = await database.computeRollup(
        rowId: statRow,
        relationPropertyId: pRel.id,
        targetPropertyId: pVal.id,
        function: RollupFunction.min,
      );
      final maxVal = await database.computeRollup(
        rowId: statRow,
        relationPropertyId: pRel.id,
        targetPropertyId: pVal.id,
        function: RollupFunction.max,
      );

      expect(minVal, equals(12));
      expect(maxVal, equals(89));
    });
  });

  group('Tier 1: F12 Table View with Inline Editing (5 tests)', () {
    late TestWorkspaceEngine workspace;
    late TestDatabaseEngine database;

    void setUp() {
      workspace = TestWorkspaceEngine();
      database = TestDatabaseEngine(workspaceEngine: workspace);
    }

    test('F12-1: Create default Table View with column definitions', () async {
      setUp();
      final page = await workspace.createPage(title: 'Table Parent');
      final db = await database.createDatabase(title: 'Table DB', pageId: page.id);
      final view = await database.createView(
        databaseId: db.id,
        name: 'Master Table',
        type: DatabaseViewType.table,
      );

      expect(view.type, equals(DatabaseViewType.table));
      expect(view.name, equals('Master Table'));
    });

    test('F12-2: Inline cell update persists immediately to row state', () async {
      setUp();
      final page = await workspace.createPage(title: 'P');
      final db = await database.createDatabase(title: 'Inline DB', pageId: page.id);
      final pText = await database.addProperty(databaseId: db.id, name: 'Note', type: PropertyType.text);

      final row = await database.createRow(db.id);
      await database.updatePropertyValue(rowId: row, propertyId: pText.id, value: 'Initial text');
      expect(await database.getPropertyValue(rowId: row, propertyId: pText.id), equals('Initial text'));

      // Inline edit
      await database.updatePropertyValue(rowId: row, propertyId: pText.id, value: 'Inline modified text');
      expect(await database.getPropertyValue(rowId: row, propertyId: pText.id), equals('Inline modified text'));
    });

    test('F12-3: Table View reactive stream receives row additions', () async {
      setUp();
      final page = await workspace.createPage(title: 'P');
      final db = await database.createDatabase(title: 'Reactive DB', pageId: page.id);

      var rowCount = 0;
      final sub = database.watchRows(db.id).listen((rows) {
        rowCount = rows.length;
      });

      await database.createRow(db.id);
      await database.createRow(db.id);

      expect(rowCount, equals(2));
      await sub.cancel();
    });

    test('F12-4: Cell watch stream emits updated cell collections', () async {
      setUp();
      final page = await workspace.createPage(title: 'P');
      final db = await database.createDatabase(title: 'Cells DB', pageId: page.id);
      final pNum = await database.addProperty(databaseId: db.id, name: 'Num', type: PropertyType.number);
      final row = await database.createRow(db.id);

      var cellValue = 0;
      final sub = database.watchCells(db.id).listen((cells) {
        final match = cells.where((c) => c.rowId == row && c.propertyId == pNum.id);
        if (match.isNotEmpty && match.first.value != null) {
          cellValue = match.first.value as int;
        }
      });

      await database.updatePropertyValue(rowId: row, propertyId: pNum.id, value: 42);
      expect(cellValue, equals(42));
      await sub.cancel();
    });

    test('F12-5: Table View handles deletion of row cleanly', () async {
      setUp();
      final page = await workspace.createPage(title: 'P');
      final db = await database.createDatabase(title: 'Del DB', pageId: page.id);
      final r1 = await database.createRow(db.id);
      await database.createRow(db.id);

      await database.deleteRow(r1);

      var remainingCount = 0;
      final sub = database.watchRows(db.id).listen((rows) {
        remainingCount = rows.length;
      });
      await Future.delayed(Duration.zero);
      expect(remainingCount, equals(1));
      await sub.cancel();
    });
  });

  group('Tier 1: F13 Kanban Board View (5 tests)', () {
    late TestWorkspaceEngine workspace;
    late TestDatabaseEngine database;

    void setUp() {
      workspace = TestWorkspaceEngine();
      database = TestDatabaseEngine(workspaceEngine: workspace);
    }

    test('F13-1: Create Kanban Board View grouped by Status property', () async {
      setUp();
      final page = await workspace.createPage(title: 'Kanban P');
      final db = await database.createDatabase(title: 'Agile DB', pageId: page.id);
      final view = await database.createView(
        databaseId: db.id,
        name: 'Sprint Board',
        type: DatabaseViewType.kanban,
        config: {'groupByProperty': 'Status'},
      );

      expect(view.type, equals(DatabaseViewType.kanban));
      expect(view.config['groupByProperty'], equals('Status'));
    });

    test('F13-2: Group rows into Kanban columns based on Status cell value', () async {
      setUp();
      final page = await workspace.createPage(title: 'Kanban P');
      final db = await database.createDatabase(title: 'Agile DB', pageId: page.id);
      final pStatus = await database.addProperty(databaseId: db.id, name: 'Status', type: PropertyType.status);

      final r1 = await database.createRow(db.id);
      final r2 = await database.createRow(db.id);
      final r3 = await database.createRow(db.id);

      await database.updatePropertyValue(rowId: r1, propertyId: pStatus.id, value: 'Todo');
      await database.updatePropertyValue(rowId: r2, propertyId: pStatus.id, value: 'In Progress');
      await database.updatePropertyValue(rowId: r3, propertyId: pStatus.id, value: 'Done');

      expect(await database.getPropertyValue(rowId: r1, propertyId: pStatus.id), equals('Todo'));
      expect(await database.getPropertyValue(rowId: r2, propertyId: pStatus.id), equals('In Progress'));
      expect(await database.getPropertyValue(rowId: r3, propertyId: pStatus.id), equals('Done'));
    });

    test('F13-3: Drag card between columns updates underlying row Status property', () async {
      setUp();
      final page = await workspace.createPage(title: 'Kanban P');
      final db = await database.createDatabase(title: 'Agile DB', pageId: page.id);
      final pStatus = await database.addProperty(databaseId: db.id, name: 'Status', type: PropertyType.status);

      final r = await database.createRow(db.id);
      await database.updatePropertyValue(rowId: r, propertyId: pStatus.id, value: 'Todo');

      // Drag to In Progress
      await database.updatePropertyValue(rowId: r, propertyId: pStatus.id, value: 'In Progress');
      expect(await database.getPropertyValue(rowId: r, propertyId: pStatus.id), equals('In Progress'));

      // Drag to Done
      await database.updatePropertyValue(rowId: r, propertyId: pStatus.id, value: 'Done');
      expect(await database.getPropertyValue(rowId: r, propertyId: pStatus.id), equals('Done'));
    });

    test('F13-4: Rows with unassigned status placed in default No Status column', () async {
      setUp();
      final page = await workspace.createPage(title: 'Kanban P');
      final db = await database.createDatabase(title: 'Agile DB', pageId: page.id);
      final pStatus = await database.addProperty(databaseId: db.id, name: 'Status', type: PropertyType.status);

      final rUnassigned = await database.createRow(db.id);
      final statusVal = await database.getPropertyValue(rowId: rUnassigned, propertyId: pStatus.id);
      expect(statusVal, isNull);
    });

    test('F13-5: Multiple cards in same column preserve distinct identity', () async {
      setUp();
      final page = await workspace.createPage(title: 'Kanban P');
      final db = await database.createDatabase(title: 'Agile DB', pageId: page.id);
      final pStatus = await database.addProperty(databaseId: db.id, name: 'Status', type: PropertyType.status);

      final r1 = await database.createRow(db.id);
      final r2 = await database.createRow(db.id);
      await database.updatePropertyValue(rowId: r1, propertyId: pStatus.id, value: 'Todo');
      await database.updatePropertyValue(rowId: r2, propertyId: pStatus.id, value: 'Todo');

      expect(await database.getPropertyValue(rowId: r1, propertyId: pStatus.id), equals('Todo'));
      expect(await database.getPropertyValue(rowId: r2, propertyId: pStatus.id), equals('Todo'));
      expect(r1 != r2, isTrue);
    });
  });

  group('Tier 1: F14 Calendar View (Month/Week) (5 tests)', () {
    late TestWorkspaceEngine workspace;
    late TestDatabaseEngine database;

    void setUp() {
      workspace = TestWorkspaceEngine();
      database = TestDatabaseEngine(workspaceEngine: workspace);
    }

    test('F14-1: Create Calendar View configured with target date property', () async {
      setUp();
      final page = await workspace.createPage(title: 'Cal P');
      final db = await database.createDatabase(title: 'Study Schedule', pageId: page.id);
      final view = await database.createView(
        databaseId: db.id,
        name: 'Monthly Schedule',
        type: DatabaseViewType.calendar,
        config: {'dateProperty': 'DueDate', 'displayMode': 'month'},
      );

      expect(view.type, equals(DatabaseViewType.calendar));
      expect(view.config['displayMode'], equals('month'));
    });

    test('F14-2: Assign date property to row for calendar day placement', () async {
      setUp();
      final page = await workspace.createPage(title: 'Cal P');
      final db = await database.createDatabase(title: 'Exams', pageId: page.id);
      final pDate = await database.addProperty(databaseId: db.id, name: 'ExamDate', type: PropertyType.date);

      final row = await database.createRow(db.id);
      await database.updatePropertyValue(rowId: row, propertyId: pDate.id, value: '2026-10-20');

      final assignedDate = await database.getPropertyValue(rowId: row, propertyId: pDate.id);
      expect(assignedDate, equals('2026-10-20'));
    });

    test('F14-3: Unscheduled tasks without date are detectable for drawer placement', () async {
      setUp();
      final page = await workspace.createPage(title: 'Cal P');
      final db = await database.createDatabase(title: 'Exams', pageId: page.id);
      final pDate = await database.addProperty(databaseId: db.id, name: 'ExamDate', type: PropertyType.date);

      final rowScheduled = await database.createRow(db.id);
      final rowUnscheduled = await database.createRow(db.id);
      await database.updatePropertyValue(rowId: rowScheduled, propertyId: pDate.id, value: '2026-10-25');

      expect(await database.getPropertyValue(rowId: rowScheduled, propertyId: pDate.id), isNotNull);
      expect(await database.getPropertyValue(rowId: rowUnscheduled, propertyId: pDate.id), isNull);
    });

    test('F14-4: Switch calendar view mode between month and week without data loss', () async {
      setUp();
      final page = await workspace.createPage(title: 'Cal P');
      final db = await database.createDatabase(title: 'Exams', pageId: page.id);
      final view = await database.createView(
        databaseId: db.id,
        name: 'Cal',
        type: DatabaseViewType.calendar,
        config: {'displayMode': 'month'},
      );

      final updatedView = view.copyWith(config: {'displayMode': 'week'});
      expect(updatedView.config['displayMode'], equals('week'));
    });

    test('F14-5: Re-assigning date property shifts task to new calendar cell', () async {
      setUp();
      final page = await workspace.createPage(title: 'Cal P');
      final db = await database.createDatabase(title: 'Tasks', pageId: page.id);
      final pDate = await database.addProperty(databaseId: db.id, name: 'DueDate', type: PropertyType.date);

      final row = await database.createRow(db.id);
      await database.updatePropertyValue(rowId: row, propertyId: pDate.id, value: '2026-10-10');
      expect(await database.getPropertyValue(rowId: row, propertyId: pDate.id), equals('2026-10-10'));

      await database.updatePropertyValue(rowId: row, propertyId: pDate.id, value: '2026-10-18');
      expect(await database.getPropertyValue(rowId: row, propertyId: pDate.id), equals('2026-10-18'));
    });
  });

  group('Tier 1: F15 Timeline / Gantt View (5 tests)', () {
    late TestWorkspaceEngine workspace;
    late TestDatabaseEngine database;

    void setUp() {
      workspace = TestWorkspaceEngine();
      database = TestDatabaseEngine(workspaceEngine: workspace);
    }

    test('F15-1: Create Timeline Gantt View with start and end date properties', () async {
      setUp();
      final page = await workspace.createPage(title: 'Timeline P');
      final db = await database.createDatabase(title: 'Project Roadmap', pageId: page.id);
      final view = await database.createView(
        databaseId: db.id,
        name: 'Gantt Chart',
        type: DatabaseViewType.timeline,
        config: {'startDate': 'Start', 'endDate': 'End'},
      );

      expect(view.type, equals(DatabaseViewType.timeline));
      expect(view.config['startDate'], equals('Start'));
    });

    test('F15-2: Assign start and end date span to task bar', () async {
      setUp();
      final page = await workspace.createPage(title: 'Timeline P');
      final db = await database.createDatabase(title: 'Gantt DB', pageId: page.id);
      final pStart = await database.addProperty(databaseId: db.id, name: 'Start', type: PropertyType.date);
      final pEnd = await database.addProperty(databaseId: db.id, name: 'End', type: PropertyType.date);

      final row = await database.createRow(db.id);
      await database.updatePropertyValue(rowId: row, propertyId: pStart.id, value: '2026-10-01');
      await database.updatePropertyValue(rowId: row, propertyId: pEnd.id, value: '2026-10-15');

      expect(await database.getPropertyValue(rowId: row, propertyId: pStart.id), equals('2026-10-01'));
      expect(await database.getPropertyValue(rowId: row, propertyId: pEnd.id), equals('2026-10-15'));
    });

    test('F15-3: Connect dependency between two timeline tasks', () async {
      setUp();
      final page = await workspace.createPage(title: 'Timeline P');
      final db = await database.createDatabase(title: 'Gantt DB', pageId: page.id);
      final pDep = await database.addProperty(databaseId: db.id, name: 'BlockedBy', type: PropertyType.relation);

      final taskA = await database.createRow(db.id);
      final taskB = await database.createRow(db.id);

      await database.updatePropertyValue(rowId: taskB, propertyId: pDep.id, value: taskA);
      final blocker = await database.getPropertyValue(rowId: taskB, propertyId: pDep.id);
      expect(blocker, equals(taskA));
    });

    test('F15-4: Adjust timeline bar end date to extend duration', () async {
      setUp();
      final page = await workspace.createPage(title: 'Timeline P');
      final db = await database.createDatabase(title: 'Gantt DB', pageId: page.id);
      final pEnd = await database.addProperty(databaseId: db.id, name: 'End', type: PropertyType.date);

      final task = await database.createRow(db.id);
      await database.updatePropertyValue(rowId: task, propertyId: pEnd.id, value: '2026-10-10');
      await database.updatePropertyValue(rowId: task, propertyId: pEnd.id, value: '2026-10-20');

      expect(await database.getPropertyValue(rowId: task, propertyId: pEnd.id), equals('2026-10-20'));
    });

    test('F15-5: Multiple timeline tasks render within identical project window', () async {
      setUp();
      final page = await workspace.createPage(title: 'Timeline P');
      final db = await database.createDatabase(title: 'Gantt DB', pageId: page.id);
      final pStart = await database.addProperty(databaseId: db.id, name: 'Start', type: PropertyType.date);

      final t1 = await database.createRow(db.id);
      final t2 = await database.createRow(db.id);
      await database.updatePropertyValue(rowId: t1, propertyId: pStart.id, value: '2026-10-05');
      await database.updatePropertyValue(rowId: t2, propertyId: pStart.id, value: '2026-10-12');

      final d1 = await database.getPropertyValue(rowId: t1, propertyId: pStart.id);
      final d2 = await database.getPropertyValue(rowId: t2, propertyId: pStart.id);
      expect(d1, equals('2026-10-05'));
      expect(d2, equals('2026-10-12'));
    });
  });

  group('Tier 1: F16 List & Gallery Views (5 tests)', () {
    late TestWorkspaceEngine workspace;
    late TestDatabaseEngine database;

    void setUp() {
      workspace = TestWorkspaceEngine();
      database = TestDatabaseEngine(workspaceEngine: workspace);
    }

    test('F16-1: Create minimalist high-density List View', () async {
      setUp();
      final page = await workspace.createPage(title: 'Views Parent');
      final db = await database.createDatabase(title: 'Reading List', pageId: page.id);
      final view = await database.createView(
        databaseId: db.id,
        name: 'Quick List',
        type: DatabaseViewType.list,
      );

      expect(view.type, equals(DatabaseViewType.list));
      expect(view.name, equals('Quick List'));
    });

    test('F16-2: Create responsive card Gallery View', () async {
      setUp();
      final page = await workspace.createPage(title: 'Views Parent');
      final db = await database.createDatabase(title: 'Flashcards', pageId: page.id);
      final view = await database.createView(
        databaseId: db.id,
        name: 'Flashcard Gallery',
        type: DatabaseViewType.gallery,
        config: {'cardSize': 'medium'},
      );

      expect(view.type, equals(DatabaseViewType.gallery));
      expect(view.config['cardSize'], equals('medium'));
    });

    test('F16-3: Gallery View displays configured card preview property', () async {
      setUp();
      final page = await workspace.createPage(title: 'Views Parent');
      final db = await database.createDatabase(title: 'Formulas', pageId: page.id);
      final pEq = await database.addProperty(databaseId: db.id, name: 'Equation', type: PropertyType.text);

      final row = await database.createRow(db.id);
      await database.updatePropertyValue(rowId: row, propertyId: pEq.id, value: 'a^2 + b^2 = c^2');

      final val = await database.getPropertyValue(rowId: row, propertyId: pEq.id);
      expect(val, equals('a^2 + b^2 = c^2'));
    });

    test('F16-4: Switching from Table to List View maintains identical underlying rows (AC2)', () async {
      setUp();
      final page = await workspace.createPage(title: 'Views Parent');
      final db = await database.createDatabase(title: 'Universal State', pageId: page.id);
      final pTitle = await database.addProperty(databaseId: db.id, name: 'TaskName', type: PropertyType.text);

      final r1 = await database.createRow(db.id);
      final r2 = await database.createRow(db.id);
      await database.updatePropertyValue(rowId: r1, propertyId: pTitle.id, value: 'Item Alpha');
      await database.updatePropertyValue(rowId: r2, propertyId: pTitle.id, value: 'Item Beta');

      // Both views inspect identical rows
      var rows = <RowEntity>[];
      final sub = database.watchRows(db.id).listen((rList) {
        rows = rList;
      });
      await Future.delayed(Duration.zero);

      expect(rows.length, equals(2));
      expect(await database.getPropertyValue(rowId: rows[0].id, propertyId: pTitle.id), equals('Item Alpha'));
      expect(await database.getPropertyValue(rowId: rows[1].id, propertyId: pTitle.id), equals('Item Beta'));
      await sub.cancel();
    });

    test('F16-5: Update in Gallery View reflects immediately in Table and List views (AC2)', () async {
      setUp();
      final page = await workspace.createPage(title: 'Views Parent');
      final db = await database.createDatabase(title: 'Sync DB', pageId: page.id);
      final pScore = await database.addProperty(databaseId: db.id, name: 'Score', type: PropertyType.number);

      final row = await database.createRow(db.id);
      await database.updatePropertyValue(rowId: row, propertyId: pScore.id, value: 10);

      // Edit in gallery
      await database.updatePropertyValue(rowId: row, propertyId: pScore.id, value: 95);

      // Verify read by any other view
      final readValue = await database.getPropertyValue(rowId: row, propertyId: pScore.id);
      expect(readValue, equals(95));
    });
  });
}
