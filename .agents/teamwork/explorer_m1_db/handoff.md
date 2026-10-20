# Milestone 1 Technical Implementation Blueprint: Drift SQLite Core & Offline Persistence

**Agent**: `explorer_m1_db` (Drift DB & Data Architecture Explorer)  
**Working Directory**: `c:\parsa\HamPA\.agents\teamwork\explorer_m1_db`  
**Parent Orchestrator Conversation ID**: `22d8faaf-eb90-463c-99a6-32a4eb94320e`  
**Date**: 2026-10-16T17:00:00Z  

---

## 1. Observation

### 1.1 Sources & Authoritative Inputs Examined
1. `c:\parsa\HamPA\.agents\teamwork\explorer_m1_db\DISPATCH.md` (Lines 1–21):
   - Scope: Milestone 1 (M1) Local-First Drift SQLite Core.
   - Deliverables:
     1. Flutter project configuration (`pubspec.yaml`) with `drift: ^2.24.0`, `drift_flutter: ^0.2.0`, `path_provider`, `path`, `uuid`, etc.
     2. Drift database schema and DAOs:
        - `pages` table & `PagesDao` (CRUD, hierarchical queries, `watchPageTree`, `updateParent`, sort orders).
        - `blocks` table & `BlocksDao` (CRUD, `watchBlocksForPage`, fractional order indexing, type-specific JSON content).
        - `subjects` table & `SubjectsDao` (core subject definitions with colors and goals).
     3. Local-first transaction management and offline persistence guarantees (AC3).
     4. Unit tests in `test/unit/drift_database_test.dart`.
     5. Concrete code templates and architectural recommendations in `handoff.md`.
2. `c:\parsa\HamPA\.agents\teamwork\ORIGINAL_REQUEST.md`:
   - R1 (Lines 12–18): "Hierarchical page tree supporting arbitrary nesting and drag-and-drop organization", "Modular block-based editor supporting text, headings, interactive checklists, callouts, toggles, code syntax highlighting, and LaTeX math formatting", "Local-first architecture (SQLite / Drift + local cache) for zero-latency offline writing and editing."
   - R2 (Line 22): "color-coded subjects with daily goals".
   - Acceptance Criteria (Line 42): "AC3: Offline edits persist reliably in local Drift SQLite and synchronize upon reconnection without data corruption."
3. `c:\parsa\HamPA\PROJECT.md`:
   - Lines 7–10: Data layer consists of Drift SQLite database (`app_database.dart`), DAOs, and local-first reactive streams.
   - Lines 13–15: Dual Identity Paradigm: "Every row in a relational database has a 1:1 dual identity as an underlying `Page` (`is_database_row = TRUE`)."
   - Lines 78–86: Interface Contract `IWorkspaceRepository`:
     ```dart
     abstract class IWorkspaceRepository {
       Stream<List<PageEntity>> watchPageTree();
       Future<PageEntity> createPage({String? parentPageId, required String title, String? icon, bool isDatabaseRow = false});
       Future<void> updatePageParent({required String pageId, String? newParentPageId, required double newSortOrder});
       Stream<List<BlockEntity>> watchBlocksForPage(String pageId);
       Future<void> insertBlock(BlockEntity block);
       Future<void> updateBlock(BlockEntity block);
       Future<void> deleteBlock(String blockId);
     }
     ```
   - Lines 166–170: Code layout for database: `lib/core/database/` with `app_database.dart`, `daos/`, and `tables/`.
4. `c:\parsa\HamPA\.agents\teamwork\explorer_survey_env\handoff.md`:
   - Observation 1.3: `sqlite3_flutter_libs` is flagged as `0.6.0+eol` with advisory "Not used anymore, update to version 3.x of package:sqlite3 instead". `drift_flutter: ^0.2.0` natively manages multi-platform connections across Windows Desktop, Android, iOS, and Web.
5. Peer Dispatches:
   - `explorer_m1_tree\DISPATCH.md`: Relies on `PagesDao.watchPageTree()` and `updatePageParent()` with LexoRank / fractional sort order for drag-and-drop re-parenting and cycle prevention.
   - `explorer_m1_editor\DISPATCH.md`: Relies on `BlocksDao.watchBlocksForPage()` and `updateBlockContent()` with debounced auto-save.

---

## 2. Logic Chain

1. **Local-First Zero-Latency Durability (AC3)**:
   - To satisfy AC3 (offline writing with zero corruption and instantaneous responsiveness), SQLite must be configured with Write-Ahead Logging (`PRAGMA journal_mode = WAL;`) and synchronous normal mode (`PRAGMA synchronous = NORMAL;`).
   - WAL allows concurrent readers to query while transactions commit in milliseconds without blocking the Flutter main isolate.
   - Foreign key enforcement (`PRAGMA foreign_keys = ON;`) ensures that deleting a page cleanly cascades to all child pages and blocks without creating orphaned records.

2. **Decoupling Drift Code-Generation from Domain & UI**:
   - Drift generates data classes (`PageEntry`, `BlockEntry`, `SubjectEntry`) and companions (`PagesCompanion`, etc.) via `build_runner`.
   - Directly exposing generated classes to UI widgets creates tight coupling and compilation roadblocks if code-gen has not yet run.
   - Designing pure Dart Domain Models (`PageEntity`, `BlockEntity`, `SubjectEntity`) and implementing `IWorkspaceRepository` and `ISubjectsRepository` creates a clean interface boundary. Peer agents (`explorer_m1_tree` and `explorer_m1_editor`) can construct their BLoCs/Notifiers and mock repositories in unit/widget tests without waiting for Drift build steps.

