# Investigation & Implementation Blueprint: SQLite Block Type Persistence

- **Author**: `explorer_m1_fix_db`
- **Working Directory**: `c:\parsa\HamPA\.agents\teamwork\explorer_m1_fix_db`
- **Parent Conversation ID**: `22d8faaf-eb90-463c-99a6-32a4eb94320e`
- **Date**: 2026-10-16T20:06:00Z
- **Target**: Milestone 1 Remediation — Persisting `block_type` and `content_json` into SQLite across `BlocksDao`, `WorkspaceRepositoryImpl`, and `BlockEditorNotifier`.

---

## 1. Observation

### 1.1 Direct Source Code Observations

1. **`WorkspaceRepositoryImpl.updateBlock` Omits `block_type`**:
   - Location: `lib/features/workspace_editor/data/repositories/workspace_repository_impl.dart` (lines 130–134)
   - Verbatim Code:
     ```dart
     @override
     Future<void> updateBlock(BlockEntity block) {
       return _blocksDao.updateBlockContent(block.id, block.contentJson);
     }
     ```
   - Observation: When `repository.updateBlock(block)` is called, it solely passes `block.id` and `block.contentJson` to `_blocksDao.updateBlockContent`. The `block.type` property (`BlockType`) is discarded completely.

2. **`BlocksDao.updateBlockContent` Only Writes `content_json` and `updated_at`**:
   - Location: `lib/core/database/daos/blocks_dao.dart` (lines 54–61)
   - Verbatim Code:
     ```dart
     Future<int> updateBlockContent(String id, String contentJson) {
       return (update(blocks)..where((tbl) => tbl.id.equals(id))).write(
         BlocksCompanion(
           contentJson: Value(contentJson),
           updatedAt: Value(DateTime.now()),
         ),
       );
     }
     ```
   - Observation: In the SQLite `blocks` table, the column `block_type` is left untouched.

3. **`BlocksDao.updateBlockEntry` Implementation & Drift Semantics**:
   - Location: `lib/core/database/daos/blocks_dao.dart` (lines 50–52)
   - Verbatim Code:
     ```dart
     Future<bool> updateBlockEntry(BlocksCompanion entry) {
       return update(blocks).replace(entry);
     }
     ```
   - Observation: Drift's `update(blocks).replace(entry)` performs a full row replacement. In Drift, `replace()` requires all non-nullable columns without table defaults (such as `createdAt`, `pageId`, `orderKey`) to be explicitly present in `entry`; if any non-default column is `Value.absent()`, `replace` fails. In contrast, `(update(blocks)..where((tbl) => tbl.id.equals(entry.id.value))).write(entry)` updates exclusively the columns whose `Value` is `.present`, preserving unmentioned columns.

4. **`BlockEditorNotifier.convertBlockType` & Flush Flow**:
   - Location: `lib/features/workspace_editor/presentation/controllers/block_editor_notifier.dart` (lines 159–179, 112–114)
   - Verbatim Code:
     ```dart
     Future<void> convertBlockType({
       required String blockId,
       required BlockType newType,
     }) async {
       final index = _state.blocks.indexWhere((b) => b.id == blockId);
       if (index == -1) return;

       final oldBlock = _state.blocks[index];
       final String currentText = (oldBlock.content['text'] ?? oldBlock.content['title'] ?? '').toString();

       final Map<String, dynamic> newContent = _convertContent(currentText, newType);

       final updated = oldBlock.copyWith(
         type: newType,
         content: newContent,
         updatedAt: DateTime.now(),
       );

       _dirtyBlocks[blockId] = updated;
       await flushDirtyBlocks();
     }
     ```
     and in `flushDirtyBlocks`:
     ```dart
     for (final block in toSave.values) {
       await repository.updateBlock(block);
     }
     ```
   - Observation: `convertBlockType` creates an updated `BlockEntity` with `type: newType`, places it in `_dirtyBlocks`, and awaits `flushDirtyBlocks()`. However, because `repository.updateBlock` ignores `block.type`, SQLite preserves the old `block_type`. When Drift's reactive `watchBlocksForPage` stream emits or the page is reloaded, the block reverts back to its old type.
   - Secondary Observation: If `convertBlockType` was invoked via a slash command query (e.g. `"/call"`), `currentText` contains `"/call"`. If not stripped, the new block gets seeded with `"/call"` as its text.
   - Tertiary Observation: In `dispose()` (lines 261–266), `_debounceSaveTimer?.cancel()` cancels the timer without saving `_dirtyBlocks`, dropping any unpersisted keystrokes.

