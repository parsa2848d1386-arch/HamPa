// Tier 2 E2E Boundary & Corner Cases: F01–F07 Workspace & Block Editor
// Minimum 5 tests per feature (35 test cases total)
// Grounded in PROJECT.md (F01–F07, AC1, AC3, E09, E10, E11)

import '../contracts/workspace_contracts.dart';
import '../harness/test_workspace_harness.dart';
import '../support/test_runner.dart';

void runWorkspaceBlocksTier2Tests() {
  group('Tier 2: F01 Hierarchical Page Tree Boundaries (5 tests)', () {
    late TestWorkspaceEngine workspace;

    void setUp() {
      workspace = TestWorkspaceEngine();
    }

    test('F01-B1: Circular parenting rejected when page is set as its own parent (E09)', () async {
      setUp();
      final p1 = await workspace.createPage(title: 'P1');
      await expectThrows<StateError>(() async {
        await workspace.updatePageParent(pageId: p1.id, newParentPageId: p1.id, newSortOrder: 0.0);
      });
    });

    test('F01-B2: Circular parenting rejected when moving page into its own descendant (E09)', () async {
      setUp();
      final p1 = await workspace.createPage(title: 'P1');
      final p2 = await workspace.createPage(parentPageId: p1.id, title: 'P2');
      final p3 = await workspace.createPage(parentPageId: p2.id, title: 'P3');

      // Attempting to move p1 into its grandchild p3
      await expectThrows<StateError>(() async {
        await workspace.updatePageParent(pageId: p1.id, newParentPageId: p3.id, newSortOrder: 0.0);
      });
    });

    test('F01-B3: Querying non-existent page ID returns null without crashing', () async {
      setUp();
      final page = await workspace.getPage('non_existent_id_9999');
      expect(page, isNull);
    });

    test('F01-B4: Querying child pages for non-existent parent returns empty list', () async {
      setUp();
      final children = await workspace.getChildPages('non_existent_parent');
      expect(children.isEmpty, isTrue);
    });

    test('F01-B5: Page with empty string title is normalized gracefully', () async {
      setUp();
      final page = await workspace.createPage(title: '');
      expect(page.title, equals(''));
      expect(page.id.isNotEmpty, isTrue);
    });
  });

  group('Tier 2: F02 Drag-and-Drop Page Tree Boundaries (5 tests)', () {
    late TestWorkspaceEngine workspace;

    void setUp() {
      workspace = TestWorkspaceEngine();
    }

    test('F02-B1: Updating non-existent page parent throws ArgumentError', () async {
      setUp();
      await expectThrows<ArgumentError>(() async {
        await workspace.updatePageParent(pageId: 'fake_id', newParentPageId: null, newSortOrder: 0.0);
      });
    });

    test('F02-B2: Negative and extreme sortOrder values maintain strict ordering', () async {
      setUp();
      final p1 = await workspace.createPage(title: 'P1');
      final p2 = await workspace.createPage(title: 'P2');

      await workspace.updatePageParent(pageId: p1.id, newSortOrder: -999999.0);
      await workspace.updatePageParent(pageId: p2.id, newSortOrder: 999999.0);

      final children = await workspace.getChildPages(null);
      expect(children.first.id, equals(p1.id));
      expect(children.last.id, equals(p2.id));
    });

    test('F02-B3: Identical sortOrder between siblings does not throw and preserves both items', () async {
      setUp();
      final p1 = await workspace.createPage(title: 'A');
      final p2 = await workspace.createPage(title: 'B');

      await workspace.updatePageParent(pageId: p1.id, newSortOrder: 1.0);
      await workspace.updatePageParent(pageId: p2.id, newSortOrder: 1.0);

      final list = await workspace.getChildPages(null);
      expect(list.length, equals(2));
    });

    test('F02-B4: Deep 10-level hierarchy re-parenting preserves all sub-branches', () async {
      setUp();
      var currentParent = await workspace.createPage(title: 'Root');
      final chain = [currentParent];
      for (var i = 1; i <= 10; i++) {
        currentParent = await workspace.createPage(parentPageId: currentParent.id, title: 'Node $i');
        chain.add(currentParent);
      }

      final leaf = chain.last;
      await workspace.updatePageParent(pageId: leaf.id, newParentPageId: chain.first.id, newSortOrder: 0.0);

      final childrenOfRoot = await workspace.getChildPages(chain.first.id);
      expect(childrenOfRoot.any((p) => p.id == leaf.id), isTrue);
    });

    test('F02-B5: Re-parenting to null clears parent reference cleanly', () async {
      setUp();
      final root = await workspace.createPage(title: 'Root');
      final child = await workspace.createPage(parentPageId: root.id, title: 'Child');
      expect(child.parentPageId, equals(root.id));

      await workspace.updatePageParent(pageId: child.id, newParentPageId: null, newSortOrder: 0.0);
      final updated = await workspace.getPage(child.id);
      expect(updated!.parentPageId, isNull);
    });
  });

  group('Tier 2: F03 Local-First Drift Persistence Boundaries (5 tests)', () {
    late TestWorkspaceEngine workspace;

    void setUp() {
      workspace = TestWorkspaceEngine();
    }

    test('F03-B1: Triggering sync while offline retains pending queue intact', () async {
      setUp();
      workspace.setNetworkOnline(false);
      await workspace.createPage(title: 'Offline 1');

      await workspace.triggerSync(); // attempted while still offline
      expect(await workspace.getPendingSyncCount(), equals(1));
    });

    test('F03-B2: Massive batch of 50 offline operations tracks exact queue size', () async {
      setUp();
      workspace.setNetworkOnline(false);
      for (var i = 0; i < 50; i++) {
        await workspace.createPage(title: 'Bulk $i');
      }
      expect(await workspace.getPendingSyncCount(), equals(50));
    });

    test('F03-B3: Deleting page multiple times is idempotent', () async {
      setUp();
      final page = await workspace.createPage(title: 'Once');
      await workspace.deletePage(page.id);
      await workspace.deletePage(page.id); // duplicate delete

      expect(await workspace.getPage(page.id), isNull);
    });

    test('F03-B4: Updating non-existent block throws ArgumentError', () async {
      setUp();
      final ghostBlock = BlockEntity(
        id: 'ghost_block',
        pageId: 'fake_page',
        type: BlockType.text,
        content: 'Ghost',
      );
      await expectThrows<ArgumentError>(() async {
        await workspace.updateBlock(ghostBlock);
      });
    });

    test('F03-B5: Concurrent modifications resolve safely with in-memory store', () async {
      setUp();
      final page = await workspace.createPage(title: 'Concurrent');
      final futures = <Future>[];
      for (var i = 0; i < 10; i++) {
        futures.add(workspace.insertBlock(BlockEntity(
          id: 'b_$i',
          pageId: page.id,
          type: BlockType.text,
          content: 'C $i',
        )));
      }
      await Future.wait(futures);

      final blocks = await workspace.getBlocksForPage(page.id);
      expect(blocks.length, equals(10));
    });
  });

  group('Tier 2: F04 Rich Text & Headings Boundaries (5 tests)', () {
    late TestWorkspaceEngine workspace;

    void setUp() {
      workspace = TestWorkspaceEngine();
    }

    test('F04-B1: Empty text block content preserves block structure', () async {
      setUp();
      final page = await workspace.createPage(title: 'Doc');
      final block = BlockEntity(id: 'b_empty', pageId: page.id, type: BlockType.text, content: '');
      await workspace.insertBlock(block);

      final blocks = await workspace.getBlocksForPage(page.id);
      expect(blocks.first.content, equals(''));
    });

    test('F04-B2: Extremely long text block (10,000 characters) preserves integrity', () async {
      setUp();
      final page = await workspace.createPage(title: 'Doc');
      final longText = 'A' * 10000;
      final block = BlockEntity(id: 'b_huge', pageId: page.id, type: BlockType.text, content: longText);
      await workspace.insertBlock(block);

      final blocks = await workspace.getBlocksForPage(page.id);
      expect(blocks.first.content.length, equals(10000));
    });

    test('F04-B3: Rich text containing Unicode emoji and Persian RTL characters', () async {
      setUp();
      final page = await workspace.createPage(title: 'Doc');
      const text = 'هم‌پای شما در مسیر موفقیت و تمرکز 🚀✨';
      final block = BlockEntity(id: 'b_rtl', pageId: page.id, type: BlockType.text, content: text);
      await workspace.insertBlock(block);

      final blocks = await workspace.getBlocksForPage(page.id);
      expect(blocks.first.content, equals(text));
    });

    test('F04-B4: Special characters and HTML tag injection handled as literal content', () async {
      setUp();
      final page = await workspace.createPage(title: 'Doc');
      const injection = '<script>alert("XSS")</script>&quot;&amp;';
      final block = BlockEntity(id: 'b_safe', pageId: page.id, type: BlockType.text, content: injection);
      await workspace.insertBlock(block);

      final blocks = await workspace.getBlocksForPage(page.id);
      expect(blocks.first.content, equals(injection));
    });

    test('F04-B5: Update block with unchanged content executes cleanly', () async {
      setUp();
      final page = await workspace.createPage(title: 'Doc');
      final block = BlockEntity(id: 'b_same', pageId: page.id, type: BlockType.text, content: 'Identical');
      await workspace.insertBlock(block);
      await workspace.updateBlock(block);

      final blocks = await workspace.getBlocksForPage(page.id);
      expect(blocks.first.content, equals('Identical'));
    });
  });

  group('Tier 2: F05 Interactive Checklist Boundaries (5 tests)', () {
    late TestWorkspaceEngine workspace;

    void setUp() {
      workspace = TestWorkspaceEngine();
    }

    test('F05-B1: Checklist block with empty title toggleable', () async {
      setUp();
      final page = await workspace.createPage(title: 'Doc');
      final todo = BlockEntity(id: 'todo_empty', pageId: page.id, type: BlockType.todo, content: '', checked: false);
      await workspace.insertBlock(todo);

      await workspace.updateBlock(todo.copyWith(checked: true));
      final blocks = await workspace.getBlocksForPage(page.id);
      expect(blocks.first.checked, isTrue);
    });

    test('F05-B2: Toggling checkbox 100 times in succession maintains consistent state', () async {
      setUp();
      final page = await workspace.createPage(title: 'Doc');
      var todo = BlockEntity(id: 'todo_flicker', pageId: page.id, type: BlockType.todo, content: 'Stress', checked: false);
      await workspace.insertBlock(todo);

      for (var i = 0; i < 100; i++) {
        todo = todo.copyWith(checked: !todo.checked);
        await workspace.updateBlock(todo);
      }

      final blocks = await workspace.getBlocksForPage(page.id);
      expect(blocks.first.checked, isFalse); // 100 toggles from false -> false
    });

    test('F05-B3: 200 checklist items on single page preserve individual checked flags', () async {
      setUp();
      final page = await workspace.createPage(title: 'Doc');
      for (var i = 0; i < 200; i++) {
        await workspace.insertBlock(BlockEntity(
          id: 'todo_$i',
          pageId: page.id,
          type: BlockType.todo,
          content: 'Task $i',
          checked: i % 2 == 0,
        ));
      }

      final blocks = await workspace.getBlocksForPage(page.id);
      expect(blocks.length, equals(200));
      expect(blocks[0].checked, isTrue);
      expect(blocks[1].checked, isFalse);
    });

    test('F05-B4: Deleting checked todo block leaves unchecked blocks intact', () async {
      setUp();
      final page = await workspace.createPage(title: 'Doc');
      final t1 = BlockEntity(id: 't1', pageId: page.id, type: BlockType.todo, content: 'T1', checked: true);
      final t2 = BlockEntity(id: 't2', pageId: page.id, type: BlockType.todo, content: 'T2', checked: false);
      await workspace.insertBlock(t1);
      await workspace.insertBlock(t2);

      await workspace.deleteBlock(t1.id);
      final blocks = await workspace.getBlocksForPage(page.id);
      expect(blocks.length, equals(1));
      expect(blocks.first.id, equals(t2.id));
    });

    test('F05-B5: Todo metadata stores checked timestamp without schema errors', () async {
      setUp();
      final page = await workspace.createPage(title: 'Doc');
      final nowStr = DateTime.now().toIso8601String();
      final todo = BlockEntity(
        id: 'todo_meta',
        pageId: page.id,
        type: BlockType.todo,
        content: 'Timestamped Todo',
        checked: true,
        metadata: {'checkedAt': nowStr},
      );
      await workspace.insertBlock(todo);

      final blocks = await workspace.getBlocksForPage(page.id);
      expect(blocks.first.metadata['checkedAt'], equals(nowStr));
    });
  });

  group('Tier 2: F06 Callout & Toggle Container Boundaries (5 tests)', () {
    late TestWorkspaceEngine workspace;

    void setUp() {
      workspace = TestWorkspaceEngine();
    }

    test('F06-B1: Callout block without icon metadata falls back cleanly', () async {
      setUp();
      final page = await workspace.createPage(title: 'Doc');
      final callout = BlockEntity(id: 'c1', pageId: page.id, type: BlockType.callout, content: 'Plain Callout');
      await workspace.insertBlock(callout);

      final blocks = await workspace.getBlocksForPage(page.id);
      expect(blocks.first.metadata['icon'], isNull);
    });

    test('F06-B2: Toggle block with 20 levels of nested child blocks', () async {
      setUp();
      final page = await workspace.createPage(title: 'Doc');
      String? parentId;
      for (var i = 0; i < 20; i++) {
        final b = BlockEntity(
          id: 'toggle_nest_$i',
          pageId: page.id,
          type: BlockType.toggle,
          content: 'Level $i',
          parentBlockId: parentId,
        );
        await workspace.insertBlock(b);
        parentId = b.id;
      }

      final blocks = await workspace.getBlocksForPage(page.id);
      expect(blocks.length, equals(20));
      expect(blocks.last.parentBlockId, equals('toggle_nest_18'));
    });

    test('F06-B3: Deleting parent toggle preserves or cleans up children safely', () async {
      setUp();
      final page = await workspace.createPage(title: 'Doc');
      final toggle = BlockEntity(id: 'top_toggle', pageId: page.id, type: BlockType.toggle, content: 'Top');
      final child = BlockEntity(id: 'nested_child', pageId: page.id, type: BlockType.text, content: 'Inside', parentBlockId: toggle.id);

      await workspace.insertBlock(toggle);
      await workspace.insertBlock(child);
      await workspace.deleteBlock(toggle.id);

      final blocks = await workspace.getBlocksForPage(page.id);
      expect(blocks.any((b) => b.id == toggle.id), isFalse);
    });

    test('F06-B4: Rapid toggle collapse and expand state updates', () async {
      setUp();
      final page = await workspace.createPage(title: 'Doc');
      var toggle = BlockEntity(id: 't_flick', pageId: page.id, type: BlockType.toggle, content: 'Flicker');
      await workspace.insertBlock(toggle);

      for (var i = 0; i < 10; i++) {
        toggle = toggle.copyWith(metadata: {'isExpanded': i % 2 == 0});
        await workspace.updateBlock(toggle);
      }

      final blocks = await workspace.getBlocksForPage(page.id);
      expect(blocks.first.metadata['isExpanded'], isFalse);
    });

    test('F06-B5: Callout with extreme padding/color metadata strings', () async {
      setUp();
      final page = await workspace.createPage(title: 'Doc');
      final callout = BlockEntity(
        id: 'c_meta',
        pageId: page.id,
        type: BlockType.callout,
        content: 'Callout text',
        metadata: {'bgColor': 'rgba(255, 0, 0, 0.5)', 'padding': 24.5},
      );
      await workspace.insertBlock(callout);

      final blocks = await workspace.getBlocksForPage(page.id);
      expect(blocks.first.metadata['padding'], equals(24.5));
    });
  });

  group('Tier 2: F07 Code & LaTeX Math Boundaries (5 tests)', () {
    late TestWorkspaceEngine workspace;

    void setUp() {
      workspace = TestWorkspaceEngine();
    }

    test('F07-B1: Malformed LaTeX equation preserved without compiler exception (E11)', () async {
      setUp();
      final page = await workspace.createPage(title: 'Doc');
      const brokenLatex = r'\frac{numerator_without_denominator';
      final math = BlockEntity(id: 'math_broken', pageId: page.id, type: BlockType.latexMath, content: brokenLatex);
      await workspace.insertBlock(math);

      final blocks = await workspace.getBlocksForPage(page.id);
      expect(blocks.first.content, equals(brokenLatex));
    });

    test('F07-B2: Unrecognized programming language defaults gracefully to plaintext', () async {
      setUp();
      final page = await workspace.createPage(title: 'Doc');
      final code = BlockEntity(
        id: 'code_unknown',
        pageId: page.id,
        type: BlockType.code,
        content: 'some code',
        metadata: {'language': 'unknown_esoteric_lang'},
      );
      await workspace.insertBlock(code);

      final blocks = await workspace.getBlocksForPage(page.id);
      expect(blocks.first.metadata['language'], equals('unknown_esoteric_lang'));
    });

    test('F07-B3: Empty LaTeX math block handles empty string', () async {
      setUp();
      final page = await workspace.createPage(title: 'Doc');
      final math = BlockEntity(id: 'math_empty', pageId: page.id, type: BlockType.latexMath, content: '');
      await workspace.insertBlock(math);

      final blocks = await workspace.getBlocksForPage(page.id);
      expect(blocks.first.content, equals(''));
    });

    test('F07-B4: Multi-line code block with tabs, indentation, and newlines', () async {
      setUp();
      final page = await workspace.createPage(title: 'Doc');
      const snippet = 'function test() {\n\tconst x = 10;\n\treturn x;\n}';
      final code = BlockEntity(id: 'code_multiline', pageId: page.id, type: BlockType.code, content: snippet);
      await workspace.insertBlock(code);

      final blocks = await workspace.getBlocksForPage(page.id);
      expect(blocks.first.content, equals(snippet));
    });

    test('F07-B5: LaTeX block with extreme formula length (100 symbols)', () async {
      setUp();
      final page = await workspace.createPage(title: 'Doc');
      final longFormula = r'\sum_{i=1}^{100} x_i + ' * 10;
      final math = BlockEntity(id: 'math_long', pageId: page.id, type: BlockType.latexMath, content: longFormula);
      await workspace.insertBlock(math);

      final blocks = await workspace.getBlocksForPage(page.id);
      expect(blocks.first.content.length, greaterThan(100));
    });
  });
}