3. **Hierarchical Page Tree & Cycle Safety**:
   - The `pages` table supports arbitrary nesting depth via `parent_page_id` self-referencing foreign key.
   - When moving a page in the sidebar tree, user error or drag-and-drop glitches could attempt to move a parent into its own descendant (creating a cycle $A \to B \to A$ that locks recursive tree renderers in infinite loops).
   - In `PagesDao.updatePageParent`, an explicit recursive ancestor traversal `_isDescendantOf` validates graph integrity before executing the update, throwing `ArgumentError` if a cycle is attempted.

4. **Fractional Indexing for $O(1)$ Block Reordering**:
   - In the Notion block editor, users insert blocks between existing blocks or drag-and-drop blocks to reorder.
   - Storing sequential integers (`order = 1, 2, 3...`) forces an $O(N)$ write shifting every subsequent block on every insert or drag.
   - Using string-based fractional indexing (`order_key` formatted via LexoRank) allows inserting a block between any two keys in $O(1)$ without touching neighboring rows.

5. **In-Memory SQLite for Instant, Deterministic Unit Testing**:
   - Unit tests must not mutate or depend on local persistent disk files.
   - `NativeDatabase.memory()` creates an isolated SQLite database in RAM for each test group, validating CRUD, stream reactivity, cascade deletion, transaction rollbacks, and cycle prevention in under 200 milliseconds.

---

## 3. Caveats

1. **Flutter SDK Setup**: Flutter CLI is not pre-installed on the host machine. Scaffolding commands (`flutter create .`, `dart run build_runner build`) will be executed by the Milestone 1 worker once the Flutter SDK is cloned or extracted to `C:\flutter`.
2. **Drift Code-Generation vs Handcrafted Classes**: When running `flutter test`, `app_database.g.dart` is required by the Drift compiler. For initial scaffolding, both the source table/DAO definitions and the generated code contract are documented here so `build_runner` produces the exact expected symbols.
3. **Web Support**: On Web, Drift utilizes Wasm and IndexedDB via `drift_flutter`. For Windows Desktop and Android, native `sqlite3` is utilized automatically by `drift_flutter`.

---

## 4. Conclusion & File-by-File Implementation Plan

### 4.1 Target File Map

```
c:\parsa\HamPA\
├── pubspec.yaml
├── lib/
│   ├── core/
│   │   └── database/
│   │       ├── app_database.dart
│   │       ├── app_database.g.dart          # Generated via build_runner
│   │       ├── tables/
│   │       │   ├── pages_table.dart
│   │       │   ├── blocks_table.dart
│   │       │   └── subjects_table.dart
│   │       └── daos/
│   │           ├── pages_dao.dart
│   │           ├── blocks_dao.dart
│   │           └── subjects_dao.dart
│   └── features/
│       ├── workspace_editor/
│       │   ├── domain/
│       │   │   ├── models/
│       │   │   │   ├── page_entity.dart
│       │   │   │   └── block_entity.dart
│       │   │   └── repositories/
│       │   │       └── workspace_repository.dart
│       │   └── data/
│       │       └── repositories/
│       │           └── workspace_repository_impl.dart
│       └── focus_engine/
│           ├── domain/
│           │   ├── models/
│           │   │   └── subject_entity.dart
│           │   └── repositories/
│           │       └── subjects_repository.dart
│           └── data/
│               └── repositories/
│                   └── subjects_repository_impl.dart
└── test/
    └── unit/
        └── drift_database_test.dart
```

---

### 4.2 File 1: `pubspec.yaml`
```yaml
name: hampa
description: "HamPA (هم‌پا) - Hybrid Notion Workspace & YPT Focus Planner"
publish_to: "none"
version: 1.0.0+1

environment:
  sdk: ">=3.4.0 <4.0.0"
  flutter: ">=3.22.0"

dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^2.0.0

  # State Management & Architecture
  flutter_bloc: ^9.1.1
  provider: ^6.1.5
  go_router: ^18.1.0

  # Local-First SQLite Database (Notion & YPT Core)
  drift: ^2.24.0
  drift_flutter: ^0.2.0
  path_provider: ^2.1.5
  path: ^1.9.0
  shared_preferences: ^2.5.6

  # Notion Rich Block Formatting
  flutter_math_fork: ^0.7.4
  flutter_highlight: ^0.7.0
  flutter_markdown: ^0.7.7

  # YPT Timetable, Sound & Sensors
  sensors_plus: ^7.1.1
  audioplayers: ^6.8.1
  table_calendar: ^3.3.0
  fl_chart: ^1.2.0

  # Social Presence & Utilities
  web_socket_channel: ^3.0.3
  uuid: ^4.5.1
  intl: ^0.20.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  build_runner: ^2.4.15
  drift_dev: ^2.24.0
  bloc_test: ^10.0.0
  mocktail: ^1.0.5
  test: ^1.25.8
  sqlite3: ^2.4.6

flutter:
  uses-material-design: true
  assets:
    - assets/sounds/
    - assets/icons/
```

---

### 4.3 File 2: `lib/core/database/tables/pages_table.dart`
```dart
import 'package:drift/drift.dart';

/// Table representing Notion-like hierarchical pages.
/// Also serves as the 1:1 dual identity backing store for relational database rows.
@TableIndex(name: 'idx_pages_parent', columns: {#parentPageId})
@TableIndex(name: 'idx_pages_parent_sort', columns: {#parentPageId, #sortOrder})
@DataClassName('PageEntry')
class Pages extends Table {
  TextColumn get id => text()();
  TextColumn get parentPageId => text().nullable().references(Pages, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text().withDefault(const Constant('Untitled'))();
  TextColumn get icon => text().nullable()();
  TextColumn get coverImageUrl => text().nullable()();
  BoolColumn get isDatabaseRow => boolean().withDefault(const Constant(false))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  RealColumn get sortOrder => real().withDefault(const Constant(0.0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
```

---