5. **`drift_database_test.dart` Test Coverage Gap**:
   - Location: `test/unit/drift_database_test.dart` (lines 271–287)
   - Verbatim Code:
     ```dart
     test('updateBlockContent updates JSON payload reactively', () async {
       ...
       await db.blocksDao.updateBlockContent('b_check', '{"text": "Task 1", "isCompleted": true}');
       final block = await db.blocksDao.getBlockById('b_check');
       expect(block?.contentJson, contains('"isCompleted": true'));
     });
     ```
   - Observation: Existing unit tests only tested `updateBlockContent`. No test in `drift_database_test.dart` tested `updateBlockEntry` or verified that changing a block's type (e.g. from `text` to `callout` or `heading_1`) updates and persists the `block_type` column in SQLite.

---

## 2. Logic Chain

1. **Premise**: Requirement R1, F03, F04–F07 and Acceptance Criterion AC3 require full local-first SQLite persistence for block modifications and conversions.
2. **Finding 1**: When a block's type is changed (via slash command or API `convertBlockType`), `BlockEntity.type` is modified.
3. **Finding 2**: When `flushDirtyBlocks()` flushes changes, `WorkspaceRepositoryImpl.updateBlock(block)` delegates strictly to `_blocksDao.updateBlockContent(block.id, block.contentJson)`.
4. **Finding 3**: `_blocksDao.updateBlockContent` issues an SQL `UPDATE blocks SET content_json = ?, updated_at = ? WHERE id = ?`. The `block_type` column is never included.
5. **Inference**: On subsequent reads (`getBlocksForPage` or reactive stream `watchBlocksForPage`), the entity is reconstructed via `_mapBlockEntryToEntity` using the old `entry.blockType` from SQLite.
6. **Remediation**:
   - `BlocksDao` must provide a resilient update mechanism that updates all present columns of a `BlocksCompanion` (specifically `blockType`, `contentJson`, and `updatedAt`) using `(update(blocks)..where(...)).write(entry)`.
   - `WorkspaceRepositoryImpl.updateBlock(BlockEntity block)` must map `BlockEntity` into `BlocksCompanion` (including `blockType: Value(block.type.toDbString())`, `contentJson: Value(block.contentJson)`, and `updatedAt: Value(DateTime.now())`) and invoke `_blocksDao.updateBlockEntry`.
   - `test/unit/drift_database_test.dart` must assert that updating a block's type persists the new `block_type` across a fresh database re-fetch and across reactive stream emissions.

---

## 3. Caveats

- **No schema migration needed**: The `blocks` table already has `block_type TEXT NOT NULL` (`TextColumn get blockType => text()();`), and `BlocksCompanion` already generated `blockType` in `app_database.g.dart`. No Drift schema bump or `build_runner` re-run is required.
- **`FakeBlockRepository` in widget tests**: The widget tests in `test/widget/block_editor_test.dart` already test slash command conversion in-memory with `FakeBlockRepository`. The bug was purely in the SQLite repository and DAO layer.
- **Foreign Keys**: Updating a block's type does not affect `parent_block_id` or `page_id` foreign key constraints.

---

## 4. Conclusion & Implementation Blueprint

### 4.1 Changes to `lib/core/database/daos/blocks_dao.dart`

#### Target: lines 50–61
Replace `updateBlockEntry` with a robust `write`-based implementation that handles partial or full updates without failing on absent columns, and add `updateBlockContentAndType`:

