# Milestone 1 Code Review & Adversarial Stress-Test Report: Modular Block Editor

- **Reviewer**: `reviewer_m1_2` (Quality Reviewer & Adversarial Critic)
- **Working Directory**: `c:\parsa\HamPA\.agents\teamwork\reviewer_m1_2`
- **Parent Conversation ID**: `22d8faaf-eb90-463c-99a6-32a4eb94320e`
- **Date**: 2026-10-16T19:30:00Z
- **Target**: Milestone 1 Modular Block Editor (F04, F05, F06, F07), Renderers, Slash Command Menu, BlockEditorNotifier, and Drift SQLite persistence.

---

## 1. Observation

### 1.1 Tool Execution & Test Results
1. **Static Analysis**:
   ```
   Command: C:\flutter\bin\flutter.bat analyze
   Result:
   Analyzing HamPA...
   No issues found! (ran in 53.7s)
   Exit Code: 0
   ```
2. **Widget Tests**:
   ```
   Command: C:\flutter\bin\flutter.bat test test/widget/
   Result:
   15 passed (100%), 0 failed, 0 errors.
   Exit Code: 0
   ```
3. **Unit Tests**:
   ```
   Command: C:\flutter\bin\flutter.bat test test/unit/
   Result:
   52 passed (100%), 0 failed, 0 errors.
   Exit Code: 0
   ```

### 1.2 Direct Code Observations & Evidence

1. **Critical Failure — Block Type Conversion is Discarded by SQLite Persistence**:
   - In `lib/features/workspace_editor/presentation/controllers/block_editor_notifier.dart` (lines 159–179):
     ```dart
     Future<void> convertBlockType({
       required String blockId,
       required BlockType newType,
     }) async {
       ...
       final updated = oldBlock.copyWith(
         type: newType,
         content: newContent,
         updatedAt: DateTime.now(),
       );
       _dirtyBlocks[blockId] = updated;
       await flushDirtyBlocks();
     }
     ```
   - In `lib/features/workspace_editor/presentation/controllers/block_editor_notifier.dart` (lines 112–114):
     ```dart
     for (final block in toSave.values) {
       await repository.updateBlock(block);
     }
     ```
   - In `lib/features/workspace_editor/data/repositories/workspace_repository_impl.dart` (lines 131–133):
     ```dart
     @override
     Future<void> updateBlock(BlockEntity block) {
       return _blocksDao.updateBlockContent(block.id, block.contentJson);
     }
     ```
   - In `lib/core/database/daos/blocks_dao.dart` (lines 54–61):
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
   - In `test/widget/block_editor_test.dart` (lines 49–56):
     The widget test uses `FakeBlockRepository`, which replaces the in-memory Dart entity (`_blocks[idx] = block;`), thereby masking this bug. In real production SQLite, `blockType` is completely omitted from the update statement.

2. **Major Failure — Adding Block Below Inside a Toggle Escapes Parent Container**:
   - In `lib/features/workspace_editor/presentation/controllers/block_editor_notifier.dart` (lines 120–135):
     ```dart
     Future<void> insertBlockAfter({
       required String afterBlockId,
       BlockType type = BlockType.text,
       String? parentBlockId,
     }) async {
       await flushDirtyBlocks();

       final currentBlocks = parentBlockId == null
           ? _state.topLevelBlocks
           : _state.getChildrenOf(parentBlockId);

       final currentIndex = currentBlocks.indexWhere((b) => b.id == afterBlockId);
       String newOrderKey;

       if (currentIndex == -1 || currentIndex == currentBlocks.length - 1) {
         final lastKey = currentBlocks.isNotEmpty ? currentBlocks.last.orderKey : null;
         newOrderKey = StringLexoRank.between(lastKey, null);
       ...
       final newBlock = BlockEntity(
         id: _uuid.v4(),
         pageId: pageId,
         parentBlockId: parentBlockId, // null!
         type: type,
         orderKey: newOrderKey,
         ...
     ```
   - In `lib/features/workspace_editor/presentation/widgets/block_editor_view.dart` (lines 86–90):
     ```dart
     onSelected: (val) {
       if (val == 'add_below') {
         widget.notifier.insertBlockAfter(afterBlockId: block.id);
       }
     ```
   - When a user selects "Add block below" on a child block of a toggle, `parentBlockId` is `null`. The child block is not found in `_state.topLevelBlocks` (`currentIndex == -1`). The new block is given `parentBlockId: null` and appended to the end of the root document instead of remaining inside the toggle.