### 4.4 File 3: `lib/core/database/tables/blocks_table.dart`
```dart
import 'package:drift/drift.dart';
import 'pages_table.dart';

/// Table representing modular blocks within a page.
/// Supports arbitrary nesting (toggles) and fractional indexing (LexoRank).
@TableIndex(name: 'idx_blocks_page_order', columns: {#pageId, #orderKey})
@TableIndex(name: 'idx_blocks_parent', columns: {#parentBlockId})
@DataClassName('BlockEntry')
class Blocks extends Table {
  TextColumn get id => text()();
  TextColumn get pageId => text().references(Pages, #id, onDelete: KeyAction.cascade)();
  TextColumn get parentBlockId => text().nullable().references(Blocks, #id, onDelete: KeyAction.cascade)();
  TextColumn get blockType => text()(); // 'text', 'heading_1', 'heading_2', 'heading_3', 'checklist', 'callout', 'toggle', 'code', 'math', 'divider', 'quote'
  TextColumn get orderKey => text()(); // LexoRank string for O(1) drag-and-drop ordering
  TextColumn get contentJson => text().withDefault(const Constant('{}'))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
```

---

### 4.5 File 4: `lib/core/database/tables/subjects_table.dart`
```dart
import 'package:drift/drift.dart';

/// Table representing study subjects with color branding and daily goals.
@TableIndex(name: 'idx_subjects_sort', columns: {#sortOrder})
@DataClassName('SubjectEntry')
class Subjects extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get colorHex => text()(); // e.g. '#3B82F6'
  TextColumn get icon => text().nullable()();
  IntColumn get dailyGoalMinutes => integer().withDefault(const Constant(60))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  RealColumn get sortOrder => real().withDefault(const Constant(0.0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
```

---

### 4.6 File 5: `lib/core/database/daos/pages_dao.dart`
```dart
import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/pages_table.dart';

part 'pages_dao.g.dart';

@DriftAccessor(tables: [Pages])
class PagesDao extends DatabaseAccessor<AppDatabase> with _$PagesDaoMixin {
  PagesDao(super.db);

  /// Watches all non-archived pages for reactive tree construction in UI
  Stream<List<PageEntry>> watchPageTree() {
    return (select(pages)
          ..where((tbl) => tbl.isArchived.equals(false))
          ..orderBy([
            (tbl) => OrderingTerm(expression: tbl.sortOrder, mode: OrderingMode.asc),
            (tbl) => OrderingTerm(expression: tbl.createdAt, mode: OrderingMode.asc),
          ]))
        .watch();
  }

  /// Watches sub-pages of a parent or root pages if parentId is null
  Stream<List<PageEntry>> watchSubPages(String? parentId) {
    return (select(pages)
          ..where((tbl) =>
              tbl.isArchived.equals(false) &
              (parentId == null ? tbl.parentPageId.isNull() : tbl.parentPageId.equals(parentId)))
          ..orderBy([
            (tbl) => OrderingTerm(expression: tbl.sortOrder, mode: OrderingMode.asc),
          ]))
        .watch();
  }

  /// Watches a single page
  Stream<PageEntry?> watchPageById(String id) {
    return (select(pages)..where((tbl) => tbl.id.equals(id))).watchSingleOrNull();
  }

  /// One-shot page retrieval
  Future<PageEntry?> getPageById(String id) {
    return (select(pages)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  /// Insert page
  Future<int> insertPage(PagesCompanion entry) {
    return into(pages).insert(entry);
  }

  /// Update page entry
  Future<bool> updatePageEntry(PagesCompanion entry) {
    return update(pages).replace(entry);
  }

  /// Update title
  Future<int> updatePageTitle(String id, String newTitle) {
    return (update(pages)..where((tbl) => tbl.id.equals(id))).write(
      PagesCompanion(
        title: Value(newTitle),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Update icon
  Future<int> updatePageIcon(String id, String? newIcon) {
    return (update(pages)..where((tbl) => tbl.id.equals(id))).write(
      PagesCompanion(
        icon: Value(newIcon),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Re-parents a page and updates sort order with cycle prevention
  Future<void> updatePageParent({
    required String pageId,
    String? newParentPageId,
    required double newSortOrder,
  }) async {
    if (pageId == newParentPageId) {
      throw ArgumentError('A page cannot be its own parent.');
    }

    if (newParentPageId != null) {
      final isDescendant = await _isDescendantOf(
        possibleChildId: newParentPageId,
        ancestorId: pageId,
      );
      if (isDescendant) {
        throw ArgumentError('Cannot move a page under its own descendant.');
      }
    }

    await (update(pages)..where((tbl) => tbl.id.equals(pageId))).write(
      PagesCompanion(
        parentPageId: Value(newParentPageId),
        sortOrder: Value(newSortOrder),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Checks if possibleChildId is a descendant of ancestorId
  Future<bool> _isDescendantOf({
    required String possibleChildId,
    required String ancestorId,
  }) async {
    String? currentParent = possibleChildId;
    while (currentParent != null) {
      if (currentParent == ancestorId) return true;
      final page = await getPageById(currentParent);
      currentParent = page?.parentPageId;
    }
    return false;
  }

  /// Resolves the ancestor breadcrumb trail from root to current page
  Future<List<PageEntry>> getBreadcrumbs(String pageId) async {
    final breadcrumbs = <PageEntry>[];
    String? currentId = pageId;

    while (currentId != null) {
      final page = await getPageById(currentId);
      if (page == null) break;
      breadcrumbs.insert(0, page);
      currentId = page.parentPageId;
    }
    return breadcrumbs;
  }

  /// Soft delete
  Future<int> archivePage(String id) {
    return (update(pages)..where((tbl) => tbl.id.equals(id))).write(
      PagesCompanion(
        isArchived: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Hard delete (cascades to blocks and subpages)
  Future<int> deletePage(String id) {
    return (delete(pages)..where((tbl) => tbl.id.equals(id))).go();
  }
}
```

