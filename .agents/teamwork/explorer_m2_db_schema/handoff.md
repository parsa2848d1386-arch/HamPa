# Milestone 2 Technical Implementation Blueprint: Relational Database Schema & Persistence

**Agent**: `explorer_m2_db_schema` (Relational Database Schema & Persistence Explorer)  
**Working Directory**: `c:\parsa\HamPA\.agents\teamwork\explorer_m2_db_schema`  
**Parent Orchestrator Conversation ID**: `22d8faaf-eb90-463c-99a6-32a4eb94320e`  
**Target Milestone**: Milestone 2 (Relational Database Engine & 6 Views: F08, F09, F11, Interface Contract 2)  
**Date**: 2026-10-16T21:55:00Z  

---

## 1. Observation

### 1.1 Sources & Authoritative Inputs Examined

1. **`c:\parsa\HamPA\.agents\teamwork\explorer_m2_db_schema\DISPATCH.md`**:
   - Scope: Milestone 2 Relational Database Schema & Persistence.
   - Core Deliverables:
     - Drift SQLite schema & tables: `DatabasesTable`, `DatabasePropertiesTable`, `DatabaseRowsTable`, `DatabaseCellsTable`, `DatabaseViewsTable`.
     - Dual Identity Paradigm: Enforce that every database row references an underlying Page (`pages.id`), ensuring that clicking any row opens its page and modular block document.
     - Property types: Title, Text, Number, Select, MultiSelect, Status, Date, Checkbox, URL, Email, Phone, CreatedTime, LastEditedTime, Relation (with 2-way target database and target property), Rollup, Formula.
     - 2-way Relations: When a Relation property is created with 2-way linking enabled, automatically create and synchronize the reciprocal relation property in the target database.
     - DAOs: `DatabasesDao`, `DatabasePropertiesDao`, `DatabaseRowsDao`, `DatabaseCellsDao`, `DatabaseViewsDao` with reactive streams and atomic transactions.
     - Clean Architecture repository: `DatabaseEngineRepositoryImpl` implementing `IDatabaseEngineRepository`.

2. **`c:\parsa\HamPA\PROJECT.md`**:
   - **Lines 13–15 (Dual Identity Paradigm)**:
     > "Every row in a relational database has a 1:1 dual identity as an underlying `Page` (`is_database_row = TRUE`). Opening any row presents a complete block-based document workspace with nested blocks, embedded databases, and in-session scratchpads."
   - **Lines 29–37 (Features F08–F16)**:
     - `F08`: Rich Property Schema Engine (dynamic columns: text, number, select, multi-select, status, date, tags, etc.).
     - `F09`: Two-Way Database Relations (1:1, 1:N, N:N linking between rows of different databases).
     - `F10`: Formula Expression Engine (AST evaluator for math, string, date, logic, and cycle detection `#CYCLE!`).
     - `F11`: Automatic Rollups & Aggregations (Sum, Average, Min, Max, Count, Percent checked across relations).
     - `F12–F16`: Table, Kanban, Calendar, Timeline, List, Gallery views.
   - **Lines 89–101 (Interface Contract 2: `IDatabaseEngineRepository`)**:
     ```dart
     abstract class IDatabaseEngineRepository {
       Stream<DatabaseEntity> watchDatabase(String databaseId);
       Stream<List<PropertyEntity>> watchProperties(String databaseId);
       Stream<List<RowEntity>> watchRows(String databaseId);
       Stream<List<CellEntity>> watchCells(String databaseId);
       Stream<List<ViewEntity>> watchViews(String databaseId);

       Future<void> updatePropertyValue({required String rowId, required String propertyId, dynamic value});
       Future<String> createRow(String databaseId); // Automatically creates underlying Page
       Future<void> deleteRow(String rowId);
     }
     ```

3. **Existing Milestone 1 Implementation**:
   - `lib/core/database/tables/pages_table.dart`:
     - Columns: `id`, `parentPageId`, `title`, `icon`, `coverImageUrl`, `isDatabaseRow` (Bool default false), `isArchived`, `sortOrder`, `createdAt`, `updatedAt`.
     - Foreign Key: `parent_page_id REFERENCES pages(id) ON DELETE CASCADE`.
   - `lib/core/database/tables/blocks_table.dart`:
     - Blocks store content belonging to `pageId`, cascading upon page deletion.
   - `lib/core/database/app_database.dart`:
     - Current `schemaVersion` is 1; uses SQLite WAL mode (`PRAGMA journal_mode = WAL;`) and foreign keys (`PRAGMA foreign_keys = ON;`).

4. **E2E Test Contracts & Harnesses (`test/e2e/`)**:
   - `test/e2e/contracts/database_contracts.dart`:
     - Defines `PropertyType`: `title`, `text`, `number`, `select`, `multiSelect`, `status`, `date`, `checkbox`, `relation`, `formula`, `rollup`.
     - Defines `RollupFunction`: `sum`, `average`, `min`, `max`, `count`, `percentChecked`.
     - Defines `DatabaseViewType`: `table`, `kanban`, `calendar`, `timeline`, `list`, `gallery`.
     - Defines Domain Entities: `DatabaseEntity`, `PropertyEntity`, `RowEntity`, `CellEntity`, `ViewEntity`.
     - Full interface: `IDatabaseEngineRepository` including `createDatabase`, `addProperty`, `createRow`, `updatePropertyValue`, `getPropertyValue`, `deleteRow`, `createView`, `evaluateFormula`, `computeRollup`.
   - `test/e2e/tier1_feature_coverage/f08_f16_relational_database_test.dart` & `test/e2e/tier2_boundary_corner/f08_f16_relational_boundary_test.dart`:
     - `F08-B1` & `F08-B2`: Duplicate property name check is case-insensitive and throws `ArgumentError`.
     - `F08-B5`: Setting cell value to `null` clears previous value.
     - `F09-1` & `F09-2`: Relations support single target string and multi-target lists (`1:N` & `N:N`).
     - `F09-4` & `F09-5`: Deleting a related row automatically clears references in relation cells (referential integrity).
     - `F10-B1`: Cyclical formula references return `#CYCLE!`.
     - `F10-B2`: Division by zero in formulas returns `#DIV/0!`.
     - `F10-4` & `F10-B3`: Missing or unpopulated properties return `null`.
     - `F10-5`: String literals/bare strings return literal value.
     - `F11-B1`: Rollup targeting empty relation returns default `0` or `null`.

---

## 2. Logic Chain

### 2.1 Schema Design & Relational Normalization
1. **Separation of Structure vs Value**:
   - Relational Notion-like databases are dynamically typed at runtime. A rigid SQLite column per property (`ALTER TABLE ADD COLUMN`) would hit SQLite's 2000 column limit, break schema reactivity, and prevent dynamic property deletion or type changes.
   - **Normalized EAV (Entity-Attribute-Value) with Typed JSON Payload**:
     - `DatabasesTable`: Database container instance, attached to an enclosing `pageId`.
     - `DatabasePropertiesTable`: Column definition (name, property type, display order, JSON configuration for options/relations/formulas).
     - `DatabaseRowsTable`: Row instance linking to database and enforcing the 1:1 Dual Identity page pointer (`pageId`).
     - `DatabaseCellsTable`: `(rowId, propertyId)` cell record storing serialized value in `valueJson`.
     - `DatabaseViewsTable`: View state (Table, Kanban, Calendar, Timeline, List, Gallery) with filter/sort/group config in `configJson`.
   - **Compound Unique Constraints & Foreign Keys**:
     - `DatabaseCellsTable`: Unique constraint on `(row_id, property_id)`.
     - `DatabaseRowsTable`: Unique constraint on `page_id`.
     - All child tables enforce `ON DELETE CASCADE` down from `DatabasesTable` and `Pages`.

### 2.2 Dual Identity Paradigm Enforcement
1. Every row in a relational database is simultaneously a fully functional Notion Page.
2. In `createRow(databaseId)`:
   - An underlying `PageEntry` is created in `pages` with `isDatabaseRow: true` and `parentPageId: db.pageId`.
   - A `DatabaseRowEntry` is created in `database_rows` referencing `page.id`.
   - If the database contains a `title` property, a cell is inserted with value `'Untitled Row'` matching `page.title`.
3. In `updatePropertyValue(rowId, propertyId, value)`:
   - If the target property is of type `title`, updating the cell value immediately updates the underlying `pages.title` in SQLite, keeping the page tree, breadcrumbs, and search index synchronized in real time.
4. In `deleteRow(rowId)`:
   - Atomic transaction deletes the row from `database_rows` (cascading to `database_cells`) and deletes the underlying page from `pages` (cascading to all blocks inside the row document).
   - Referential integrity routine scrubs `rowId` from any relation cells in other databases.

### 2.3 Two-Way Relations Architecture
1. **Creation**:
   - When a Relation property is created with `isTwoWay: true`:
     - Database A creates `propA` with `targetDatabaseId: dbB.id` and `targetPropertyId: propB.id`.
     - Database B automatically creates reciprocal `propB` with `targetDatabaseId: dbA.id` and `targetPropertyId: propA.id`.
     - Executed in a single atomic transaction. Duplicate name checks are enforced on both databases.
2. **Cell Synchronization**:
   - When `rowA` in Database A sets `propA` to `[rowB1, rowB2]`:
     - Target rows `rowB1` and `rowB2` have their reciprocal `propB` cells updated to include `rowA`.
     - Any previously linked rows that were removed have `rowA` stripped from their `propB` cells.
3. **Cascading Referential Integrity**:
   - When any row is deleted, a full-text or pattern scan over relation cells removes the deleted `rowId` from relation arrays or nullifies single references.

