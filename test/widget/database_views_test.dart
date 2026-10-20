import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hampa/core/database/app_database.dart';
import 'package:hampa/core/database/daos/databases_dao.dart';
import 'package:hampa/core/database/daos/database_properties_dao.dart';
import 'package:hampa/core/database/daos/database_rows_dao.dart';
import 'package:hampa/core/database/daos/database_cells_dao.dart';
import 'package:hampa/core/database/daos/database_views_dao.dart';
import 'package:hampa/core/database/daos/pages_dao.dart';
import 'package:hampa/features/workspace_database/data/repositories/database_engine_repository_impl.dart';
import 'package:hampa/features/workspace_database/domain/models/database_view_type.dart';
import 'package:hampa/features/workspace_database/domain/models/property_type.dart';
import 'package:hampa/features/workspace_database/presentation/controllers/database_view_cubit.dart';
import 'package:hampa/features/workspace_database/presentation/widgets/database_view_container.dart';
import 'package:hampa/features/workspace_database/presentation/widgets/views/table/table_view_widget.dart';
import 'package:hampa/features/workspace_database/presentation/widgets/views/kanban/kanban_view_widget.dart';
import 'package:hampa/features/workspace_database/presentation/widgets/views/calendar/calendar_view_widget.dart';
import 'package:hampa/features/workspace_database/presentation/widgets/views/timeline/timeline_view_widget.dart';
import 'package:hampa/features/workspace_database/presentation/widgets/views/list/list_view_widget.dart';
import 'package:hampa/features/workspace_database/presentation/widgets/views/gallery/gallery_view_widget.dart';

void main() {
  late AppDatabase db;
  late DatabasesDao databasesDao;
  late DatabasePropertiesDao propertiesDao;
  late DatabaseRowsDao rowsDao;
  late DatabaseCellsDao cellsDao;
  late DatabaseViewsDao viewsDao;
  late PagesDao pagesDao;
  late DatabaseEngineRepositoryImpl repository;
  late String databaseId;

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

    // Setup base page and database
    await pagesDao.insertPage(PagesCompanion.insert(
      id: 'page_test',
      title: const Value('Test Container'),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));

    final dbEntity = await repository.createDatabase(
      title: 'Milestone 2 Tasks',
      pageId: 'page_test',
    );
    databaseId = dbEntity.id;

    // Add status and date properties
    await repository.addProperty(
      databaseId: databaseId,
      name: 'Status',
      type: PropertyType.status,
      config: {
        'options': ['To Do', 'In Progress', 'Done'],
      },
    );
    await repository.addProperty(
      databaseId: databaseId,
      name: 'Due Date',
      type: PropertyType.date,
    );

    // Add views
    await repository.createView(databaseId: databaseId, name: 'Kanban View', type: DatabaseViewType.kanban);
    await repository.createView(databaseId: databaseId, name: 'Calendar View', type: DatabaseViewType.calendar);
    await repository.createView(databaseId: databaseId, name: 'Timeline View', type: DatabaseViewType.timeline);
    await repository.createView(databaseId: databaseId, name: 'List View', type: DatabaseViewType.list);
    await repository.createView(databaseId: databaseId, name: 'Gallery View', type: DatabaseViewType.gallery);

    // Create test row with Title 'Task Alpha'
    final rowId = await repository.createRow(databaseId);
    final props = await propertiesDao.getPropertiesForDatabase(databaseId);
    final titleProp = props.firstWhere((p) => p.propertyType == PropertyType.title.name);
    await repository.updatePropertyValue(rowId: rowId, propertyId: titleProp.id, value: 'Task Alpha');
  });

  tearDown(() async {
    await db.close();
  });

  Widget buildTestWidget(DatabaseViewCubit cubit) {
    return MaterialApp(
      home: Scaffold(
        body: BlocProvider.value(
          value: cubit,
          child: const DatabaseViewContainer(),
        ),
      ),
    );
  }

  group('Database Views & AC2 Invariant Widget Tests', () {
    testWidgets('Renders Table View by default with Task Alpha', (tester) async {
      final cubit = DatabaseViewCubit(
        repository: repository,
        databaseId: databaseId,
      );

      await tester.pumpWidget(buildTestWidget(cubit));
      await tester.pumpAndSettle();

      expect(find.byType(TableViewWidget), findsOneWidget);
      expect(find.text('Task Alpha'), findsOneWidget);
      expect(find.text('Table View'), findsOneWidget);
      expect(find.text('Kanban View'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await cubit.close();
      await tester.pump(Duration.zero);
    });

    testWidgets('AC2 Invariant: Switching across all 6 views preserves identical underlying data', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final cubit = DatabaseViewCubit(
        repository: repository,
        databaseId: databaseId,
      );

      await tester.pumpWidget(buildTestWidget(cubit));
      await tester.pumpAndSettle();

      // 1. Initial Table View has Task Alpha
      expect(find.byType(TableViewWidget), findsOneWidget);
      expect(find.text('Task Alpha'), findsOneWidget);

      // 2. Switch to Kanban View
      await tester.tap(find.text('Kanban View'));
      await tester.pumpAndSettle();

      expect(find.byType(KanbanViewWidget), findsOneWidget);
      expect(find.text('Task Alpha'), findsOneWidget);

      // 3. Switch to Calendar View
      await tester.tap(find.text('Calendar View'));
      await tester.pumpAndSettle();

      expect(find.byType(CalendarViewWidget), findsOneWidget);

      // 4. Switch to Timeline View
      await tester.tap(find.text('Timeline View'));
      await tester.pumpAndSettle();

      expect(find.byType(TimelineViewWidget), findsOneWidget);
      expect(find.text('Task Alpha'), findsOneWidget);

      // 5. Switch to List View
      await tester.tap(find.text('List View'));
      await tester.pumpAndSettle();

      expect(find.byType(ListViewWidget), findsOneWidget);
      expect(find.text('Task Alpha'), findsOneWidget);

      // 6. Switch to Gallery View
      await tester.tap(find.text('Gallery View'));
      await tester.pumpAndSettle();

      expect(find.byType(GalleryViewWidget), findsOneWidget);
      expect(find.text('Task Alpha'), findsOneWidget);

      // 7. Switch back to Table View — data is still identical!
      await tester.tap(find.text('Table View'));
      await tester.pumpAndSettle();

      expect(find.byType(TableViewWidget), findsOneWidget);
      expect(find.text('Task Alpha'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await cubit.close();
      await tester.pump(Duration.zero);
    });

    testWidgets('Search query filters visible rows in real-time', (tester) async {
      // Add second row
      final r2 = await repository.createRow(databaseId);
      final props = await propertiesDao.getPropertiesForDatabase(databaseId);
      final titleProp = props.firstWhere((p) => p.propertyType == PropertyType.title.name);
      await repository.updatePropertyValue(rowId: r2, propertyId: titleProp.id, value: 'Task Beta');

      final cubit = DatabaseViewCubit(
        repository: repository,
        databaseId: databaseId,
      );

      await tester.pumpWidget(buildTestWidget(cubit));
      await tester.pumpAndSettle();

      expect(find.text('Task Alpha'), findsOneWidget);
      expect(find.text('Task Beta'), findsOneWidget);

      // Type "Alpha" in search
      await tester.enterText(find.byType(TextField).first, 'Alpha');
      await tester.pumpAndSettle();

      expect(find.text('Task Alpha'), findsOneWidget);
      expect(find.text('Task Beta'), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      await cubit.close();
      await tester.pump(Duration.zero);
    });
  });
}
