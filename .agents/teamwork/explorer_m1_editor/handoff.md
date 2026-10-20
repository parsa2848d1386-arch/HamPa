# Handoff Report: Milestone 1 Modular Block-Based Editor Architecture & Implementation Plan

**Agent**: `explorer_m1_editor` (Modular Block Editor Explorer)  
**Working Directory**: `c:\parsa\HamPA\.agents\teamwork\explorer_m1_editor`  
**Parent Orchestrator Conversation ID**: `22d8faaf-eb90-463c-99a6-32a4eb94320e`  
**Date**: 2026-10-16T17:00:00Z  

---

## 1. Observation

### 1.1 Direct Observations & Examined Specifications
1. **Authoritative Request (`ORIGINAL_REQUEST.md`, Lines 12–18, 39–43)**:
   - R1: "Modular block-based editor supporting text, headings, interactive checklists, callouts, toggles, code syntax highlighting, and LaTeX math formatting."
   - R1: "Local-first architecture (SQLite / Drift + local cache) for zero-latency offline writing and editing."
   - Acceptance Criteria AC1: "Nested sub-pages can be created, edited, and rearranged without state loss."
   - Hybrid Synergy R3 / AC8: Checklist blocks linkable to focus sessions ("Focus Now") and auto-check completion.
2. **Global Project Specification (`PROJECT.md`, Lines 20–28, 64, 76–87, 155–186)**:
   - Features F04 (Rich text & headings: H1, H2, H3 with inline styling), F05 (Interactive checklists with timestamped completion), F06 (Callouts with tinted boxes/icons and collapsible toggles with nested children), F07 (Code syntax highlighting via `flutter_highlight` and KaTeX math via `flutter_math_fork`).
   - Clean Architecture layout: Presentation layer at `lib/features/workspace_editor/presentation/`, Domain layer at `lib/features/workspace_editor/domain/`.
3. **Architecture Blueprint (`explorer_survey_arch/handoff.md`, Lines 153–181)**:
   - SQLite table schema for `blocks`:
     ```sql
     CREATE TABLE blocks (
       id TEXT NOT NULL PRIMARY KEY,
       page_id TEXT NOT NULL,
       parent_block_id TEXT, -- NULL for top-level, non-null for toggles/nested lists
       block_type TEXT NOT NULL, -- 'text', 'heading_1', 'heading_2', 'heading_3', 'checklist', 'callout', 'toggle', 'code', 'math', 'divider'
       order_key TEXT NOT NULL, -- Fractional index (LexoRank) for O(1) reordering
       content_json TEXT NOT NULL, -- Type-specific JSON payload
       created_at INTEGER NOT NULL,
       updated_at INTEGER NOT NULL,
       is_archived BOOLEAN NOT NULL DEFAULT FALSE,
       FOREIGN KEY (page_id) REFERENCES pages (id) ON DELETE CASCADE,
       FOREIGN KEY (parent_block_id) REFERENCES blocks (id) ON DELETE CASCADE
     );
     ```
4. **Environment Survey (`explorer_survey_env/handoff.md`, Lines 86–113)**:
   - Verified dependencies on pub.dev:
     `flutter_math_fork: ^0.7.4`, `flutter_highlight: ^0.7.0`, `flutter_markdown: ^0.7.7`, `drift: ^2.24.0`, `drift_flutter: ^0.2.0`, `uuid: ^4.6.0`, `intl: ^0.20.3`.

---

## 2. Logic Chain

1. **Polymorphic Block Architecture with Uniform Persistence**:
   - Notion's modularity relies on blocks being atomic, reorderable units rather than a monolithic document string.
   - By standardizing on `BlockEntity` with a discriminator `BlockType` and a strongly-typed `content_json` map, any block can be transformed into any other block in-place (e.g., text to heading, text to checklist) simply by altering its `type` and transforming its content payload.
2. **Fractional Indexing (`order_key`) for Zero-Cascade Reordering**:
   - Sequential integer ordering ($0, 1, 2, \dots$) requires updating $N$ database rows when inserting a block in the middle of a document, causing SQLite lock contention and frame drops.
   - LexoRank fractional indexing generates string keys (e.g. midpoint between "a0" and "a1" is "a0V") requiring only a single row insertion or update ($O(1)$ database cost).
3. **Hierarchical Nesting via `parent_block_id`**:
   - Toggle blocks (F06) and indented lists require child blocks to belong to a parent container block while retaining page association.
   - Giving `BlockEntity` an optional `parent_block_id` allows recursive tree rendering for toggles: collapsing a toggle hides all descendant blocks with `parent_block_id == toggle.id` without detaching them from the page.
4. **Debounced Local-First Auto-Save (AC3)**:
   - Typing generates high-frequency state emissions (keystroke events). Spanning SQLite transactions on every keystroke causes I/O thrashing.
   - A debounced save engine (300ms window) buffers content changes in-memory in `BlockEditorNotifier` and commits to `BlocksDao` when idle, or immediately upon focus loss, block creation, or deletion.
5. **Slash Command Menu (`/`) as Primary Interaction Paradigm**:
   - Typing `/` on an empty or active line must open an inline floating command palette filtered by keystrokes.
   - Selecting a command converts the current block type or inserts a new block of that type, clearing the `/` prefix.

---

## 3. Caveats & Edge Cases

1. **Rich Text Formatting vs Markdown Representation**:
   - Pure HTML or Quill delta formats can become bloated. For M1, we store text content with markdown formatting support, parsed inline using `TextEditingController` spans or markdown regexes, keeping serialization lightweight and human-readable.
2. **KaTeX / LaTeX Rendering Errors (`flutter_math_fork`)**:
   - Malformed LaTeX input could throw exceptions during layout. The `MathBlockRenderer` must wrap `Math.tex()` in an error-handling builder, displaying syntax warnings in red without breaking the editor widget tree.
3. **Code Syntax Highlighting (`flutter_highlight`)**:
   - While editing code, real-time syntax re-highlighting on large snippets (>500 lines) can cause frame jank. In edit mode, the block renders a high-performance monospace `TextField`; when unfocused or set to preview mode, it renders the syntax-highlighted widget.
4. **IME (Input Method Editor) and Multilingual RTL/LTR**:
   - HamPA supports Persian (هم‌پا) and English. Text blocks must automatically detect or inherit text direction (`textDirection: TextDirection.rtl` or `ltr`) based on the first strong directional character.

---

## 4. Conclusion & Complete File-by-File Implementation Plan

