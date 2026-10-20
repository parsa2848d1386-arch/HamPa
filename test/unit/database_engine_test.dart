import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hampa/core/database/app_database.dart';
import 'package:hampa/core/database/daos/databases_dao.dart';
import 'package:hampa/core/database/daos/database_properties_dao.dart';
import 'package:hampa/core/database/daos/database_rows_dao.dart';
import 'package:hampa/core/database/daos/database_cells_dao.dart';
import 'package:hampa/core/database/daos/database_views_dao.dart';
import 'package:hampa/core/database/daos/pages_dao.dart';
import 'package:hampa/features/workspace_database/data/repositories/database_engine_repository_impl.dart';
import 'package:hampa/features/workspace_database/domain/models/property_type.dart';
import 'package:hampa/features/workspace_database/domain/models/rollup_function.dart';
import 'package:hampa/features/workspace_database/domain/models/database_view_type.dart';

void main() {
  late AppDatabase db;
  late DatabasesDao databasesDao;
  late DatabasePropertiesDao propertiesDao;
  late DatabaseRowsDao rowsDao;
  late DatabaseCellsDao cellsDao;
  late DatabaseViewsDao viewsDao;
  late PagesDao pagesDao;
  late DatabaseEngineRepositoryImpl repository;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    databasesDao = DatabasesDao(db);
    propertiesDao = DatabasePropertiesDao(db);
    rowsDao = DatabaseRowsDao(db);
    cellsDao = DatabaseCellsDao(db);
    viewsDao = DatabaseViewsDao(db);
    pagesDao = PagesDao(db);

    repository = DatabaseEngineRepositoryImpl(
      db: db,
      databasesDao: databasesDao,
      propertiesDao: propertiesDao,
      rowsDao: rowsDao,
      cellsDao: cellsDao,
      viewsDao: viewsDao,
      pagesDao: pagesDao,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('DatabaseEngineRepository Unit Tests', () {
    test('createDatabase creates container, default title property and table view', () async {
      // Create root page
      await pagesDao.insertPage(PagesCompanion.insert(
        id: 'page_root',
        title: const Value('Root Page'),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      final database = await repository.createDatabase(
        title: 'Tasks Database',
        pageId: 'page_root',
      );

      expect(database.id, startsWith('db_'));
      expect(database.title, equals('Tasks Database'));
      expect(database.pageId, equals('page_root'));

      // Check default property
      final props = await propertiesDao.getPropertiesForDatabase(database.id);
      expect(props.length, equals(1));
      expect(props.first.name, equals('Name'));
      expect(props.first.propertyType, equals(PropertyType.title.name));

      // Check default view
      final views = await viewsDao.getViewsForDatabase(database.id);
      expect(views.length, equals(1));
      expect(views.first.name, equals('Table View'));
      expect(views.first.viewType, equals(DatabaseViewType.table.name));
    });

    test('addProperty validates duplicate names case-insensitively', () async {
      await pagesDao.insertPage(PagesCompanion.insert(
        id: 'page_1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      final dbEntity = await repository.createDatabase(title: 'DB', pageId: 'page_1');

      await repository.addProperty(
        databaseId: dbEntity.id,
        name: 'Status',
        type: PropertyType.status,
      );

      expect(
        () => repository.addProperty(
          databaseId: dbEntity.id,
          name: 'status', // duplicate case-insensitive
          type: PropertyType.select,
        ),
        throwsArgumentError,
      );
    });

    test('Two-way relation creates reciprocal property in target database', () async {
      await pagesDao.insertPage(PagesCompanion.insert(
        id: 'page_container',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      final dbA = await repository.createDatabase(title: 'Projects', pageId: 'page_container');
      final dbB = await repository.createDatabase(title: 'Tasks', pageId: 'page_container');

      final propA = await repository.addProperty(
        databaseId: dbA.id,
        name: 'Tasks',
        type: PropertyType.relation,
        config: {
          'targetDatabaseId': dbB.id,
          'isTwoWay': true,
          'reciprocalPropertyName': 'Project',
        },
      );

      final propsB = await propertiesDao.getPropertiesForDatabase(dbB.id);
      final propB = propsB.where((p) => p.name == 'Project').firstOrNull;

      expect(propB, isNotNull);
      expect(propB!.propertyType, equals(PropertyType.relation.name));
      expect(propA.config['targetPropertyId'], equals(propB.id));
    });

    test('Dual Identity Paradigm: createRow creates backing Page with isDatabaseRow=true', () async {
      await pagesDao.insertPage(PagesCompanion.insert(
        id: 'page_main',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      final dbEntity = await repository.createDatabase(title: 'Courses', pageId: 'page_main');

      final rowId = await repository.createRow(dbEntity.id);
      final row = await rowsDao.getRowById(rowId);
      expect(row, isNotNull);

      final backingPage = await pagesDao.getPageById(row!.pageId);
      expect(backingPage, isNotNull);
      expect(backingPage!.isDatabaseRow, isTrue);
      expect(backingPage.parentPageId, equals('page_main'));
    });

    test('updatePropertyValue updates cell and synchronizes Title property with Page.title', () async {
      await pagesDao.insertPage(PagesCompanion.insert(
        id: 'page_parent',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      final dbEntity = await repository.createDatabase(title: 'Study DB', pageId: 'page_parent');
      final props = await propertiesDao.getPropertiesForDatabase(dbEntity.id);
      final titleProp = props.firstWhere((p) => p.propertyType == PropertyType.title.name);

      final rowId = await repository.createRow(dbEntity.id);
      await repository.updatePropertyValue(
        rowId: rowId,
        propertyId: titleProp.id,
        value: 'Physics 101',
      );

      expect(await repository.getPropertyValue(rowId: rowId, propertyId: titleProp.id), equals('Physics 101'));

      final row = await rowsDao.getRowById(rowId);
      final page = await pagesDao.getPageById(row!.pageId);
      expect(page!.title, equals('Physics 101'));
    });

    test('Setting cell value to null clears previous value', () async {
      await pagesDao.insertPage(PagesCompanion.insert(
        id: 'page_p',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      final dbEntity = await repository.createDatabase(title: 'Notes', pageId: 'page_p');
      final pText = await repository.addProperty(databaseId: dbEntity.id, name: 'Notes', type: PropertyType.text);

      final rowId = await repository.createRow(dbEntity.id);
      await repository.updatePropertyValue(rowId: rowId, propertyId: pText.id, value: 'Initial text');
      expect(await repository.getPropertyValue(rowId: rowId, propertyId: pText.id), equals('Initial text'));

      await repository.updatePropertyValue(rowId: rowId, propertyId: pText.id, value: null);
      expect(await repository.getPropertyValue(rowId: rowId, propertyId: pText.id), isNull);
    });

    test('Two-way relation cell synchronization and referential cascade on deleteRow', () async {
      await pagesDao.insertPage(PagesCompanion.insert(
        id: 'page_wrap',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      final dbA = await repository.createDatabase(title: 'Authors', pageId: 'page_wrap');
      final dbB = await repository.createDatabase(title: 'Books', pageId: 'page_wrap');

      final propA = await repository.addProperty(
        databaseId: dbA.id,
        name: 'Books',
        type: PropertyType.relation,
        config: {
          'targetDatabaseId': dbB.id,
          'isTwoWay': true,
          'reciprocalPropertyName': 'Author',
        },
      );

      final authorRowId = await repository.createRow(dbA.id);
      final bookRowId1 = await repository.createRow(dbB.id);
      final bookRowId2 = await repository.createRow(dbB.id);

      // Link author to book1 and book2
      await repository.updatePropertyValue(
        rowId: authorRowId,
        propertyId: propA.id,
        value: [bookRowId1, bookRowId2],
      );

      final reciprocalPropId = propA.config['targetPropertyId'] as String;
      final book1Author = await repository.getPropertyValue(rowId: bookRowId1, propertyId: reciprocalPropId);
      expect(book1Author, contains(authorRowId));

      // Now delete book1
      await repository.deleteRow(bookRowId1);

      // Verify book1 removed from author relation cell
      final authorBooks = await repository.getPropertyValue(rowId: authorRowId, propertyId: propA.id);
      expect(authorBooks, isNot(contains(bookRowId1)));
      expect(authorBooks, contains(bookRowId2));
    });

    test('Formula evaluation with arithmetic, properties, cycle detection, div zero', () async {
      await pagesDao.insertPage(PagesCompanion.insert(
        id: 'p_math',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      final dbEntity = await repository.createDatabase(title: 'Math DB', pageId: 'p_math');
      final pA = await repository.addProperty(databaseId: dbEntity.id, name: 'A', type: PropertyType.number);
      final pB = await repository.addProperty(databaseId: dbEntity.id, name: 'B', type: PropertyType.number);

      final rowId = await repository.createRow(dbEntity.id);
      await repository.updatePropertyValue(rowId: rowId, propertyId: pA.id, value: 50.0);
      await repository.updatePropertyValue(rowId: rowId, propertyId: pB.id, value: 2.0);

      // Simple math
      final res1 = await repository.evaluateFormula(rowId: rowId, expression: 'prop("A") * prop("B")');
      expect(res1, equals(100.0));

      // Division by zero
      final resDiv0 = await repository.evaluateFormula(rowId: rowId, expression: 'prop("A") / 0');
      expect(resDiv0, equals('#DIV/0!'));

      // Cycle detection
      final resCycle = await repository.evaluateFormula(
        rowId: rowId,
        expression: 'prop("A") + 10',
        visitedProperties: {'A'},
      );
      expect(resCycle, equals('#CYCLE!'));
    });

    test('computeRollup aggregates numbers and handles empty list gracefully', () async {
      await pagesDao.insertPage(PagesCompanion.insert(
        id: 'p_rollup',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      final dbA = await repository.createDatabase(title: 'Invoices', pageId: 'p_rollup');
      final dbB = await repository.createDatabase(title: 'LineItems', pageId: 'p_rollup');

      final pRel = await repository.addProperty(
        databaseId: dbA.id,
        name: 'Items',
        type: PropertyType.relation,
        config: {'targetDatabaseId': dbB.id},
      );
      final pPrice = await repository.addProperty(databaseId: dbB.id, name: 'Price', type: PropertyType.number);
      final pDone = await repository.addProperty(databaseId: dbB.id, name: 'Done', type: PropertyType.checkbox);

      final invoiceId = await repository.createRow(dbA.id);
      final item1 = await repository.createRow(dbB.id);
      final item2 = await repository.createRow(dbB.id);

      await repository.updatePropertyValue(rowId: item1, propertyId: pPrice.id, value: 40);
      await repository.updatePropertyValue(rowId: item1, propertyId: pDone.id, value: true);
      await repository.updatePropertyValue(rowId: item2, propertyId: pPrice.id, value: 60);
      await repository.updatePropertyValue(rowId: item2, propertyId: pDone.id, value: false);

      await repository.updatePropertyValue(rowId: invoiceId, propertyId: pRel.id, value: [item1, item2]);

      // Sum
      final sum = await repository.computeRollup(
        rowId: invoiceId,
        relationPropertyId: pRel.id,
        targetPropertyId: pPrice.id,
        function: RollupFunction.sum,
      );
      expect(sum, equals(100));

      // Average
      final avg = await repository.computeRollup(
        rowId: invoiceId,
        relationPropertyId: pRel.id,
        targetPropertyId: pPrice.id,
        function: RollupFunction.average,
      );
      expect(avg, equals(50.0));

      // Percent Checked
      final pct = await repository.computeRollup(
        rowId: invoiceId,
        relationPropertyId: pRel.id,
        targetPropertyId: pDone.id,
        function: RollupFunction.percentChecked,
      );
      expect(pct, equals(50.0));

      // Empty relation
      final emptyInvoiceId = await repository.createRow(dbA.id);
      final emptySum = await repository.computeRollup(
        rowId: emptyInvoiceId,
        relationPropertyId: pRel.id,
        targetPropertyId: pPrice.id,
        function: RollupFunction.sum,
      );
      expect(emptySum, equals(0));
    });
  });
}