### 2.4 Reactive Streams & Atomic Transactions in DAOs
1. DAOs utilize Drift's built-in query stream observers:
   - `watchDatabaseById(databaseId)`
   - `watchPropertiesForDatabase(databaseId)` (ordered by `sortOrder`)
   - `watchRowsForDatabase(databaseId)` (ordered by `sortOrder`, `createdAt`)
   - `watchCellsForDatabase(databaseId)` (reactive join between `database_rows` and `database_cells`)
   - `watchViewsForDatabase(databaseId)` (ordered by `sortOrder`)
2. All multi-table operations (creating databases with default title/view, creating dual-identity rows, 2-way relation linking, and cascading row deletions) are wrapped in `_db.transaction(() async { ... })` guaranteeing ACID guarantees.

### 2.5 Clean Architecture Layering
1. The domain layer (`lib/features/workspace_database/domain/`) remains 100% pure Dart, independent of Drift or Flutter UI.
2. `DatabaseEngineRepositoryImpl` acts as the translation boundary:
   - Converts Drift database entries (`DatabaseEntry`, `DatabasePropertyEntry`, `DatabaseRowEntry`, `DatabaseCellEntry`, `DatabaseViewEntry`) into pure domain entities (`DatabaseEntity`, `PropertyEntity`, `RowEntity`, `CellEntity`, `ViewEntity`).
   - Implements `IDatabaseEngineRepository` matching both `PROJECT.md` and `database_contracts.dart`.

---

## 3. Caveats

1. **Schema Migration**:
   - Upgrading `schemaVersion` from `1` to `2` in `app_database.dart` requires `onUpgrade` logic in `MigrationStrategy` to invoke `createTable()` for the 5 new tables when running against existing databases.
2. **Code Generation**:
   - Drift requires `build_runner` to generate `app_database.g.dart` and DAO mixins (`*_dao.g.dart`). To avoid build friction, standard Drift table syntax and companion classes are followed meticulously.
3. **Cell Value Storage & Deserialization**:
   - Values in `DatabaseCellsTable.valueJson` are stored as JSON-encoded primitives (`"string"`, `123`, `true`, `["id1", "id2"]`, `{"start": "..."}`). When `value` is null, `valueJson` is stored as SQL `NULL`. Deserialization handles dynamic decoding cleanly.

---

## 4. Conclusion & File-by-File Blueprint

### 4.1 System File Inventory

```
c:\parsa\HamPA\
├── lib/
│   ├── core/
│   │   ├── database/
│   │   │   ├── app_database.dart                     # [UPDATE] Schema v2, 5 new tables, 5 new DAOs
│   │   │   ├── tables/
│   │   │   │   ├── databases_table.dart              # [NEW] DatabasesTable
│   │   │   │   ├── database_properties_table.dart    # [NEW] DatabasePropertiesTable
│   │   │   │   ├── database_rows_table.dart          # [NEW] DatabaseRowsTable
│   │   │   │   ├── database_cells_table.dart         # [NEW] DatabaseCellsTable
│   │   │   │   └── database_views_table.dart         # [NEW] DatabaseViewsTable
│   │   │   └── daos/
│   │   │       ├── databases_dao.dart                # [NEW] DatabasesDao
│   │   │       ├── database_properties_dao.dart      # [NEW] DatabasePropertiesDao
│   │   │       ├── database_rows_dao.dart            # [NEW] DatabaseRowsDao
│   │   │       ├── database_cells_dao.dart           # [NEW] DatabaseCellsDao
│   │   │       └── database_views_dao.dart           # [NEW] DatabaseViewsDao
│   │   └── utils/
│   │       ├── formula_evaluator.dart                # [NEW] Formula AST evaluator (#CYCLE!, #DIV/0!)
│   │       └── rollup_evaluator.dart                 # [NEW] Rollup aggregator (sum, avg, count, etc.)
│   └── features/
│       └── workspace_database/
│           ├── domain/
│           │   ├── models/
│           │   │   ├── property_type.dart            # [NEW] Enum PropertyType (16 types)
│           │   │   ├── rollup_function.dart          # [NEW] Enum RollupFunction (6 functions)
│           │   │   ├── database_view_type.dart       # [NEW] Enum DatabaseViewType (6 views)
│           │   │   ├── database_entity.dart          # [NEW] Pure domain DatabaseEntity
│           │   │   ├── property_entity.dart          # [NEW] Pure domain PropertyEntity
│           │   │   ├── row_entity.dart               # [NEW] Pure domain RowEntity
│           │   │   ├── cell_entity.dart              # [NEW] Pure domain CellEntity
│           │   │   └── view_entity.dart              # [NEW] Pure domain ViewEntity
│           │   └── repositories/
│           │       └── i_database_engine_repository.dart # [NEW] Clean architecture contract
│           └── data/
│               └── repositories/
│                   └── database_engine_repository_impl.dart # [NEW] Implementation of IDatabaseEngineRepository
└── test/
    └── unit/
        └── database_engine_test.dart                 # [NEW] In-memory Drift SQLite unit test suite
```

---

### 4.2 Drift Tables Specification

#### 4.2.1 `lib/core/database/tables/databases_table.dart`
```dart
import 'package:drift/drift.dart';
import 'pages_table.dart';

/// Table representing relational database containers in HamPA.
/// A database belongs to an enclosing Page document via [pageId].
@TableIndex(name: 'idx_databases_page_id', columns: {#pageId})
@DataClassName('DatabaseEntry')
class DatabasesTable extends Table {
  @override
  String get tableName => 'databases';

  TextColumn get id => text()();
  TextColumn get pageId => text()(); // Enclosing page ID
  TextColumn get title => text().withDefault(const Constant('Untitled Database'))();
  TextColumn get icon => text().nullable()();
  TextColumn get coverImageUrl => text().nullable()();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (page_id) REFERENCES pages(id) ON DELETE CASCADE',
  ];
}
```

#### 4.2.2 `lib/core/database/tables/database_properties_table.dart`
```dart
import 'package:drift/drift.dart';
import 'databases_table.dart';

/// Table representing dynamic column/property schemas of a database.
/// Supports 16 rich property types, fractional ordering, and JSON configuration.
@TableIndex(name: 'idx_properties_database_sort', columns: {#databaseId, #sortOrder})
@DataClassName('DatabasePropertyEntry')
class DatabasePropertiesTable extends Table {
  @override
  String get tableName => 'database_properties';

  TextColumn get id => text()();
  TextColumn get databaseId => text()();
  TextColumn get name => text()();
  TextColumn get propertyType => text()(); // 'title', 'text', 'number', 'select', etc.
  RealColumn get sortOrder => real().withDefault(const Constant(0.0))();
  TextColumn get configJson => text().withDefault(const Constant('{}'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (database_id) REFERENCES databases(id) ON DELETE CASCADE',
  ];
}
```

#### 4.2.3 `lib/core/database/tables/database_rows_table.dart`
```dart
import 'package:drift/drift.dart';
import 'databases_table.dart';
import 'pages_table.dart';

/// Table representing rows within a relational database.
/// Enforces the Dual Identity Paradigm: [pageId] references an underlying Page
/// with a 1:1 unique constraint, ensuring each row is a full modular document.
@TableIndex(name: 'idx_rows_database_sort', columns: {#databaseId, #sortOrder})
@TableIndex(name: 'idx_rows_page_id', columns: {#pageId}, unique: true)
@DataClassName('DatabaseRowEntry')
class DatabaseRowsTable extends Table {
  @override
  String get tableName => 'database_rows';

  TextColumn get id => text()();
  TextColumn get databaseId => text()();
  TextColumn get pageId => text()(); // 1:1 Dual Identity Page reference
  RealColumn get sortOrder => real().withDefault(const Constant(0.0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (database_id) REFERENCES databases(id) ON DELETE CASCADE',
    'FOREIGN KEY (page_id) REFERENCES pages(id) ON DELETE CASCADE',
  ];
}
```

#### 4.2.4 `lib/core/database/tables/database_cells_table.dart`
```dart
import 'package:drift/drift.dart';
import 'database_rows_table.dart';
import 'database_properties_table.dart';

/// Table representing individual cell values for (row, property) intersections.
/// Stores typed serialized JSON values with full referential cascading.
@TableIndex(name: 'idx_cells_row_property', columns: {#rowId, #propertyId}, unique: true)
@TableIndex(name: 'idx_cells_property', columns: {#propertyId})
@DataClassName('DatabaseCellEntry')
class DatabaseCellsTable extends Table {
  @override
  String get tableName => 'database_cells';

  TextColumn get id => text()();
  TextColumn get rowId => text()();
  TextColumn get propertyId => text()();
  TextColumn get valueJson => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (row_id) REFERENCES database_rows(id) ON DELETE CASCADE',
    'FOREIGN KEY (property_id) REFERENCES database_properties(id) ON DELETE CASCADE',
  ];
}
```

#### 4.2.5 `lib/core/database/tables/database_views_table.dart`
```dart
import 'package:drift/drift.dart';
import 'databases_table.dart';

/// Table representing database views (Table, Kanban, Calendar, Timeline, List, Gallery).
/// Stores view configurations (filters, sorts, groupings, calendar ranges) in [configJson].
@TableIndex(name: 'idx_views_database_sort', columns: {#databaseId, #sortOrder})
@DataClassName('DatabaseViewEntry')
class DatabaseViewsTable extends Table {
  @override
  String get tableName => 'database_views';

  TextColumn get id => text()();
  TextColumn get databaseId => text()();
  TextColumn get name => text().withDefault(const Constant('Default View'))();
  TextColumn get viewType => text()(); // 'table', 'kanban', 'calendar', 'timeline', 'list', 'gallery'
  RealColumn get sortOrder => real().withDefault(const Constant(0.0))();
  TextColumn get configJson => text().withDefault(const Constant('{}'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (database_id) REFERENCES databases(id) ON DELETE CASCADE',
  ];
}
```