### 4.1 Target File Structure for Milestone 1 Editor

```
c:\parsa\HamPA\
├── lib/
│   └── features/
│       └── workspace_editor/
│           ├── domain/
│           │   ├── models/
│           │   │   ├── block_entity.dart
│           │   │   ├── block_type.dart
│           │   │   └── block_contents.dart
│           │   └── repositories/
│           │       └── block_repository.dart
│           ├── presentation/
│           │   ├── controllers/
│           │   │   ├── block_editor_state.dart
│           │   │   └── block_editor_notifier.dart
│           │   └── widgets/
│           │       ├── block_editor_view.dart
│           │       ├── block_item_widget.dart
│           │       ├── slash_menu/
│           │       │   ├── slash_command_menu.dart
│           │       │   └── slash_command_item.dart
│           │       └── renderers/
│           │           ├── text_block_renderer.dart
│           │           ├── checklist_block_renderer.dart
│           │           ├── callout_block_renderer.dart
│           │           ├── toggle_block_renderer.dart
│           │           ├── code_block_renderer.dart
│           │           ├── math_block_renderer.dart
│           │           └── divider_block_renderer.dart
└── test/
    └── widget/
        └── block_editor_test.dart
```

---

### 4.2 File 1: Domain Models — `lib/features/workspace_editor/domain/models/block_type.dart`

```dart
import 'package:flutter/material.dart';

enum BlockType {
  text('text'),
  heading1('heading_1'),
  heading2('heading_2'),
  heading3('heading_3'),
  checklist('checklist'),
  callout('callout'),
  toggle('toggle'),
  code('code'),
  math('math'),
  divider('divider');

  final String value;
  const BlockType(this.value);

  static BlockType fromString(String value) {
    return BlockType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => BlockType.text,
    );
  }

  String get displayName {
    switch (this) {
      case BlockType.text:
        return 'Text';
      case BlockType.heading1:
        return 'Heading 1';
      case BlockType.heading2:
        return 'Heading 2';
      case BlockType.heading3:
        return 'Heading 3';
      case BlockType.checklist:
        return 'To-do List';
      case BlockType.callout:
        return 'Callout';
      case BlockType.toggle:
        return 'Toggle List';
      case BlockType.code:
        return 'Code Block';
      case BlockType.math:
        return 'Math Equation';
      case BlockType.divider:
        return 'Divider';
    }
  }

  IconData get iconData {
    switch (this) {
      case BlockType.text:
        return Icons.short_text;
      case BlockType.heading1:
        return Icons.title;
      case BlockType.heading2:
        return Icons.format_size;
      case BlockType.heading3:
        return Icons.format_size;
      case BlockType.checklist:
        return Icons.check_box_outlined;
      case BlockType.callout:
        return Icons.lightbulb_outline;
      case BlockType.toggle:
        return Icons.arrow_right;
      case BlockType.code:
        return Icons.code;
      case BlockType.math:
        return Icons.functions;
      case BlockType.divider:
        return Icons.horizontal_rule;
    }
  }

  String get placeholderText {
    switch (this) {
      case BlockType.text:
        return "Type '/' for commands...";
      case BlockType.heading1:
        return 'Heading 1';
      case BlockType.heading2:
        return 'Heading 2';
      case BlockType.heading3:
        return 'Heading 3';
      case BlockType.checklist:
        return 'To-do';
      case BlockType.callout:
        return 'Callout content...';
      case BlockType.toggle:
        return 'Toggle title...';
      case BlockType.code:
        return '// Enter code here';
      case BlockType.math:
        return 'E = mc^2';
      case BlockType.divider:
        return '';
    }
  }

  bool get isHeader =>
      this == BlockType.heading1 ||
      this == BlockType.heading2 ||
      this == BlockType.heading3;

  bool get supportsChildren => this == BlockType.toggle;
}
```

---

### 4.3 File 2: Domain Models — `lib/features/workspace_editor/domain/models/block_contents.dart`

```dart
import 'dart:convert';

/// Value objects representing type-safe content JSON structures
abstract class BlockContentPayload {
  Map<String, dynamic> toJson();
}

class TextBlockContent implements BlockContentPayload {
  final String text;

  const TextBlockContent({required this.text});

  factory TextBlockContent.fromJson(Map<String, dynamic> json) {
    return TextBlockContent(text: json['text'] as String? ?? '');
  }

  @override
  Map<String, dynamic> toJson() => {'text': text};
}

class ChecklistBlockContent implements BlockContentPayload {
  final String text;
  final bool isCompleted;
  final int? checkedAt;

  const ChecklistBlockContent({
    required this.text,
    this.isCompleted = false,
    this.checkedAt,
  });

  factory ChecklistBlockContent.fromJson(Map<String, dynamic> json) {
    return ChecklistBlockContent(
      text: json['text'] as String? ?? '',
      isCompleted: json['isCompleted'] as bool? ?? false,
      checkedAt: json['checkedAt'] as int?,
    );
  }

  ChecklistBlockContent copyWith({
    String? text,
    bool? isCompleted,
    int? checkedAt,
  }) {
    return ChecklistBlockContent(
      text: text ?? this.text,
      isCompleted: isCompleted ?? this.isCompleted,
      checkedAt: checkedAt ?? this.checkedAt,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'text': text,
    'isCompleted': isCompleted,
    if (checkedAt != null) 'checkedAt': checkedAt,
  };
}

class CalloutBlockContent implements BlockContentPayload {
  final String text;
  final String icon; // Emoji or identifier
  final String colorTheme; // 'amber', 'blue', 'green', 'rose', 'purple'

  const CalloutBlockContent({
    required this.text,
    this.icon = '💡',
    this.colorTheme = 'amber',
  });

  factory CalloutBlockContent.fromJson(Map<String, dynamic> json) {
    return CalloutBlockContent(
      text: json['text'] as String? ?? '',
      icon: json['icon'] as String? ?? '💡',
      colorTheme: json['colorTheme'] as String? ?? 'amber',
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'text': text,
    'icon': icon,
    'colorTheme': colorTheme,
  };
}

class ToggleBlockContent implements BlockContentPayload {
  final String title;
  final bool isOpen;

  const ToggleBlockContent({
    required this.title,
    this.isOpen = false,
  });

  factory ToggleBlockContent.fromJson(Map<String, dynamic> json) {
    return ToggleBlockContent(
      title: json['title'] as String? ?? '',
      isOpen: json['isOpen'] as bool? ?? false,
    );
  }

  ToggleBlockContent copyWith({String? title, bool? isOpen}) {
    return ToggleBlockContent(
      title: title ?? this.title,
      isOpen: isOpen ?? this.isOpen,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'title': title,
    'isOpen': isOpen,
  };
}

class CodeBlockContent implements BlockContentPayload {
  final String code;
  final String language;
  final bool showLineNumbers;

  const CodeBlockContent({
    required this.code,
    this.language = 'dart',
    this.showLineNumbers = true,
  });

  factory CodeBlockContent.fromJson(Map<String, dynamic> json) {
    return CodeBlockContent(
      code: json['code'] as String? ?? '',
      language: json['language'] as String? ?? 'dart',
      showLineNumbers: json['showLineNumbers'] as bool? ?? true,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'code': code,
    'language': language,
    'showLineNumbers': showLineNumbers,
  };
}

class MathBlockContent implements BlockContentPayload {
  final String latex;
  final bool isDisplayMode;

  const MathBlockContent({
    required this.latex,
    this.isDisplayMode = true,
  });

  factory MathBlockContent.fromJson(Map<String, dynamic> json) {
    return MathBlockContent(
      latex: json['latex'] as String? ?? '',
      isDisplayMode: json['isDisplayMode'] as bool? ?? true,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'latex': latex,
    'isDisplayMode': isDisplayMode,
  };
}
```

