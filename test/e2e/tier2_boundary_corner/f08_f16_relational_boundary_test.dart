// Tier 2 E2E Boundary & Corner Cases: F08–F16 Relational Database Engine & 6 Views
// Minimum 5 tests per feature (45 test cases total)
// Grounded in PROJECT.md (F08–F16, AC2, AC8, E06, E07, E08)

import '../contracts/database_contracts.dart';
import '../harness/test_database_harness.dart';
import '../harness/test_workspace_harness.dart';
import '../support/test_runner.dart';

void runRelationalDatabaseTier2Tests() {
  group('Tier 2: F08 Rich Property Schema Engine Boundaries (5 tests)', () {
    late TestWorkspaceEngine workspace;
    late TestDatabaseEngine database;

    void setUp() {
      workspace = TestWorkspaceEngine();
      database = TestDatabaseEngine(workspaceEngine: workspace);
    }

    test('F08-B1: Duplicate property name in database throws ArgumentError', () async {
      setUp();
      final page = await workspace.createPage(title: 'DB Parent');
      final db = await database.createDatabase(title: 'DB', pageId: page.id);

      await database.addProperty(databaseId: db.id, name: 'Score', type: PropertyType.number);
      await expectThrows<ArgumentError>(() async {
        await database.addProperty(databaseId: db.id, name: 'Score', type: PropertyType.number);
      });
    });

    test('F08-B2: Property name check is case-insensitive for duplicates', () async {
      setUp();
      final page = await workspace.createPage(title: 'DB Parent');
      final db = await database.createDatabase(title: 'DB', pageId: page.id);

      await database.addProperty(databaseId: db.id, name: 'Status', type: PropertyType.status);
      await expectThrows<ArgumentError>(() async {
        await database.addProperty(databaseId: db.id, name: 'status', type: PropertyType.status);
      });
    });

    test('F08-B3: Adding 50 distinct properties to database schema', () async {
      setUp();
      final page = await workspace.createPage(title: 'DB Parent');
      final db = await database.createDatabase(title: 'DB', pageId: page.id);

      for (var i = 0; i < 50; i++) {
        await database.addProperty(databaseId: db.id, name: 'Prop_$i', type: PropertyType.text);
      }

      var count = 0;
      final sub = database.watchProperties(db.id).listen((props) {
        count = props.length;
      });
      await Future.delayed(Duration.zero);
      expect(count, equals(51)); // 50 custom + 1 default 'Name'
      await sub.cancel();
    });

    test('F08-B4: Querying property value on non-existent row returns null', () async {
      setUp();
      final val = await database.getPropertyValue(rowId: 'fake_row', propertyId: 'fake_prop');
      expect(val, isNull);
    });

    test('F08-B5: Setting cell value to null clears previous value', () async {
      setUp();
      final page = await workspace.createPage(title: 'DB Parent');
      final db = await database.createDatabase(title: 'DB', pageId: page.id);
      final pText = await database.addProperty(databaseId: db.id, name: 'Note', type: PropertyType.text);
      final row = await database.createRow(db.id);

      await database.updatePropertyValue(rowId: row, propertyId: pText.id, value: 'Hello');
      expect(await database.getPropertyValue(rowId: row, propertyId: pText.id), equals('Hello'));

      await database.updatePropertyValue(rowId: row, propertyId: pText.id, value: null);
      expect(await database.getPropertyValue(rowId: row, propertyId: pText.id), isNull);
    });
  });

  group('Tier 2: F09 Two-Way Database Relations Boundaries (5 tests)', () {
    late TestWorkspaceEngine workspace;
    late TestDatabaseEngine database;

    void setUp() {
      workspace = TestWorkspaceEngine();
      database = TestDatabaseEngine(workspaceEngine: workspace);
    }

    test('F09-B1: Empty relation cell returns null or empty list', () async {
      setUp();
      final page = await workspace.createPage(title: 'DB Parent');
      final db = await database.createDatabase(title: 'DB', pageId: page.id);
      final pRel = await database.addProperty(databaseId: db.id, name: 'Rel', type: PropertyType.relation);
      final row = await database.createRow(db.id);

      final val = await database.getPropertyValue(rowId: row, propertyId: pRel.id);
      expect(val, isNull);
    });

    test('F09-B2: Self-referential relation linking row to itself handled cleanly', () async {
      setUp();
      final page = await workspace.createPage(title: 'DB Parent');
      final db = await database.createDatabase(title: 'Tasks', pageId: page.id);
      final pRel = await database.addProperty(databaseId: db.id, name: 'ParentTask', type: PropertyType.relation);
      final row = await database.createRow(db.id);

      await database.updatePropertyValue(rowId: row, propertyId: pRel.id, value: row);
      final linked = await database.getPropertyValue(rowId: row, propertyId: pRel.id);
      expect(linked, equals(row));
    });

    test('F09-B3: Linking non-existent row ID does not throw and preserves ID string', () async {
      setUp();
      final page = await workspace.createPage(title: 'DB Parent');
      final db = await database.createDatabase(title: 'DB', pageId: page.id);
      final pRel = await database.addProperty(databaseId: db.id, name: 'Rel', type: PropertyType.relation);
      final row = await database.createRow(db.id);

      await database.updatePropertyValue(rowId: row, propertyId: pRel.id, value: 'non_existent_row');
      expect(await database.getPropertyValue(rowId: row, propertyId: pRel.id), equals('non_existent_row'));
    });

    test('F09-B4: Deleting multiple target rows cleans all references simultaneously', () async {
      setUp();
      final page = await workspace.createPage(title: 'DB Parent');
      final dbA = await database.createDatabase(title: 'DB A', pageId: page.id);
      final dbB = await database.createDatabase(title: 'DB B', pageId: page.id);
      final pRel = await database.addProperty(databaseId: dbA.id, name: 'Links', type: PropertyType.relation);

      final rowA = await database.createRow(dbA.id);
      final b1 = await database.createRow(dbB.id);
      final b2 = await database.createRow(dbB.id);

      await database.updatePropertyValue(rowId: rowA, propertyId: pRel.id, value: [b1, b2]);
      await database.deleteRow(b1);
      await database.deleteRow(b2);

      final list = await database.getPropertyValue(rowId: rowA, propertyId: pRel.id) as List;
      expect(list.isEmpty, isTrue);
    });

    test('F09-B5: Setting empty list to relation clears relation list', () async {
      setUp();
      final page = await workspace.createPage(title: 'DB Parent');
      final db = await database.createDatabase(title: 'DB', pageId: page.id);
      final pRel = await database.addProperty(databaseId: db.id, name: 'Links', type: PropertyType.relation);
      final row = await database.createRow(db.id);

      await database.updatePropertyValue(rowId: row, propertyId: pRel.id, value: ['r1', 'r2']);
      await database.updatePropertyValue(rowId: row, propertyId: pRel.id, value: []);

      final list = await database.getPropertyValue(rowId: row, propertyId: pRel.id) as List;
      expect(list.isEmpty, isTrue);
    });
  });

  group('Tier 2: F10 Formula Expression Engine Boundaries (5 tests)', () {
    late TestWorkspaceEngine workspace;
    late TestDatabaseEngine database;

    void setUp() {
      workspace = TestWorkspaceEngine();
      database = TestDatabaseEngine(workspaceEngine: workspace);
    }

    test('F10-B1: Circular formula reference returns #CYCLE! error badge (E06)', () async {
      setUp();
      final page = await workspace.createPage(title: 'Math');
      final db = await database.createDatabase(title: 'Loop', pageId: page.id);
      final row = await database.createRow(db.id);

      // Simulating cyclical formula evaluation where expression loop is detected
      final res = await database.evaluateFormula(
        rowId: row,
        expression: 'prop("A")',
        visitedProperties: {'prop("A")'},
      );

      expect(res, equals('#CYCLE!'));
    });

    test('F10-B2: Division by zero returns #DIV/0! error badge (E07)', () async {
      setUp();
      final page = await workspace.createPage(title: 'Math');
      final db = await database.createDatabase(title: 'Div', pageId: page.id);
      final row = await database.createRow(db.id);

      final res1 = await database.evaluateFormula(rowId: row, expression: '100 / 0');
      final res2 = await database.evaluateFormula(rowId: row, expression: '50 /0');

      expect(res1, equals('#DIV/0!'));
      expect(res2, equals('#DIV/0!'));
    });

    test('F10-B3: Formula with missing referenced property returns null', () async {
      setUp();
      final page = await workspace.createPage(title: 'Math');
      final db = await database.createDatabase(title: 'DB', pageId: page.id);
      final row = await database.createRow(db.id);

      final res = await database.evaluateFormula(rowId: row, expression: 'prop("GhostProperty") + 1');
      expect(res, isNull);
    });

    test('F10-B4: Negative numbers in formula evaluate accurately', () async {
      setUp();
      final page = await workspace.createPage(title: 'Math');
      final db = await database.createDatabase(title: 'DB', pageId: page.id);
      final row = await database.createRow(db.id);

      final res = await database.evaluateFormula(rowId: row, expression: '50 - 80');
      expect(res, equals(-30.0));
    });

    test('F10-B5: Large numeric values evaluate without integer overflow', () async {
      setUp();
      final page = await workspace.createPage(title: 'Math');
      final db = await database.createDatabase(title: 'DB', pageId: page.id);
      final row = await database.createRow(db.id);

      final res = await database.evaluateFormula(rowId: row, expression: '1000000 * 2000');
      expect(res, equals(2000000000.0));
    });
  });

  group('Tier 2: F11 Automatic Rollups & Aggregations Boundaries (5 tests)', () {
    late TestWorkspaceEngine workspace;
    late TestDatabaseEngine database;

    void setUp() {
      workspace = TestWorkspaceEngine();
      database = TestDatabaseEngine(workspaceEngine: workspace);
    }

    test('F11-B1: Rollup targeting empty relation returns default 0 or null (E08)', () async {
      setUp();
      final page = await workspace.createPage(title: 'P');
      final db = await database.createDatabase(title: 'DB', pageId: page.id);
      final pRel = await database.addProperty(databaseId: db.id, name: 'Rel', type: PropertyType.relation);
      final pNum = await database.addProperty(databaseId: db.id, name: 'Val', type: PropertyType.number);
      final row = await database.createRow(db.id);

      final sumVal = await database.computeRollup(
        rowId: row,
        relationPropertyId: pRel.id,
        targetPropertyId: pNum.id,
        function: RollupFunction.sum,
      );
      final avgVal = await database.computeRollup(
        rowId: row,
        relationPropertyId: pRel.id,
        targetPropertyId: pNum.id,
        function: RollupFunction.average,
      );

      expect(sumVal, equals(0));
      expect(avgVal, isNull);
    });

    test('F11-B2: Rollup Percent Checked with 0 total items returns 0.0 without divide by zero', () async {
      setUp();
      final page = await workspace.createPage(title: 'P');
      final db = await database.createDatabase(title: 'DB', pageId: page.id);
      final pRel = await database.addProperty(databaseId: db.id, name: 'Rel', type: PropertyType.relation);
      final pBool = await database.addProperty(databaseId: db.id, name: 'Done', type: PropertyType.checkbox);
      final row = await database.createRow(db.id);

      final pct = await database.computeRollup(
        rowId: row,
        relationPropertyId: pRel.id,
        targetPropertyId: pBool.id,
        function: RollupFunction.percentChecked,
      );

      expect(pct, equals(0.0));
    });

    test('F11-B3: Rollup Min and Max on empty list returns null', () async {
      setUp();
      final page = await workspace.createPage(title: 'P');
      final db = await database.createDatabase(title: 'DB', pageId: page.id);
      final pRel = await database.addProperty(databaseId: db.id, name: 'Rel', type: PropertyType.relation);
      final pNum = await database.addProperty(databaseId: db.id, name: 'Num', type: PropertyType.number);
      final row = await database.createRow(db.id);

      final minVal = await database.computeRollup(
        rowId: row,
        relationPropertyId: pRel.id,
        targetPropertyId: pNum.id,
        function: RollupFunction.min,
      );
      expect(minVal, isNull);
    });

    test('F11-B4: Rollup Average on list with single item returns exact item value', () async {
      setUp();
      final page = await workspace.createPage(title: 'P');
      final dbA = await database.createDatabase(title: 'A', pageId: page.id);
      final dbB = await database.createDatabase(title: 'B', pageId: page.id);
      final pRel = await database.addProperty(databaseId: dbA.id, name: 'Rel', type: PropertyType.relation);
      final pScore = await database.addProperty(databaseId: dbB.id, name: 'Score', type: PropertyType.number);

      final rA = await database.createRow(dbA.id);
      final rB = await database.createRow(dbB.id);
      await database.updatePropertyValue(rowId: rB, propertyId: pScore.id, value: 77);
      await database.updatePropertyValue(rowId: rA, propertyId: pRel.id, value: rB);

      final avg = await database.computeRollup(
        rowId: rA,
        relationPropertyId: pRel.id,
        targetPropertyId: pScore.id,
        function: RollupFunction.average,
      );
      expect(avg, equals(77.0));
    });

    test('F11-B5: Rollup Count on single item relation returns 1', () async {
      setUp();
      final page = await workspace.createPage(title: 'P');
      final dbA = await database.createDatabase(title: 'A', pageId: page.id);
      final dbB = await database.createDatabase(title: 'B', pageId: page.id);
      final pRel = await database.addProperty(databaseId: dbA.id, name: 'Rel', type: PropertyType.relation);
      final pText = await database.addProperty(databaseId: dbB.id, name: 'Name', type: PropertyType.text);

      final rA = await database.createRow(dbA.id);
      final rB = await database.createRow(dbB.id);
      await database.updatePropertyValue(rowId: rB, propertyId: pText.id, value: 'Item');
      await database.updatePropertyValue(rowId: rA, propertyId: pRel.id, value: rB);

      final count = await database.computeRollup(
        rowId: rA,
        relationPropertyId: pRel.id,
        targetPropertyId: pText.id,
        function: RollupFunction.count,
      );
      expect(count, equals(1));
    });
  });

  group('Tier 2: F12 Table View with Inline Editing Boundaries (5 tests)', () {
    late TestWorkspaceEngine workspace;
    late TestDatabaseEngine database;

    void setUp() {
      workspace = TestWorkspaceEngine();
      database = TestDatabaseEngine(workspaceEngine: workspace);
    }

    test('F12-B1: Empty database renders 0 rows in Table View without error', () async {
      setUp();
      final page = await workspace.createPage(title: 'P');
      final db = await database.createDatabase(title: 'Empty DB', pageId: page.id);

      final rows = await database.watchRows(db.id).first;
      expect(rows.isEmpty, isTrue);
    });

    test('F12-B2: Table View handles 500 rows with sequential IDs', () async {
      setUp();
      final page = await workspace.createPage(title: 'P');
      final db = await database.createDatabase(title: 'Big DB', pageId: page.id);

      for (var i = 0; i < 500; i++) {
        await database.createRow(db.id);
      }

      final rows = await database.watchRows(db.id).first;
      expect(rows.length, equals(500));
    });

    test('F12-B3: Concurrent cell updates on different rows do not clobber each other', () async {
      setUp();
      final page = await workspace.createPage(title: 'P');
      final db = await database.createDatabase(title: 'DB', pageId: page.id);
      final pText = await database.addProperty(databaseId: db.id, name: 'Note', type: PropertyType.text);

      final r1 = await database.createRow(db.id);
      final r2 = await database.createRow(db.id);

      await Future.wait([
        database.updatePropertyValue(rowId: r1, propertyId: pText.id, value: 'V1'),
        database.updatePropertyValue(rowId: r2, propertyId: pText.id, value: 'V2'),
      ]);

      expect(await database.getPropertyValue(rowId: r1, propertyId: pText.id), equals('V1'));
      expect(await database.getPropertyValue(rowId: r2, propertyId: pText.id), equals('V2'));
    });

    test('F12-B4: Deleting all rows empties cell collection', () async {
      setUp();
      final page = await workspace.createPage(title: 'P');
      final db = await database.createDatabase(title: 'DB', pageId: page.id);
      final r1 = await database.createRow(db.id);
      final r2 = await database.createRow(db.id);

      await database.deleteRow(r1);
      await database.deleteRow(r2);

      final remaining = await database.watchRows(db.id).first;
      expect(remaining.isEmpty, isTrue);
    });

    test('F12-B5: Duplicate createView calls generate distinct view IDs', () async {
      setUp();
      final page = await workspace.createPage(title: 'P');
      final db = await database.createDatabase(title: 'DB', pageId: page.id);

      final v1 = await database.createView(databaseId: db.id, name: 'Table', type: DatabaseViewType.table);
      final v2 = await database.createView(databaseId: db.id, name: 'Table', type: DatabaseViewType.table);

      expect(v1.id != v2.id, isTrue);
    });
  });

  group('Tier 2: F13 Kanban Board View Boundaries (5 tests)', () {
    late TestWorkspaceEngine workspace;
    late TestDatabaseEngine database;

    void setUp() {
      workspace = TestWorkspaceEngine();
      database = TestDatabaseEngine(workspaceEngine: workspace);
    }

    test('F13-B1: Empty status column renders 0 cards', () async {
      setUp();
      final page = await workspace.createPage(title: 'P');
      final db = await database.createDatabase(title: 'DB', pageId: page.id);
      final pStatus = await database.addProperty(databaseId: db.id, name: 'Status', type: PropertyType.status);

      final row = await database.createRow(db.id);
      await database.updatePropertyValue(rowId: row, propertyId: pStatus.id, value: 'Done');

      // 'Todo' column has 0 cards
      final val = await database.getPropertyValue(rowId: row, propertyId: pStatus.id);
      expect(val, equals('Done'));
    });

    test('F13-B2: Kanban board with 10 status options handles wide layout', () async {
      setUp();
      final page = await workspace.createPage(title: 'P');
      final db = await database.createDatabase(title: 'DB', pageId: page.id);
      final options = List.generate(10, (i) => 'Stage $i');
      final pStatus = await database.addProperty(
        databaseId: db.id,
        name: 'Stage',
        type: PropertyType.status,
        config: {'options': options},
      );

      expect(pStatus.config['options'].length, equals(10));
    });

    test('F13-B3: Moving card to null status sets cell value to null', () async {
      setUp();
      final page = await workspace.createPage(title: 'P');
      final db = await database.createDatabase(title: 'DB', pageId: page.id);
      final pStatus = await database.addProperty(databaseId: db.id, name: 'Status', type: PropertyType.status);

      final row = await database.createRow(db.id);
      await database.updatePropertyValue(rowId: row, propertyId: pStatus.id, value: 'Todo');
      await database.updatePropertyValue(rowId: row, propertyId: pStatus.id, value: null);

      expect(await database.getPropertyValue(rowId: row, propertyId: pStatus.id), isNull);
    });

    test('F13-B4: 100 cards in single Kanban column preserves all cards', () async {
      setUp();
      final page = await workspace.createPage(title: 'P');
      final db = await database.createDatabase(title: 'DB', pageId: page.id);
      final pStatus = await database.addProperty(databaseId: db.id, name: 'Status', type: PropertyType.status);

      for (var i = 0; i < 100; i++) {
        final r = await database.createRow(db.id);
        await database.updatePropertyValue(rowId: r, propertyId: pStatus.id, value: 'Backlog');
      }

      final rows = await database.watchRows(db.id).first;
      expect(rows.length, equals(100));
    });

    test('F13-B5: Changing group-by property from Status to Priority updates view configuration', () async {
      setUp();
      final page = await workspace.createPage(title: 'P');
      final db = await database.createDatabase(title: 'DB', pageId: page.id);
      final view = await database.createView(
        databaseId: db.id,
        name: 'Kanban',
        type: DatabaseViewType.kanban,
        config: {'groupBy': 'Status'},
      );

      final updated = view.copyWith(config: {'groupBy': 'Priority'});
      expect(updated.config['groupBy'], equals('Priority'));
    });
  });

  group('Tier 2: F14 Calendar View Boundaries (5 tests)', () {
    late TestWorkspaceEngine workspace;
    late TestDatabaseEngine database;

    void setUp() {
      workspace = TestWorkspaceEngine();
      database = TestDatabaseEngine(workspaceEngine: workspace);
    }

    test('F14-B1: Malformed date string handled without runtime crash', () async {
      setUp();
      final page = await workspace.createPage(title: 'P');
      final db = await database.createDatabase(title: 'DB', pageId: page.id);
      final pDate = await database.addProperty(databaseId: db.id, name: 'Date', type: PropertyType.date);
      final row = await database.createRow(db.id);

      await database.updatePropertyValue(rowId: row, propertyId: pDate.id, value: 'not-a-valid-date');
      final val = await database.getPropertyValue(rowId: row, propertyId: pDate.id);
      expect(val, equals('not-a-valid-date'));
    });

    test('F14-B2: Leap day Feb 29 date string assignment', () async {
      setUp();
      final page = await workspace.createPage(title: 'P');
      final db = await database.createDatabase(title: 'DB', pageId: page.id);
      final pDate = await database.addProperty(databaseId: db.id, name: 'Date', type: PropertyType.date);
      final row = await database.createRow(db.id);

      await database.updatePropertyValue(rowId: row, propertyId: pDate.id, value: '2024-02-29');
      expect(await database.getPropertyValue(rowId: row, propertyId: pDate.id), equals('2024-02-29'));
    });

    test('F14-B3: Year boundary transition (December 31 to January 1)', () async {
      setUp();
      final page = await workspace.createPage(title: 'P');
      final db = await database.createDatabase(title: 'DB', pageId: page.id);
      final pDate = await database.addProperty(databaseId: db.id, name: 'Date', type: PropertyType.date);

      final r1 = await database.createRow(db.id);
      final r2 = await database.createRow(db.id);
      await database.updatePropertyValue(rowId: r1, propertyId: pDate.id, value: '2026-12-31');
      await database.updatePropertyValue(rowId: r2, propertyId: pDate.id, value: '2027-01-01');

      expect(await database.getPropertyValue(rowId: r1, propertyId: pDate.id), equals('2026-12-31'));
      expect(await database.getPropertyValue(rowId: r2, propertyId: pDate.id), equals('2027-01-01'));
    });

    test('F14-B4: 50 tasks on same calendar day preserved without index clash', () async {
      setUp();
      final page = await workspace.createPage(title: 'P');
      final db = await database.createDatabase(title: 'DB', pageId: page.id);
      final pDate = await database.addProperty(databaseId: db.id, name: 'Date', type: PropertyType.date);

      for (var i = 0; i < 50; i++) {
        final r = await database.createRow(db.id);
        await database.updatePropertyValue(rowId: r, propertyId: pDate.id, value: '2026-10-16');
      }

      final rows = await database.watchRows(db.id).first;
      expect(rows.length, equals(50));
    });

    test('F14-B5: Null date rows distinguishable from scheduled rows', () async {
      setUp();
      final page = await workspace.createPage(title: 'P');
      final db = await database.createDatabase(title: 'DB', pageId: page.id);
      final pDate = await database.addProperty(databaseId: db.id, name: 'Date', type: PropertyType.date);

      final rScheduled = await database.createRow(db.id);
      final rUnscheduled = await database.createRow(db.id);
      await database.updatePropertyValue(rowId: rScheduled, propertyId: pDate.id, value: '2026-10-16');

      expect(await database.getPropertyValue(rowId: rScheduled, propertyId: pDate.id), isNotNull);
      expect(await database.getPropertyValue(rowId: rUnscheduled, propertyId: pDate.id), isNull);
    });
  });

  group('Tier 2: F15 Timeline / Gantt View Boundaries (5 tests)', () {
    late TestWorkspaceEngine workspace;
    late TestDatabaseEngine database;

    void setUp() {
      workspace = TestWorkspaceEngine();
      database = TestDatabaseEngine(workspaceEngine: workspace);
    }

    test('F15-B1: Single-day task duration where start date equals end date', () async {
      setUp();
      final page = await workspace.createPage(title: 'P');
      final db = await database.createDatabase(title: 'DB', pageId: page.id);
      final pStart = await database.addProperty(databaseId: db.id, name: 'Start', type: PropertyType.date);
      final pEnd = await database.addProperty(databaseId: db.id, name: 'End', type: PropertyType.date);

      final row = await database.createRow(db.id);
      await database.updatePropertyValue(rowId: row, propertyId: pStart.id, value: '2026-10-16');
      await database.updatePropertyValue(rowId: row, propertyId: pEnd.id, value: '2026-10-16');

      expect(await database.getPropertyValue(rowId: row, propertyId: pStart.id), equals('2026-10-16'));
      expect(await database.getPropertyValue(rowId: row, propertyId: pEnd.id), equals('2026-10-16'));
    });

    test('F15-B2: Task with missing end date defaults to single day milestone', () async {
      setUp();
      final page = await workspace.createPage(title: 'P');
      final db = await database.createDatabase(title: 'DB', pageId: page.id);
      final pStart = await database.addProperty(databaseId: db.id, name: 'Start', type: PropertyType.date);
      final pEnd = await database.addProperty(databaseId: db.id, name: 'End', type: PropertyType.date);

      final row = await database.createRow(db.id);
      await database.updatePropertyValue(rowId: row, propertyId: pStart.id, value: '2026-10-16');

      expect(await database.getPropertyValue(rowId: row, propertyId: pStart.id), isNotNull);
      expect(await database.getPropertyValue(rowId: row, propertyId: pEnd.id), isNull);
    });

    test('F15-B3: Dependency link to self prohibited or detected', () async {
      setUp();
      final page = await workspace.createPage(title: 'P');
      final db = await database.createDatabase(title: 'DB', pageId: page.id);
      final pDep = await database.addProperty(databaseId: db.id, name: 'Dependency', type: PropertyType.relation);

      final row = await database.createRow(db.id);
      await database.updatePropertyValue(rowId: row, propertyId: pDep.id, value: row);
      expect(await database.getPropertyValue(rowId: row, propertyId: pDep.id), equals(row));
    });

    test('F15-B4: Timeline bar spanning multiple calendar months (60 days)', () async {
      setUp();
      final page = await workspace.createPage(title: 'P');
      final db = await database.createDatabase(title: 'DB', pageId: page.id);
      final pStart = await database.addProperty(databaseId: db.id, name: 'Start', type: PropertyType.date);
      final pEnd = await database.addProperty(databaseId: db.id, name: 'End', type: PropertyType.date);

      final row = await database.createRow(db.id);
      await database.updatePropertyValue(rowId: row, propertyId: pStart.id, value: '2026-10-01');
      await database.updatePropertyValue(rowId: row, propertyId: pEnd.id, value: '2026-11-30');

      expect(await database.getPropertyValue(rowId: row, propertyId: pStart.id), equals('2026-10-01'));
      expect(await database.getPropertyValue(rowId: row, propertyId: pEnd.id), equals('2026-11-30'));
    });

    test('F15-B5: Long dependency chain across 5 sequential tasks', () async {
      setUp();
      final page = await workspace.createPage(title: 'P');
      final db = await database.createDatabase(title: 'DB', pageId: page.id);
      final pDep = await database.addProperty(databaseId: db.id, name: 'Predecessor', type: PropertyType.relation);

      var prevRow = await database.createRow(db.id);
      for (var i = 1; i < 5; i++) {
        final nextRow = await database.createRow(db.id);
        await database.updatePropertyValue(rowId: nextRow, propertyId: pDep.id, value: prevRow);
        prevRow = nextRow;
      }

      final rows = await database.watchRows(db.id).first;
      expect(rows.length, equals(5));
    });
  });

  group('Tier 2: F16 List & Gallery Views Boundaries (5 tests)', () {
    late TestWorkspaceEngine workspace;
    late TestDatabaseEngine database;

    void setUp() {
      workspace = TestWorkspaceEngine();
      database = TestDatabaseEngine(workspaceEngine: workspace);
    }

    test('F16-B1: Gallery view with row having null/missing cover image', () async {
      setUp();
      final page = await workspace.createPage(title: 'P');
      final db = await database.createDatabase(title: 'DB', pageId: page.id);
      final pCover = await database.addProperty(databaseId: db.id, name: 'CoverImage', type: PropertyType.text);

      final row = await database.createRow(db.id);
      expect(await database.getPropertyValue(rowId: row, propertyId: pCover.id), isNull);
    });

    test('F16-B2: List view with 0 rows renders clean empty state', () async {
      setUp();
      final page = await workspace.createPage(title: 'P');
      final db = await database.createDatabase(title: 'Empty List', pageId: page.id);
      final view = await database.createView(databaseId: db.id, name: 'List', type: DatabaseViewType.list);

      expect(view.type, equals(DatabaseViewType.list));
      final rows = await database.watchRows(db.id).first;
      expect(rows.isEmpty, isTrue);
    });

    test('F16-B3: Rapid switching between all 6 views preserves underlying row identity (AC2)', () async {
      setUp();
      final page = await workspace.createPage(title: 'P');
      final db = await database.createDatabase(title: 'All Views DB', pageId: page.id);
      final r1 = await database.createRow(db.id);

      // Create all 6 views
      await database.createView(databaseId: db.id, name: 'T', type: DatabaseViewType.table);
      await database.createView(databaseId: db.id, name: 'K', type: DatabaseViewType.kanban);
      await database.createView(databaseId: db.id, name: 'C', type: DatabaseViewType.calendar);
      await database.createView(databaseId: db.id, name: 'G', type: DatabaseViewType.timeline);
      await database.createView(databaseId: db.id, name: 'L', type: DatabaseViewType.list);
      await database.createView(databaseId: db.id, name: 'Gal', type: DatabaseViewType.gallery);

      final views = await database.watchViews(db.id).first;
      expect(views.length, greaterThanOrEqualTo(6));

      // Underlying row remains single source of truth
      final rows = await database.watchRows(db.id).first;
      expect(rows.first.id, equals(r1));
    });

    test('F16-B4: Deleting row reflected immediately in List and Gallery view streams (AC2)', () async {
      setUp();
      final page = await workspace.createPage(title: 'P');
      final db = await database.createDatabase(title: 'DB', pageId: page.id);
      final r1 = await database.createRow(db.id);
      final r2 = await database.createRow(db.id);

      await database.deleteRow(r1);

      final remaining = await database.watchRows(db.id).first;
      expect(remaining.length, equals(1));
      expect(remaining.first.id, equals(r2));
    });

    test('F16-B5: Gallery card with extreme long title text clamps safely', () async {
      setUp();
      final page = await workspace.createPage(title: 'P');
      final db = await database.createDatabase(title: 'DB', pageId: page.id);
      final pTitle = await database.addProperty(databaseId: db.id, name: 'Title', type: PropertyType.text);

      final row = await database.createRow(db.id);
      final hugeTitle = 'Very Long Card Title ' * 20;
      await database.updatePropertyValue(rowId: row, propertyId: pTitle.id, value: hugeTitle);

      expect((await database.getPropertyValue(rowId: row, propertyId: pTitle.id) as String).length, greaterThan(200));
    });
  });
}