---

### 4.3 Database Configuration & Migration Blueprint

#### 4.3.1 `lib/core/database/app_database.dart`
```dart
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/pages_table.dart';
import 'tables/blocks_table.dart';
import 'tables/subjects_table.dart';
import 'tables/databases_table.dart';
import 'tables/database_properties_table.dart';
import 'tables/database_rows_table.dart';
import 'tables/database_cells_table.dart';
import 'tables/database_views_table.dart';

import 'daos/pages_dao.dart';
import 'daos/blocks_dao.dart';
import 'daos/subjects_dao.dart';
import 'daos/databases_dao.dart';
import 'daos/database_properties_dao.dart';
import 'daos/database_rows_dao.dart';
import 'daos/database_cells_dao.dart';
import 'daos/database_views_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Pages,
    Blocks,
    Subjects,
    DatabasesTable,
    DatabasePropertiesTable,
    DatabaseRowsTable,
    DatabaseCellsTable,
    DatabaseViewsTable,
  ],
  daos: [
    PagesDao,
    BlocksDao,
    SubjectsDao,
    DatabasesDao,
    DatabasePropertiesDao,
    DatabaseRowsDao,
    DatabaseCellsDao,
    DatabaseViewsDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 2;

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'hampa_db',
      native: const DriftNativeOptions(
        shareAcrossIsolates: true,
      ),
    );
  }

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.createTable(databasesTable);
          await m.createTable(databasePropertiesTable);
          await m.createTable(databaseRowsTable);
          await m.createTable(databaseCellsTable);
          await m.createTable(databaseViewsTable);
        }
      },
      beforeOpen: (details) async {
        // Enforce foreign keys and configure WAL mode for zero-latency concurrent operations
        await customStatement('PRAGMA foreign_keys = ON;');
        await customStatement('PRAGMA journal_mode = WAL;');
        await customStatement('PRAGMA synchronous = NORMAL;');
      },
    );
  }
}
```

---

### 4.4 Data Access Objects (DAOs) Specification

#### 4.4.1 `lib/core/database/daos/databases_dao.dart`
```dart
import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/databases_table.dart';

part 'databases_dao.g.dart';

@DriftAccessor(tables: [DatabasesTable])
class DatabasesDao extends DatabaseAccessor<AppDatabase> with _$DatabasesDaoMixin {
  DatabasesDao(super.db);

  Stream<DatabaseEntry?> watchDatabaseById(String id) {
    return (select(databasesTable)..where((tbl) => tbl.id.equals(id))).watchSingleOrNull();
  }

  Stream<List<DatabaseEntry>> watchDatabasesForPage(String pageId) {
    return (select(databasesTable)
          ..where((tbl) => tbl.pageId.equals(pageId) & tbl.isArchived.equals(false))
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.createdAt)]))
        .watch();
  }

  Future<DatabaseEntry?> getDatabaseById(String id) {
    return (select(databasesTable)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  Future<int> insertDatabase(DatabasesTableCompanion entry) {
    return into(databasesTable).insert(entry);
  }

  Future<bool> updateDatabase(DatabasesTableCompanion entry) {
    return update(databasesTable).replace(entry);
  }

  Future<int> deleteDatabase(String id) {
    return (delete(databasesTable)..where((tbl) => tbl.id.equals(id))).go();
  }
}
```

#### 4.4.2 `lib/core/database/daos/database_properties_dao.dart`
```dart
import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/database_properties_table.dart';

part 'database_properties_dao.g.dart';

@DriftAccessor(tables: [DatabasePropertiesTable])
class DatabasePropertiesDao extends DatabaseAccessor<AppDatabase> with _$DatabasePropertiesDaoMixin {
  DatabasePropertiesDao(super.db);

  Stream<List<DatabasePropertyEntry>> watchPropertiesForDatabase(String databaseId) {
    return (select(databasePropertiesTable)
          ..where((tbl) => tbl.databaseId.equals(databaseId))
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.sortOrder, mode: OrderingMode.asc)]))
        .watch();
  }

  Future<List<DatabasePropertyEntry>> getPropertiesForDatabase(String databaseId) {
    return (select(databasePropertiesTable)
          ..where((tbl) => tbl.databaseId.equals(databaseId))
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.sortOrder, mode: OrderingMode.asc)]))
        .get();
  }

  Future<DatabasePropertyEntry?> getPropertyById(String id) {
    return (select(databasePropertiesTable)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  Future<int> insertProperty(DatabasePropertiesTableCompanion entry) {
    return into(databasePropertiesTable).insert(entry);
  }

  Future<bool> updateProperty(DatabasePropertiesTableCompanion entry) {
    return update(databasePropertiesTable).replace(entry);
  }

  Future<int> deleteProperty(String id) {
    return (delete(databasePropertiesTable)..where((tbl) => tbl.id.equals(id))).go();
  }

  Future<void> batchUpdateSortOrders(Map<String, double> propertySortOrders) async {
    await batch((b) {
      for (final entry in propertySortOrders.entries) {
        b.update(
          databasePropertiesTable,
          DatabasePropertiesTableCompanion(
            sortOrder: Value(entry.value),
            updatedAt: Value(DateTime.now()),
          ),
          where: (tbl) => tbl.id.equals(entry.key),
        );
      }
    });
  }
}
```

#### 4.4.3 `lib/core/database/daos/database_rows_dao.dart`
```dart
import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/database_rows_table.dart';

part 'database_rows_dao.g.dart';

@DriftAccessor(tables: [DatabaseRowsTable])
class DatabaseRowsDao extends DatabaseAccessor<AppDatabase> with _$DatabaseRowsDaoMixin {
  DatabaseRowsDao(super.db);

  Stream<List<DatabaseRowEntry>> watchRowsForDatabase(String databaseId) {
    return (select(databaseRowsTable)
          ..where((tbl) => tbl.databaseId.equals(databaseId))
          ..orderBy([
            (tbl) => OrderingTerm(expression: tbl.sortOrder, mode: OrderingMode.asc),
            (tbl) => OrderingTerm(expression: tbl.createdAt, mode: OrderingMode.asc),
          ]))
        .watch();
  }

  Future<List<DatabaseRowEntry>> getRowsForDatabase(String databaseId) {
    return (select(databaseRowsTable)
          ..where((tbl) => tbl.databaseId.equals(databaseId))
          ..orderBy([
            (tbl) => OrderingTerm(expression: tbl.sortOrder, mode: OrderingMode.asc),
            (tbl) => OrderingTerm(expression: tbl.createdAt, mode: OrderingMode.asc),
          ]))
        .get();
  }

  Future<DatabaseRowEntry?> getRowById(String id) {
    return (select(databaseRowsTable)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  Future<DatabaseRowEntry?> getRowByPageId(String pageId) {
    return (select(databaseRowsTable)..where((tbl) => tbl.pageId.equals(pageId))).getSingleOrNull();
  }

  Future<int> insertRow(DatabaseRowsTableCompanion entry) {
    return into(databaseRowsTable).insert(entry);
  }

  Future<bool> updateRow(DatabaseRowsTableCompanion entry) {
    return update(databaseRowsTable).replace(entry);
  }

  Future<int> deleteRow(String id) {
    return (delete(databaseRowsTable)..where((tbl) => tbl.id.equals(id))).go();
  }

  Future<void> batchUpdateSortOrders(Map<String, double> rowSortOrders) async {
    await batch((b) {
      for (final entry in rowSortOrders.entries) {
        b.update(
          databaseRowsTable,
          DatabaseRowsTableCompanion(
            sortOrder: Value(entry.value),
            updatedAt: Value(DateTime.now()),
          ),
          where: (tbl) => tbl.id.equals(entry.key),
        );
      }
    });
  }
}
```

#### 4.4.4 `lib/core/database/daos/database_cells_dao.dart`
```dart
import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/database_cells_table.dart';
import '../tables/database_rows_table.dart';

part 'database_cells_dao.g.dart';

@DriftAccessor(tables: [DatabaseCellsTable, DatabaseRowsTable])
class DatabaseCellsDao extends DatabaseAccessor<AppDatabase> with _$DatabaseCellsDaoMixin {
  DatabaseCellsDao(super.db);

  Stream<List<DatabaseCellEntry>> watchCellsForDatabase(String databaseId) {
    final query = select(databaseCellsTable).join([
      innerJoin(
        databaseRowsTable,
        databaseRowsTable.id.equalsExp(databaseCellsTable.rowId),
      ),
    ])..where(databaseRowsTable.databaseId.equals(databaseId));

    return query.watch().map((rows) => rows.map((r) => r.readTable(databaseCellsTable)).toList());
  }

  Stream<List<DatabaseCellEntry>> watchCellsForRow(String rowId) {
    return (select(databaseCellsTable)..where((tbl) => tbl.rowId.equals(rowId))).watch();
  }

  Future<List<DatabaseCellEntry>> getCellsForRow(String rowId) {
    return (select(databaseCellsTable)..where((tbl) => tbl.rowId.equals(rowId))).get();
  }

  Future<DatabaseCellEntry?> getCell(String rowId, String propertyId) {
    return (select(databaseCellsTable)
          ..where((tbl) => tbl.rowId.equals(rowId) & tbl.propertyId.equals(propertyId)))
        .getSingleOrNull();
  }

  Future<void> upsertCell({
    required String rowId,
    required String propertyId,
    required String? valueJson,
  }) async {
    final cellId = 'cell_${rowId}_$propertyId';
    await into(databaseCellsTable).insertOnConflictUpdate(
      DatabaseCellsTableCompanion(
        id: Value(cellId),
        rowId: Value(rowId),
        propertyId: Value(propertyId),
        valueJson: Value(valueJson),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> deleteCellsForRow(String rowId) {
    return (delete(databaseCellsTable)..where((tbl) => tbl.rowId.equals(rowId))).go();
  }

  Future<int> deleteCellsForProperty(String propertyId) {
    return (delete(databaseCellsTable)..where((tbl) => tbl.propertyId.equals(propertyId))).go();
  }

  /// Searches for relation cells containing a given target rowId for referential cleanup
  Future<List<DatabaseCellEntry>> findRelationCellsContaining(String targetRowId) {
    return (select(databaseCellsTable)
          ..where((tbl) => tbl.valueJson.like('%$targetRowId%')))
        .get();
  }
}
```