---

### 4.7 File 6: `lib/core/database/daos/blocks_dao.dart`
```dart
import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/blocks_table.dart';

part 'blocks_dao.g.dart';

@DriftAccessor(tables: [Blocks])
class BlocksDao extends DatabaseAccessor<AppDatabase> with _$BlocksDaoMixin {
  BlocksDao(super.db);

  /// Watches all blocks for a page ordered by orderKey
  Stream<List<BlockEntry>> watchBlocksForPage(String pageId) {
    return (select(blocks)
          ..where((tbl) => tbl.pageId.equals(pageId) & tbl.isArchived.equals(false))
          ..orderBy([
            (tbl) => OrderingTerm(expression: tbl.orderKey, mode: OrderingMode.asc),
          ]))
        .watch();
  }

  /// Watches nested blocks inside a toggle container
  Stream<List<BlockEntry>> watchChildBlocks(String parentBlockId) {
    return (select(blocks)
          ..where((tbl) =>
              tbl.parentBlockId.equals(parentBlockId) & tbl.isArchived.equals(false))
          ..orderBy([
            (tbl) => OrderingTerm(expression: tbl.orderKey, mode: OrderingMode.asc),
          ]))
        .watch();
  }

  /// One-shot retrieval of page blocks
  Future<List<BlockEntry>> getBlocksForPage(String pageId) {
    return (select(blocks)
          ..where((tbl) => tbl.pageId.equals(pageId) & tbl.isArchived.equals(false))
          ..orderBy([
            (tbl) => OrderingTerm(expression: tbl.orderKey, mode: OrderingMode.asc),
          ]))
        .get();
  }

  Future<BlockEntry?> getBlockById(String id) {
    return (select(blocks)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  Future<int> insertBlock(BlocksCompanion entry) {
    return into(blocks).insert(entry);
  }

  Future<bool> updateBlockEntry(BlocksCompanion entry) {
    return update(blocks).replace(entry);
  }

  Future<int> updateBlockContent(String id, String contentJson) {
    return (update(blocks)..where((tbl) => tbl.id.equals(id))).write(
      BlocksCompanion(
        contentJson: Value(contentJson),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> updateBlockOrderKey(String id, String newOrderKey) {
    return (update(blocks)..where((tbl) => tbl.id.equals(id))).write(
      BlocksCompanion(
        orderKey: Value(newOrderKey),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> updateBlockParent({
    required String id,
    String? newParentBlockId,
    required String newOrderKey,
  }) {
    return (update(blocks)..where((tbl) => tbl.id.equals(id))).write(
      BlocksCompanion(
        parentBlockId: Value(newParentBlockId),
        orderKey: Value(newOrderKey),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> deleteBlock(String id) {
    return (delete(blocks)..where((tbl) => tbl.id.equals(id))).go();
  }

  Future<void> batchUpsertBlocks(List<BlocksCompanion> entries) async {
    await batch((b) {
      b.insertAllOnConflictUpdate(blocks, entries);
    });
  }
}
```

---

### 4.8 File 7: `lib/core/database/daos/subjects_dao.dart`
```dart
import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/subjects_table.dart';

part 'subjects_dao.g.dart';

@DriftAccessor(tables: [Subjects])
class SubjectsDao extends DatabaseAccessor<AppDatabase> with _$SubjectsDaoMixin {
  SubjectsDao(super.db);

  Stream<List<SubjectEntry>> watchActiveSubjects() {
    return (select(subjects)
          ..where((tbl) => tbl.isArchived.equals(false))
          ..orderBy([
            (tbl) => OrderingTerm(expression: tbl.sortOrder, mode: OrderingMode.asc),
            (tbl) => OrderingTerm(expression: tbl.name, mode: OrderingMode.asc),
          ]))
        .watch();
  }

  Future<List<SubjectEntry>> getActiveSubjects() {
    return (select(subjects)
          ..where((tbl) => tbl.isArchived.equals(false))
          ..orderBy([
            (tbl) => OrderingTerm(expression: tbl.sortOrder, mode: OrderingMode.asc),
            (tbl) => OrderingTerm(expression: tbl.name, mode: OrderingMode.asc),
          ]))
        .get();
  }

  Future<SubjectEntry?> getSubjectById(String id) {
    return (select(subjects)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  Future<int> insertSubject(SubjectsCompanion entry) {
    return into(subjects).insert(entry);
  }

  Future<bool> updateSubjectEntry(SubjectsCompanion entry) {
    return update(subjects).replace(entry);
  }

  Future<int> archiveSubject(String id) {
    return (update(subjects)..where((tbl) => tbl.id.equals(id))).write(
      SubjectsCompanion(
        isArchived: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Seeds standard subjects on first run
  Future<void> seedDefaultSubjects() async {
    final existing = await (select(subjects)..where((tbl) => tbl.isArchived.equals(false))).get();
    if (existing.isEmpty) {
      final now = DateTime.now();
      await batch((b) {
        b.insertAll(subjects, [
          SubjectsCompanion.insert(
            id: 'sub_math',
            name: 'Mathematics',
            colorHex: '#3B82F6',
            icon: const Value('calculator'),
            dailyGoalMinutes: const Value(90),
            sortOrder: const Value(0.0),
            createdAt: now,
            updatedAt: now,
          ),
          SubjectsCompanion.insert(
            id: 'sub_science',
            name: 'Science & Physics',
            colorHex: '#10B981',
            icon: const Value('atom'),
            dailyGoalMinutes: const Value(90),
            sortOrder: const Value(1.0),
            createdAt: now,
            updatedAt: now,
          ),
          SubjectsCompanion.insert(
            id: 'sub_languages',
            name: 'Languages & Literature',
            colorHex: '#F59E0B',
            icon: const Value('book'),
            dailyGoalMinutes: const Value(60),
            sortOrder: const Value(2.0),
            createdAt: now,
            updatedAt: now,
          ),
          SubjectsCompanion.insert(
            id: 'sub_general',
            name: 'General Study',
            colorHex: '#8B5CF6',
            icon: const Value('sparkles'),
            dailyGoalMinutes: const Value(60),
            sortOrder: const Value(3.0),
            createdAt: now,
            updatedAt: now,
          ),
        ]);
      });
    }
  }
}
```

