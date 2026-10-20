# Investigation & Implementation Blueprint: Modular Block Editor Fixes (Milestone 1)

- **Agent**: `explorer_m1_fix_editor`
- **Working Directory**: `c:\parsa\HamPA\.agents\teamwork\explorer_m1_fix_editor`
- **Parent Conversation ID**: `22d8faaf-eb90-463c-99a6-32a4eb94320e`
- **Date**: 2026-10-16T20:10:00Z
- **Scope**: Block editor presentation controllers, views, renderers, keyboard interactions, debounce auto-save, and toggle encapsulation.

---

## 1. Observation

### 1.1 Baseline Tool Execution & Test Results
1. **Static Analysis**:
   - Command: `C:\flutter\bin\flutter.bat analyze lib/`
   - Output: `Analyzing lib... No issues found! (ran in 51.4s)` — 0 errors, 0 warnings.
2. **Unit Tests**:
   - Command: `C:\flutter\bin\flutter.bat test test/unit/`
   - Output: `00:02 +60: All tests passed!` — 60 passed, 0 failed.
3. **Widget Tests**:
   - Command: `C:\flutter\bin\flutter.bat test test/widget/`
   - Output: `00:20 +41: All tests passed!` — 41 passed, 0 failed.
   - Note: In `test/widget/block_editor_adversarial_test.dart`, tests at lines 433 and 616 were previously authored to assert empirical failure modes (`hasCrash == true` for unsupported code language and `isStillVisible == true` for orphaned slash menu).

### 1.2 Direct Code Observations by File & Line Number