#### 4.4.5 `lib/core/database/daos/database_views_dao.dart`
```dart
import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/database_views_table.dart';

part 'database_views_dao.g.dart';

@DriftAccessor(tables: [DatabaseViewsTable])
class DatabaseViewsDao extends DatabaseAccessor<AppDatabase> with _$DatabaseViewsDaoMixin {
  DatabaseViewsDao(super.db);

  Stream<List<DatabaseViewEntry>> watchViewsForDatabase(String databaseId) {
    return (select(databaseViewsTable)
          ..where((tbl) => tbl.databaseId.equals(databaseId))
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.sortOrder, mode: OrderingMode.asc)]))
        .watch();
  }

  Future<List<DatabaseViewEntry>> getViewsForDatabase(String databaseId) {
    return (select(databaseViewsTable)
          ..where((tbl) => tbl.databaseId.equals(databaseId))
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.sortOrder, mode: OrderingMode.asc)]))
        .get();
  }

  Future<DatabaseViewEntry?> getViewById(String id) {
    return (select(databaseViewsTable)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  Future<int> insertView(DatabaseViewsTableCompanion entry) {
    return into(databaseViewsTable).insert(entry);
  }

  Future<bool> updateView(DatabaseViewsTableCompanion entry) {
    return update(databaseViewsTable).replace(entry);
  }

  Future<int> deleteView(String id) {
    return (delete(databaseViewsTable)..where((tbl) => tbl.id.equals(id))).go();
  }

  Future<void> batchUpdateSortOrders(Map<String, double> viewSortOrders) async {
    await batch((b) {
      for (final entry in viewSortOrders.entries) {
        b.update(
          databaseViewsTable,
          DatabaseViewsTableCompanion(
            sortOrder: Value(entry.value),
            updatedAt: Value(DateTime.now()),
          ),
          where: (tbl) => tbl.id.equals(entry.key),
        );
      }
    });
  }
}
```

---

### 4.5 Domain Models & Interfaces Specification

#### 4.5.1 `lib/features/workspace_database/domain/models/property_type.dart`
```dart
enum PropertyType {
  title,
  text,
  number,
  select,
  multiSelect,
  status,
  date,
  checkbox,
  url,
  email,
  phone,
  createdTime,
  lastEditedTime,
  relation,
  rollup,
  formula,
}

extension PropertyTypeParsing on PropertyType {
  static PropertyType fromString(String str) {
    return PropertyType.values.firstWhere(
      (e) => e.name.toLowerCase() == str.toLowerCase(),
      orElse: () => PropertyType.text,
    );
  }
}
```

#### 4.5.2 `lib/features/workspace_database/domain/models/rollup_function.dart`
```dart
enum RollupFunction {
  sum,
  average,
  min,
  max,
  count,
  percentChecked,
}
```

#### 4.5.3 `lib/features/workspace_database/domain/models/database_view_type.dart`
```dart
enum DatabaseViewType {
  table,
  kanban,
  calendar,
  timeline,
  list,
  gallery,
}
```

#### 4.5.4 Domain Entities (`database_entity.dart`, `property_entity.dart`, `row_entity.dart`, `cell_entity.dart`, `view_entity.dart`)
```dart
// lib/features/workspace_database/domain/models/database_entity.dart
import 'package:flutter/foundation.dart';

@immutable
class DatabaseEntity {
  final String id;
  final String title;
  final String pageId;

  const DatabaseEntity({
    required this.id,
    required this.title,
    required this.pageId,
  });

  DatabaseEntity copyWith({String? id, String? title, String? pageId}) {
    return DatabaseEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      pageId: pageId ?? this.pageId,
    );
  }
}

// lib/features/workspace_database/domain/models/property_entity.dart
import 'package:flutter/foundation.dart';
import 'property_type.dart';

@immutable
class PropertyEntity {
  final String id;
  final String databaseId;
  final String name;
  final PropertyType type;
  final Map<String, dynamic> config;

  PropertyEntity({
    required this.id,
    required this.databaseId,
    required this.name,
    required this.type,
    Map<String, dynamic>? config,
  }) : config = config ?? {};

  PropertyEntity copyWith({
    String? id,
    String? databaseId,
    String? name,
    PropertyType? type,
    Map<String, dynamic>? config,
  }) {
    return PropertyEntity(
      id: id ?? this.id,
      databaseId: databaseId ?? this.databaseId,
      name: name ?? this.name,
      type: type ?? this.type,
      config: config ?? Map.from(this.config),
    );
  }
}

// lib/features/workspace_database/domain/models/row_entity.dart
import 'package:flutter/foundation.dart';

@immutable
class RowEntity {
  final String id;
  final String databaseId;
  final String pageId; // 1:1 dual identity page ID
  final DateTime createdAt;
  final DateTime updatedAt;

  RowEntity({
    required this.id,
    required this.databaseId,
    required this.pageId,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  RowEntity copyWith({
    String? id,
    String? databaseId,
    String? pageId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RowEntity(
      id: id ?? this.id,
      databaseId: databaseId ?? this.databaseId,
      pageId: pageId ?? this.pageId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// lib/features/workspace_database/domain/models/cell_entity.dart
import 'package:flutter/foundation.dart';

@immutable
class CellEntity {
  final String id;
  final String rowId;
  final String propertyId;
  final dynamic value;

  const CellEntity({
    required this.id,
    required this.rowId,
    required this.propertyId,
    this.value,
  });

  CellEntity copyWith({
    String? id,
    String? rowId,
    String? propertyId,
    dynamic value,
  }) {
    return CellEntity(
      id: id ?? this.id,
      rowId: rowId ?? this.rowId,
      propertyId: propertyId ?? this.propertyId,
      value: value ?? this.value,
    );
  }
}

// lib/features/workspace_database/domain/models/view_entity.dart
import 'package:flutter/foundation.dart';
import 'database_view_type.dart';

@immutable
class ViewEntity {
  final String id;
  final String databaseId;
  final String name;
  final DatabaseViewType type;
  final Map<String, dynamic> config;

  ViewEntity({
    required this.id,
    required this.databaseId,
    required this.name,
    required this.type,
    Map<String, dynamic>? config,
  }) : config = config ?? {};

  ViewEntity copyWith({
    String? id,
    String? databaseId,
    String? name,
    DatabaseViewType? type,
    Map<String, dynamic>? config,
  }) {
    return ViewEntity(
      id: id ?? this.id,
      databaseId: databaseId ?? this.databaseId,
      name: name ?? this.name,
      type: type ?? this.type,
      config: config ?? Map.from(this.config),
    );
  }
}
```

#### 4.5.5 `lib/features/workspace_database/domain/repositories/i_database_engine_repository.dart`
```dart
import '../models/database_entity.dart';
import '../models/property_entity.dart';
import '../models/property_type.dart';
import '../models/row_entity.dart';
import '../models/cell_entity.dart';
import '../models/view_entity.dart';
import '../models/database_view_type.dart';
import '../models/rollup_function.dart';

abstract class IDatabaseEngineRepository {
  Stream<DatabaseEntity> watchDatabase(String databaseId);
  Stream<List<PropertyEntity>> watchProperties(String databaseId);
  Stream<List<RowEntity>> watchRows(String databaseId);
  Stream<List<CellEntity>> watchCells(String databaseId);
  Stream<List<ViewEntity>> watchViews(String databaseId);

  Future<DatabaseEntity> createDatabase({
    required String title,
    required String pageId,
  });

  Future<PropertyEntity> addProperty({
    required String databaseId,
    required String name,
    required PropertyType type,
    Map<String, dynamic>? config,
  });

  Future<String> createRow(String databaseId); // Automatically creates underlying Page
  Future<void> updatePropertyValue({
    required String rowId,
    required String propertyId,
    dynamic value,
  });
  Future<dynamic> getPropertyValue({
    required String rowId,
    required String propertyId,
  });
  Future<void> deleteRow(String rowId);

  Future<ViewEntity> createView({
    required String databaseId,
    required String name,
    required DatabaseViewType type,
    Map<String, dynamic>? config,
  });

  // Formula evaluation and cycle detection
  Future<dynamic> evaluateFormula({
    required String rowId,
    required String expression,
    Set<String>? visitedProperties,
  });

  // Rollup calculation across related databases
  Future<dynamic> computeRollup({
    required String rowId,
    required String relationPropertyId,
    required String targetPropertyId,
    required RollupFunction function,
  });
}
```

---

### 4.6 Formula & Rollup Computation Engine Specification

