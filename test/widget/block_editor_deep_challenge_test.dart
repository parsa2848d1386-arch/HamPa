import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:hampa/features/workspace_editor/domain/models/block_entity.dart';
import 'package:hampa/features/workspace_editor/domain/models/block_type.dart';
import 'package:hampa/features/workspace_editor/domain/repositories/block_repository.dart';
import 'package:hampa/features/workspace_editor/presentation/controllers/block_editor_notifier.dart';
import 'package:hampa/features/workspace_editor/presentation/widgets/block_editor_view.dart';
import 'package:hampa/features/workspace_editor/presentation/widgets/renderers/code_block_renderer.dart';
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
  TestWidgetsFlutterBinding.ensureInitialized();
  const testPageId = 'page_deep_challenge_1';

  group('Deep Challenge 1: Toggle Child Block Insertion & Scoping', () {
    late FakeBlockRepository repository;
    BlockEditorNotifier? notifier;

    setUp(() {
      repository = FakeBlockRepository();
    });

    tearDown(() {
      notifier?.dispose();
      repository.dispose();
    });

    testWidgets('Inserting below middle child inside a toggle keeps effectiveParentId and orders correctly', (tester) async {
      final now = DateTime.now();
      final toggle = BlockEntity(
        id: 'toggle_root',
        pageId: testPageId,
        type: BlockType.toggle,
        orderKey: 'a0',
        content: {'title': 'Root Toggle', 'isOpen': true},
        createdAt: now,
        updatedAt: now,
      );
      final childA = BlockEntity(
        id: 'child_a',
        pageId: testPageId,
        parentBlockId: 'toggle_root',
        type: BlockType.text,
        orderKey: 'a0:a0',
        content: {'text': 'Child A'},
        createdAt: now,
        updatedAt: now,
      );
      final childB = BlockEntity(
        id: 'child_b',
        pageId: testPageId,
        parentBlockId: 'toggle_root',
        type: BlockType.text,
        orderKey: 'a0:a1',
        content: {'text': 'Child B'},
        createdAt: now,
        updatedAt: now,
      );
      final childC = BlockEntity(
        id: 'child_c',
        pageId: testPageId,
        parentBlockId: 'toggle_root',
        type: BlockType.text,
        orderKey: 'a0:a2',
        content: {'text': 'Child C'},
        createdAt: now,
        updatedAt: now,
      );

      repository.seed([toggle, childA, childB, childC]);
      notifier = BlockEditorNotifier(
        repository: repository,
        pageId: testPageId,
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: BlockEditorView(notifier: notifier!)),
      ));
      await tester.pumpAndSettle();

      // Insert below Child B without specifying parentBlockId
      await notifier!.insertBlockAfter(afterBlockId: 'child_b');
      await tester.pumpAndSettle();

      final children = notifier!.state.getChildrenOf('toggle_root');
      expect(children.length, equals(4), reason: 'Toggle must now have 4 children');

      final insertedBlock = children[2];
      expect(insertedBlock.id, isNot('child_c'));
      expect(insertedBlock.parentBlockId, equals('toggle_root'),
          reason: 'effectiveParentId must match toggle_root, NOT null');

      // Check strict LexoRank ordering: childA < childB < insertedBlock < childC
      expect(childA.orderKey.compareTo(childB.orderKey), lessThan(0));
      expect(childB.orderKey.compareTo(insertedBlock.orderKey), lessThan(0));
      expect(insertedBlock.orderKey.compareTo(childC.orderKey), lessThan(0));
    });

    testWidgets('Nested toggle insertion scopes to innermost toggle container', (tester) async {
      final now = DateTime.now();
      final outerToggle = BlockEntity(
        id: 'outer_toggle',
        pageId: testPageId,
        type: BlockType.toggle,
        orderKey: 'a0',
        content: {'title': 'Outer', 'isOpen': true},
        createdAt: now,
        updatedAt: now,
      );
      final innerToggle = BlockEntity(
        id: 'inner_toggle',
        pageId: testPageId,
        parentBlockId: 'outer_toggle',
        type: BlockType.toggle,
        orderKey: 'a0:a0',
        content: {'title': 'Inner', 'isOpen': true},
        createdAt: now,
        updatedAt: now,
      );
      final leafChild = BlockEntity(
        id: 'leaf_child',
        pageId: testPageId,
        parentBlockId: 'inner_toggle',
        type: BlockType.text,
        orderKey: 'a0:a0:a0',
        content: {'text': 'Innermost leaf'},
        createdAt: now,
        updatedAt: now,
      );

      repository.seed([outerToggle, innerToggle, leafChild]);
      notifier = BlockEditorNotifier(
        repository: repository,
        pageId: testPageId,
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: BlockEditorView(notifier: notifier!)),
      ));
      await tester.pumpAndSettle();

      // Insert below leaf_child
      await notifier!.insertBlockAfter(afterBlockId: 'leaf_child');
      await tester.pumpAndSettle();

      final innerChildren = notifier!.state.getChildrenOf('inner_toggle');
      expect(innerChildren.length, equals(2));
      expect(innerChildren[1].parentBlockId, equals('inner_toggle'),
          reason: 'New block must belong to inner_toggle, not outer_toggle or null');

      final outerChildren = notifier!.state.getChildrenOf('outer_toggle');
      expect(outerChildren.length, equals(1)); // Only inner_toggle is directly under outer_toggle
    });

    testWidgets('Interactive UI popup menu "Add block below" on child inside toggle stays in toggle', (tester) async {
      final now = DateTime.now();
      final toggle = BlockEntity(
        id: 'ui_toggle',
        pageId: testPageId,
        type: BlockType.toggle,
        orderKey: 'a0',
        content: {'title': 'UI Toggle', 'isOpen': true},
        createdAt: now,
        updatedAt: now,
      );
      final child = BlockEntity(
        id: 'ui_child',
        pageId: testPageId,
        parentBlockId: 'ui_toggle',
        type: BlockType.text,
        orderKey: 'a0:a0',
        content: {'text': 'UI Child Item'},
        createdAt: now,
        updatedAt: now,
      );

      repository.seed([toggle, child]);
      notifier = BlockEditorNotifier(
        repository: repository,
        pageId: testPageId,
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: BlockEditorView(notifier: notifier!)),
      ));
      await tester.pumpAndSettle();

      // Find all drag_indicator icons (one for toggle, one for child)
      final dragIcons = find.byIcon(Icons.drag_indicator);
      expect(dragIcons, findsNWidgets(2));

      // Tap popup menu for child (the second drag indicator)
      await tester.tap(dragIcons.at(1));
      await tester.pumpAndSettle();

      // Tap 'Add block below'
      final addBelowItem = find.text('Add block below');
      expect(addBelowItem, findsOneWidget);
      await tester.tap(addBelowItem);
      await tester.pumpAndSettle();

      // Verify that the child collection in state has 2 items under ui_toggle
      final children = notifier!.state.getChildrenOf('ui_toggle');
      expect(children.length, equals(2));
      expect(children[1].parentBlockId, equals('ui_toggle'),
          reason: 'UI insertion below toggle child must retain parentBlockId == ui_toggle');
    });
  });

  group('Deep Challenge 2: Unmounting & Debounce Auto-Save with Persistence', () {
    testWidgets('Unmounting during 300ms debounce flushes dirty blocks to repository', (tester) async {
      final repository = FakeBlockRepository();
      final now = DateTime.now();

      final b1 = BlockEntity(
        id: 'b_flush_1',
        pageId: testPageId,
        type: BlockType.text,
        orderKey: 'a0',
        content: {'text': 'Initial B1'},
        createdAt: now,
        updatedAt: now,
      );
      final b2 = BlockEntity(
        id: 'b_flush_2',
        pageId: testPageId,
        type: BlockType.checklist,
        orderKey: 'a1',
        content: {'text': 'Initial B2', 'isCompleted': false},
        createdAt: now,
        updatedAt: now,
      );
      repository.seed([b1, b2]);

      final notifier = BlockEditorNotifier(
        repository: repository,
        pageId: testPageId,
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: BlockEditorView(notifier: notifier)),
      ));
      await tester.pumpAndSettle();

      // Modify both blocks within the 300ms debounce window
      notifier.updateBlockContent(
        blockId: 'b_flush_1',
        newContent: {'text': 'Dirty edit on B1 before unmount'},
      );
      notifier.updateBlockContent(
        blockId: 'b_flush_2',
        newContent: {'text': 'Dirty edit on B2 before unmount', 'isCompleted': true},
      );

      // Verify repository still holds old content (debounce timer is running)
      var savedB1 = (await repository.getBlocksForPage(testPageId))
          .firstWhere((b) => b.id == 'b_flush_1');
      expect(savedB1.content['text'], equals('Initial B1'));

      // Advance clock only 100ms (debounce timer has NOT fired yet)
      await tester.pump(const Duration(milliseconds: 100));

      // Unmount the widget tree and dispose notifier
      await tester.pumpWidget(const SizedBox.shrink());
      notifier.dispose();

      // Allow any microtasks dispatched by dispose() to settle
      await tester.pumpAndSettle();

      // Query repository directly
      savedB1 = (await repository.getBlocksForPage(testPageId))
          .firstWhere((b) => b.id == 'b_flush_1');
      final savedB2 = (await repository.getBlocksForPage(testPageId))
          .firstWhere((b) => b.id == 'b_flush_2');

      expect(savedB1.content['text'], contains('Dirty edit on B1 before unmount'),
          reason: 'b_flush_1 must be flushed and persisted');
      expect(savedB2.content['text'], contains('Dirty edit on B2 before unmount'),
          reason: 'b_flush_2 must be flushed and persisted');
      expect(savedB2.content['isCompleted'], isTrue);

      repository.dispose();
    });
  });

  group('Deep Challenge 3: Slash Menu Dismissal on Backspace', () {
    late FakeBlockRepository repository;
    BlockEditorNotifier? notifier;

    setUp(() async {
      repository = FakeBlockRepository();
      final initialBlock = BlockEntity(
        id: 'slash_text_block',
        pageId: testPageId,
        type: BlockType.text,
        orderKey: 'a0',
        content: {'text': ''},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      repository.seed([initialBlock]);

      notifier = BlockEditorNotifier(
        repository: repository,
        pageId: testPageId,
      );
    });

    tearDown(() {
      notifier?.dispose();
      repository.dispose();
    });

    testWidgets('Slash menu appears on "/", filters on text, disappears on backspace to empty', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: BlockEditorView(notifier: notifier!)),
      ));
      await tester.pumpAndSettle();

      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      // 1. Type "/"
      await tester.enterText(textField, '/');
      await tester.pumpAndSettle();
      expect(find.byType(SlashCommandMenu), findsOneWidget, reason: 'Slash menu should appear on "/"');

      // 2. Type "heading"
      await tester.enterText(textField, '/heading');
      await tester.pumpAndSettle();
      expect(find.text('Heading 1'), findsOneWidget);
      expect(find.text('Callout'), findsNothing);

      // 3. Backspace characters one by one down to "/"
      await tester.enterText(textField, '/head');
      await tester.pumpAndSettle();
      expect(find.byType(SlashCommandMenu), findsOneWidget);

      await tester.enterText(textField, '/');
      await tester.pumpAndSettle();
      expect(find.byType(SlashCommandMenu), findsOneWidget);
      expect(find.text('Heading 1'), findsOneWidget);
      expect(find.text('Text'), findsOneWidget);

      // 4. Backspace "/" away to empty string ""
      await tester.enterText(textField, '');
      await tester.pumpAndSettle();
      expect(find.byType(SlashCommandMenu), findsNothing,
          reason: 'Slash menu must be dismissed when "/" is backspaced away');

      // 5. Type non-slash text "hello"
      await tester.enterText(textField, 'hello');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      expect(find.byType(SlashCommandMenu), findsNothing,
          reason: 'Slash menu must not appear for normal text');
    });
  });

  group('Deep Challenge 4: CodeBlockRenderer Unlisted Language Resilience', () {
    final unlistedLanguages = [
      'rust',
      'go',
      'kotlin',
      'csharp',
      'ruby',
      'swift',
      'scala',
      'typescript',
      'elixir',
      'haskell',
      '',
    ];

    for (final lang in unlistedLanguages) {
      testWidgets('CodeBlockRenderer with unlisted language "$lang" falls back to plain without crash', (tester) async {
        final block = BlockEntity(
          id: 'code_$lang',
          pageId: testPageId,
          type: BlockType.code,
          orderKey: 'a0',
          content: {'code': '// test code', 'language': lang},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        FlutterErrorDetails? caughtError;
        final originalOnError = FlutterError.onError;
        FlutterError.onError = (details) {
          caughtError = details;
        };

        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: CodeBlockRenderer(
              block: block,
              onChanged: (_) {},
            ),
          ),
        ));
        await tester.pumpAndSettle();

        FlutterError.onError = originalOnError;

        expect(caughtError, isNull, reason: 'Must not trigger FlutterError assertion on unlisted language $lang');
        expect(tester.takeException(), isNull, reason: 'Must not throw exception');

        // Verify DropdownButton displays 'plain'
        final dropdown = tester.widget<DropdownButton<String>>(find.byType(DropdownButton<String>));
        expect(dropdown.value, equals('plain'),
            reason: 'DropdownButton value must be "plain" for unlisted language "$lang"');

        // Verify HighlightView is rendered with language "plain"
        final highlightView = tester.widget<HighlightView>(find.byType(HighlightView));
        expect(highlightView.language, equals('plain'));
      });
    }

    testWidgets('Changing language from plain to supported language triggers onChanged', (tester) async {
      Map<String, dynamic>? updatedContent;
      final block = BlockEntity(
        id: 'code_change_lang',
        pageId: testPageId,
        type: BlockType.code,
        orderKey: 'a0',
        content: {'code': 'println("hello")', 'language': 'rust'},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: CodeBlockRenderer(
            block: block,
            onChanged: (content) {
              updatedContent = content;
            },
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Tap dropdown to open menu
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();

      // Select 'python'
      await tester.tap(find.text('python').last);
      await tester.pumpAndSettle();

      expect(updatedContent, isNotNull);
      expect(updatedContent!['language'], equals('python'));
    });
  });
}