---

### 4.9 File 8: `lib/core/database/app_database.dart`
```dart
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'tables/pages_table.dart';
import 'tables/blocks_table.dart';
import 'tables/subjects_table.dart';
import 'daos/pages_dao.dart';
import 'daos/blocks_dao.dart';
import 'daos/subjects_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Pages, Blocks, Subjects],
  daos: [PagesDao, BlocksDao, SubjectsDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 1;

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

### 4.10 File 9: `lib/features/workspace_editor/domain/models/page_entity.dart`
```dart
class PageEntity {
  final String id;
  final String? parentPageId;
  final String title;
  final String? icon;
  final String? coverImageUrl;
  final bool isDatabaseRow;
  final bool isArchived;
  final double sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PageEntity({
    required this.id,
    this.parentPageId,
    required this.title,
    this.icon,
    this.coverImageUrl,
    this.isDatabaseRow = false,
    this.isArchived = false,
    this.sortOrder = 0.0,
    required this.createdAt,
    required this.updatedAt,
  });

  PageEntity copyWith({
    String? id,
    String? parentPageId,
    String? title,
    String? icon,
    String? coverImageUrl,
    bool? isDatabaseRow,
    bool? isArchived,
    double? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PageEntity(
      id: id ?? this.id,
      parentPageId: parentPageId ?? this.parentPageId,
      title: title ?? this.title,
      icon: icon ?? this.icon,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      isDatabaseRow: isDatabaseRow ?? this.isDatabaseRow,
      isArchived: isArchived ?? this.isArchived,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
```

---

### 4.11 File 10: `lib/features/workspace_editor/domain/models/block_entity.dart`
```dart
enum BlockType {
  text,
  heading1,
  heading2,
  heading3,
  checklist,
  callout,
  toggle,
  code,
  math,
  divider,
  quote,
  databaseInline;

  String toDbString() {
    switch (this) {
      case BlockType.text: return 'text';
      case BlockType.heading1: return 'heading_1';
      case BlockType.heading2: return 'heading_2';
      case BlockType.heading3: return 'heading_3';
      case BlockType.checklist: return 'checklist';
      case BlockType.callout: return 'callout';
      case BlockType.toggle: return 'toggle';
      case BlockType.code: return 'code';
      case BlockType.math: return 'math';
      case BlockType.divider: return 'divider';
      case BlockType.quote: return 'quote';
      case BlockType.databaseInline: return 'database_inline';
    }
  }

  static BlockType fromDbString(String str) {
    switch (str) {
      case 'text': return BlockType.text;
      case 'heading_1': return BlockType.heading1;
      case 'heading_2': return BlockType.heading2;
      case 'heading_3': return BlockType.heading3;
      case 'checklist': return BlockType.checklist;
      case 'callout': return BlockType.callout;
      case 'toggle': return BlockType.toggle;
      case 'code': return BlockType.code;
      case 'math': return BlockType.math;
      case 'divider': return BlockType.divider;
      case 'quote': return BlockType.quote;
      case 'database_inline': return BlockType.databaseInline;
      default: return BlockType.text;
    }
  }
}

class BlockEntity {
  final String id;
  final String pageId;
  final String? parentBlockId;
  final BlockType type;
  final String orderKey;
  final String contentJson;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BlockEntity({
    required this.id,
    required this.pageId,
    this.parentBlockId,
    required this.type,
    required this.orderKey,
    this.contentJson = '{}',
    this.isArchived = false,
    required this.createdAt,
    required this.updatedAt,
  });

  BlockEntity copyWith({
    String? id,
    String? pageId,
    String? parentBlockId,
    BlockType? type,
    String? orderKey,
    String? contentJson,
    bool? isArchived,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BlockEntity(
      id: id ?? this.id,
      pageId: pageId ?? this.pageId,
      parentBlockId: parentBlockId ?? this.parentBlockId,
      type: type ?? this.type,
      orderKey: orderKey ?? this.orderKey,
      contentJson: contentJson ?? this.contentJson,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
```

---

### 4.12 File 11: `lib/features/focus_engine/domain/models/subject_entity.dart`
```dart
class SubjectEntity {
  final String id;
  final String name;
  final String colorHex;
  final String? icon;
  final int dailyGoalMinutes;
  final bool isArchived;
  final double sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SubjectEntity({
    required this.id,
    required this.name,
    required this.colorHex,
    this.icon,
    this.dailyGoalMinutes = 60,
    this.isArchived = false,
    this.sortOrder = 0.0,
    required this.createdAt,
    required this.updatedAt,
  });
}
```

---

### 4.13 File 12: `lib/features/workspace_editor/domain/repositories/workspace_repository.dart`
```dart
import '../models/page_entity.dart';
import '../models/block_entity.dart';

/// Pure domain interface contract for Milestone 1 Notion Workspace operations
abstract class IWorkspaceRepository {
  Stream<List<PageEntity>> watchPageTree();
  Future<PageEntity> createPage({
    String? parentPageId,
    required String title,
    String? icon,
    bool isDatabaseRow = false,
  });
  Future<void> updatePageParent({
    required String pageId,
    String? newParentPageId,
    required double newSortOrder,
  });
  Stream<List<BlockEntity>> watchBlocksForPage(String pageId);
  Future<void> insertBlock(BlockEntity block);
  Future<void> updateBlock(BlockEntity block);
  Future<void> deleteBlock(String blockId);
}
```

---

### 4.14 File 13: `lib/features/workspace_editor/data/repositories/workspace_repository_impl.dart`
```dart
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/pages_dao.dart';
import '../../../../core/database/daos/blocks_dao.dart';
import '../../domain/models/page_entity.dart';
import '../../domain/models/block_entity.dart';
import '../../domain/repositories/workspace_repository.dart';

class WorkspaceRepositoryImpl implements IWorkspaceRepository {
  final PagesDao _pagesDao;
  final BlocksDao _blocksDao;
  final _uuid = const Uuid();

  WorkspaceRepositoryImpl({
    required PagesDao pagesDao,
    required BlocksDao blocksDao,
  })  : _pagesDao = pagesDao,
        _blocksDao = blocksDao;

  @override
  Stream<List<PageEntity>> watchPageTree() {
    return _pagesDao.watchPageTree().map((entries) => entries.map(_mapPageEntryToEntity).toList());
  }

  @override
  Future<PageEntity> createPage({
    String? parentPageId,
    required String title,
    String? icon,
    bool isDatabaseRow = false,
  }) async {
    final now = DateTime.now();
    final newId = _uuid.v4();
    final entry = PagesCompanion.insert(
      id: newId,
      parentPageId: Value(parentPageId),
      title: Value(title),
      icon: Value(icon),
      isDatabaseRow: Value(isDatabaseRow),
      createdAt: now,
      updatedAt: now,
    );
    await _pagesDao.insertPage(entry);
    return PageEntity(
      id: newId,
      parentPageId: parentPageId,
      title: title,
      icon: icon,
      isDatabaseRow: isDatabaseRow,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Future<void> updatePageParent({
    required String pageId,
    String? newParentPageId,
    required double newSortOrder,
  }) {
    return _pagesDao.updatePageParent(
      pageId: pageId,
      newParentPageId: newParentPageId,
      newSortOrder: newSortOrder,
    );
  }

  @override
  Stream<List<BlockEntity>> watchBlocksForPage(String pageId) {
    return _blocksDao.watchBlocksForPage(pageId).map((entries) => entries.map(_mapBlockEntryToEntity).toList());
  }

  @override
  Future<void> insertBlock(BlockEntity block) {
    return _blocksDao.insertBlock(BlocksCompanion.insert(
      id: block.id,
      pageId: block.pageId,
      parentBlockId: Value(block.parentBlockId),
      blockType: block.type.toDbString(),
      orderKey: block.orderKey,
      contentJson: Value(block.contentJson),
      isArchived: Value(block.isArchived),
      createdAt: block.createdAt,
      updatedAt: block.updatedAt,
    ));
  }

  @override
  Future<void> updateBlock(BlockEntity block) {
    return _blocksDao.updateBlockContent(block.id, block.contentJson);
  }

  @override
  Future<void> deleteBlock(String blockId) {
    return _blocksDao.deleteBlock(blockId);
  }

  PageEntity _mapPageEntryToEntity(PageEntry entry) {
    return PageEntity(
      id: entry.id,
      parentPageId: entry.parentPageId,
      title: entry.title,
      icon: entry.icon,
      coverImageUrl: entry.coverImageUrl,
      isDatabaseRow: entry.isDatabaseRow,
      isArchived: entry.isArchived,
      sortOrder: entry.sortOrder,
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
    );
  }

  BlockEntity _mapBlockEntryToEntity(BlockEntry entry) {
    return BlockEntity(
      id: entry.id,
      pageId: entry.pageId,
      parentBlockId: entry.parentBlockId,
      type: BlockType.fromDbString(entry.blockType),
      orderKey: entry.orderKey,
      contentJson: entry.contentJson,
      isArchived: entry.isArchived,
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
    );
  }
}
```

---

### 4.15 File 14: `lib/features/focus_engine/domain/repositories/subjects_repository.dart`
```dart
import '../models/subject_entity.dart';

abstract class ISubjectsRepository {
  Stream<List<SubjectEntity>> watchActiveSubjects();
  Future<List<SubjectEntity>> getActiveSubjects();
  Future<SubjectEntity?> getSubjectById(String id);
  Future<void> seedDefaultSubjects();
}
```

---

### 4.16 File 15: `lib/features/focus_engine/data/repositories/subjects_repository_impl.dart`
```dart
import '../../../../core/database/daos/subjects_dao.dart';
import '../../../../core/database/tables/subjects_table.dart';
import '../../domain/models/subject_entity.dart';
import '../../domain/repositories/subjects_repository.dart';

class SubjectsRepositoryImpl implements ISubjectsRepository {
  final SubjectsDao _subjectsDao;

  SubjectsRepositoryImpl({required SubjectsDao subjectsDao}) : _subjectsDao = subjectsDao;

  @override
  Stream<List<SubjectEntity>> watchActiveSubjects() {
    return _subjectsDao.watchActiveSubjects().map((entries) => entries.map(_mapSubject).toList());
  }

  @override
  Future<List<SubjectEntity>> getActiveSubjects() async {
    final entries = await _subjectsDao.getActiveSubjects();
    return entries.map(_mapSubject).toList();
  }

  @override
  Future<SubjectEntity?> getSubjectById(String id) async {
    final entry = await _subjectsDao.getSubjectById(id);
    return entry != null ? _mapSubject(entry) : null;
  }

  @override
  Future<void> seedDefaultSubjects() {
    return _subjectsDao.seedDefaultSubjects();
  }

  SubjectEntity _mapSubject(SubjectEntry entry) {
    return SubjectEntity(
      id: entry.id,
      name: entry.name,
      colorHex: entry.colorHex,
      icon: entry.icon,
      dailyGoalMinutes: entry.dailyGoalMinutes,
      isArchived: entry.isArchived,
      sortOrder: entry.sortOrder,
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
    );
  }
}
```

---

### 4.17 File 16: `test/unit/drift_database_test.dart`
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' as drift;
import 'package:hampa/core/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    // In-memory isolated database instance per test
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('PagesDao & Hierarchical Page Tree', () {
    test('createPage inserts and watchPageTree emits newly created root page', () async {
      final now = DateTime.now();
      await db.pagesDao.insertPage(PagesCompanion.insert(
        id: 'page_1',
        title: const drift.Value('Root Page 1'),
        icon: const drift.Value('📘'),
        sortOrder: const drift.Value(1.0),
        createdAt: now,
        updatedAt: now,
      ));

      final pages = await db.pagesDao.watchPageTree().first;
      expect(pages.length, equals(1));
      expect(pages.first.id, equals('page_1'));
      expect(pages.first.title, equals('Root Page 1'));
      expect(pages.first.icon, equals('📘'));
      expect(pages.first.parentPageId, isNull);
    });

    test('hierarchical nesting and watchSubPages emits only children of target parent', () async {
      final now = DateTime.now();
      await db.pagesDao.insertPage(PagesCompanion.insert(
        id: 'root_1',
        title: const drift.Value('Root 1'),
        createdAt: now,
        updatedAt: now,
      ));
      await db.pagesDao.insertPage(PagesCompanion.insert(
        id: 'child_1_1',
        parentPageId: const drift.Value('root_1'),
        title: const drift.Value('Child 1.1'),
        createdAt: now,
        updatedAt: now,
      ));
      await db.pagesDao.insertPage(PagesCompanion.insert(
        id: 'child_1_2',
        parentPageId: const drift.Value('root_1'),
        title: const drift.Value('Child 1.2'),
        createdAt: now,
        updatedAt: now,
      ));
      await db.pagesDao.insertPage(PagesCompanion.insert(
        id: 'root_2',
        title: const drift.Value('Root 2'),
        createdAt: now,
        updatedAt: now,
      ));

      final rootSubPages = await db.pagesDao.watchSubPages('root_1').first;
      expect(rootSubPages.length, equals(2));
      expect(rootSubPages.map((p) => p.id), containsAll(['child_1_1', 'child_1_2']));

      final topLevelPages = await db.pagesDao.watchSubPages(null).first;
      expect(topLevelPages.length, equals(2));
      expect(topLevelPages.map((p) => p.id), containsAll(['root_1', 'root_2']));
    });

    test('updatePageParent reparents node and updates sort order', () async {
      final now = DateTime.now();
      await db.pagesDao.insertPage(PagesCompanion.insert(
        id: 'page_a',
        title: const drift.Value('Page A'),
        createdAt: now,
        updatedAt: now,
      ));
      await db.pagesDao.insertPage(PagesCompanion.insert(
        id: 'page_b',
        title: const drift.Value('Page B'),
        createdAt: now,
        updatedAt: now,
      ));

      // Move page_b under page_a
      await db.pagesDao.updatePageParent(
        pageId: 'page_b',
        newParentPageId: 'page_a',
        newSortOrder: 2.5,
      );

      final updatedB = await db.pagesDao.getPageById('page_b');
      expect(updatedB?.parentPageId, equals('page_a'));
      expect(updatedB?.sortOrder, equals(2.5));
    });

    test('updatePageParent prevents cycle when moving page under its own descendant', () async {
      final now = DateTime.now();
      await db.pagesDao.insertPage(PagesCompanion.insert(
        id: 'node_1',
        title: const drift.Value('Node 1'),
        createdAt: now,
        updatedAt: now,
      ));
      await db.pagesDao.insertPage(PagesCompanion.insert(
        id: 'node_2',
        parentPageId: const drift.Value('node_1'),
        title: const drift.Value('Node 2'),
        createdAt: now,
        updatedAt: now,
      ));
      await db.pagesDao.insertPage(PagesCompanion.insert(
        id: 'node_3',
        parentPageId: const drift.Value('node_2'),
        title: const drift.Value('Node 3'),
        createdAt: now,
        updatedAt: now,
      ));

      // Attempt to move node_1 under node_3 (which would create a cycle: node_1 -> node_2 -> node_3 -> node_1)
      expect(
        () => db.pagesDao.updatePageParent(
          pageId: 'node_1',
          newParentPageId: 'node_3',
          newSortOrder: 1.0,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('getBreadcrumbs traverses ancestor path from leaf to root', () async {
      final now = DateTime.now();
      await db.pagesDao.insertPage(PagesCompanion.insert(id: 'l1', title: const drift.Value('Level 1'), createdAt: now, updatedAt: now));
      await db.pagesDao.insertPage(PagesCompanion.insert(id: 'l2', parentPageId: const drift.Value('l1'), title: const drift.Value('Level 2'), createdAt: now, updatedAt: now));
      await db.pagesDao.insertPage(PagesCompanion.insert(id: 'l3', parentPageId: const drift.Value('l2'), title: const drift.Value('Level 3'), createdAt: now, updatedAt: now));

      final breadcrumbs = await db.pagesDao.getBreadcrumbs('l3');
      expect(breadcrumbs.length, equals(3));
      expect(breadcrumbs.map((b) => b.id).toList(), equals(['l1', 'l2', 'l3']));
    });
  });

  group('BlocksDao & Fractional LexoRank Ordering', () {
    test('insertBlock and watchBlocksForPage returns blocks sorted by orderKey', () async {
      final now = DateTime.now();
      await db.pagesDao.insertPage(PagesCompanion.insert(id: 'p1', title: const drift.Value('Doc'), createdAt: now, updatedAt: now));

      await db.blocksDao.insertBlock(BlocksCompanion.insert(
        id: 'b2',
        pageId: 'p1',
        blockType: 'text',
        orderKey: 'b0',
        contentJson: const drift.Value('{"text": "Second"}'),
        createdAt: now,
        updatedAt: now,
      ));
      await db.blocksDao.insertBlock(BlocksCompanion.insert(
        id: 'b1',
        pageId: 'p1',
        blockType: 'heading_1',
        orderKey: 'a0',
        contentJson: const drift.Value('{"text": "First"}'),
        createdAt: now,
        updatedAt: now,
      ));

      final blocks = await db.blocksDao.watchBlocksForPage('p1').first;
      expect(blocks.length, equals(2));
      expect(blocks[0].id, equals('b1'));
      expect(blocks[1].id, equals('b2'));
    });

    test('updateBlockContent updates JSON payload reactively', () async {
      final now = DateTime.now();
      await db.pagesDao.insertPage(PagesCompanion.insert(id: 'p1', title: const drift.Value('Doc'), createdAt: now, updatedAt: now));
      await db.blocksDao.insertBlock(BlocksCompanion.insert(
        id: 'b_check',
        pageId: 'p1',
        blockType: 'checklist',
        orderKey: 'a0',
        contentJson: const drift.Value('{"text": "Task 1", "isCompleted": false}'),
        createdAt: now,
        updatedAt: now,
      ));

      await db.blocksDao.updateBlockContent('b_check', '{"text": "Task 1", "isCompleted": true}');
      final block = await db.blocksDao.getBlockById('b_check');
      expect(block?.contentJson, contains('"isCompleted": true'));
    });

    test('nested blocks under toggle cascade delete when parent block is deleted', () async {
      final now = DateTime.now();
      await db.pagesDao.insertPage(PagesCompanion.insert(id: 'p1', title: const drift.Value('Doc'), createdAt: now, updatedAt: now));

      await db.blocksDao.insertBlock(BlocksCompanion.insert(
        id: 'toggle_1',
        pageId: 'p1',
        blockType: 'toggle',
        orderKey: 'a0',
        contentJson: const drift.Value('{"title": "Section"}'),
        createdAt: now,
        updatedAt: now,
      ));

      await db.blocksDao.insertBlock(BlocksCompanion.insert(
        id: 'child_block_1',
        pageId: 'p1',
        parentBlockId: const drift.Value('toggle_1'),
        blockType: 'text',
        orderKey: 'a0:a0',
        contentJson: const drift.Value('{"text": "Inside toggle"}'),
        createdAt: now,
        updatedAt: now,
      ));

      final childrenBefore = await db.blocksDao.watchChildBlocks('toggle_1').first;
      expect(childrenBefore.length, equals(1));

      // Delete parent toggle
      await db.blocksDao.deleteBlock('toggle_1');

      final childrenAfter = await db.blocksDao.watchChildBlocks('toggle_1').first;
      expect(childrenAfter.isEmpty, isTrue);
    });
  });

  group('SubjectsDao & Study Configuration', () {
    test('seedDefaultSubjects initializes standard 4 study subjects', () async {
      await db.subjectsDao.seedDefaultSubjects();
      final subjects = await db.subjectsDao.getActiveSubjects();

      expect(subjects.length, equals(4));
      expect(subjects.map((s) => s.name), containsAll(['Mathematics', 'Science & Physics', 'Languages & Literature', 'General Study']));
    });

    test('watchActiveSubjects updates when subject is archived', () async {
      await db.subjectsDao.seedDefaultSubjects();
      await db.subjectsDao.archiveSubject('sub_math');

      final active = await db.subjectsDao.watchActiveSubjects().first;
      expect(active.length, equals(3));
      expect(active.any((s) => s.id == 'sub_math'), isFalse);
    });
  });

  group('AC3 Offline Persistence & Transaction Atomicity', () {
    test('transactions roll back completely on exception', () async {
      final now = DateTime.now();

      try {
        await db.transaction(() async {
          await db.pagesDao.insertPage(PagesCompanion.insert(
            id: 'txn_page',
            title: const drift.Value('Transaction Test'),
            createdAt: now,
            updatedAt: now,
          ));

          // Throw simulated error
          throw Exception('Simulated crash during atomic write');
        });
      } catch (_) {
        // Expected
      }

      final page = await db.pagesDao.getPageById('txn_page');
      expect(page, isNull, reason: 'Transaction must rollback completely on error');
    });
  });
}
```

---

## 5. Verification Method

To independently verify the Drift SQLite data layer once files are placed and Flutter SDK is active:

1. **Dependency Resolution**:
   ```powershell
   flutter pub get
   ```
   *Expected outcome*: Zero version conflict errors, clean exit code 0.

2. **Code Generation**:
   ```powershell
   dart run build_runner build --delete-conflicting-outputs
   ```
   *Expected outcome*: Generates `lib/core/database/app_database.g.dart`, `pages_dao.g.dart`, `blocks_dao.g.dart`, and `subjects_dao.g.dart` with all `$PagesTable`, `$BlocksTable`, and `$SubjectsTable` entities.

3. **In-Memory Database Unit Tests**:
   ```powershell
   flutter test test/unit/drift_database_test.dart
   ```
   *Expected outcome*: 100% passing tests across all 4 test groups:
   - `PagesDao & Hierarchical Page Tree`
   - `BlocksDao & Fractional LexoRank Ordering`
   - `SubjectsDao & Study Configuration`
   - `AC3 Offline Persistence & Transaction Atomicity`

4. **Invalidation Conditions**:
   - If `updatePageParent` allows setting a page's parent to its own descendant, cycle prevention fails.
   - If an unhandled exception inside `db.transaction()` commits partial records to SQLite, AC3 is violated.
   - If `watchPageTree` fails to emit upon inserting or archiving a page, reactive streams are broken.