#### 4.6.1 `lib/core/utils/formula_evaluator.dart`
```dart
/// Pure Dart AST formula evaluator for database formulas (F10).
/// Handles arithmetic (+, -, *, /), parentheses, property references prop("..."),
/// cycle detection returning '#CYCLE!', and division-by-zero returning '#DIV/0!'.
class FormulaEvaluator {
  final Future<dynamic> Function(String propName) propertyLookup;
  final Set<String> visitedProperties;

  FormulaEvaluator({
    required this.propertyLookup,
    Set<String>? visitedProperties,
  }) : visitedProperties = visitedProperties ?? {};

  Future<dynamic> evaluate(String expression) async {
    final trimmed = expression.trim();
    if (trimmed.isEmpty) return null;

    // Check circular reference in visited stack
    if (visitedProperties.contains(trimmed)) {
      return '#CYCLE!';
    }

    try {
      final tokens = _tokenize(trimmed);
      if (tokens.isEmpty) return null;

      // Single string keyword or non-math literal fallback (e.g. 'ACTIVE')
      if (tokens.length == 1) {
        final single = tokens.first;
        if (single.startsWith('prop(')) {
          return await _resolvePropertyToken(single);
        }
        final numVal = double.tryParse(single);
        if (numVal != null) return numVal;
        return single;
      }

      final parser = _ExpressionParser(
        tokens: tokens,
        lookup: (token) async => await _resolvePropertyToken(token),
      );

      final result = await parser.parse();
      return result;
    } catch (e) {
      if (e is _CycleException) return '#CYCLE!';
      if (e is _DivZeroException) return '#DIV/0!';
      // Fallback to raw string literal
      return trimmed;
    }
  }

  Future<dynamic> _resolvePropertyToken(String token) async {
    if (visitedProperties.contains(token)) {
      throw _CycleException();
    }
    final match = RegExp(r'^prop\("([^"]+)"\)$').firstMatch(token);
    if (match == null) return null;
    final propName = match.group(1)!;

    final childVisited = Set<String>.from(visitedProperties)..add(token);
    final val = await propertyLookup(propName);
    if (val == null) return null;
    if (val is num) return val.toDouble();
    if (val is String) {
      final numVal = double.tryParse(val);
      if (numVal != null) return numVal;
      return val;
    }
    return val;
  }

  List<String> _tokenize(String expr) {
    final tokens = <String>[];
    final buffer = StringBuffer();
    var inQuotes = false;
    var i = 0;

    while (i < expr.length) {
      final char = expr[i];

      if (char == '"') {
        inQuotes = !inQuotes;
        buffer.write(char);
        i++;
        continue;
      }

      if (!inQuotes) {
        if (char == ' ' || char == '\t') {
          if (buffer.isNotEmpty) {
            tokens.add(buffer.toString());
            buffer.clear();
          }
          i++;
          continue;
        }

        if (char == '+' || char == '*' || char == '/' || char == '(' || char == ')') {
          if (buffer.isNotEmpty) {
            tokens.add(buffer.toString());
            buffer.clear();
          }
          tokens.add(char);
          i++;
          continue;
        }

        if (char == '-') {
          // Determine if unary minus or binary subtraction
          if (buffer.isEmpty && (tokens.isEmpty || tokens.last == '+' || tokens.last == '-' || tokens.last == '*' || tokens.last == '/' || tokens.last == '(')) {
            buffer.write(char); // Unary minus
            i++;
            continue;
          } else {
            if (buffer.isNotEmpty) {
              tokens.add(buffer.toString());
              buffer.clear();
            }
            tokens.add(char);
            i++;
            continue;
          }
        }
      }

      buffer.write(char);
      i++;
    }

    if (buffer.isNotEmpty) {
      tokens.add(buffer.toString());
    }

    return tokens;
  }
}

class _CycleException implements Exception {}
class _DivZeroException implements Exception {}

class _ExpressionParser {
  final List<String> tokens;
  final Future<dynamic> Function(String token) lookup;
  int _pos = 0;

  _ExpressionParser({required this.tokens, required this.lookup});

  Future<dynamic> parse() async {
    _pos = 0;
    final result = await _parseAddSub();
    return result;
  }

  Future<dynamic> _parseAddSub() async {
    var left = await _parseMulDiv();
    if (left == null) return null;

    while (_pos < tokens.length) {
      final op = tokens[_pos];
      if (op != '+' && op != '-') break;
      _pos++;

      final right = await _parseMulDiv();
      if (right == null) return null;

      if (left is num && right is num) {
        if (op == '+') {
          left = left + right;
        } else {
          left = left - right;
        }
      } else {
        left = '$left$right';
      }
    }
    return left;
  }

  Future<dynamic> _parseMulDiv() async {
    var left = await _parsePrimary();
    if (left == null) return null;

    while (_pos < tokens.length) {
      final op = tokens[_pos];
      if (op != '*' && op != '/') break;
      _pos++;

      final right = await _parsePrimary();
      if (right == null) return null;

      if (left is num && right is num) {
        if (op == '*') {
          left = left * right;
        } else {
          if (right == 0) throw _DivZeroException();
          left = left / right;
        }
      } else {
        return null;
      }
    }
    return left;
  }

  Future<dynamic> _parsePrimary() async {
    if (_pos >= tokens.length) return null;
    final token = tokens[_pos++];

    if (token == '(') {
      final inner = await _parseAddSub();
      if (_pos < tokens.length && tokens[_pos] == ')') {
        _pos++;
      }
      return inner;
    }

    if (token.startsWith('prop(')) {
      final resolved = await lookup(token);
      return resolved;
    }

    final numVal = double.tryParse(token);
    if (numVal != null) return numVal;

    return token;
  }
}
```

#### 4.6.2 `lib/core/utils/rollup_evaluator.dart`
```dart
import '../database/daos/database_cells_dao.dart';
import '../../features/workspace_database/domain/models/rollup_function.dart';

/// Aggregation engine for computing database rollups across related rows (F11).
class RollupEvaluator {
  final DatabaseCellsDao cellsDao;

  RollupEvaluator({required this.cellsDao});

  dynamic compute({
    required List<dynamic> relatedRowValues,
    required RollupFunction function,
  }) {
    if (relatedRowValues.isEmpty) {
      switch (function) {
        case RollupFunction.sum:
        case RollupFunction.count:
        case RollupFunction.percentChecked:
          return 0;
        case RollupFunction.average:
          return 0.0;
        case RollupFunction.min:
        case RollupFunction.max:
          return null;
      }
    }

    switch (function) {
      case RollupFunction.count:
        return relatedRowValues.length;

      case RollupFunction.sum:
        num total = 0;
        for (final val in relatedRowValues) {
          if (val is num) total += val;
        }
        return total;

      case RollupFunction.average:
        num total = 0;
        var count = 0;
        for (final val in relatedRowValues) {
          if (val is num) {
            total += val;
            count++;
          }
        }
        if (count == 0) return 0.0;
        return total / count;

      case RollupFunction.min:
        num? minVal;
        for (final val in relatedRowValues) {
          if (val is num) {
            if (minVal == null || val < minVal) minVal = val;
          }
        }
        return minVal;

      case RollupFunction.max:
        num? maxVal;
        for (final val in relatedRowValues) {
          if (val is num) {
            if (maxVal == null || val > maxVal) maxVal = val;
          }
        }
        return maxVal;

      case RollupFunction.percentChecked:
        var checked = 0;
        for (final val in relatedRowValues) {
          if (val == true || val == 1 || val == 'true') checked++;
        }
        return (checked / relatedRowValues.length) * 100.0;
    }
  }
}
```

---

### 4.7 Clean Architecture Repository Implementation