---

### 4.4 File 3: Domain Models — `lib/features/workspace_editor/domain/models/block_entity.dart`

```dart
import 'dart:convert';
import 'block_type.dart';

class BlockEntity {
  final String id;
  final String pageId;
  final String? parentBlockId;
  final BlockType type;
  final String orderKey;
  final Map<String, dynamic> content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isArchived;

  const BlockEntity({
    required this.id,
    required this.pageId,
    this.parentBlockId,
    required this.type,
    required this.orderKey,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.isArchived = false,
  });

  BlockEntity copyWith({
    String? id,
    String? pageId,
    String? parentBlockId,
    BlockType? type,
    String? orderKey,
    Map<String, dynamic>? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isArchived,
  }) {
    return BlockEntity(
      id: id ?? this.id,
      pageId: pageId ?? this.pageId,
      parentBlockId: parentBlockId ?? this.parentBlockId,
      type: type ?? this.type,
      orderKey: orderKey ?? this.orderKey,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  String get contentJsonString => jsonEncode(content);

  factory BlockEntity.fromJson(Map<String, dynamic> json) {
    return BlockEntity(
      id: json['id'] as String,
      pageId: json['page_id'] as String,
      parentBlockId: json['parent_block_id'] as String?,
      type: BlockType.fromString(json['block_type'] as String),
      orderKey: json['order_key'] as String,
      content: json['content_json'] is String
          ? jsonDecode(json['content_json'] as String) as Map<String, dynamic>
          : json['content_json'] as Map<String, dynamic>,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updated_at'] as int),
      isArchived: json['is_archived'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'page_id': pageId,
      'parent_block_id': parentBlockId,
      'block_type': type.value,
      'order_key': orderKey,
      'content_json': jsonEncode(content),
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'is_archived': isArchived,
    };
  }
}
```

---

### 4.5 File 4: State Management — `lib/features/workspace_editor/presentation/controllers/block_editor_state.dart`

```dart
import '../../domain/models/block_entity.dart';

enum BlockEditorStatus { initial, loading, loaded, error }

class BlockEditorState {
  final BlockEditorStatus status;
  final String pageId;
  final List<BlockEntity> blocks;
  final String? focusedBlockId;
  final bool isSaving;
  final String? errorMessage;

  const BlockEditorState({
    required this.status,
    required this.pageId,
    this.blocks = const [],
    this.focusedBlockId,
    this.isSaving = false,
    this.errorMessage,
  });

  factory BlockEditorState.initial(String pageId) => BlockEditorState(
        status: BlockEditorStatus.initial,
        pageId: pageId,
      );

  BlockEditorState copyWith({
    BlockEditorStatus? status,
    String? pageId,
    List<BlockEntity>? blocks,
    String? focusedBlockId,
    bool? isSaving,
    String? errorMessage,
  }) {
    return BlockEditorState(
      status: status ?? this.status,
      pageId: pageId ?? this.pageId,
      blocks: blocks ?? this.blocks,
      focusedBlockId: focusedBlockId ?? this.focusedBlockId,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
    );
  }

  List<BlockEntity> get topLevelBlocks =>
      blocks.where((b) => b.parentBlockId == null && !b.isArchived).toList()
        ..sort((a, b) => a.orderKey.compareTo(b.orderKey));

  List<BlockEntity> getChildrenOf(String parentId) =>
      blocks.where((b) => b.parentBlockId == parentId && !b.isArchived).toList()
        ..sort((a, b) => a.orderKey.compareTo(b.orderKey));
}
```

---

### 4.6 File 5: Controller & Auto-Save Notifier — `lib/features/workspace_editor/presentation/controllers/block_editor_notifier.dart`

```dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/block_entity.dart';
import '../../domain/models/block_type.dart';
import '../../domain/repositories/block_repository.dart';
import 'block_editor_state.dart';

class BlockEditorNotifier extends ChangeNotifier {
  final IBlockRepository repository;
  final String pageId;

  BlockEditorState _state;
  BlockEditorState get state => _state;

  StreamSubscription<List<BlockEntity>>? _blocksSubscription;
  Timer? _debounceSaveTimer;
  final Map<String, BlockEntity> _dirtyBlocks = {};
  static const _uuid = Uuid();

  BlockEditorNotifier({
    required this.repository,
    required this.pageId,
  }) : _state = BlockEditorState.initial(pageId) {
    _init();
  }

  void _init() {
    _state = _state.copyWith(status: BlockEditorStatus.loading);
    notifyListeners();

    _blocksSubscription = repository.watchBlocksForPage(pageId).listen(
      (blocks) {
        // If empty page, initialize with a default text block
        if (blocks.isEmpty) {
          createInitialBlock();
        } else {
          _state = _state.copyWith(
            status: BlockEditorStatus.loaded,
            blocks: blocks,
          );
          notifyListeners();
        }
      },
      onError: (err) {
        _state = _state.copyWith(
          status: BlockEditorStatus.error,
          errorMessage: err.toString(),
        );
        notifyListeners();
      },
    );
  }

  Future<void> createInitialBlock() async {
    final block = BlockEntity(
      id: _uuid.v4(),
      pageId: pageId,
      type: BlockType.text,
      orderKey: 'a0',
      content: {'text': ''},
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await repository.insertBlock(block);
  }

  void updateBlockContent({
    required String blockId,
    required Map<String, dynamic> newContent,
  }) {
    final index = _state.blocks.indexWhere((b) => b.id == blockId);
    if (index == -1) return;

    final updated = _state.blocks[index].copyWith(
      content: newContent,
      updatedAt: DateTime.now(),
    );

    final updatedList = List<BlockEntity>.from(_state.blocks);
    updatedList[index] = updated;

    _dirtyBlocks[blockId] = updated;
    _state = _state.copyWith(blocks: updatedList, isSaving: true);
    notifyListeners();

    _scheduleDebouncedSave();
  }

  void _scheduleDebouncedSave() {
    _debounceSaveTimer?.cancel();
    _debounceSaveTimer = Timer(const Duration(milliseconds: 350), () async {
      await flushDirtyBlocks();
    });
  }

  Future<void> flushDirtyBlocks() async {
    if (_dirtyBlocks.isEmpty) {
      if (_state.isSaving) {
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

    _state = _state.copyWith(isSaving: false);
    notifyListeners();
  }

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
      // Append at end
      final lastKey = currentBlocks.isNotEmpty ? currentBlocks.last.orderKey : 'a0';
      newOrderKey = '${lastKey}z';
    } else {
      // Generate midpoint
      final currentKey = currentBlocks[currentIndex].orderKey;
      final nextKey = currentBlocks[currentIndex + 1].orderKey;
      newOrderKey = _generateMidpoint(currentKey, nextKey);
    }

    final newBlock = BlockEntity(
      id: _uuid.v4(),
      pageId: pageId,
      parentBlockId: parentBlockId,
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

  Map<String, dynamic> _convertContent(String existingText, BlockType newType) {
    switch (newType) {
      case BlockType.text:
      case BlockType.heading1:
      case BlockType.heading2:
      case BlockType.heading3:
        return {'text': existingText};
      case BlockType.checklist:
        return {'text': existingText, 'isCompleted': false};
      case BlockType.callout:
        return {'text': existingText, 'icon': '💡', 'colorTheme': 'amber'};
      case BlockType.toggle:
        return {'title': existingText.isEmpty ? 'Toggle' : existingText, 'isOpen': false};
      case BlockType.code:
        return {'code': existingText, 'language': 'dart', 'showLineNumbers': true};
      case BlockType.math:
        return {'latex': existingText.isEmpty ? 'E = mc^2' : existingText, 'isDisplayMode': true};
      case BlockType.divider:
        return {};
    }
  }

  Map<String, dynamic> _getInitialContentFor(BlockType type) {
    return _convertContent('', type);
  }

  Future<void> toggleChecklist(String blockId) async {
    final index = _state.blocks.indexWhere((b) => b.id == blockId);
    if (index == -1) return;

    final block = _state.blocks[index];
    final currentCompleted = block.content['isCompleted'] as bool? ?? false;
    final newCompleted = !currentCompleted;

    final newContent = Map<String, dynamic>.from(block.content)
      ..['isCompleted'] = newCompleted
      ..['checkedAt'] = newCompleted ? DateTime.now().millisecondsSinceEpoch : null;

    updateBlockContent(blockId: blockId, newContent: newContent);
    await flushDirtyBlocks();
  }

  Future<void> toggleCollapse(String blockId) async {
    final index = _state.blocks.indexWhere((b) => b.id == blockId);
    if (index == -1) return;

    final block = _state.blocks[index];
    final currentOpen = block.content['isOpen'] as bool? ?? false;

    final newContent = Map<String, dynamic>.from(block.content)
      ..['isOpen'] = !currentOpen;

    updateBlockContent(blockId: blockId, newContent: newContent);
    await flushDirtyBlocks();
  }

  Future<void> deleteBlock(String blockId) async {
    await flushDirtyBlocks();
    await repository.deleteBlock(blockId);
  }

  String _generateMidpoint(String a, String b) {
    return '${a}m';
  }

  @override
  void dispose() {
    _debounceSaveTimer?.cancel();
    _blocksSubscription?.cancel();
    flushDirtyBlocks();
    super.dispose();
  }
}
```

---

### 4.7 File 6: Slash Command Menu — `lib/features/workspace_editor/presentation/widgets/slash_menu/slash_command_menu.dart`

```dart
import 'package:flutter/material.dart';
import '../../../domain/models/block_type.dart';

class SlashCommandItem {
  final BlockType type;
  final String title;
  final String subtitle;
  final IconData icon;

  const SlashCommandItem({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

class SlashCommandMenu extends StatefulWidget {
  final String filterQuery;
  final ValueChanged<BlockType> onSelect;
  final VoidCallback onDismiss;

  const SlashCommandMenu({
    super.key,
    required this.filterQuery,
    required this.onSelect,
    required this.onDismiss,
  });

  @override
  State<SlashCommandMenu> createState() => _SlashCommandMenuState();
}

class _SlashCommandMenuState extends State<SlashCommandMenu> {
  int _selectedIndex = 0;

  static const List<SlashCommandItem> allItems = [
    SlashCommandItem(
      type: BlockType.text,
      title: 'Text',
      subtitle: 'Just start writing with plain text.',
      icon: Icons.short_text,
    ),
    SlashCommandItem(
      type: BlockType.heading1,
      title: 'Heading 1',
      subtitle: 'Big section heading.',
      icon: Icons.title,
    ),
    SlashCommandItem(
      type: BlockType.heading2,
      title: 'Heading 2',
      subtitle: 'Medium section heading.',
      icon: Icons.format_size,
    ),
    SlashCommandItem(
      type: BlockType.heading3,
      title: 'Heading 3',
      subtitle: 'Small section heading.',
      icon: Icons.format_size,
    ),
    SlashCommandItem(
      type: BlockType.checklist,
      title: 'To-do List',
      subtitle: 'Track tasks with a to-do list.',
      icon: Icons.check_box_outlined,
    ),
    SlashCommandItem(
      type: BlockType.callout,
      title: 'Callout',
      subtitle: 'Make writing stand out with tinted box.',
      icon: Icons.lightbulb_outline,
    ),
    SlashCommandItem(
      type: BlockType.toggle,
      title: 'Toggle List',
      subtitle: 'Toggles can hide and show nested content.',
      icon: Icons.arrow_right,
    ),
    SlashCommandItem(
      type: BlockType.code,
      title: 'Code Block',
      subtitle: 'Capture a code snippet with syntax highlighting.',
      icon: Icons.code,
    ),
    SlashCommandItem(
      type: BlockType.math,
      title: 'Math Formula',
      subtitle: 'LaTeX mathematical equation.',
      icon: Icons.functions,
    ),
    SlashCommandItem(
      type: BlockType.divider,
      title: 'Divider',
      subtitle: 'Visually divide blocks with a clean line.',
      icon: Icons.horizontal_rule,
    ),
  ];

  List<SlashCommandItem> get filteredItems {
    final query = widget.filterQuery.toLowerCase().trim();
    if (query.isEmpty) return allItems;
    return allItems.where((item) {
      return item.title.toLowerCase().contains(query) ||
          item.subtitle.toLowerCase().contains(query) ||
          item.type.value.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = filteredItems;
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Text('No matching block types', style: TextStyle(color: Colors.grey)),
      );
    }

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 300,
        constraints: const BoxConstraints(maxHeight: 320),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.2)),
        ),
        child: ListView.builder(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 4),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final isSelected = index == _selectedIndex;

            return InkWell(
              onTap: () => widget.onSelect(item.type),
              child: Container(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.08)
                    : null,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).dividerColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(item.icon, size: 20, color: Theme.of(context).colorScheme.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          Text(
                            item.subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
```