3. **Major Failure — Dead / Unwired `onEnter` and `onBackspaceEmpty` Callbacks**:
   - In `lib/features/workspace_editor/presentation/widgets/renderers/text_block_renderer.dart`:
     - Lines 8–9: `final VoidCallback onEnter; final VoidCallback onBackspaceEmpty;`
     - Lines 88–108: `TextField` has `maxLines: null`. It has no `onSubmitted`, no `onEditingComplete`, and no `FocusNode.onKeyEvent` / `KeyboardListener`.
     - Neither `onEnter` nor `onBackspaceEmpty` is ever called anywhere in `text_block_renderer.dart`. Pressing Enter simply inserts `\n` in the current block, and Backspace on an empty block does nothing.
   - In `lib/features/workspace_editor/presentation/widgets/renderers/checklist_block_renderer.dart`:
     - Lines 8–9: `final VoidCallback onEnter; final VoidCallback onBackspaceEmpty;`
     - Lines 58–81: `TextField` has no keyboard listeners; `onEnter` and `onBackspaceEmpty` are never invoked.

4. **Major Failure — Data Loss on Navigation / Disposing Notifier During Debounce Window**:
   - In `lib/features/workspace_editor/presentation/controllers/block_editor_notifier.dart` (lines 261–266):
     ```dart
     @override
     void dispose() {
       _debounceSaveTimer?.cancel();
       _blocksSubscription?.cancel();
       super.dispose();
     }
     ```
   - When text is typed in a block, `_scheduleDebouncedSave()` starts a 300ms timer. If the user navigates away or the screen is disposed before the 300ms elapses, `dispose()` cancels `_debounceSaveTimer` without calling `flushDirtyBlocks()`. All dirty changes in `_dirtyBlocks` are permanently lost.

5. **Minor Defects**:
   - **Slash command query not stripped**: In `TextBlockRenderer`, typing `/call` triggers `_showSlashMenu`. Upon selecting `Callout`, `BlockEditorNotifier.convertBlockType` receives the raw string `"/call"`, creating a Callout block with text `"/call"`.
   - **Missing `didUpdateWidget` in renderers**: `ToggleBlockRenderer`, `CodeBlockRenderer`, and `MathBlockRenderer` do not implement `didUpdateWidget` to synchronize their internal `_controller.text` when `widget.block.content` changes from an external source (undo, remote sync, or reset).

---

## 2. Logic Chain

1. **Premise**: Milestone 1 requires a modular block editor supporting 7 block types and local-first SQLite persistence (F03, F04, F05, F06, F07, R1, AC1, AC3).
2. **Observation**: `WorkspaceRepositoryImpl.updateBlock(block)` only invokes `_blocksDao.updateBlockContent(block.id, block.contentJson)`.
3. **Inference**: Drift's `updateBlockContent` modifies only `content_json` and `updated_at`. The SQLite column `block_type` is left untouched.
4. **Impact**: Whenever a user converts a block (e.g. from Text to Callout, Heading, Checklist, or Code block), SQLite preserves the original `block_type`. When the app restarts or `watchBlocksForPage` re-emits from SQLite, the block reverts back to its old type.
5. **Masking Cause**: `test/widget/block_editor_test.dart` used an in-memory `FakeBlockRepository` that updated `_blocks[idx] = block;`, hiding the repository bug.
6. **Conclusion**: Production block conversion persistence is broken and violates AC3 / F03–F07 requirements.

---