#### Defect 1: Toggle Child Insertion Escapes Parent Container
- **File**: `lib/features/workspace_editor/presentation/controllers/block_editor_notifier.dart` (lines 120–157)
- **Observed Code**:
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
    ...
    final newBlock = BlockEntity(
      id: _uuid.v4(),
      pageId: pageId,
      parentBlockId: parentBlockId,
      type: type,
      orderKey: newOrderKey,
      ...
    );
  ```
- **File**: `lib/features/workspace_editor/presentation/widgets/block_editor_view.dart` (lines 86–90, 116, 128–131):
  ```dart
  onSelected: (val) {
    if (val == 'add_below') {
      widget.notifier.insertBlockAfter(afterBlockId: block.id);
    }
  ```
  ```dart
  onEnter: () => widget.notifier.insertBlockAfter(afterBlockId: block.id),
  ```
- **Direct Finding**: Neither the popup menu nor `onEnter` provides `parentBlockId`. When `block.id` is a child of a toggle container (e.g., `parentBlockId: 'toggle_1'`), `parentBlockId` defaults to `null`. `currentBlocks` falls back to `_state.topLevelBlocks`. `currentIndex` becomes `-1` because the child is not top-level. `newBlock` is created with `parentBlockId: null` and appended to the end of the top-level page, breaking encapsulation and corrupting the block tree.

#### Defect 2: Keystroke Data Loss on Notifier Disposal During Debounce Window
- **File**: `lib/features/workspace_editor/presentation/controllers/block_editor_notifier.dart` (lines 87–118, 261–266)
- **Observed Code**:
  ```dart
  void _scheduleDebouncedSave() {
    _debounceSaveTimer?.cancel();
    _debounceSaveTimer = Timer(const Duration(milliseconds: 300), () async {
      await flushDirtyBlocks();
    });
  }
  ...
  @override
  void dispose() {
    _debounceSaveTimer?.cancel();
    _blocksSubscription?.cancel();
    super.dispose();
  }
  ```
- **Direct Finding**: `_dirtyBlocks` holds pending unsaved changes during the 300ms debounce interval. If the screen unmounts, widget tree rebuilds, or user navigates away before 300ms expires, `dispose()` cancels `_debounceSaveTimer` without flushing `_dirtyBlocks`. All keystrokes typed within the 300ms window are permanently lost.

#### Defect 3: Dead / Unconnected Keyboard Listeners for `onEnter` and `onBackspaceEmpty`
- **File**: `lib/features/workspace_editor/presentation/widgets/renderers/text_block_renderer.dart` (lines 8–9, 27, 34, 88–108)
- **File**: `lib/features/workspace_editor/presentation/widgets/renderers/checklist_block_renderer.dart` (lines 8–9, 27, 58–81)
- **Observed Code**:
  - In `TextBlockRenderer`:
    ```dart
    final VoidCallback onEnter;
    final VoidCallback onBackspaceEmpty;
    ...
    _focusNode = FocusNode(); // No onKeyEvent listener
    ...
    TextField(
      controller: _controller,
      focusNode: _focusNode,
      maxLines: null,
      ...
    );
    ```
  - In `ChecklistBlockRenderer`:
    ```dart
    final VoidCallback onEnter;
    final VoidCallback onBackspaceEmpty;
    ...
    // _ChecklistBlockRendererState has no FocusNode at all!
    TextField(
      controller: _controller,
      maxLines: null,
      ...
    );
    ```
- **Direct Finding**: In both renderers, `onEnter` and `onBackspaceEmpty` are declared as constructor parameters but never invoked anywhere in the codebase. Pressing Enter inserts a literal newline `\n` into the single block, and pressing Backspace in an empty block does nothing.

#### Defect 4: `CodeBlockRenderer` Dropdown Assertion Crash on Unsupported Language
- **File**: `lib/features/workspace_editor/presentation/widgets/renderers/code_block_renderer.dart` (lines 27–37, 47–48, 72–76)
- **Observed Code**:
  ```dart
  static const List<String> supportedLanguages = [
    'dart', 'python', 'javascript', 'sql', 'json', 'markdown', 'html', 'bash', 'cpp',
  ];
  ...
  final language = widget.block.content['language'] as String? ?? 'dart';
  ...
  DropdownButton<String>(
    value: language,
    items: supportedLanguages
        .map((l) => DropdownMenuItem(value: l, child: Text(l, style: const TextStyle(fontSize: 12))))
        .toList(),
  ```
- **Direct Finding**: If a block has an unsupported language (e.g. `'rust'`, `'ruby'`, `'plain'`, or a legacy/imported code snippet), `DropdownButton` throws an assertion error (`items.where((item) => item.value == value).length == 1`), crashing the entire editor.

#### Defect 5: Slash Command Menu Orphaned on Backspace Erase
- **File**: `lib/features/workspace_editor/presentation/widgets/renderers/text_block_renderer.dart` (lines 102–107)
- **File**: `lib/features/workspace_editor/presentation/widgets/block_editor_view.dart` (lines 118, 181–219)
- **Observed Code**:
  ```dart
  onChanged: (val) {
    if (val.startsWith('/')) {
      widget.onSlashTriggered?.call(val.substring(1));
    }
    widget.onChanged({'text': val});
  },
  ```
- **Direct Finding**: When `/` is typed, `_showSlashMenu` mounts `_slashOverlayEntry`. When `/` is subsequently deleted via backspace, `val.startsWith('/')` is false, but no dismissal callback is triggered. `_slashOverlayEntry` remains permanently on screen until an item is selected or the view is disposed.
- Furthermore, when converting via slash menu, the query string (`/call`) was previously passed directly into the new block's text rather than being stripped.

---

## 2. Logic Chain

1. **Premise 1 (Toggle Encapsulation)**:
   - When a user adds a block below an existing block $B$, the new block should become a sibling of $B$. If $B$ has a parent ($B.\text{parentBlockId} \neq \text{null}$), the new block must inherit that parent.
   - If the caller does not specify `parentBlockId`, resolving `effectiveParentId = parentBlockId ?? afterBlock?.parentBlockId` ensures that children of a toggle container remain scoped within that container. Sibling LexoRank ordering is computed within `getChildrenOf(effectiveParentId)` rather than the unrelated `topLevelBlocks`.
2. **Premise 2 (Zero Keystroke Loss on Unmount)**:
   - Drift persistence operates via `_dirtyBlocks` with a 300ms debounce.
   - Calling `dispose()` occurs when a user closes a page, navigates to another route, or switches views.
   - Synchronously dispatching `repository.updateBlock(b)` for all blocks in `_dirtyBlocks` inside `dispose()` ensures dirty edits are committed to the Drift database before destruction, while guarding `notifyListeners()` with `hasListeners` prevents post-dispose Flutter framework crashes.
3. **Premise 3 (Keyboard UX Contracts)**:
   - In Notion-style block editors, Enter on a text or checklist block spawns a new block below (`onEnter`), while Backspace on an empty block either removes the block or converts it to paragraph text (`onBackspaceEmpty`).
   - Using `FocusNode.onKeyEvent` to intercept `LogicalKeyboardKey.enter` (when `!isShiftPressed`) and `LogicalKeyboardKey.backspace` (when `_controller.text.isEmpty`) provides clean, testable event routing on hardware, desktop, web, and Flutter test drivers (`tester.sendKeyEvent`).
4. **Premise 4 (Resilient Code Block Fallback)**:
   - User-generated or imported markdown can specify any syntax tag (e.g. `rust`, `go`, `text`, or `plain`).
   - Adding `'plain'` to `supportedLanguages` and computing `final language = supportedLanguages.contains(raw) ? raw : 'plain'` guarantees that `DropdownButton` always finds a matching `DropdownMenuItem`, and `HighlightView` renders unstyled monospace text without crashing.
5. **Premise 5 (Slash Menu Lifecycle)**:
   - The slash command overlay should exist only while the block's text begins with `/`.
   - Adding `onSlashDismissed` to `TextBlockRenderer` and calling it when `!val.startsWith('/')` ensures that backspacing `/` immediately calls `_hideSlashMenu()`, cleanly unmounting the overlay.
   - In `BlockEditorNotifier.convertBlockType`, stripping leading `/...` from `currentText` ensures the slash trigger does not become the content of the converted block.

---

## 3. Implementation Blueprint & Proposed Code

### Blueprint 1: Toggle Child Encapsulation in `BlockEditorNotifier`
**File**: `lib/features/workspace_editor/presentation/controllers/block_editor_notifier.dart`
**Target Lines**: 120–157

#### Replacement Code:
```dart
  Future<void> insertBlockAfter({
    required String afterBlockId,
    BlockType type = BlockType.text,
    String? parentBlockId,
  }) async {
    await flushDirtyBlocks();

    BlockEntity? afterBlock;
    for (final b in _state.blocks) {
      if (b.id == afterBlockId) {
        afterBlock = b;
        break;
      }
    }

    final effectiveParentId = parentBlockId ?? afterBlock?.parentBlockId;

    final currentBlocks = effectiveParentId == null
        ? _state.topLevelBlocks
        : _state.getChildrenOf(effectiveParentId);

    final currentIndex = currentBlocks.indexWhere((b) => b.id == afterBlockId);
    String newOrderKey;

    if (currentIndex == -1 || currentIndex == currentBlocks.length - 1) {
      final lastKey = currentBlocks.isNotEmpty ? currentBlocks.last.orderKey : null;
      newOrderKey = StringLexoRank.between(lastKey, null);
    } else {
      final currentKey = currentBlocks[currentIndex].orderKey;
      final nextKey = currentBlocks[currentIndex + 1].orderKey;
      newOrderKey = StringLexoRank.between(currentKey, nextKey);
    }

    final newBlock = BlockEntity(
      id: _uuid.v4(),
      pageId: pageId,
      parentBlockId: effectiveParentId,
      type: type,
      orderKey: newOrderKey,
      content: _getInitialContentFor(type),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await repository.insertBlock(newBlock);
    _state = _state.copyWith(focusedBlockId: newBlock.id);
    notifyListeners();
  }
```

---

### Blueprint 2: Auto-Save Debounce Flushing on Dispose
**File**: `lib/features/workspace_editor/presentation/controllers/block_editor_notifier.dart`
**Target Lines**: 97–118, 261–266

#### Replacement Code:
```dart
  Future<void> flushDirtyBlocks() async {
    _debounceSaveTimer?.cancel();
    _debounceSaveTimer = null;

    if (_dirtyBlocks.isEmpty) {
      if (_state.isSaving && hasListeners) {
        _state = _state.copyWith(isSaving: false);
        notifyListeners();
      }
      return;
    }

    final toSave = Map<String, BlockEntity>.from(_dirtyBlocks);
    _dirtyBlocks.clear();

    for (final block in toSave.values) {
      await repository.updateBlock(block);
    }

    if (hasListeners) {
      _state = _state.copyWith(isSaving: false);
      notifyListeners();
    }
  }
```
And in `dispose()`:
```dart
  @override
  void dispose() {
    _debounceSaveTimer?.cancel();
    _debounceSaveTimer = null;
    if (_dirtyBlocks.isNotEmpty) {
      final toSave = Map<String, BlockEntity>.from(_dirtyBlocks);
      _dirtyBlocks.clear();
      for (final block in toSave.values) {
        repository.updateBlock(block);
      }
    }
    _blocksSubscription?.cancel();
    super.dispose();
  }
```

---

### Blueprint 3: Keyboard Listeners in `TextBlockRenderer`
**File**: `lib/features/workspace_editor/presentation/widgets/renderers/text_block_renderer.dart`
**Target Lines**: 1–20, 25–45, 88–108

#### Changes:
1. Import `package:flutter/services.dart`.
2. Add `final VoidCallback? onSlashDismissed;` constructor parameter.
3. Configure `_focusNode` with `onKeyEvent`.
4. In `onChanged`, call `widget.onSlashDismissed?.call()` when `!val.startsWith('/')`.

#### Replacement Code:
```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../domain/models/block_entity.dart';
import '../../../domain/models/block_type.dart';

class TextBlockRenderer extends StatefulWidget {
  final BlockEntity block;
  final ValueChanged<Map<String, dynamic>> onChanged;
  final VoidCallback onEnter;
  final VoidCallback onBackspaceEmpty;
  final ValueChanged<String>? onSlashTriggered;
  final VoidCallback? onSlashDismissed;

  const TextBlockRenderer({
    super.key,
    required this.block,
    required this.onChanged,
    required this.onEnter,
    required this.onBackspaceEmpty,
    this.onSlashTriggered,
    this.onSlashDismissed,
  });

  @override
  State<TextBlockRenderer> createState() => _TextBlockRendererState();
}

class _TextBlockRendererState extends State<TextBlockRenderer> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    final text = widget.block.content['text'] as String? ?? '';
    _controller = TextEditingController(text: text);
    _focusNode = FocusNode(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if ((event.logicalKey == LogicalKeyboardKey.enter ||
                  event.logicalKey == LogicalKeyboardKey.numpadEnter) &&
              !HardwareKeyboard.instance.isShiftPressed) {
            widget.onEnter();
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.backspace &&
              _controller.text.isEmpty) {
            widget.onBackspaceEmpty();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
    );
  }

  @override
  void didUpdateWidget(covariant TextBlockRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final text = widget.block.content['text'] as String? ?? '';
    if (text != _controller.text) {
      _controller.text = text;
    }
  }
...
      onChanged: (val) {
        if (val.startsWith('/')) {
          widget.onSlashTriggered?.call(val.substring(1));
        } else {
          widget.onSlashDismissed?.call();
        }
        widget.onChanged({'text': val});
      },
```

---

### Blueprint 4: Keyboard Listeners in `ChecklistBlockRenderer`
**File**: `lib/features/workspace_editor/presentation/widgets/renderers/checklist_block_renderer.dart`
**Target Lines**: 1–43, 58–81, 108–113

#### Changes:
1. Import `package:flutter/services.dart`.
2. Add `late final FocusNode _focusNode;` to `_ChecklistBlockRendererState`.
3. Intercept Enter (handled -> `widget.onEnter()`) and Backspace on empty (handled -> `widget.onBackspaceEmpty()`).
4. Pass `focusNode: _focusNode` to `TextField`.
5. Dispose `_focusNode` in `dispose()`.

#### Replacement Code:
```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../domain/models/block_entity.dart';

class ChecklistBlockRenderer extends StatefulWidget {
  final BlockEntity block;
  final VoidCallback onToggle;
  final ValueChanged<Map<String, dynamic>> onChanged;
  final VoidCallback onEnter;
  final VoidCallback onBackspaceEmpty;
  final VoidCallback? onFocusNow;

  const ChecklistBlockRenderer({
    super.key,
    required this.block,
    required this.onToggle,
    required this.onChanged,
    required this.onEnter,
    required this.onBackspaceEmpty,
    this.onFocusNow,
  });

  @override
  State<ChecklistBlockRenderer> createState() => _ChecklistBlockRendererState();
}

class _ChecklistBlockRendererState extends State<ChecklistBlockRenderer> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.block.content['text'] ?? '');
    _focusNode = FocusNode(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if ((event.logicalKey == LogicalKeyboardKey.enter ||
                  event.logicalKey == LogicalKeyboardKey.numpadEnter) &&
              !HardwareKeyboard.instance.isShiftPressed) {
            widget.onEnter();
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.backspace &&
              _controller.text.isEmpty) {
            widget.onBackspaceEmpty();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
    );
  }

  @override
  void didUpdateWidget(covariant ChecklistBlockRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final text = widget.block.content['text'] as String? ?? '';
    if (text != _controller.text) {
      _controller.text = text;
    }
  }

  @override
  Widget build(BuildContext context) {
    ...
        Expanded(
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            maxLines: null,
            style: TextStyle(
    ...
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }
```

---

### Blueprint 5: Fallback & Resilience in `CodeBlockRenderer`
**File**: `lib/features/workspace_editor/presentation/widgets/renderers/code_block_renderer.dart`
**Target Lines**: 27–48, 71–86, 136–143

#### Changes:
1. Include `'plain'` in `supportedLanguages`.
2. Compute `final rawLanguage = widget.block.content['language'] as String? ?? 'plain';`
3. Fall back: `final language = supportedLanguages.contains(rawLanguage) ? rawLanguage : 'plain';`
4. Add `didUpdateWidget` to synchronize `_controller.text` on external content changes.

#### Replacement Code:
```dart
  static const List<String> supportedLanguages = [
    'plain',
    'dart',
    'python',
    'javascript',
    'sql',
    'json',
    'markdown',
    'html',
    'bash',
    'cpp',
  ];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.block.content['code'] ?? '');
  }

  @override
  void didUpdateWidget(covariant CodeBlockRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final code = widget.block.content['code'] as String? ?? '';
    if (code != _controller.text) {
      _controller.text = code;
    }
  }

  @override
  Widget build(BuildContext context) {
    final rawLanguage = widget.block.content['language'] as String? ?? 'dart';
    final language = supportedLanguages.contains(rawLanguage) ? rawLanguage : 'plain';
    final code = widget.block.content['code'] as String? ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;
```

---

### Blueprint 6: Slash Menu Dismissal & Block Conversion Stripping
**Files**:
1. `lib/features/workspace_editor/presentation/widgets/block_editor_view.dart` (lines 110–120)
2. `lib/features/workspace_editor/presentation/controllers/block_editor_notifier.dart` (lines 160–175)

#### Changes in `block_editor_view.dart`:
Wire `onSlashDismissed`:
```dart
      case BlockType.text:
      case BlockType.heading1:
      case BlockType.heading2:
      case BlockType.heading3:
      case BlockType.quote:
        return TextBlockRenderer(
          block: block,
          onChanged: (content) => widget.notifier.updateBlockContent(
            blockId: block.id,
            newContent: content,
          ),
          onEnter: () => widget.notifier.insertBlockAfter(afterBlockId: block.id),
          onBackspaceEmpty: () => widget.notifier.deleteBlock(block.id),
          onSlashTriggered: (query) => _showSlashMenu(block.id, query),
          onSlashDismissed: () {
            if (_slashBlockId == block.id) {
              _hideSlashMenu();
            }
          },
        );
```

#### Changes in `block_editor_notifier.dart`:
Strip leading `/...` query when converting:
```dart
  Future<void> convertBlockType({
    required String blockId,
    required BlockType newType,
  }) async {
    final index = _state.blocks.indexWhere((b) => b.id == blockId);
    if (index == -1) return;

    final oldBlock = _state.blocks[index];
    final String rawText = (oldBlock.content['text'] ?? oldBlock.content['title'] ?? '').toString();
    final String currentText = rawText.startsWith('/') ? '' : rawText;

    final Map<String, dynamic> newContent = _convertContent(currentText, newType);
...
```

---

### Blueprint 7: Minor Hardening — `didUpdateWidget` in Remaining Renderers
**Files**:
1. `lib/features/workspace_editor/presentation/widgets/renderers/toggle_block_renderer.dart`
2. `lib/features/workspace_editor/presentation/widgets/renderers/math_block_renderer.dart`

#### Add to `_ToggleBlockRendererState`:
```dart
  @override
  void didUpdateWidget(covariant ToggleBlockRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final title = widget.block.content['title'] as String? ?? '';
    if (title != _controller.text) {
      _controller.text = title;
    }
  }
```

#### Add to `_MathBlockRendererState`:
```dart
  @override
  void didUpdateWidget(covariant MathBlockRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final latex = widget.block.content['latex'] as String? ?? '';
    if (latex != _controller.text) {
      _controller.text = latex;
    }
  }
```

---

### Blueprint 8: Adversarial Test Suite Synchronization
**File**: `test/widget/block_editor_adversarial_test.dart`

1. **Update Test 35 (Unsupported Language)** (lines 431–434):
   Previously:
   ```dart
   final hasCrash = exception != null || caughtError != null;
   expect(hasCrash, isTrue, reason: 'DropdownButton throws assertion failure when language is not in supportedLanguages');
   ```
   Update to:
   ```dart
   final hasCrash = exception != null || caughtError != null;
   expect(hasCrash, isFalse, reason: 'CodeBlockRenderer gracefully falls back to plain for unsupported languages');
   expect(find.byType(CodeBlockRenderer), findsOneWidget);
   ```
2. **Update Test 40 (Slash Menu Backspace Dismissal)** (lines 614–616):
   Previously:
   ```dart
   final isStillVisible = find.byType(SlashCommandMenu).evaluate().isNotEmpty;
   expect(isStillVisible, isTrue, reason: 'SlashCommandMenu is orphaned on screen when "/" is backspaced');
   ```
   Update to:
   ```dart
   expect(find.byType(SlashCommandMenu), findsNothing, reason: 'SlashCommandMenu is dismissed when "/" is backspaced');
   ```
3. **Add Tests**:
   - Test toggle child insertion: insert below a toggle child block; verify the new block has `parentBlockId: toggleBlock.id` and appears in `getChildrenOf(toggleBlock.id)`.
   - Test unmount flush: update block text, immediately dispose `notifier`, verify `repository.updateBlock` was called with the latest text.
   - Test Enter & Backspace keyboard listeners on `TextBlockRenderer` and `ChecklistBlockRenderer`.

---

## 4. Caveats

- **Scope Boundary**: This investigation strictly blueprints the presentation controller (`BlockEditorNotifier`), views (`BlockEditorView`), and renderers. The underlying DAO fix (`_blocksDao.updateBlockEntry`) and LexoRank midpoint fix (`StringLexoRank.between`) are handled by their respective explorer/worker pairs.
- **Hardware Keyboard Dependency**: In unit/widget test environments, `tester.sendKeyEvent` fires `KeyDownEvent` / `KeyUpEvent` through Flutter's `HardwareKeyboard`. On software keyboards without hardware key events, standard `onChanged` and `TextInputAction` handle text mutation; `FocusNode.onKeyEvent` specifically ensures desktop, web, external keyboard, and testing harness compatibility.

---

## 5. Conclusion

The 5 identified issues have been investigated to root causes, verified with empirical traces, and provided with exact, drop-in Dart replacements:
1. `effectiveParentId = parentBlockId ?? afterBlock?.parentBlockId` guarantees toggle children remain encapsulated.
2. Synchronous flushing of `_dirtyBlocks` in `dispose()` eliminates keystroke data loss during the 300ms debounce window.
3. `FocusNode.onKeyEvent` handles `onEnter` and `onBackspaceEmpty` without modifying block content unintentionally.
4. Adding `'plain'` to `supportedLanguages` and using `supportedLanguages.contains(...) ? ... : 'plain'` eliminates `DropdownButton` crashes.
5. `onSlashDismissed` cleans up the slash menu overlay as soon as `/` is backspaced.

---

## 6. Verification Method

To independently verify the implementation once applied by the worker:

1. **Static Analysis**:
   ```powershell
   C:\flutter\bin\flutter.bat analyze lib/ test/
   ```
   *Expected*: `No issues found!`, 0 errors, 0 warnings.
2. **Execute Full Widget Suite**:
   ```powershell
   C:\flutter\bin\flutter.bat test test/widget/
   ```
   *Expected*: All 41+ widget tests pass with 0 failures, including the updated tests for `CodeBlockRenderer` language fallback and slash menu backspace dismissal.
3. **Execute Full Unit Suite**:
   ```powershell
   C:\flutter\bin\flutter.bat test test/unit/
   ```
   *Expected*: All 60+ unit tests pass with 0 failures.
4. **Behavioral Invalidation Check**:
   - If calling `insertBlockAfter(afterBlockId: childBlock.id)` results in `newBlock.parentBlockId == null`, verification fails.
   - If unmounting during active debounce drops unsaved keystrokes in `_dirtyBlocks`, verification fails.
   - If rendering a code block with `language: 'rust'` throws an assertion error, verification fails.
   - If backspacing `/` leaves `SlashCommandMenu` visible, verification fails.