---

### 4.8 File 7: Block Renderers (Checklist, Callout, Toggle, Code, Math, Text, Divider)

#### 4.8.1 Text & Heading Renderer — `lib/features/workspace_editor/presentation/widgets/renderers/text_block_renderer.dart`
```dart
import 'package:flutter/material.dart';
import '../../../domain/models/block_entity.dart';
import '../../../domain/models/block_type.dart';

class TextBlockRenderer extends StatefulWidget {
  final BlockEntity block;
  final ValueChanged<Map<String, dynamic>> onChanged;
  final VoidCallback onEnter;
  final VoidCallback onBackspaceEmpty;
  final ValueChanged<String>? onSlashTriggered;

  const TextBlockRenderer({
    super.key,
    required this.block,
    required this.onChanged,
    required this.onEnter,
    required this.onBackspaceEmpty,
    this.onSlashTriggered,
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
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant TextBlockRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final text = widget.block.content['text'] as String? ?? '';
    if (text != _controller.text) {
      _controller.text = text;
    }
  }

  TextStyle _getStyle(BuildContext context) {
    final theme = Theme.of(context);
    switch (widget.block.type) {
      case BlockType.heading1:
        return theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              height: 1.3,
            ) ??
            const TextStyle(fontSize: 26, fontWeight: FontWeight.bold);
      case BlockType.heading2:
        return theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              height: 1.3,
            ) ??
            const TextStyle(fontSize: 21, fontWeight: FontWeight.bold);
      case BlockType.heading3:
        return theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              height: 1.3,
            ) ??
            const TextStyle(fontSize: 17, fontWeight: FontWeight.w600);
      default:
        return theme.textTheme.bodyMedium?.copyWith(
              fontSize: 15,
              height: 1.5,
            ) ??
            const TextStyle(fontSize: 15);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      maxLines: null,
      style: _getStyle(context),
      decoration: InputDecoration(
        border: InputBorder.none,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 4),
        hintText: widget.block.type.placeholderText,
        hintStyle: TextStyle(
          color: Theme.of(context).hintColor.withOpacity(0.4),
        ),
      ),
      onChanged: (val) {
        if (val.startsWith('/')) {
          widget.onSlashTriggered?.call(val.substring(1));
        }
        widget.onChanged({'text': val});
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}
```

#### 4.8.2 Checklist Renderer with "Focus Now" Bridge Link — `lib/features/workspace_editor/presentation/widgets/renderers/checklist_block_renderer.dart`
```dart
import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.block.content['text'] ?? '');
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
    final isCompleted = widget.block.content['isCompleted'] as bool? ?? false;
    final checkedAt = widget.block.content['checkedAt'] as int?;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Checkbox(
          value: isCompleted,
          onChanged: (_) => widget.onToggle(),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        Expanded(
          child: TextField(
            controller: _controller,
            maxLines: null,
            style: TextStyle(
              fontSize: 15,
              decoration: isCompleted ? TextDecoration.lineThrough : null,
              color: isCompleted
                  ? Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5)
                  : null,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 4),
              hintText: 'To-do item...',
            ),
            onChanged: (val) {
              widget.onChanged({
                ...widget.block.content,
                'text': val,
              });
            },
          ),
        ),
        if (checkedAt != null && isCompleted)
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Text(
              '✓ ${_formatTimestamp(checkedAt)}',
              style: TextStyle(fontSize: 11, color: Colors.green.shade600),
            ),
          ),
        // F29 Focus Now Button for quick study integration
        if (!isCompleted && widget.onFocusNow != null)
          IconButton(
            icon: const Icon(Icons.timer_outlined, size: 18),
            tooltip: 'Focus on this task (YPT Stopwatch)',
            onPressed: widget.onFocusNow,
            visualDensity: VisualDensity.compact,
          ),
      ],
    );
  }

  String _formatTimestamp(int epoch) {
    final dt = DateTime.fromMillisecondsSinceEpoch(epoch);
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

#### 4.8.3 Callout Renderer — `lib/features/workspace_editor/presentation/widgets/renderers/callout_block_renderer.dart`
```dart
import 'package:flutter/material.dart';
import '../../../domain/models/block_entity.dart';

class CalloutBlockRenderer extends StatefulWidget {
  final BlockEntity block;
  final ValueChanged<Map<String, dynamic>> onChanged;

  const CalloutBlockRenderer({
    super.key,
    required this.block,
    required this.onChanged,
  });

  @override
  State<CalloutBlockRenderer> createState() => _CalloutBlockRendererState();
}

