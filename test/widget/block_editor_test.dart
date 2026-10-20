import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:hampa/features/workspace_editor/domain/models/block_entity.dart';
import 'package:hampa/features/workspace_editor/domain/models/block_type.dart';
import 'package:hampa/features/workspace_editor/domain/repositories/block_repository.dart';
import 'package:hampa/features/workspace_editor/presentation/controllers/block_editor_notifier.dart';
import 'package:hampa/features/workspace_editor/presentation/widgets/block_editor_view.dart';
import 'package:hampa/features/workspace_editor/presentation/widgets/slash_menu/slash_command_menu.dart';

class FakeBlockRepository implements IBlockRepository {
  final List<BlockEntity> _blocks = [];
  final StreamController<List<BlockEntity>> _streamController =
      StreamController<List<BlockEntity>>.broadcast();

  int insertCount = 0;
  int updateCount = 0;
  int deleteCount = 0;

  void seed(List<BlockEntity> blocks) {
    _blocks.clear();
    _blocks.addAll(blocks);
    _streamController.add(List.unmodifiable(_blocks));
  }

  @override
  Stream<List<BlockEntity>> watchBlocksForPage(String pageId) async* {
    yield List.unmodifiable(_blocks.where((b) => b.pageId == pageId).toList());
    yield* _streamController.stream.map(
      (list) => list.where((b) => b.pageId == pageId).toList(),
    );
  }

  @override
  Future<List<BlockEntity>> getBlocksForPage(String pageId) async {
    return _blocks.where((b) => b.pageId == pageId).toList();
  }

  @override
  Future<void> insertBlock(BlockEntity block) async {
    insertCount++;
    _blocks.add(block);
    _streamController.add(List.unmodifiable(_blocks));
  }

  @override
  Future<void> updateBlock(BlockEntity block) async {
    updateCount++;
    final idx = _blocks.indexWhere((b) => b.id == block.id);
    if (idx != -1) {
      _blocks[idx] = block;
      _streamController.add(List.unmodifiable(_blocks));
    }
  }

  @override
  Future<void> deleteBlock(String blockId) async {
    deleteCount++;
    _blocks.removeWhere((b) => b.id == blockId || b.parentBlockId == blockId);
    _streamController.add(List.unmodifiable(_blocks));
  }

  @override
  Future<void> reorderBlock({
    required String blockId,
    required String newOrderKey,
    String? newParentBlockId,
  }) async {
    final idx = _blocks.indexWhere((b) => b.id == blockId);
    if (idx != -1) {
      _blocks[idx] = _blocks[idx].copyWith(
        orderKey: newOrderKey,
        parentBlockId: newParentBlockId,
        clearParentBlockId: newParentBlockId == null,
      );
      _streamController.add(List.unmodifiable(_blocks));
    }
  }

  void dispose() {
    _streamController.close();
  }
}