```dart
  /// Updates block entry columns that are present in [entry] matching [entry.id].
  /// Uses write() to only update specified columns, preserving absent fields.
  Future<bool> updateBlockEntry(BlocksCompanion entry) async {
    assert(entry.id.present, 'Block id must be present for update');
    final count = await (update(blocks)..where((tbl) => tbl.id.equals(entry.id.value))).write(entry);
    return count > 0;
  }

  /// Explicitly updates blockType, contentJson, and updatedAt.
  Future<int> updateBlockContentAndType({
    required String id,
    required String blockType,
    required String contentJson,
    DateTime? updatedAt,
  }) {
    return (update(blocks)..where((tbl) => tbl.id.equals(id))).write(
      BlocksCompanion(
        blockType: Value(blockType),
        contentJson: Value(contentJson),
        updatedAt: Value(updatedAt ?? DateTime.now()),
      ),
    );
  }
```

### 4.2 Changes to `lib/features/workspace_editor/data/repositories/workspace_repository_impl.dart`

#### Target: lines 130–134
Update `updateBlock` to construct a full `BlocksCompanion` with `blockType` and invoke `_blocksDao.updateBlockEntry`:

```dart
  @override
  Future<void> updateBlock(BlockEntity block) {
    return _blocksDao.updateBlockEntry(BlocksCompanion(
      id: Value(block.id),
      pageId: Value(block.pageId),
      parentBlockId: Value(block.parentBlockId),
      blockType: Value(block.type.toDbString()),
      orderKey: Value(block.orderKey),
      contentJson: Value(block.contentJson),
      isArchived: Value(block.isArchived),
      createdAt: Value(block.createdAt),
      updatedAt: Value(DateTime.now()),
    ));
  }
```

### 4.3 Enhancements to `lib/features/workspace_editor/presentation/controllers/block_editor_notifier.dart`

#### Target 1: lines 159–179 (`convertBlockType`)
Strip leading slash command queries and update `_state.blocks` optimistically:

```dart
  Future<void> convertBlockType({
    required String blockId,
    required BlockType newType,
  }) async {
    final index = _state.blocks.indexWhere((b) => b.id == blockId);
    if (index == -1) return;

    final oldBlock = _state.blocks[index];
    final String rawText = (oldBlock.content['text'] ?? oldBlock.content['title'] ?? '').toString();
    // Strip slash command trigger if present (e.g. "/call", "/h1", "/")
    final String currentText = rawText.startsWith('/') ? '' : rawText;

    final Map<String, dynamic> newContent = _convertContent(currentText, newType);

    final updated = oldBlock.copyWith(
      type: newType,
      content: newContent,
      updatedAt: DateTime.now(),
    );

    // Optimistically update local state so UI updates immediately
    final updatedList = List<BlockEntity>.from(_state.blocks);
    updatedList[index] = updated;
    _state = _state.copyWith(blocks: updatedList);
    notifyListeners();

    _dirtyBlocks[blockId] = updated;
    await flushDirtyBlocks();
  }
```

#### Target 2: lines 261–267 (`dispose`)
Flush any remaining `_dirtyBlocks` before unmounting to prevent data loss:

```dart
  @override
  void dispose() {
    _debounceSaveTimer?.cancel();
    if (_dirtyBlocks.isNotEmpty) {
      final toSave = Map<String, BlockEntity>.from(_dirtyBlocks);
      _dirtyBlocks.clear();
      for (final block in toSave.values) {
        unawaited(repository.updateBlock(block));
      }
    }
    _blocksSubscription?.cancel();
    super.dispose();
  }
```

### 4.4 Changes to `test/unit/drift_database_test.dart`

Add two unit tests under `group('BlocksDao & Fractional LexoRank Ordering', ...)`:
1. Direct DAO test testing `updateBlockEntry` and `updateBlockContentAndType` persistence.
2. End-to-end `WorkspaceRepositoryImpl` test verifying `BlockEntity` conversion persistence with in-memory Drift database.