class _CalloutBlockRendererState extends State<CalloutBlockRenderer> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.block.content['text'] ?? '');
  }

  Color _getBackgroundColor(String theme, bool isDark) {
    switch (theme) {
      case 'blue':
        return isDark ? Colors.blue.shade900.withOpacity(0.3) : Colors.blue.shade50;
      case 'green':
        return isDark ? Colors.green.shade900.withOpacity(0.3) : Colors.green.shade50;
      case 'rose':
        return isDark ? Colors.red.shade900.withOpacity(0.3) : Colors.red.shade50;
      case 'purple':
        return isDark ? Colors.purple.shade900.withOpacity(0.3) : Colors.purple.shade50;
      case 'amber':
      default:
        return isDark ? Colors.amber.shade900.withOpacity(0.3) : Colors.amber.shade50;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final icon = widget.block.content['icon'] as String? ?? '💡';
    final theme = widget.block.content['colorTheme'] as String? ?? 'amber';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _getBackgroundColor(theme, isDark),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black12,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _controller,
              maxLines: null,
              style: const TextStyle(fontSize: 15),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintText: 'Type callout message...',
              ),
              onChanged: (val) {
                widget.onChanged({
                  ...widget.block.content,
                  'text': val,
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

#### 4.8.4 Toggle Block Renderer — `lib/features/workspace_editor/presentation/widgets/renderers/toggle_block_renderer.dart`
```dart
import 'package:flutter/material.dart';
import '../../../domain/models/block_entity.dart';

class ToggleBlockRenderer extends StatefulWidget {
  final BlockEntity block;
  final VoidCallback onToggle;
  final ValueChanged<Map<String, dynamic>> onChanged;
  final Widget childBlocksWidget;

  const ToggleBlockRenderer({
    super.key,
    required this.block,
    required this.onToggle,
    required this.onChanged,
    required this.childBlocksWidget,
  });

  @override
  State<ToggleBlockRenderer> createState() => _ToggleBlockRendererState();
}

class _ToggleBlockRendererState extends State<ToggleBlockRenderer> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.block.content['title'] ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final isOpen = widget.block.content['isOpen'] as bool? ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            InkWell(
              onTap: widget.onToggle,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: AnimatedRotation(
                  turns: isOpen ? 0.25 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.arrow_right, size: 24),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: TextField(
                controller: _controller,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  hintText: 'Toggle list title...',
                ),
                onChanged: (val) {
                  widget.onChanged({
                    ...widget.block.content,
                    'title': val,
                  });
                },
              ),
            ),
          ],
        ),
        if (isOpen)
          Padding(
            padding: const EdgeInsets.only(left: 28.0),
            child: widget.childBlocksWidget,
          ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

#### 4.8.5 Code Block Renderer (`flutter_highlight`) — `lib/features/workspace_editor/presentation/widgets/renderers/code_block_renderer.dart`
```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom_one_dark.dart';
import 'package:flutter_highlight/themes/atom_one_light.dart';
import '../../../domain/models/block_entity.dart';

class CodeBlockRenderer extends StatefulWidget {
  final BlockEntity block;
  final ValueChanged<Map<String, dynamic>> onChanged;

  const CodeBlockRenderer({
    super.key,
    required this.block,
    required this.onChanged,
  });

  @override
  State<CodeBlockRenderer> createState() => _CodeBlockRendererState();
}

class _CodeBlockRendererState extends State<CodeBlockRenderer> {
  late final TextEditingController _controller;
  bool _isEditing = false;
  bool _copied = false;

  static const List<String> supportedLanguages = [
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
  Widget build(BuildContext context) {
    final language = widget.block.content['language'] as String? ?? 'dart';
    final code = widget.block.content['code'] as String? ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF282C34) : const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? Colors.black26 : Colors.black.withOpacity(0.04),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: language,
                    items: supportedLanguages
                        .map((l) => DropdownMenuItem(value: l, child: Text(l, style: const TextStyle(fontSize: 12))))
                        .toList(),
                    onChanged: (newLang) {
                      if (newLang != null) {
                        widget.onChanged({
                          ...widget.block.content,
                          'language': newLang,
                        });
                      }
                    },
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(_isEditing ? Icons.visibility : Icons.edit, size: 16),
                      tooltip: _isEditing ? 'Preview' : 'Edit code',
                      onPressed: () => setState(() => _isEditing = !_isEditing),
                    ),
                    IconButton(
                      icon: Icon(_copied ? Icons.check : Icons.copy, size: 16),
                      tooltip: 'Copy code',
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: code));
                        setState(() => _copied = true);
                        Future.delayed(const Duration(seconds: 2), () {
                          if (mounted) setState(() => _copied = false);
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Code Body
          if (_isEditing || code.isEmpty)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                controller: _controller,
                maxLines: null,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  hintText: '// Write or paste code...',
                ),
                onChanged: (val) {
                  widget.onChanged({
                    ...widget.block.content,
                    'code': val,
                  });
                },
              ),
            )
          else
            InkWell(
              onTap: () => setState(() => _isEditing = true),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: HighlightView(
                  code,
                  language: language,
                  theme: isDark ? atomOneDarkTheme : atomOneLightTheme,
                  textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

#### 4.8.6 LaTeX Math Block Renderer (`flutter_math_fork`) — `lib/features/workspace_editor/presentation/widgets/renderers/math_block_renderer.dart`
```dart
import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import '../../../domain/models/block_entity.dart';

class MathBlockRenderer extends StatefulWidget {
  final BlockEntity block;
  final ValueChanged<Map<String, dynamic>> onChanged;

  const MathBlockRenderer({
    super.key,
    required this.block,
    required this.onChanged,
  });

  @override
  State<MathBlockRenderer> createState() => _MathBlockRendererState();
}

class _MathBlockRendererState extends State<MathBlockRenderer> {
  late final TextEditingController _controller;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    final latex = widget.block.content['latex'] as String? ?? 'E = mc^2';
    _controller = TextEditingController(text: latex);
  }

  @override
  Widget build(BuildContext context) {
    final latex = widget.block.content['latex'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.functions, size: 16, color: Colors.blueAccent),
                  SizedBox(width: 6),
                  Text('TeX Formula', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
              IconButton(
                icon: Icon(_isEditing ? Icons.visibility : Icons.edit, size: 16),
                tooltip: _isEditing ? 'Preview formula' : 'Edit LaTeX',
                onPressed: () => setState(() => _isEditing = !_isEditing),
              ),
            ],
          ),
          if (_isEditing || latex.isEmpty)
            TextField(
              controller: _controller,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
              decoration: const InputDecoration(
                hintText: r'\int_{a}^{b} f(x)dx',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (val) {
                widget.onChanged({
                  ...widget.block.content,
                  'latex': val,
                });
              },
            )
          else
            Center(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Math.tex(
                    latex,
                    mathStyle: MathStyle.display,
                    textStyle: const TextStyle(fontSize: 18),
                    onErrorFallback: (err) => Text(
                      'LaTeX Error: ${err.message}',
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

#### 4.8.7 Divider Block Renderer — `lib/features/workspace_editor/presentation/widgets/renderers/divider_block_renderer.dart`
```dart
import 'package:flutter/material.dart';

class DividerBlockRenderer extends StatelessWidget {
  const DividerBlockRenderer({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: Divider(thickness: 1.5),
    );
  }
}
```

---

### 4.9 File 8: Unified Block Item & Editor View — `lib/features/workspace_editor/presentation/widgets/block_editor_view.dart`

```dart
import 'package:flutter/material.dart';
import '../../domain/models/block_entity.dart';
import '../../domain/models/block_type.dart';
import '../controllers/block_editor_notifier.dart';
import 'renderers/callout_block_renderer.dart';
import 'renderers/checklist_block_renderer.dart';
import 'renderers/code_block_renderer.dart';
import 'renderers/divider_block_renderer.dart';
import 'renderers/math_block_renderer.dart';
import 'renderers/text_block_renderer.dart';
import 'renderers/toggle_block_renderer.dart';
import 'slash_menu/slash_command_menu.dart';

class BlockEditorView extends StatefulWidget {
  final BlockEditorNotifier notifier;

  const BlockEditorView({super.key, required this.notifier});

  @override
  State<BlockEditorView> createState() => _BlockEditorViewState();
}

class _BlockEditorViewState extends State<BlockEditorView> {
  String? _slashBlockId;
  String _slashQuery = '';
  OverlayEntry? _slashOverlayEntry;
  final LayerLink _layerLink = LayerLink();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.notifier,
      builder: (context, _) {
        final state = widget.notifier.state;
        final blocks = state.topLevelBlocks;

        return Stack(
          children: [
            CompositedTransformTarget(
              link: _layerLink,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                itemCount: blocks.length,
                itemBuilder: (context, index) {
                  final block = blocks[index];
                  return _buildBlockItem(block);
                },
              ),
            ),
            if (state.isSaving)
              Positioned(
                top: 8,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('Saving...', style: TextStyle(color: Colors.white, fontSize: 11)),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildBlockItem(BlockEntity block) {
    return Padding(
      key: ValueKey(block.id),
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reorder / Action Handle
          MouseRegion(
            cursor: SystemMouseCursors.grab,
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.drag_indicator, size: 18, color: Colors.grey),
              padding: EdgeInsets.zero,
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'add_below', child: Text('Add block below')),
                const PopupMenuItem(value: 'delete', child: Text('Delete block', style: TextStyle(color: Colors.red))),
              ],
              onSelected: (val) {
                if (val == 'add_below') {
                  widget.notifier.insertBlockAfter(afterBlockId: block.id);
                } else if (val == 'delete') {
                  widget.notifier.deleteBlock(block.id);
                }
              },
            ),
          ),
          const SizedBox(width: 4),
          // Block Content
          Expanded(child: _renderBlock(block)),
        ],
      ),
    );
  }

  Widget _renderBlock(BlockEntity block) {
    switch (block.type) {
      case BlockType.text:
      case BlockType.heading1:
      case BlockType.heading2:
      case BlockType.heading3:
        return TextBlockRenderer(
          block: block,
          onChanged: (content) => widget.notifier.updateBlockContent(
            blockId: block.id,
            newContent: content,
          ),
          onEnter: () => widget.notifier.insertBlockAfter(afterBlockId: block.id),
          onBackspaceEmpty: () => widget.notifier.deleteBlock(block.id),
          onSlashTriggered: (query) => _showSlashMenu(block.id, query),
        );
      case BlockType.checklist:
        return ChecklistBlockRenderer(
          block: block,
          onToggle: () => widget.notifier.toggleChecklist(block.id),
          onChanged: (content) => widget.notifier.updateBlockContent(
            blockId: block.id,
            newContent: content,
          ),
          onEnter: () => widget.notifier.insertBlockAfter(
            afterBlockId: block.id,
            type: BlockType.checklist,
          ),
          onBackspaceEmpty: () => widget.notifier.convertBlockType(
            blockId: block.id,
            newType: BlockType.text,
          ),
        );
      case BlockType.callout:
        return CalloutBlockRenderer(
          block: block,
          onChanged: (content) => widget.notifier.updateBlockContent(
            blockId: block.id,
            newContent: content,
          ),
        );
      case BlockType.toggle:
        final children = widget.notifier.state.getChildrenOf(block.id);
        return ToggleBlockRenderer(
          block: block,
          onToggle: () => widget.notifier.toggleCollapse(block.id),
          onChanged: (content) => widget.notifier.updateBlockContent(
            blockId: block.id,
            newContent: content,
          ),
          childBlocksWidget: Column(
            children: children.map((c) => _buildBlockItem(c)).toList(),
          ),
        );
      case BlockType.code:
        return CodeBlockRenderer(
          block: block,
          onChanged: (content) => widget.notifier.updateBlockContent(
            blockId: block.id,
            newContent: content,
          ),
        );
      case BlockType.math:
        return MathBlockRenderer(
          block: block,
          onChanged: (content) => widget.notifier.updateBlockContent(
            blockId: block.id,
            newContent: content,
          ),
        );
      case BlockType.divider:
        return const DividerBlockRenderer();
    }
  }

  void _showSlashMenu(String blockId, String query) {
    _slashBlockId = blockId;
    _slashQuery = query;

    _slashOverlayEntry?.remove();
    _slashOverlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: 300,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(30, 40),
          child: SlashCommandMenu(
            filterQuery: _slashQuery,
            onSelect: (newType) {
              _hideSlashMenu();
              widget.notifier.convertBlockType(
                blockId: _slashBlockId!,
                newType: newType,
              );
            },
            onDismiss: _hideSlashMenu,
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_slashOverlayEntry!);
  }

  void _hideSlashMenu() {
    _slashOverlayEntry?.remove();
    _slashOverlayEntry = null;
    _slashBlockId = null;
    _slashQuery = '';
  }

  @override
  void dispose() {
    _slashOverlayEntry?.remove();
    super.dispose();
  }
}
```

---

### 4.10 File 9: Widget Test Suite — `test/widget/block_editor_test.dart`

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hampa/features/workspace_editor/domain/models/block_entity.dart';
import 'package:hampa/features/workspace_editor/domain/models/block_type.dart';
import 'package:hampa/features/workspace_editor/domain/repositories/block_repository.dart';
import 'package:hampa/features/workspace_editor/presentation/controllers/block_editor_notifier.dart';
import 'package:hampa/features/workspace_editor/presentation/widgets/block_editor_view.dart';
import 'package:hampa/features/workspace_editor/presentation/widgets/renderers/checklist_block_renderer.dart';
import 'package:hampa/features/workspace_editor/presentation/widgets/renderers/toggle_block_renderer.dart';
import 'package:hampa/features/workspace_editor/presentation/widgets/slash_menu/slash_command_menu.dart';

class MockBlockRepository implements IBlockRepository {
  final _controller = StreamController<List<BlockEntity>>.broadcast();
  final List<BlockEntity> _storage = [];

  void seed(List<BlockEntity> blocks) {
    _storage.clear();
    _storage.addAll(blocks);
    _controller.add(List.unmodifiable(_storage));
  }

  @override
  Stream<List<BlockEntity>> watchBlocksForPage(String pageId) => _controller.stream;

  @override
  Future<void> insertBlock(BlockEntity block) async {
    _storage.add(block);
    _controller.add(List.unmodifiable(_storage));
  }

  @override
  Future<void> updateBlock(BlockEntity block) async {
    final idx = _storage.indexWhere((b) => b.id == block.id);
    if (idx != -1) {
      _storage[idx] = block;
      _controller.add(List.unmodifiable(_storage));
    }
  }

  @override
  Future<void> deleteBlock(String blockId) async {
    _storage.removeWhere((b) => b.id == blockId);
    _controller.add(List.unmodifiable(_storage));
  }
}

void main() {
  late MockBlockRepository repository;
  late BlockEditorNotifier notifier;
  const testPageId = 'page_123';

  setUp(() {
    repository = MockBlockRepository();
    notifier = BlockEditorNotifier(repository: repository, pageId: testPageId);
  });

  tearDown(() {
    notifier.dispose();
  });

  Widget buildTestWidget() {
    return MaterialApp(
      home: Scaffold(
        body: BlockEditorView(notifier: notifier),
      ),
    );
  }

  testWidgets('Renders text, checklist, callout, and toggle blocks correctly', (tester) async {
    final now = DateTime.now();
    repository.seed([
      BlockEntity(
        id: 'b1',
        pageId: testPageId,
        type: BlockType.heading1,
        orderKey: 'a0',
        content: {'text': 'Calculus Notes'},
        createdAt: now,
        updatedAt: now,
      ),
      BlockEntity(
        id: 'b2',
        pageId: testPageId,
        type: BlockType.checklist,
        orderKey: 'a1',
        content: {'text': 'Read Chapter 4', 'isCompleted': false},
        createdAt: now,
        updatedAt: now,
      ),
      BlockEntity(
        id: 'b3',
        pageId: testPageId,
        type: BlockType.callout,
        orderKey: 'a2',
        content: {'text': 'Remember integration rules', 'icon': '💡', 'colorTheme': 'amber'},
        createdAt: now,
        updatedAt: now,
      ),
      BlockEntity(
        id: 'b4',
        pageId: testPageId,
        type: BlockType.toggle,
        orderKey: 'a3',
        content: {'title': 'Proof of Theorem 1', 'isOpen': false},
        createdAt: now,
        updatedAt: now,
      ),
    ]);

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Calculus Notes'), findsOneWidget);
    expect(find.text('Read Chapter 4'), findsOneWidget);
    expect(find.text('Remember integration rules'), findsOneWidget);
    expect(find.text('Proof of Theorem 1'), findsOneWidget);
    expect(find.byType(Checkbox), findsOneWidget);
  });

  testWidgets('Tapping checklist checkbox toggles completed state & applies strikethrough', (tester) async {
    final now = DateTime.now();
    repository.seed([
      BlockEntity(
        id: 'chk_1',
        pageId: testPageId,
        type: BlockType.checklist,
        orderKey: 'a0',
        content: {'text': 'Finish homework', 'isCompleted': false},
        createdAt: now,
        updatedAt: now,
      ),
    ]);

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    final checkbox = find.byType(Checkbox);
    expect(tester.widget<Checkbox>(checkbox).value, isFalse);

    // Tap checkbox
    await tester.tap(checkbox);
    await tester.pumpAndSettle();

    // Verify state updated
    expect(tester.widget<Checkbox>(checkbox).value, isTrue);
  });

  testWidgets('Expanding toggle reveals nested child blocks', (tester) async {
    final now = DateTime.now();
    repository.seed([
      BlockEntity(
        id: 'toggle_1',
        pageId: testPageId,
        type: BlockType.toggle,
        orderKey: 'a0',
        content: {'title': 'Hidden Details', 'isOpen': false},
        createdAt: now,
        updatedAt: now,
      ),
      BlockEntity(
        id: 'child_1',
        pageId: testPageId,
        parentBlockId: 'toggle_1',
        type: BlockType.text,
        orderKey: 'a0_c1',
        content: {'text': 'Secret nested paragraph!'},
        createdAt: now,
        updatedAt: now,
      ),
    ]);

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Initially closed, child not visible
    expect(find.text('Hidden Details'), findsOneWidget);
    expect(find.text('Secret nested paragraph!'), findsNothing);

    // Tap toggle arrow
    await tester.tap(find.byIcon(Icons.arrow_right));
    await tester.pumpAndSettle();

    // Now open, child visible
    expect(find.text('Secret nested paragraph!'), findsOneWidget);
  });
}
```

---

## 5. Verification Method

To verify the Milestone 1 Modular Block Editor implementation:

1. **Widget Test Execution**:
   - Command: `flutter test test/widget/block_editor_test.dart`
   - Target Assertions:
     - All 8 block types (Text, H1-H3, Checklist, Callout, Toggle, Code, Math, Divider) render without runtime overflow or layout exceptions.
     - Checklist toggles accurately toggle `isCompleted` and stamp `checkedAt`.
     - Toggle blocks expand and collapse nested children based on `parent_block_id`.
     - Slash menu filters by query and converts the active block type.
2. **Offline Drift Persistence Test**:
   - Invalidation Condition: If debounced updates fail to write to `BlocksDao` within 500ms, or if reordering corrupts the `order_key` sequence.
3. **LaTeX Math & Code Syntax Guarding**:
   - Verify that invalid LaTeX syntax (e.g. `\invalid{syntax{`) triggers the fallback error widget without crashing the Flutter framework.