## 3. Caveats

- All unit tests (`test/unit/`) and widget tests (`test/widget/`) currently pass because they either test `BlocksDao.updateBlockContent` directly or use `FakeBlockRepository` rather than `WorkspaceRepositoryImpl`.
- Static analysis is completely clean (`0 issues`).
- The UI renderers themselves (visual layout, font sizes, colors, toggle chevron animation, LaTeX TeX parsing, and syntax highlighting) visually display all 7 block types properly when provided with pre-seeded data.

---

## 4. Conclusion

**VERDICT: REQUEST_CHANGES**

The implementation provides good foundational UI widgets and passes existing mocked tests, but contains a critical database persistence flaw, hierarchy-breaking bugs with nested toggle blocks, dead keyboard interaction contracts, and data loss upon unmounting during auto-save debounce.

### Required Changes for Worker:

1. **[CRITICAL] Persist `blockType` in `WorkspaceRepositoryImpl.updateBlock`**:
   - Update `WorkspaceRepositoryImpl.updateBlock` to persist both `blockType` and `contentJson`:
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
         updatedAt: Value(DateTime.now()),
       ));
     }
     ```
   - Add a unit test in `test/unit/drift_database_test.dart` verifying that updating a block's type (e.g., from `text` to `callout`) persists across database reload.

2. **[MAJOR] Resolve Parent Container in `insertBlockAfter`**:
   - In `BlockEditorNotifier.insertBlockAfter`:
     ```dart
     final afterBlock = _state.blocks.firstWhereOrNull((b) => b.id == afterBlockId);
     final effectiveParentId = parentBlockId ?? afterBlock?.parentBlockId;
     final currentBlocks = effectiveParentId == null
         ? _state.topLevelBlocks
         : _state.getChildrenOf(effectiveParentId);
     ```
   - Ensure the created block uses `parentBlockId: effectiveParentId` so that adding a block below a nested child stays inside the parent toggle.

3. **[MAJOR] Implement or Wire `onEnter` and `onBackspaceEmpty`**:
   - In `TextBlockRenderer` and `ChecklistBlockRenderer`, connect keyboard handling (e.g. `FocusNode.onKeyEvent` or `RawKeyboardListener`) to invoke `onEnter` when Enter is pressed (creating a block below) and `onBackspaceEmpty` when Backspace is pressed on an empty block.

4. **[MAJOR] Flush Dirty Blocks on Dispose**:
   - In `BlockEditorNotifier.dispose()`, trigger an immediate asynchronous/unawaited flush of `_dirtyBlocks` before disposing, or ensure dirty blocks are saved so that keystrokes within the 300ms window are not lost when closing the editor.

5. **[MINOR] Strip Slash Command Query on Conversion**:
   - When converting a block triggered via `/query`, strip the leading `/...` query string from the block content.

6. **[MINOR] Add `didUpdateWidget` to `ToggleBlockRenderer`, `CodeBlockRenderer`, and `MathBlockRenderer`**:
   - Synchronize text controllers with updated `widget.block.content` values.

---

## 5. Verification Method

To verify the required fixes once implemented:

1. **Run Static Analysis**:
   ```powershell
   C:\flutter\bin\flutter.bat analyze
   ```
   *Expected*: `No issues found!`, 0 errors, 0 warnings.

2. **Run Unit Tests**:
   ```powershell
   C:\flutter\bin\flutter.bat test test/unit/
   ```
   *Expected*: All tests pass, including new test verifying `WorkspaceRepositoryImpl.updateBlock` updates `blockType` in SQLite.

3. **Run Widget Tests**:
   ```powershell
   C:\flutter\bin\flutter.bat test test/widget/
   ```
   *Expected*: All tests pass, including toggle child insertion test.

4. **Integration Verification of Block Type Persistence**:
   Inspect SQLite table after `convertBlockType` call:
   `SELECT block_type FROM blocks WHERE id = ?;` must equal the converted type (`heading_1`, `callout`, etc.), not `'text'`.