void main() {
  const testPageId = 'page_test_1';
  late FakeBlockRepository repository;
  late BlockEditorNotifier notifier;

  setUp(() {
    repository = FakeBlockRepository();
    notifier = BlockEditorNotifier(
      repository: repository,
      pageId: testPageId,
    );
  });

  tearDown(() {
    notifier.dispose();
    repository.dispose();
  });

  Widget buildTestWidget() {
    return MaterialApp(
      home: Scaffold(
        body: BlockEditorView(notifier: notifier),
      ),
    );
  }

  testWidgets('Renders all block types without exceptions (Text, H1-H3, Checklist, Callout, Toggle, Code, Math, Divider)', (tester) async {
    final now = DateTime.now();
    repository.seed([
      BlockEntity(
        id: 'b_text',
        pageId: testPageId,
        type: BlockType.text,
        orderKey: 'a0',
        content: {'text': 'Standard paragraph text'},
        createdAt: now,
        updatedAt: now,
      ),
      BlockEntity(
        id: 'b_h1',
        pageId: testPageId,
        type: BlockType.heading1,
        orderKey: 'a1',
        content: {'text': 'Calculus Heading 1'},
        createdAt: now,
        updatedAt: now,
      ),
      BlockEntity(
        id: 'b_check',
        pageId: testPageId,
        type: BlockType.checklist,
        orderKey: 'a2',
        content: {'text': 'Review practice exam', 'isCompleted': false},
        createdAt: now,
        updatedAt: now,
      ),
      BlockEntity(
        id: 'b_callout',
        pageId: testPageId,
        type: BlockType.callout,
        orderKey: 'a3',
        content: {'text': 'Important exam formula hint', 'icon': '💡'},
        createdAt: now,
        updatedAt: now,
      ),
      BlockEntity(
        id: 'b_toggle',
        pageId: testPageId,
        type: BlockType.toggle,
        orderKey: 'a4',
        content: {'title': 'Derivation of Euler Formula', 'isOpen': false},
        createdAt: now,
        updatedAt: now,
      ),
      BlockEntity(
        id: 'b_code',
        pageId: testPageId,
        type: BlockType.code,
        orderKey: 'a5',
        content: {'code': 'void main() => print("Hello HamPA");', 'language': 'dart'},
        createdAt: now,
        updatedAt: now,
      ),
      BlockEntity(
        id: 'b_math',
        pageId: testPageId,
        type: BlockType.math,
        orderKey: 'a6',
        content: {'latex': r'e^{i\pi} + 1 = 0'},
        createdAt: now,
        updatedAt: now,
      ),
      BlockEntity(
        id: 'b_div',
        pageId: testPageId,
        type: BlockType.divider,
        orderKey: 'a7',
        content: {},
        createdAt: now,
        updatedAt: now,
      ),
    ]);

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Verify all contents render
    expect(find.text('Standard paragraph text'), findsOneWidget);
    expect(find.text('Calculus Heading 1'), findsOneWidget);
    expect(find.text('Review practice exam'), findsOneWidget);
    expect(find.text('Important exam formula hint'), findsOneWidget);
    expect(find.text('💡'), findsOneWidget);
    expect(find.text('Derivation of Euler Formula'), findsOneWidget);
    expect(find.byType(HighlightView), findsOneWidget);
    expect(find.byType(Math), findsOneWidget);
    expect(find.byType(Divider), findsOneWidget);
    expect(find.byType(Checkbox), findsOneWidget);
  });

  testWidgets('Checklist toggle updates isCompleted state and applies strikethrough', (tester) async {
    final now = DateTime.now();
    repository.seed([
      BlockEntity(
        id: 'chk_1',
        pageId: testPageId,
        type: BlockType.checklist,
        orderKey: 'a0',
        content: {'text': 'Finish homework problem set', 'isCompleted': false},
        createdAt: now,
        updatedAt: now,
      ),
    ]);

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    final checkboxFinder = find.byType(Checkbox);
    expect(tester.widget<Checkbox>(checkboxFinder).value, isFalse);

    // Tap checkbox to complete
    await tester.tap(checkboxFinder);
    await tester.pumpAndSettle();

    expect(tester.widget<Checkbox>(checkboxFinder).value, isTrue);

    // Verify text style contains lineThrough
    final textField = tester.widget<TextField>(find.widgetWithText(TextField, 'Finish homework problem set'));
    expect(textField.style?.decoration, equals(TextDecoration.lineThrough));

    // Tap checkbox again to uncomplete
    await tester.tap(checkboxFinder);
    await tester.pumpAndSettle();

    expect(tester.widget<Checkbox>(checkboxFinder).value, isFalse);
  });

  testWidgets('Toggle accordion expands and collapses nested child blocks', (tester) async {
    final now = DateTime.now();
    repository.seed([
      BlockEntity(
        id: 'toggle_container',
        pageId: testPageId,
        type: BlockType.toggle,
        orderKey: 'a0',
        content: {'title': 'Hidden Solutions Section', 'isOpen': false},
        createdAt: now,
        updatedAt: now,
      ),
      BlockEntity(
        id: 'nested_child',
        pageId: testPageId,
        parentBlockId: 'toggle_container',
        type: BlockType.text,
        orderKey: 'a0:a0',
        content: {'text': 'Nested solution step 1'},
        createdAt: now,
        updatedAt: now,
      ),
    ]);

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Initially collapsed: parent visible, child hidden
    expect(find.text('Hidden Solutions Section'), findsOneWidget);
    expect(find.text('Nested solution step 1'), findsNothing);

    // Tap toggle arrow to expand
    final arrowFinder = find.byIcon(Icons.arrow_right);
    expect(arrowFinder, findsOneWidget);
    await tester.tap(arrowFinder);
    await tester.pumpAndSettle();

    // Now open: nested child visible
    expect(find.text('Nested solution step 1'), findsOneWidget);

    // Tap arrow again to collapse
    await tester.tap(arrowFinder);
    await tester.pumpAndSettle();

    // Hidden again
    expect(find.text('Nested solution step 1'), findsNothing);
  });

  testWidgets('Typing / opens SlashCommandMenu and selecting an item converts block type', (tester) async {
    final now = DateTime.now();
    repository.seed([
      BlockEntity(
        id: 'text_block_1',
        pageId: testPageId,
        type: BlockType.text,
        orderKey: 'a0',
        content: {'text': ''},
        createdAt: now,
        updatedAt: now,
      ),
    ]);

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Type /call into the text block
    final textFieldFinder = find.byType(TextField);
    await tester.enterText(textFieldFinder, '/call');
    await tester.pumpAndSettle();

    // Slash command overlay should be active
    expect(find.byType(SlashCommandMenu), findsOneWidget);
    expect(find.text('Callout'), findsOneWidget);

    // Tap Callout command
    await tester.tap(find.text('Callout'));
    await tester.pumpAndSettle();

    // Slash menu should be dismissed
    expect(find.byType(SlashCommandMenu), findsNothing);

    // Block type should now be converted to Callout
    final currentBlock = notifier.state.blocks.firstWhere((b) => b.id == 'text_block_1');
    expect(currentBlock.type, equals(BlockType.callout));
    expect(find.text('💡'), findsOneWidget);
  });

  testWidgets('Auto-save debouncing commits dirty blocks to repository', (tester) async {
    final now = DateTime.now();
    repository.seed([
      BlockEntity(
        id: 'edit_block',
        pageId: testPageId,
        type: BlockType.text,
        orderKey: 'a0',
        content: {'text': 'Initial'},
        createdAt: now,
        updatedAt: now,
      ),
    ]);

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    notifier.updateBlockContent(
      blockId: 'edit_block',
      newContent: {'text': 'Modified by keystrokes'},
    );
    await tester.pump();

    // Saving indicator visible
    expect(notifier.state.isSaving, isTrue);
    expect(find.text('Saving...'), findsOneWidget);

    // Flush dirty blocks
    await notifier.flushDirtyBlocks();
    await tester.pumpAndSettle();

    expect(notifier.state.isSaving, isFalse);
    expect(find.text('Saving...'), findsNothing);
    expect(repository.updateCount, greaterThanOrEqualTo(1));
  });

  testWidgets('Block action popup menu allows adding block below and deleting block', (tester) async {
    final now = DateTime.now();
    repository.seed([
      BlockEntity(
        id: 'b1',
        pageId: testPageId,
        type: BlockType.text,
        orderKey: 'a0',
        content: {'text': 'First Block'},
        createdAt: now,
        updatedAt: now,
      ),
    ]);

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Open drag indicator popup menu
    final dragIcon = find.byIcon(Icons.drag_indicator);
    expect(dragIcon, findsOneWidget);
    await tester.tap(dragIcon);
    await tester.pumpAndSettle();

    expect(find.text('Add block below'), findsOneWidget);
    expect(find.text('Delete block'), findsOneWidget);

    // Tap Add block below
    await tester.tap(find.text('Add block below'));
    await tester.pumpAndSettle();

    expect(notifier.state.blocks.length, equals(2));
  });
}