```dart
    test('updateBlockEntry persists blockType and contentJson across DB re-fetch', () async {
      final now = DateTime.now();
      await db.pagesDao.insertPage(PagesCompanion.insert(
        id: 'p_conv',
        title: const drift.Value('Conversion Doc'),
        createdAt: now,
        updatedAt: now,
      ));

      // 1. Insert initial text block
      await db.blocksDao.insertBlock(BlocksCompanion.insert(
        id: 'b_convert',
        pageId: 'p_conv',
        blockType: 'text',
        orderKey: 'a0',
        contentJson: const drift.Value('{"text": "Initial paragraph"}'),
        createdAt: now,
        updatedAt: now,
      ));

      final initial = await db.blocksDao.getBlockById('b_convert');
      expect(initial?.blockType, equals('text'));
      expect(initial?.contentJson, contains('Initial paragraph'));

      // 2. Perform block type conversion via updateBlockEntry (text -> callout)
      final updatedTime = now.add(const Duration(seconds: 1));
      await db.blocksDao.updateBlockEntry(BlocksCompanion(
        id: const drift.Value('b_convert'),
        blockType: const drift.Value('callout'),
        contentJson: const drift.Value('{"text": "Converted callout", "icon": "💡"}'),
        updatedAt: drift.Value(updatedTime),
      ));

      // 3. Re-fetch from SQLite via one-shot query
      final updated = await db.blocksDao.getBlockById('b_convert');
      expect(updated, isNotNull);
      expect(updated?.blockType, equals('callout'), reason: 'blockType must be updated in SQLite');
      expect(updated?.contentJson, contains('Converted callout'));
      expect(updated?.contentJson, contains('💡'));

      // 4. Assert reactive stream watchBlocksForPage emits converted blockType
      final streamBlocks = await db.blocksDao.watchBlocksForPage('p_conv').first;
      expect(streamBlocks.first.blockType, equals('callout'));
    });

    test('WorkspaceRepositoryImpl persists blockType conversion end-to-end to SQLite', () async {
      final repo = WorkspaceRepositoryImpl(
        pagesDao: db.pagesDao,
        blocksDao: db.blocksDao,
      );

      final now = DateTime.now();
      await db.pagesDao.insertPage(PagesCompanion.insert(
        id: 'p_repo_conv',
        title: const drift.Value('Repo Test Page'),
        createdAt: now,
        updatedAt: now,
      ));

      final initialBlock = BlockEntity(
        id: 'b_repo_conv',
        pageId: 'p_repo_conv',
        type: BlockType.text,
        orderKey: 'a0',
        content: {'text': 'Initial text'},
        createdAt: now,
        updatedAt: now,
      );
      await repo.insertBlock(initialBlock);

      // Verify initial state
      var blocks = await repo.getBlocksForPage('p_repo_conv');
      expect(blocks.first.type, equals(BlockType.text));

      // Convert to heading1
      final convertedBlock = initialBlock.copyWith(
        type: BlockType.heading1,
        content: {'text': 'Converted Heading'},
        updatedAt: now.add(const Duration(seconds: 2)),
      );
      await repo.updateBlock(convertedBlock);

      // Re-fetch from SQLite through repository
      blocks = await repo.getBlocksForPage('p_repo_conv');
      expect(blocks.length, equals(1));
      expect(blocks.first.type, equals(BlockType.heading1), reason: 'Repository must persist updated blockType');
      expect(blocks.first.content['text'], equals('Converted Heading'));
    });
```

*(Note: Required imports for `test/unit/drift_database_test.dart`: `import 'package:hampa/features/workspace_editor/data/repositories/workspace_repository_impl.dart';`, `import 'package:hampa/features/workspace_editor/domain/models/block_entity.dart';`, and `import 'package:hampa/features/workspace_editor/domain/models/block_type.dart';`)*

---

## 5. Verification Method

To verify the implementation once applied:

1. **Run Unit Tests**:
   ```powershell
   C:\flutter\bin\flutter.bat test test/unit/drift_database_test.dart
   ```
   *Expected Result*: All tests pass, including the new `updateBlockEntry` and `WorkspaceRepositoryImpl` block type conversion tests.

2. **Run Full Test Suite**:
   ```powershell
   C:\flutter\bin\flutter.bat test test/unit/
   C:\flutter\bin\flutter.bat test test/widget/
   ```
   *Expected Result*: 100% tests pass.

3. **Run Static Analysis**:
   ```powershell
   C:\flutter\bin\flutter.bat analyze
   ```
   *Expected Result*: `No issues found!`, 0 errors, 0 warnings.

4. **Invalidation Conditions**:
   - If calling `updateBlock(BlockEntity)` leaves `blocks.block_type` unchanged when queried with `db.blocksDao.getBlockById(id)`, the fix has failed.
   - If `updateBlockEntry` throws due to missing `createdAt`, `write()` was not used instead of `replace()`.
