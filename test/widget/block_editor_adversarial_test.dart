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
import 'package:hampa/features/workspace_editor/presentation/widgets/renderers/math_block_renderer.dart';
import 'package:hampa/features/workspace_editor/presentation/widgets/slash_menu/slash_command_menu.dart';

class AdversarialFakeBlockRepository implements IBlockRepository {
  final List<BlockEntity> _blocks = [];
  final StreamController<List<BlockEntity>> _streamController =
      StreamController<List<BlockEntity>>.broadcast();

  int insertCount = 0;
  int updateCount = 0;
  int deleteCount = 0;

  void seed(List<BlockEntity> blocks) {
    _blocks.clear();
    _blocks.addAll(blocks);
    _emit();
  }

  void _emit() {
    if (!_streamController.isClosed) {
      _streamController.add(List.unmodifiable(_blocks));
    }
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
    _emit();
  }

  @override
  Future<void> updateBlock(BlockEntity block) async {
    updateCount++;
    final idx = _blocks.indexWhere((b) => b.id == block.id);
    if (idx != -1) {
      _blocks[idx] = block;
      _emit();
    }
  }

  @override
  Future<void> deleteBlock(String blockId) async {
    deleteCount++;
    _blocks.removeWhere((b) => b.id == blockId || b.parentBlockId == blockId);
    _emit();
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
      _emit();
    }
  }

  void dispose() {
    _streamController.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const testPageId = 'page_adversarial_1';
  late AdversarialFakeBlockRepository repository;
  late BlockEditorNotifier notifier;

  setUp(() {
    repository = AdversarialFakeBlockRepository();
    notifier = BlockEditorNotifier(
      repository: repository,
      pageId: testPageId,
    );
  });

  tearDown(() {
    notifier.dispose();
    repository.dispose();
  });

  Widget buildEditorWidget(BlockEditorNotifier n) {
    return MaterialApp(
      home: Scaffold(
        body: BlockEditorView(notifier: n),
      ),
    );
  }

  group('Adversarial Test Suite 1: Debounced Auto-Save & Rapid Keystrokes', () {
    testWidgets('Rapid 100-keystroke burst does not drop final edit or crash', (tester) async {
      final now = DateTime.now();
      repository.seed([
        BlockEntity(
          id: 'burst_block',
          pageId: testPageId,
          type: BlockType.text,
          orderKey: 'a0',
          content: {'text': ''},
          createdAt: now,
          updatedAt: now,
        ),
      ]);

      await tester.pumpWidget(buildEditorWidget(notifier));
      await tester.pumpAndSettle();

      // Simulate 100 rapid keystrokes with 5ms interval (well under 300ms debounce)
      for (int i = 1; i <= 100; i++) {
        notifier.updateBlockContent(
          blockId: 'burst_block',
          newContent: {'text': 'Keystroke $i'},
        );
        await tester.pump(const Duration(milliseconds: 5));
      }

      // Check saving state is active
      expect(notifier.state.isSaving, isTrue);

      // Advance time past the 300ms debounce threshold
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      // Verification: isSaving must be false, repository must have the final state
      expect(notifier.state.isSaving, isFalse);
      final finalBlock = (await repository.getBlocksForPage(testPageId))
          .firstWhere((b) => b.id == 'burst_block');
      expect(finalBlock.content['text'], equals('Keystroke 100'));
    });

    testWidgets('Multi-block high-frequency interleaving updates preserve all blocks', (tester) async {
      final now = DateTime.now();
      final blocks = List.generate(
        10,
        (i) => BlockEntity(
          id: 'mb_$i',
          pageId: testPageId,
          type: BlockType.text,
          orderKey: 'a$i',
          content: {'text': 'Init $i'},
          createdAt: now,
          updatedAt: now,
        ),
      );
      repository.seed(blocks);

      await tester.pumpWidget(buildEditorWidget(notifier));
      await tester.pumpAndSettle();

      // Interleave 50 updates across 10 blocks in rapid succession
      for (int round = 0; round < 5; round++) {
        for (int i = 0; i < 10; i++) {
          notifier.updateBlockContent(
            blockId: 'mb_$i',
            newContent: {'text': 'Round $round Block $i text'},
          );
          await tester.pump(const Duration(milliseconds: 2));
        }
      }

      // Settle past debounce timer
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      final savedBlocks = await repository.getBlocksForPage(testPageId);
      expect(savedBlocks.length, equals(10));
      for (int i = 0; i < 10; i++) {
        final b = savedBlocks.firstWhere((blk) => blk.id == 'mb_$i');
        expect(b.content['text'], equals('Round 4 Block $i text'));
      }
    });

    testWidgets('Disposal during pending debounce timer does not leak or throw', (tester) async {
      final localRepo = AdversarialFakeBlockRepository();
      final localNotifier = BlockEditorNotifier(
        repository: localRepo,
        pageId: 'local_page',
      );

      final now = DateTime.now();
      localRepo.seed([
        BlockEntity(
          id: 'dispose_block',
          pageId: 'local_page',
          type: BlockType.text,
          orderKey: 'a0',
          content: {'text': 'Before'},
          createdAt: now,
          updatedAt: now,
        ),
      ]);

      await tester.pumpWidget(buildEditorWidget(localNotifier));
      await tester.pumpAndSettle();

      // Trigger change
      localNotifier.updateBlockContent(
        blockId: 'dispose_block',
        newContent: {'text': 'Unsaved before unmount'},
      );
      await tester.pump();

      // Dispose widget and notifier mid-timer
      await tester.pumpWidget(const SizedBox.shrink());
      localNotifier.dispose();
      localRepo.dispose();

      // Advance clock past debounce time; ensure no exception
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
    });
  });

  group('Adversarial Test Suite 2: Malformed KaTeX/LaTeX Formula Fallback', () {
    final malformedLatexSamples = [
      r'\frac{1}{', // Missing closing denominator
      r'\sqrt{', // Unclosed square root
      r'\binom{n}', // Missing second argument
      r'\begin{matrix} 1 & 2', // Unclosed environment
      r'\begin{cases} x & \text{if } x > 0', // Unclosed cases
      r'{{{{{{{{', // Unmatched opening braces
      r'}}}}}}}}', // Unmatched closing braces
      r'\nonExistentLatexCommand12345', // Unknown macro
      r'^', // Lone superscript
      r'_', // Lone subscript
      r'\left( 1 + 2', // Unmatched delimiter
      r'\begin{align} x = 1', // Unclosed align environment
      r'$$ \frac{a}{b} $$', // Redundant dollar signs in expression
      r'\text{unclosed text string', // Unclosed text
    ];

    for (final sample in malformedLatexSamples) {
      testWidgets('Malformed LaTeX "$sample" gracefully renders fallback without throwing', (tester) async {
        final block = BlockEntity(
          id: 'math_malformed',
          pageId: testPageId,
          type: BlockType.math,
          orderKey: 'a0',
          content: {'latex': sample, 'isDisplayMode': true},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MathBlockRenderer(
                block: block,
                onChanged: (_) {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Must find LaTeX Error fallback text, never throw or crash
        expect(find.textContaining('LaTeX Error:'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('Empty latex formula renders edit field rather than crashing', (tester) async {
      final block = BlockEntity(
        id: 'math_empty',
        pageId: testPageId,
        type: BlockType.math,
        orderKey: 'a0',
        content: {'latex': ''},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MathBlockRenderer(
              block: block,
              onChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Empty latex should trigger the TextField editor branch
      expect(find.byType(TextField), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Switching between edit and preview mode on malformed formula survives', (tester) async {
      final block = BlockEntity(
        id: 'math_toggle',
        pageId: testPageId,
        type: BlockType.math,
        orderKey: 'a0',
        content: {'latex': r'\invalid{bad'},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MathBlockRenderer(
              block: block,
              onChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially in preview mode showing LaTeX Error
      expect(find.textContaining('LaTeX Error:'), findsOneWidget);

      // Tap Edit button
      final editBtn = find.byTooltip('Edit LaTeX');
      await tester.tap(editBtn);
      await tester.pumpAndSettle();

      // Should now show TextField
      expect(find.byType(TextField), findsOneWidget);

      // Tap Preview button
      final previewBtn = find.byTooltip('Preview formula');
      await tester.tap(previewBtn);
      await tester.pumpAndSettle();

      // Back to preview showing LaTeX Error
      expect(find.textContaining('LaTeX Error:'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Adversarial Test Suite 3: Code Block & Language Safety', () {
    testWidgets('Multi-line code snippet (100 lines) renders without overflowing or crashing', (tester) async {
      final lines = List.generate(100, (i) => 'Line $i: x = x + $i;').join('\n');
      final block = BlockEntity(
        id: 'code_large',
        pageId: testPageId,
        type: BlockType.code,
        orderKey: 'a0',
        content: {'code': lines, 'language': 'dart'},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CodeBlockRenderer(
                block: block,
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HighlightView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Code block with unsupported language in content causes DropdownButton assertion crash', (tester) async {
      // EMPIRICAL CHALLENGE: Verify whether CodeBlockRenderer crashes on unsupported language
      final block = BlockEntity(
        id: 'code_unsupported_lang',
        pageId: testPageId,
        type: BlockType.code,
        orderKey: 'a0',
        content: {'code': 'fn main() {}', 'language': 'rust'},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      FlutterErrorDetails? caughtError;
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        caughtError = details;
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CodeBlockRenderer(
              block: block,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      FlutterError.onError = originalOnError;

      // DropdownButton asserts that value must match an item in items
      // This test proves whether the bug exists
      final exception = tester.takeException();
      final hasCrash = exception != null || caughtError != null;
      expect(hasCrash, isFalse, reason: 'CodeBlockRenderer gracefully falls back to plain for unsupported languages');
      expect(find.byType(CodeBlockRenderer), findsOneWidget);
    });
  });

  group('Adversarial Test Suite 4: Empty Blocks & Toggle Expand/Collapse Cycles', () {
    testWidgets('Rapid toggle expand/collapse cycles (20 times) maintain consistent state', (tester) async {
      final now = DateTime.now();
      repository.seed([
        BlockEntity(
          id: 'toggle_stress',
          pageId: testPageId,
          type: BlockType.toggle,
          orderKey: 'a0',
          content: {'title': 'Stress Toggle', 'isOpen': false},
          createdAt: now,
          updatedAt: now,
        ),
        BlockEntity(
          id: 'child_stress',
          pageId: testPageId,
          parentBlockId: 'toggle_stress',
          type: BlockType.text,
          orderKey: 'a0:a0',
          content: {'text': 'Child payload'},
          createdAt: now,
          updatedAt: now,
        ),
      ]);

      await tester.pumpWidget(buildEditorWidget(notifier));
      await tester.pumpAndSettle();

      final arrowFinder = find.byIcon(Icons.arrow_right);
      expect(arrowFinder, findsOneWidget);

      // Perform 20 rapid toggles
      for (int i = 0; i < 20; i++) {
        await tester.tap(arrowFinder);
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.pumpAndSettle();

      // After an even number of toggles (20), it should be collapsed (isOpen = false)
      final toggleBlock = notifier.state.blocks.firstWhere((b) => b.id == 'toggle_stress');
      expect(toggleBlock.content['isOpen'], isFalse);
      expect(find.text('Child payload'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Empty text blocks on Enter insert subsequent block without crashing', (tester) async {
      final now = DateTime.now();
      repository.seed([
        BlockEntity(
          id: 'empty_b1',
          pageId: testPageId,
          type: BlockType.text,
          orderKey: 'a0',
          content: {'text': ''},
          createdAt: now,
          updatedAt: now,
        ),
      ]);

      await tester.pumpWidget(buildEditorWidget(notifier));
      await tester.pumpAndSettle();

      await notifier.insertBlockAfter(afterBlockId: 'empty_b1');
      await tester.pumpAndSettle();

      expect(notifier.state.blocks.length, equals(2));
      expect(notifier.state.blocks.last.content['text'], equals(''));
    });

    testWidgets('Deleting the only block in an editor automatically creates initial block', (tester) async {
      final now = DateTime.now();
      repository.seed([
        BlockEntity(
          id: 'sole_block',
          pageId: testPageId,
          type: BlockType.text,
          orderKey: 'a0',
          content: {'text': 'Will be deleted'},
          createdAt: now,
          updatedAt: now,
        ),
      ]);

      await tester.pumpWidget(buildEditorWidget(notifier));
      await tester.pumpAndSettle();

      expect(notifier.state.blocks.length, equals(1));

      // Delete the only block
      await notifier.deleteBlock('sole_block');
      await tester.pumpAndSettle();

      // BlockEditorNotifier watchBlocksForPage listener triggers createInitialBlock() when empty
      expect(notifier.state.blocks.isNotEmpty, isTrue);
      expect(notifier.state.blocks.first.type, equals(BlockType.text));
    });
  });

  group('Adversarial Test Suite 5: Slash Menu Rapid Cycles & Overlay Dismissal', () {
    testWidgets('Rapid slash menu open and query filtering', (tester) async {
      final now = DateTime.now();
      repository.seed([
        BlockEntity(
          id: 'slash_stress_block',
          pageId: testPageId,
          type: BlockType.text,
          orderKey: 'a0',
          content: {'text': ''},
          createdAt: now,
          updatedAt: now,
        ),
      ]);

      await tester.pumpWidget(buildEditorWidget(notifier));
      await tester.pumpAndSettle();

      final textField = find.byType(TextField);

      // Rapidly type /h, /code, /math
      await tester.enterText(textField, '/h');
      await tester.pumpAndSettle();
      expect(find.byType(SlashCommandMenu), findsOneWidget);
      expect(find.text('Heading 1'), findsOneWidget);

      await tester.enterText(textField, '/math');
      await tester.pumpAndSettle();
      expect(find.text('Math Formula'), findsOneWidget);

      // Non-matching query
      await tester.enterText(textField, '/nonexistentquery');
      await tester.pumpAndSettle();
      expect(find.text('No matching block types'), findsOneWidget);

      // Select an item
      await tester.enterText(textField, '/code');
      await tester.pumpAndSettle();
      expect(find.text('Code Block'), findsOneWidget);

      await tester.tap(find.text('Code Block'));
      await tester.pumpAndSettle();

      // Slash menu dismissed, block converted to code
      expect(find.byType(SlashCommandMenu), findsNothing);
      expect(notifier.state.blocks.first.type, equals(BlockType.code));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Empirical Probe: Backspacing "/" leaves slash menu floating on screen', (tester) async {
      final now = DateTime.now();
      repository.seed([
        BlockEntity(
          id: 'slash_backspace_block',
          pageId: testPageId,
          type: BlockType.text,
          orderKey: 'a0',
          content: {'text': ''},
          createdAt: now,
          updatedAt: now,
        ),
      ]);

      await tester.pumpWidget(buildEditorWidget(notifier));
      await tester.pumpAndSettle();

      final textField = find.byType(TextField);

      // User types / to trigger slash menu
      await tester.enterText(textField, '/');
      await tester.pumpAndSettle();
      expect(find.byType(SlashCommandMenu), findsOneWidget);

      // User backspaces to erase "/"
      await tester.enterText(textField, '');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      // TextBlockRenderer calls onSlashDismissed when !val.startsWith('/')
      expect(find.byType(SlashCommandMenu), findsNothing, reason: 'SlashCommandMenu is dismissed when "/" is backspaced');
    });

    testWidgets('Toggle child insertion preserves parent container scoping', (tester) async {
      final now = DateTime.now();
      final toggleBlock = BlockEntity(
        id: 'toggle_container',
        pageId: testPageId,
        type: BlockType.toggle,
        orderKey: 'a0',
        content: {'title': 'My Toggle', 'isOpen': true},
        createdAt: now,
        updatedAt: now,
      );
      final childBlock = BlockEntity(
        id: 'toggle_child_1',
        pageId: testPageId,
        parentBlockId: 'toggle_container',
        type: BlockType.text,
        orderKey: 'a0:a0',
        content: {'text': 'First child'},
        createdAt: now,
        updatedAt: now,
      );

      repository.seed([toggleBlock, childBlock]);
      await tester.pumpWidget(buildEditorWidget(notifier));
      await tester.pumpAndSettle();

      // Insert below child_1 without specifying parentBlockId
      await notifier.insertBlockAfter(afterBlockId: 'toggle_child_1');
      await tester.pumpAndSettle();

      final children = notifier.state.getChildrenOf('toggle_container');
      expect(children.length, equals(2));
      expect(children[1].parentBlockId, equals('toggle_container'));
      expect(children[1].orderKey.compareTo(childBlock.orderKey), greaterThan(0));
    });

    testWidgets('Notifier disposal during debounce window flushes dirty blocks to repository', (tester) async {
      final now = DateTime.now();
      final localRepo = AdversarialFakeBlockRepository();
      final localNotifier = BlockEditorNotifier(
        repository: localRepo,
        pageId: 'local_page',
      );
      final textBlock = BlockEntity(
        id: 'flush_on_dispose_block',
        pageId: 'local_page',
        type: BlockType.text,
        orderKey: 'a0',
        content: {'text': 'Initial text'},
        createdAt: now,
        updatedAt: now,
      );

      localRepo.seed([textBlock]);
      await tester.pumpWidget(buildEditorWidget(localNotifier));
      await tester.pumpAndSettle();

      // Mutate content within debounce window
      localNotifier.updateBlockContent(
        blockId: 'flush_on_dispose_block',
        newContent: {'text': 'Rapid edit before unmount'},
      );

      // Verify not yet flushed to repository (debounce active)
      expect(localRepo.updateCount, equals(0));

      // Dispose immediately before 300ms expires
      localNotifier.dispose();

      // Verify disposal flushed dirty blocks
      expect(localRepo.updateCount, equals(1));
      final savedBlock = localRepo._blocks.firstWhere((b) => b.id == 'flush_on_dispose_block');
      expect(savedBlock.content['text'], equals('Rapid edit before unmount'));
      localRepo.dispose();
    });
  });
}