#### 4.7.1 `lib/features/workspace_database/data/repositories/database_engine_repository_impl.dart`
```dart
import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/databases_dao.dart';
import '../../../../core/database/daos/database_properties_dao.dart';
import '../../../../core/database/daos/database_rows_dao.dart';
import '../../../../core/database/daos/database_cells_dao.dart';
import '../../../../core/database/daos/database_views_dao.dart';
import '../../../../core/database/daos/pages_dao.dart';
import '../../../../core/utils/formula_evaluator.dart';
import '../../../../core/utils/rollup_evaluator.dart';

import '../../domain/models/database_entity.dart';
import '../../domain/models/property_entity.dart';
import '../../domain/models/property_type.dart';
import '../../domain/models/row_entity.dart';
import '../../domain/models/cell_entity.dart';
import '../../domain/models/view_entity.dart';
import '../../domain/models/database_view_type.dart';
import '../../domain/models/rollup_function.dart';
import '../../domain/repositories/i_database_engine_repository.dart';

class DatabaseEngineRepositoryImpl implements IDatabaseEngineRepository {
  final AppDatabase _db;
  final DatabasesDao _databasesDao;
  final DatabasePropertiesDao _propertiesDao;
  final DatabaseRowsDao _rowsDao;
  final DatabaseCellsDao _cellsDao;
  final DatabaseViewsDao _viewsDao;
  final PagesDao _pagesDao;

  final _uuid = const Uuid();
  late final RollupEvaluator _rollupEvaluator;

  DatabaseEngineRepositoryImpl({
    required AppDatabase db,
    required DatabasesDao databasesDao,
    required DatabasePropertiesDao propertiesDao,
    required DatabaseRowsDao rowsDao,
    required DatabaseCellsDao cellsDao,
    required DatabaseViewsDao viewsDao,
    required PagesDao pagesDao,
  })  : _db = db,
        _databasesDao = databasesDao,
        _propertiesDao = propertiesDao,
        _rowsDao = rowsDao,
        _cellsDao = cellsDao,
        _viewsDao = viewsDao,
        _pagesDao = pagesDao {
    _rollupEvaluator = RollupEvaluator(cellsDao: _cellsDao);
  }

  @override
  Stream<DatabaseEntity> watchDatabase(String databaseId) {
    return _databasesDao.watchDatabaseById(databaseId).map((entry) {
      if (entry == null) throw ArgumentError('Database not found: $databaseId');
      return DatabaseEntity(
        id: entry.id,
        title: entry.title,
        pageId: entry.pageId,
      );
    });
  }

  @override
  Stream<List<PropertyEntity>> watchProperties(String databaseId) {
    return _propertiesDao.watchPropertiesForDatabase(databaseId).map(
      (entries) => entries.map(_mapPropertyEntryToEntity).toList(),
    );
  }

  @override
  Stream<List<RowEntity>> watchRows(String databaseId) {
    return _rowsDao.watchRowsForDatabase(databaseId).map(
      (entries) => entries.map(_mapRowEntryToEntity).toList(),
    );
  }

  @override
  Stream<List<CellEntity>> watchCells(String databaseId) {
    return _cellsDao.watchCellsForDatabase(databaseId).map(
      (entries) => entries.map(_mapCellEntryToEntity).toList(),
    );
  }

  @override
  Stream<List<ViewEntity>> watchViews(String databaseId) {
    return _viewsDao.watchViewsForDatabase(databaseId).map(
      (entries) => entries.map(_mapViewEntryToEntity).toList(),
    );
  }

  @override
  Future<DatabaseEntity> createDatabase({
    required String title,
    required String pageId,
  }) async {
    final dbId = 'db_${DateTime.now().microsecondsSinceEpoch}_${_uuid.v4().substring(0, 8)}';
    final now = DateTime.now();

    await _db.transaction(() async {
      await _databasesDao.insertDatabase(
        DatabasesTableCompanion.insert(
          id: dbId,
          pageId: pageId,
          title: Value(title),
          createdAt: now,
          updatedAt: now,
        ),
      );

      // Default 'Name' title property
      await addProperty(
        databaseId: dbId,
        name: 'Name',
        type: PropertyType.title,
      );

      // Default Table View
      await createView(
        databaseId: dbId,
        name: 'Table View',
        type: DatabaseViewType.table,
      );
    });

    return DatabaseEntity(id: dbId, title: title, pageId: pageId);
  }

  @override
  Future<PropertyEntity> addProperty({
    required String databaseId,
    required String name,
    required PropertyType type,
    Map<String, dynamic>? config,
  }) async {
    final existing = await _propertiesDao.getPropertiesForDatabase(databaseId);
    if (existing.any((p) => p.name.trim().toLowerCase() == name.trim().toLowerCase())) {
      throw ArgumentError('Duplicate property name in database: $name');
    }

    final propId = 'prop_${DateTime.now().microsecondsSinceEpoch}_${existing.length}';
    final now = DateTime.now();
    final effectiveConfig = Map<String, dynamic>.from(config ?? {});

    // Two-way relation automation
    if (type == PropertyType.relation && effectiveConfig['isTwoWay'] == true) {
      final targetDbId = effectiveConfig['targetDatabaseId'] as String?;
      if (targetDbId == null) {
        throw ArgumentError('Two-way relation requires targetDatabaseId');
      }

      final reciprocalPropId = 'prop_${DateTime.now().microsecondsSinceEpoch}_reciprocal';
      final currentDb = await _databasesDao.getDatabaseById(databaseId);
      final reciprocalName = effectiveConfig['reciprocalPropertyName'] as String? ??
          'Related ${currentDb?.title ?? 'Database'}';

      final targetProps = await _propertiesDao.getPropertiesForDatabase(targetDbId);
      if (targetProps.any((p) => p.name.trim().toLowerCase() == reciprocalName.trim().toLowerCase())) {
        throw ArgumentError('Duplicate property name in target database: $reciprocalName');
      }

      effectiveConfig['targetPropertyId'] = reciprocalPropId;

      final reciprocalConfig = <String, dynamic>{
        'targetDatabaseId': databaseId,
        'targetPropertyId': propId,
        'isTwoWay': true,
        'reciprocalPropertyName': name,
      };

      await _db.transaction(() async {
        await _propertiesDao.insertProperty(
          DatabasePropertiesTableCompanion.insert(
            id: propId,
            databaseId: databaseId,
            name: name,
            propertyType: type.name,
            sortOrder: Value(existing.length.toDouble()),
            configJson: Value(jsonEncode(effectiveConfig)),
            createdAt: now,
            updatedAt: now,
          ),
        );

        await _propertiesDao.insertProperty(
          DatabasePropertiesTableCompanion.insert(
            id: reciprocalPropId,
            databaseId: targetDbId,
            name: reciprocalName,
            propertyType: PropertyType.relation.name,
            sortOrder: Value(targetProps.length.toDouble()),
            configJson: Value(jsonEncode(reciprocalConfig)),
            createdAt: now,
            updatedAt: now,
          ),
        );
      });

      return PropertyEntity(
        id: propId,
        databaseId: databaseId,
        name: name,
        type: type,
        config: effectiveConfig,
      );
    }

    await _propertiesDao.insertProperty(
      DatabasePropertiesTableCompanion.insert(
        id: propId,
        databaseId: databaseId,
        name: name,
        propertyType: type.name,
        sortOrder: Value(existing.length.toDouble()),
        configJson: Value(jsonEncode(effectiveConfig)),
        createdAt: now,
        updatedAt: now,
      ),
    );

    return PropertyEntity(
      id: propId,
      databaseId: databaseId,
      name: name,
      type: type,
      config: effectiveConfig,
    );
  }

  @override
  Future<String> createRow(String databaseId) async {
    final db = await _databasesDao.getDatabaseById(databaseId);
    if (db == null) throw ArgumentError('Database not found: $databaseId');

    final now = DateTime.now();
    final rowId = 'row_${DateTime.now().microsecondsSinceEpoch}_${_uuid.v4().substring(0, 8)}';
    final pageId = _uuid.v4();

    return await _db.transaction(() async {
      // 1. Dual Identity: create underlying page
      await _pagesDao.insertPage(
        PagesCompanion.insert(
          id: pageId,
          parentPageId: Value(db.pageId),
          title: const Value('Untitled Row'),
          isDatabaseRow: const Value(true),
          createdAt: now,
          updatedAt: now,
        ),
      );

      // 2. Insert row record
      final existingRows = await _rowsDao.getRowsForDatabase(databaseId);
      await _rowsDao.insertRow(
        DatabaseRowsTableCompanion.insert(
          id: rowId,
          databaseId: databaseId,
          pageId: pageId,
          sortOrder: Value(existingRows.length.toDouble()),
          createdAt: now,
          updatedAt: now,
        ),
      );

      // 3. Find title property and initialize cell
      final props = await _propertiesDao.getPropertiesForDatabase(databaseId);
      final titleProp = props.where((p) => p.propertyType == PropertyType.title.name).firstOrNull;
      if (titleProp != null) {
        await _cellsDao.upsertCell(
          rowId: rowId,
          propertyId: titleProp.id,
          valueJson: jsonEncode('Untitled Row'),
        );
      }

      return rowId;
    });
  }

  @override
  Future<void> updatePropertyValue({
    required String rowId,
    required String propertyId,
    dynamic value,
  }) async {
    final prop = await _propertiesDao.getPropertyById(propertyId);
    if (prop == null) throw ArgumentError('Property not found: $propertyId');

    final propType = PropertyTypeParsing.fromString(prop.propertyType);

    await _db.transaction(() async {
      // 1. If Title property: keep underlying Page.title synchronized
      if (propType == PropertyType.title) {
        final row = await _rowsDao.getRowById(rowId);
        if (row != null && value is String) {
          await _pagesDao.updatePageTitle(row.pageId, value);
        }
      }

      // 2. If Relation property: handle reciprocal 2-way relation sync
      if (propType == PropertyType.relation) {
        await _handleRelationUpdate(
          sourceRowId: rowId,
          property: prop,
          newValue: value,
        );
        return;
      }

      // 3. Standard cell upsert
      final String? encodedValue = value == null ? null : jsonEncode(value);
      await _cellsDao.upsertCell(
        rowId: rowId,
        propertyId: propertyId,
        valueJson: encodedValue,
      );
    });
  }

  Future<void> _handleRelationUpdate({
    required String sourceRowId,
    required DatabasePropertyEntry property,
    dynamic newValue,
  }) async {
    final config = jsonDecode(property.configJson) as Map<String, dynamic>;
    final isTwoWay = config['isTwoWay'] == true;
    final reciprocalPropId = config['targetPropertyId'] as String?;

    // Parse new target row IDs
    final List<String> newTargetIds = [];
    if (newValue is String && newValue.isNotEmpty) {
      newTargetIds.add(newValue);
    } else if (newValue is List) {
      newTargetIds.addAll(newValue.map((e) => e.toString()));
    }

    // Get current cell value to compute delta
    final currentCell = await _cellsDao.getCell(sourceRowId, property.id);
    final List<String> oldTargetIds = [];
    if (currentCell?.valueJson != null) {
      final decoded = jsonDecode(currentCell!.valueJson!);
      if (decoded is String) {
        oldTargetIds.add(decoded);
      } else if (decoded is List) {
        oldTargetIds.addAll(decoded.map((e) => e.toString()));
      }
    }

    // Upsert source cell preserving exact format (single vs list vs null)
    String? serialized;
    if (newValue == null) {
      serialized = null;
    } else if (newValue is List) {
      serialized = jsonEncode(newTargetIds);
    } else {
      serialized = jsonEncode(newTargetIds.isEmpty ? null : newTargetIds.first);
    }

    await _cellsDao.upsertCell(
      rowId: sourceRowId,
      propertyId: property.id,
      valueJson: serialized,
    );

    // If 2-way relation, update reciprocal cells on target rows
    if (isTwoWay && reciprocalPropId != null) {
      final added = newTargetIds.where((id) => !oldTargetIds.contains(id)).toList();
      final removed = oldTargetIds.where((id) => !newTargetIds.contains(id)).toList();

      for (final targetId in added) {
        await _addReciprocalLink(targetRowId: targetId, reciprocalPropId: reciprocalPropId, sourceRowId: sourceRowId);
      }

      for (final targetId in removed) {
        await _removeReciprocalLink(targetRowId: targetId, reciprocalPropId: reciprocalPropId, sourceRowId: sourceRowId);
      }
    }
  }

  Future<void> _addReciprocalLink({
    required String targetRowId,
    required String reciprocalPropId,
    required String sourceRowId,
  }) async {
    final cell = await _cellsDao.getCell(targetRowId, reciprocalPropId);
    List<String> list = [];
    if (cell?.valueJson != null) {
      final decoded = jsonDecode(cell!.valueJson!);
      if (decoded is List) {
        list = List<String>.from(decoded);
      } else if (decoded is String) {
        list = [decoded];
      }
    }
    if (!list.contains(sourceRowId)) {
      list.add(sourceRowId);
      await _cellsDao.upsertCell(
        rowId: targetRowId,
        propertyId: reciprocalPropId,
        valueJson: jsonEncode(list),
      );
    }
  }

  Future<void> _removeReciprocalLink({
    required String targetRowId,
    required String reciprocalPropId,
    required String sourceRowId,
  }) async {
    final cell = await _cellsDao.getCell(targetRowId, reciprocalPropId);
    if (cell?.valueJson == null) return;
    final decoded = jsonDecode(cell!.valueJson!);
    if (decoded is List) {
      final list = List<String>.from(decoded);
      list.remove(sourceRowId);
      await _cellsDao.upsertCell(
        rowId: targetRowId,
        propertyId: reciprocalPropId,
        valueJson: jsonEncode(list),
      );
    } else if (decoded == sourceRowId) {
      await _cellsDao.upsertCell(
        rowId: targetRowId,
        propertyId: reciprocalPropId,
        valueJson: null,
      );
    }
  }

  @override
  Future<dynamic> getPropertyValue({
    required String rowId,
    required String propertyId,
  }) async {
    final cell = await _cellsDao.getCell(rowId, propertyId);
    if (cell == null || cell.valueJson == null) return null;
    return jsonDecode(cell.valueJson!);
  }

  @override
  Future<void> deleteRow(String rowId) async {
    final row = await _rowsDao.getRowById(rowId);
    if (row == null) return;

    await _db.transaction(() async {
      // 1. Maintain referential integrity across relation cells in other databases
      final referencingCells = await _cellsDao.findRelationCellsContaining(rowId);
      for (final cell in referencingCells) {
        if (cell.valueJson == null) continue;
        final decoded = jsonDecode(cell.valueJson!);
        if (decoded is List) {
          final list = List<dynamic>.from(decoded);
          if (list.remove(rowId)) {
            await _cellsDao.upsertCell(
              rowId: cell.rowId,
              propertyId: cell.propertyId,
              valueJson: jsonEncode(list),
            );
          }
        } else if (decoded == rowId) {
          await _cellsDao.upsertCell(
            rowId: cell.rowId,
            propertyId: cell.propertyId,
            valueJson: null,
          );
        }
      }

      // 2. Delete row from database_rows (cascades to cells)
      await _rowsDao.deleteRow(rowId);

      // 3. Delete underlying page (cascades to blocks)
      await _pagesDao.deletePage(row.pageId);
    });
  }

  @override
  Future<ViewEntity> createView({
    required String databaseId,
    required String name,
    required DatabaseViewType type,
    Map<String, dynamic>? config,
  }) async {
    final views = await _viewsDao.getViewsForDatabase(databaseId);
    final viewId = 'view_${DateTime.now().microsecondsSinceEpoch}_${views.length}';
    final now = DateTime.now();
    final effectiveConfig = config ?? {};

    await _viewsDao.insertView(
      DatabaseViewsTableCompanion.insert(
        id: viewId,
        databaseId: databaseId,
        name: Value(name),
        viewType: type.name,
        sortOrder: Value(views.length.toDouble()),
        configJson: Value(jsonEncode(effectiveConfig)),
        createdAt: now,
        updatedAt: now,
      ),
    );

    return ViewEntity(
      id: viewId,
      databaseId: databaseId,
      name: name,
      type: type,
      config: effectiveConfig,
    );
  }

  @override
  Future<dynamic> evaluateFormula({
    required String rowId,
    required String expression,
    Set<String>? visitedProperties,
  }) async {
    final evaluator = FormulaEvaluator(
      visitedProperties: visitedProperties,
      propertyLookup: (propName) async {
        final row = await _rowsDao.getRowById(rowId);
        if (row == null) return null;
        final props = await _propertiesDao.getPropertiesForDatabase(row.databaseId);
        final prop = props.where((p) => p.name.trim().toLowerCase() == propName.trim().toLowerCase()).firstOrNull;
        if (prop == null) return null;
        return await getPropertyValue(rowId: rowId, propertyId: prop.id);
      },
    );
    return await evaluator.evaluate(expression);
  }

  @override
  Future<dynamic> computeRollup({
    required String rowId,
    required String relationPropertyId,
    required String targetPropertyId,
    required RollupFunction function,
  }) async {
    final relVal = await getPropertyValue(rowId: rowId, propertyId: relationPropertyId);
    final List<String> targetRowIds = [];
    if (relVal is String && relVal.isNotEmpty) {
      targetRowIds.add(relVal);
    } else if (relVal is List) {
      targetRowIds.addAll(relVal.map((e) => e.toString()));
    }

    if (targetRowIds.isEmpty) {
      return _rollupEvaluator.compute(relatedRowValues: [], function: function);
    }

    final List<dynamic> extractedValues = [];
    for (final trId in targetRowIds) {
      final val = await getPropertyValue(rowId: trId, propertyId: targetPropertyId);
      if (val != null) extractedValues.add(val);
    }

    return _rollupEvaluator.compute(relatedRowValues: extractedValues, function: function);
  }

  // Mapping Helpers
  PropertyEntity _mapPropertyEntryToEntity(DatabasePropertyEntry e) {
    return PropertyEntity(
      id: e.id,
      databaseId: e.databaseId,
      name: e.name,
      type: PropertyTypeParsing.fromString(e.propertyType),
      config: jsonDecode(e.configJson) as Map<String, dynamic>,
    );
  }

  RowEntity _mapRowEntryToEntity(DatabaseRowEntry e) {
    return RowEntity(
      id: e.id,
      databaseId: e.databaseId,
      pageId: e.pageId,
      createdAt: e.createdAt,
      updatedAt: e.updatedAt,
    );
  }

  CellEntity _mapCellEntryToEntity(DatabaseCellEntry e) {
    return CellEntity(
      id: e.id,
      rowId: e.rowId,
      propertyId: e.propertyId,
      value: e.valueJson != null ? jsonDecode(e.valueJson!) : null,
    );
  }

  ViewEntity _mapViewEntryToEntity(DatabaseViewEntry e) {
    return ViewEntity(
      id: e.id,
      databaseId: e.databaseId,
      name: e.name,
      type: DatabaseViewType.values.firstWhere((t) => t.name == e.viewType),
      config: jsonDecode(e.configJson) as Map<String, dynamic>,
    );
  }
}
```

---

### 4.8 Unit Test Suite Specification (`test/unit/database_engine_test.dart`)

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';

import 'package:hampa/core/database/app_database.dart';
import 'package:hampa/core/database/daos/pages_dao.dart';
import 'package:hampa/core/database/daos/blocks_dao.dart';
import 'package:hampa/core/database/daos/databases_dao.dart';
import 'package:hampa/core/database/daos/database_properties_dao.dart';
import 'package:hampa/core/database/daos/database_rows_dao.dart';
import 'package:hampa/core/database/daos/database_cells_dao.dart';
import 'package:hampa/core/database/daos/database_views_dao.dart';
import 'package:hampa/features/workspace_database/data/repositories/database_engine_repository_impl.dart';
import 'package:hampa/features/workspace_database/domain/models/property_type.dart';
import 'package:hampa/features/workspace_database/domain/models/rollup_function.dart';
import 'package:hampa/features/workspace_database/domain/models/database_view_type.dart';

void main() {
  late AppDatabase db;
  late PagesDao pagesDao;
  late BlocksDao blocksDao;
  late DatabasesDao databasesDao;
  late DatabasePropertiesDao propertiesDao;
  late DatabaseRowsDao rowsDao;
  late DatabaseCellsDao cellsDao;
  late DatabaseViewsDao viewsDao;
  late DatabaseEngineRepositoryImpl repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    pagesDao = PagesDao(db);
    blocksDao = BlocksDao(db);
    databasesDao = DatabasesDao(db);
    propertiesDao = DatabasePropertiesDao(db);
    rowsDao = DatabaseRowsDao(db);
    cellsDao = DatabaseCellsDao(db);
    viewsDao = DatabaseViewsDao(db);

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

  group('Milestone 2: Relational Database Schema & Persistence', () {
    test('Create database with default title property and table view', () async {
      final rootPageId = 'page_root';
      await pagesDao.insertPage(PagesCompanion.insert(
        id: rootPageId,
        title: const Value('Workspace Page'),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      final database = await repository.createDatabase(
        title: 'Project Tracker',
        pageId: rootPageId,
      );

      expect(database.title, equals('Project Tracker'));
      expect(database.pageId, equals(rootPageId));

      final props = await propertiesDao.getPropertiesForDatabase(database.id);
      expect(props.length, equals(1));
      expect(props.first.name, equals('Name'));
      expect(props.first.propertyType, equals(PropertyType.title.name));

      final views = await viewsDao.getViewsForDatabase(database.id);
      expect(views.length, equals(1));
      expect(views.first.name, equals('Table View'));
      expect(views.first.viewType, equals(DatabaseViewType.table.name));
    });

    test('Dual Identity Paradigm: createRow creates underlying page and syncs title', () async {
      final rootPageId = 'page_root';
      await pagesDao.insertPage(PagesCompanion.insert(
        id: rootPageId,
        title: const Value('Workspace'),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      final dbEntity = await repository.createDatabase(title: 'Tasks', pageId: rootPageId);
      final rowId = await repository.createRow(dbEntity.id);

      final row = await rowsDao.getRowById(rowId);
      expect(row, isNotNull);

      // Verify underlying page exists with isDatabaseRow = true
      final page = await pagesDao.getPageById(row!.pageId);
      expect(page, isNotNull);
      expect(page!.isDatabaseRow, isTrue);
      expect(page.title, equals('Untitled Row'));

      // Update title cell and verify page.title updates
      final props = await propertiesDao.getPropertiesForDatabase(dbEntity.id);
      final titleProp = props.firstWhere((p) => p.propertyType == PropertyType.title.name);

      await repository.updatePropertyValue(
        rowId: rowId,
        propertyId: titleProp.id,
        value: 'Finish M2 Specification',
      );

      final updatedPage = await pagesDao.getPageById(row.pageId);
      expect(updatedPage!.title, equals('Finish M2 Specification'));
    });

    test('Two-Way Relations: automatic reciprocal property creation and synchronization', () async {
      final rootPageId = 'page_root';
      await pagesDao.insertPage(PagesCompanion.insert(
        id: rootPageId,
        title: const Value('Workspace'),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      final dbA = await repository.createDatabase(title: 'Projects', pageId: rootPageId);
      final dbB = await repository.createDatabase(title: 'Tasks', pageId: rootPageId);

      // Create two-way relation on dbA pointing to dbB
      final relPropA = await repository.addProperty(
        databaseId: dbA.id,
        name: 'Linked Tasks',
        type: PropertyType.relation,
        config: {
          'targetDatabaseId': dbB.id,
          'isTwoWay': true,
          'reciprocalPropertyName': 'Project',
        },
      );

      // Check reciprocal property was auto-created in dbB
      final bProps = await propertiesDao.getPropertiesForDatabase(dbB.id);
      final relPropB = bProps.firstWhere((p) => p.name == 'Project');
      expect(relPropB.propertyType, equals(PropertyType.relation.name));

      // Create rows in both databases
      final projRow = await repository.createRow(dbA.id);
      final taskRow = await repository.createRow(dbB.id);

      // Link projRow to taskRow
      await repository.updatePropertyValue(
        rowId: projRow,
        propertyId: relPropA.id,
        value: [taskRow],
      );

      // Verify reciprocal link is populated on taskRow
      final reciprocalVal = await repository.getPropertyValue(
        rowId: taskRow,
        propertyId: relPropB.id,
      );
      expect(reciprocalVal, isA<List>());
      expect((reciprocalVal as List), contains(projRow));
    });

    test('Referential Integrity: deleting row cleans relation references across databases', () async {
      final rootPageId = 'page_root';
      await pagesDao.insertPage(PagesCompanion.insert(
        id: rootPageId,
        title: const Value('Workspace'),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      final dbA = await repository.createDatabase(title: 'DB A', pageId: rootPageId);
      final dbB = await repository.createDatabase(title: 'DB B', pageId: rootPageId);

      final relProp = await repository.addProperty(
        databaseId: dbA.id,
        name: 'Ref',
        type: PropertyType.relation,
      );

      final rowA = await repository.createRow(dbA.id);
      final target1 = await repository.createRow(dbB.id);
      final target2 = await repository.createRow(dbB.id);

      await repository.updatePropertyValue(
        rowId: rowA,
        propertyId: relProp.id,
        value: [target1, target2],
      );

      // Delete target1
      await repository.deleteRow(target1);

      final updatedRef = await repository.getPropertyValue(
        rowId: rowA,
        propertyId: relProp.id,
      ) as List;

      expect(updatedRef.length, equals(1));
      expect(updatedRef.first, equals(target2));
    });

    test('Formula Expression Evaluation & Cycle Detection', () async {
      final rootPageId = 'page_root';
      await pagesDao.insertPage(PagesCompanion.insert(
        id: rootPageId,
        title: const Value('Workspace'),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      final db = await repository.createDatabase(title: 'Math DB', pageId: rootPageId);
      final numProp1 = await repository.addProperty(databaseId: db.id, name: 'A', type: PropertyType.number);
      final numProp2 = await repository.addProperty(databaseId: db.id, name: 'B', type: PropertyType.number);

      final row = await repository.createRow(db.id);
      await repository.updatePropertyValue(rowId: row, propertyId: numProp1.id, value: 20);
      await repository.updatePropertyValue(rowId: row, propertyId: numProp2.id, value: 30);

      final sumResult = await repository.evaluateFormula(
        rowId: row,
        expression: 'prop("A") + prop("B")',
      );
      expect(sumResult, equals(50.0));

      final divZero = await repository.evaluateFormula(
        rowId: row,
        expression: '100 / 0',
      );
      expect(divZero, equals('#DIV/0!'));

      final cycle = await repository.evaluateFormula(
        rowId: row,
        expression: 'prop("A")',
        visitedProperties: {'prop("A")'},
      );
      expect(cycle, equals('#CYCLE!'));
    });

    test('Rollup Calculations: sum, average, count, percentChecked', () async {
      final rootPageId = 'page_root';
      await pagesDao.insertPage(PagesCompanion.insert(
        id: rootPageId,
        title: const Value('Workspace'),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      final coursesDb = await repository.createDatabase(title: 'Courses', pageId: rootPageId);
      final assignmentsDb = await repository.createDatabase(title: 'Assignments', pageId: rootPageId);

      final relProp = await repository.addProperty(
        databaseId: coursesDb.id,
        name: 'Assignments',
        type: PropertyType.relation,
      );

      final scoreProp = await repository.addProperty(
        databaseId: assignmentsDb.id,
        name: 'Score',
        type: PropertyType.number,
      );

      final doneProp = await repository.addProperty(
        databaseId: assignmentsDb.id,
        name: 'Done',
        type: PropertyType.checkbox,
      );

      final courseRow = await repository.createRow(coursesDb.id);
      final a1 = await repository.createRow(assignmentsDb.id);
      final a2 = await repository.createRow(assignmentsDb.id);

      await repository.updatePropertyValue(rowId: a1, propertyId: scoreProp.id, value: 80);
      await repository.updatePropertyValue(rowId: a1, propertyId: doneProp.id, value: true);

      await repository.updatePropertyValue(rowId: a2, propertyId: scoreProp.id, value: 100);
      await repository.updatePropertyValue(rowId: a2, propertyId: doneProp.id, value: false);

      await repository.updatePropertyValue(
        rowId: courseRow,
        propertyId: relProp.id,
        value: [a1, a2],
      );

      final sum = await repository.computeRollup(
        rowId: courseRow,
        relationPropertyId: relProp.id,
        targetPropertyId: scoreProp.id,
        function: RollupFunction.sum,
      );
      expect(sum, equals(180));

      final avg = await repository.computeRollup(
        rowId: courseRow,
        relationPropertyId: relProp.id,
        targetPropertyId: scoreProp.id,
        function: RollupFunction.average,
      );
      expect(avg, equals(90.0));

      final count = await repository.computeRollup(
        rowId: courseRow,
        relationPropertyId: relProp.id,
        targetPropertyId: scoreProp.id,
        function: RollupFunction.count,
      );
      expect(count, equals(2));

      final percent = await repository.computeRollup(
        rowId: courseRow,
        relationPropertyId: relProp.id,
        targetPropertyId: doneProp.id,
        function: RollupFunction.percentChecked,
      );
      expect(percent, equals(50.0));
    });
  });
}
```

---

## 5. Verification Method

### 5.1 Independent Verification Commands

1. **Drift Code Generation**:
   ```powershell
   dart run build_runner build --delete-conflicting-outputs
   ```
   *Expected outcome*: `app_database.g.dart` and the 5 DAO `.g.dart` files compile cleanly with 0 errors.

2. **Milestone 2 Database Engine Unit Test Suite**:
   ```powershell
   flutter test test/unit/database_engine_test.dart
   ```
   *Expected outcome*: 100% pass across all 6 test scenarios (database creation, dual identity page sync, 2-way relations, cascading delete referential integrity, formulas & cycle detection, rollup aggregations).

3. **E2E Feature & Boundary Regression Suites**:
   ```powershell
   flutter test test/e2e/tier1_feature_coverage/f08_f16_relational_database_test.dart
   flutter test test/e2e/tier2_boundary_corner/f08_f16_relational_boundary_test.dart
   ```
   *Expected outcome*: All F08, F09, F10, and F11 test cases pass.

### 5.2 Invalidation Conditions
- If any database row is created without an underlying `pages` row (`isDatabaseRow == true`), invalidating the Dual Identity Paradigm.
- If updating a row's `title` property does not automatically update `pages.title`.
- If creating a two-way relation does not atomically create the reciprocal property in the target database.
- If deleting a row leaves dangling reference IDs in relation cells in other databases.
- If cyclical formulas cause infinite recursion or stack overflow instead of returning `'#CYCLE!'`.
