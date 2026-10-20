// Tier 1 E2E Feature Coverage: F01–F07 Workspace & Block Editor
// Minimum 5 tests per feature (35 test cases total)
// Grounded in PROJECT.md (F01–F07, AC1, AC3)

import '../contracts/workspace_contracts.dart';
import '../harness/test_workspace_harness.dart';
import '../support/test_runner.dart';

void runWorkspaceBlocksTier1Tests() {
  group('Tier 1: F01 Hierarchical Page Tree (5 tests)', () {
    late TestWorkspaceEngine workspace;

    void setUp() {
      workspace = TestWorkspaceEngine();
    }

    test('F01-1: Create root page with title and icon', () async {
      setUp();
      final page = await workspace.createPage(
        title: 'Study Workspace',
        icon: '📚',
      );
      expect(page.title, equals('Study Workspace'));
      expect(page.icon, equals('📚'));
      expect(page.parentPageId, isNull);
      expect(page.isDatabaseRow, isFalse);
    });

    test('F01-2: Create nested sub-page with parent reference', () async {
      setUp();
      final root = await workspace.createPage(title: 'University');
      final child = await workspace.createPage(
        parentPageId: root.id,
        title: 'Calculus I',
        icon: '📐',
      );
      expect(child.parentPageId, equals(root.id));
      expect(child.title, equals('Calculus I'));
    });

    test('F01-3: Deep nesting across 5 hierarchical levels', () async {
      setUp();
      final p1 = await workspace.createPage(title: 'Level 1');
      final p2 = await workspace.createPage(parentPageId: p1.id, title: 'Level 2');
      final p3 = await workspace.createPage(parentPageId: p2.id, title: 'Level 3');
      final p4 = await workspace.createPage(parentPageId: p3.id, title: 'Level 4');
      final p5 = await workspace.createPage(parentPageId: p4.id, title: 'Level 5');

      expect(p5.parentPageId, equals(p4.id));
      final childrenOfP4 = await workspace.getChildPages(p4.id);
      expect(childrenOfP4.length, equals(1));
      expect(childrenOfP4.first.id, equals(p5.id));
    });

    test('F01-4: Query child pages for a specific parent', () async {
      setUp();
      final root = await workspace.createPage(title: 'Semester 1');
      await workspace.createPage(parentPageId: root.id, title: 'Math');
      await workspace.createPage(parentPageId: root.id, title: 'Physics');
      await workspace.createPage(parentPageId: root.id, title: 'Chemistry');

      final children = await workspace.getChildPages(root.id);
      expect(children.length, equals(3));
      expect(children.map((p) => p.title).toList(), equals(['Math', 'Physics', 'Chemistry']));
    });

    test('F01-5: Page tree watch stream emits updated list on new page creation', () async {
      setUp();
      var emissionCount = 0;
      final sub = workspace.watchPageTree().listen((pages) {
        emissionCount++;
      });

      await workspace.createPage(title: 'Stream Test Page');
      expect(emissionCount, greaterThan(0));
      await sub.cancel();
    });
  });

  group('Tier 1: F02 Drag-and-Drop Page Tree (5 tests)', () {
    late TestWorkspaceEngine workspace;

    void setUp() {
      workspace = TestWorkspaceEngine();
    }

    test('F02-1: Reorder sibling pages by updating sortOrder', () async {
      setUp();
      final p1 = await workspace.createPage(title: 'Page A');
      final p2 = await workspace.createPage(title: 'Page B');

      // Swap positions: move p2 before p1
      await workspace.updatePageParent(pageId: p2.id, newSortOrder: -1.0);
      final tree = await workspace.getChildPages(null);
      expect(tree.first.id, equals(p2.id));
      expect(tree.last.id, equals(p1.id));
    });

    test('F02-2: Re-parent page from one parent to another', () async {
      setUp();
      final parentA = await workspace.createPage(title: 'Parent A');
      final parentB = await workspace.createPage(title: 'Parent B');
      final child = await workspace.createPage(parentPageId: parentA.id, title: 'Target Child');

      await workspace.updatePageParent(
        pageId: child.id,
        newParentPageId: parentB.id,
        newSortOrder: 0.0,
      );

      final childrenA = await workspace.getChildPages(parentA.id);
      final childrenB = await workspace.getChildPages(parentB.id);
      expect(childrenA.isEmpty, isTrue);
      expect(childrenB.length, equals(1));
      expect(childrenB.first.id, equals(child.id));
    });

    test('F02-3: Un-parent page back to root level (null parent)', () async {
      setUp();
      final parent = await workspace.createPage(title: 'Parent');
      final child = await workspace.createPage(parentPageId: parent.id, title: 'Child');

      await workspace.updatePageParent(
        pageId: child.id,
        newParentPageId: null,
        newSortOrder: 10.0,
      );

      final updatedChild = await workspace.getPage(child.id);
      expect(updatedChild!.parentPageId, isNull);
    });

    test('F02-4: Reordering a parent retains all its nested descendants intact', () async {
      setUp();
      final parent = await workspace.createPage(title: 'Parent');
      final child = await workspace.createPage(parentPageId: parent.id, title: 'Child');
      final grandchild = await workspace.createPage(parentPageId: child.id, title: 'Grandchild');

      await workspace.updatePageParent(pageId: parent.id, newSortOrder: 5.0);

      final descendants = await workspace.getChildPages(child.id);
      expect(descendants.length, equals(1));
      expect(descendants.first.id, equals(grandchild.id));
    });

    test('F02-5: getChildPages returns pages sorted strictly by sortOrder', () async {
      setUp();
      final root = await workspace.createPage(title: 'Root');
      final c1 = await workspace.createPage(parentPageId: root.id, title: 'C1');
      final c2 = await workspace.createPage(parentPageId: root.id, title: 'C2');

      await workspace.updatePageParent(pageId: c1.id, newParentPageId: root.id, newSortOrder: 100.0);
      await workspace.updatePageParent(pageId: c2.id, newParentPageId: root.id, newSortOrder: 10.0);

      final children = await workspace.getChildPages(root.id);
      expect(children.first.id, equals(c2.id));
      expect(children.last.id, equals(c1.id));
    });
  });

  group('Tier 1: F03 Local-First Drift Persistence & Sync (5 tests)', () {
    late TestWorkspaceEngine workspace;

    void setUp() {
      workspace = TestWorkspaceEngine();
    }

    test('F03-1: Offline page creation saves directly to local store', () async {
      setUp();
      workspace.setNetworkOnline(false);
      expect(workspace.isOnline, isFalse);

      final page = await workspace.createPage(title: 'Offline Notes');
      final retrieved = await workspace.getPage(page.id);
      expect(retrieved, isNotNull);
      expect(retrieved!.title, equals('Offline Notes'));
    });

    test('F03-2: Pending sync queue tracks offline modifications', () async {
      setUp();
      workspace.setNetworkOnline(false);
      await workspace.createPage(title: 'Note 1');
      await workspace.createPage(title: 'Note 2');

      final pendingCount = await workspace.getPendingSyncCount();
      expect(pendingCount, equals(2));
    });

    test('F03-3: Online reconnection flushes pending sync queue', () async {
      setUp();
      workspace.setNetworkOnline(false);
      await workspace.createPage(title: 'Sync Note');
      expect(await workspace.getPendingSyncCount(), equals(1));

      workspace.setNetworkOnline(true);
      await workspace.triggerSync();
      expect(await workspace.getPendingSyncCount(), equals(0));
    });

    test('F03-4: Offline block mutations persist in local state', () async {
      setUp();
      final page = await workspace.createPage(title: 'Doc');
      workspace.setNetworkOnline(false);

      final block = BlockEntity(
        id: 'block_offline_1',
        pageId: page.id,
        type: BlockType.text,
        content: 'Offline typed text',
      );
      await workspace.insertBlock(block);

      final blocks = await workspace.getBlocksForPage(page.id);
      expect(blocks.length, equals(1));
      expect(blocks.first.content, equals('Offline typed text'));
    });

    test('F03-5: Cascade deletion removes sub-pages and blocks', () async {
      setUp();
      final p1 = await workspace.createPage(title: 'P1');
      final p2 = await workspace.createPage(parentPageId: p1.id, title: 'P2');
      await workspace.insertBlock(BlockEntity(
        id: 'b1',
        pageId: p2.id,
        type: BlockType.text,
        content: 'Sub content',
      ));

      await workspace.deletePage(p1.id);

      expect(await workspace.getPage(p1.id), isNull);
      expect(await workspace.getPage(p2.id), isNull);
      expect((await workspace.getBlocksForPage(p2.id)).isEmpty, isTrue);
    });
  });

  group('Tier 1: F04 Rich Text & Headings Blocks (5 tests)', () {
    late TestWorkspaceEngine workspace;

    void setUp() {
      workspace = TestWorkspaceEngine();
    }

    test('F04-1: Insert standard paragraph text block', () async {
      setUp();
      final page = await workspace.createPage(title: 'Doc');
      final block = BlockEntity(
        id: 'b_text',
        pageId: page.id,
        type: BlockType.text,
        content: 'This is a standard paragraph with rich notes.',
      );
      await workspace.insertBlock(block);

      final blocks = await workspace.getBlocksForPage(page.id);
      expect(blocks.first.type, equals(BlockType.text));
      expect(blocks.first.content, contains('standard paragraph'));
    });

    test('F04-2: Insert Heading 1 (H1) block', () async {
      setUp();
      final page = await workspace.createPage(title: 'Doc');
      final block = BlockEntity(
        id: 'b_h1',
        pageId: page.id,
        type: BlockType.heading1,
        content: 'Chapter 1: Real Analysis',
      );
      await workspace.insertBlock(block);

      final blocks = await workspace.getBlocksForPage(page.id);
      expect(blocks.first.type, equals(BlockType.heading1));
      expect(blocks.first.content, equals('Chapter 1: Real Analysis'));
    });

    test('F04-3: Insert Heading 2 and Heading 3 blocks with proper hierarchy', () async {
      setUp();
      final page = await workspace.createPage(title: 'Doc');
      await workspace.insertBlock(BlockEntity(
        id: 'b_h2',
        pageId: page.id,
        type: BlockType.heading2,
        content: 'Section 1.1 Limits',
        sortOrder: 1.0,
      ));
      await workspace.insertBlock(BlockEntity(
        id: 'b_h3',
        pageId: page.id,
        type: BlockType.heading3,
        content: 'Definition of Epsilon-Delta',
        sortOrder: 2.0,
      ));

      final blocks = await workspace.getBlocksForPage(page.id);
      expect(blocks.length, equals(2));
      expect(blocks[0].type, equals(BlockType.heading2));
      expect(blocks[1].type, equals(BlockType.heading3));
    });

    test('F04-4: Update existing text block content', () async {
      setUp();
      final page = await workspace.createPage(title: 'Doc');
      final block = BlockEntity(
        id: 'b_edit',
        pageId: page.id,
        type: BlockType.text,
        content: 'Draft content',
      );
      await workspace.insertBlock(block);

      final updated = block.copyWith(content: 'Final reviewed content');
      await workspace.updateBlock(updated);

      final blocks = await workspace.getBlocksForPage(page.id);
      expect(blocks.first.content, equals('Final reviewed content'));
    });

    test('F04-5: Rich text metadata attributes preserve formatting styles', () async {
      setUp();
      final page = await workspace.createPage(title: 'Doc');
      final block = BlockEntity(
        id: 'b_rich',
        pageId: page.id,
        type: BlockType.text,
        content: 'Bold and italicized statement',
        metadata: {'bold': true, 'italic': true, 'color': '#FF5722'},
      );
      await workspace.insertBlock(block);

      final blocks = await workspace.getBlocksForPage(page.id);
      expect(blocks.first.metadata['bold'], equals(true));
      expect(blocks.first.metadata['color'], equals('#FF5722'));
    });
  });

  group('Tier 1: F05 Interactive Checklist Blocks (5 tests)', () {
    late TestWorkspaceEngine workspace;

    void setUp() {
      workspace = TestWorkspaceEngine();
    }

    test('F05-1: Create unchecked todo checklist item', () async {
      setUp();
      final page = await workspace.createPage(title: 'Checklist');
      final todo = BlockEntity(
        id: 'todo_1',
        pageId: page.id,
        type: BlockType.todo,
        content: 'Complete homework exercise 3',
        checked: false,
      );
      await workspace.insertBlock(todo);

      final blocks = await workspace.getBlocksForPage(page.id);
      expect(blocks.first.type, equals(BlockType.todo));
      expect(blocks.first.checked, isFalse);
    });

    test('F05-2: Toggle todo item to checked state', () async {
      setUp();
      final page = await workspace.createPage(title: 'Checklist');
      final todo = BlockEntity(
        id: 'todo_toggle',
        pageId: page.id,
        type: BlockType.todo,
        content: 'Read Chapter 4',
        checked: false,
      );
      await workspace.insertBlock(todo);

      await workspace.updateBlock(todo.copyWith(checked: true));
      final blocks = await workspace.getBlocksForPage(page.id);
      expect(blocks.first.checked, isTrue);
    });

    test('F05-3: Toggle todo item back from checked to unchecked', () async {
      setUp();
      final page = await workspace.createPage(title: 'Checklist');
      final todo = BlockEntity(
        id: 'todo_revert',
        pageId: page.id,
        type: BlockType.todo,
        content: 'Review flashcards',
        checked: true,
      );
      await workspace.insertBlock(todo);

      await workspace.updateBlock(todo.copyWith(checked: false));
      final blocks = await workspace.getBlocksForPage(page.id);
      expect(blocks.first.checked, isFalse);
    });

    test('F05-4: Multiple todo checklist items maintain independent checked states', () async {
      setUp();
      final page = await workspace.createPage(title: 'Checklist');
      final t1 = BlockEntity(id: 't1', pageId: page.id, type: BlockType.todo, content: 'T1', checked: true, sortOrder: 1.0);
      final t2 = BlockEntity(id: 't2', pageId: page.id, type: BlockType.todo, content: 'T2', checked: false, sortOrder: 2.0);
      final t3 = BlockEntity(id: 't3', pageId: page.id, type: BlockType.todo, content: 'T3', checked: true, sortOrder: 3.0);

      await workspace.insertBlock(t1);
      await workspace.insertBlock(t2);
      await workspace.insertBlock(t3);

      final blocks = await workspace.getBlocksForPage(page.id);
      expect(blocks.map((b) => b.checked).toList(), equals([true, false, true]));
    });

    test('F05-5: Block watch stream fires event on checklist checkbox toggle', () async {
      setUp();
      final page = await workspace.createPage(title: 'Checklist');
      final todo = BlockEntity(id: 't_stream', pageId: page.id, type: BlockType.todo, content: 'Stream Todo', checked: false);
      await workspace.insertBlock(todo);

      var eventFired = false;
      final sub = workspace.watchBlocksForPage(page.id).listen((blocks) {
        if (blocks.any((b) => b.id == 't_stream' && b.checked)) {
          eventFired = true;
        }
      });

      await workspace.updateBlock(todo.copyWith(checked: true));
      expect(eventFired, isTrue);
      await sub.cancel();
    });
  });

  group('Tier 1: F06 Callout & Toggle Container Blocks (5 tests)', () {
    late TestWorkspaceEngine workspace;

    void setUp() {
      workspace = TestWorkspaceEngine();
    }

    test('F06-1: Create callout block with custom icon and tint', () async {
      setUp();
      final page = await workspace.createPage(title: 'Notes');
      final callout = BlockEntity(
        id: 'callout_1',
        pageId: page.id,
        type: BlockType.callout,
        content: 'Important Exam Date: June 15',
        metadata: {'icon': '⚠️', 'tintColor': '#FFF3E0'},
      );
      await workspace.insertBlock(callout);

      final blocks = await workspace.getBlocksForPage(page.id);
      expect(blocks.first.type, equals(BlockType.callout));
      expect(blocks.first.metadata['icon'], equals('⚠️'));
    });

    test('F06-2: Create collapsible toggle block in collapsed state', () async {
      setUp();
      final page = await workspace.createPage(title: 'Notes');
      final toggle = BlockEntity(
        id: 'toggle_1',
        pageId: page.id,
        type: BlockType.toggle,
        content: 'Click to expand solutions',
        metadata: {'isExpanded': false},
      );
      await workspace.insertBlock(toggle);

      final blocks = await workspace.getBlocksForPage(page.id);
      expect(blocks.first.type, equals(BlockType.toggle));
      expect(blocks.first.metadata['isExpanded'], isFalse);
    });

    test('F06-3: Attach child blocks to a toggle container block', () async {
      setUp();
      final page = await workspace.createPage(title: 'Notes');
      final toggle = BlockEntity(
        id: 'toggle_parent',
        pageId: page.id,
        type: BlockType.toggle,
        content: 'Proof of Theorem 2',
      );
      await workspace.insertBlock(toggle);

      final child = BlockEntity(
        id: 'child_text',
        pageId: page.id,
        type: BlockType.text,
        content: 'By induction on n...',
        parentBlockId: toggle.id,
      );
      await workspace.insertBlock(child);

      final blocks = await workspace.getBlocksForPage(page.id);
      final attachedChild = blocks.firstWhere((b) => b.id == 'child_text');
      expect(attachedChild.parentBlockId, equals(toggle.id));
    });

    test('F06-4: Expand and collapse toggle container block state', () async {
      setUp();
      final page = await workspace.createPage(title: 'Notes');
      final toggle = BlockEntity(
        id: 'toggle_exp',
        pageId: page.id,
        type: BlockType.toggle,
        content: 'Toggle Header',
        metadata: {'isExpanded': false},
      );
      await workspace.insertBlock(toggle);

      // Expand
      await workspace.updateBlock(toggle.copyWith(metadata: {'isExpanded': true}));
      var blocks = await workspace.getBlocksForPage(page.id);
      expect(blocks.first.metadata['isExpanded'], isTrue);

      // Collapse
      await workspace.updateBlock(toggle.copyWith(metadata: {'isExpanded': false}));
      blocks = await workspace.getBlocksForPage(page.id);
      expect(blocks.first.metadata['isExpanded'], isFalse);
    });

    test('F06-5: Deleting toggle block removes it from page', () async {
      setUp();
      final page = await workspace.createPage(title: 'Notes');
      final toggle = BlockEntity(id: 't_del', pageId: page.id, type: BlockType.toggle, content: 'Delete me');
      await workspace.insertBlock(toggle);

      await workspace.deleteBlock(toggle.id);
      final blocks = await workspace.getBlocksForPage(page.id);
      expect(blocks.isEmpty, isTrue);
    });
  });

  group('Tier 1: F07 Code Syntax Highlighting & LaTeX Math (5 tests)', () {
    late TestWorkspaceEngine workspace;

    void setUp() {
      workspace = TestWorkspaceEngine();
    }

    test('F07-1: Insert code block with specified programming language', () async {
      setUp();
      final page = await workspace.createPage(title: 'CS Notes');
      final code = BlockEntity(
        id: 'code_dart',
        pageId: page.id,
        type: BlockType.code,
        content: 'void main() { print("HamPA Focus"); }',
        metadata: {'language': 'dart'},
      );
      await workspace.insertBlock(code);

      final blocks = await workspace.getBlocksForPage(page.id);
      expect(blocks.first.type, equals(BlockType.code));
      expect(blocks.first.metadata['language'], equals('dart'));
    });

    test('F07-2: Insert inline LaTeX math equation block', () async {
      setUp();
      final page = await workspace.createPage(title: 'Physics');
      final math = BlockEntity(
        id: 'math_1',
        pageId: page.id,
        type: BlockType.latexMath,
        content: r'E = m c^2',
      );
      await workspace.insertBlock(math);

      final blocks = await workspace.getBlocksForPage(page.id);
      expect(blocks.first.type, equals(BlockType.latexMath));
      expect(blocks.first.content, equals(r'E = m c^2'));
    });

    test('F07-3: Insert complex multi-symbol LaTeX math formula', () async {
      setUp();
      final page = await workspace.createPage(title: 'Calculus');
      const formula = r'\int_{-\infty}^{\infty} e^{-x^2} dx = \sqrt{\pi}';
      final math = BlockEntity(
        id: 'math_complex',
        pageId: page.id,
        type: BlockType.latexMath,
        content: formula,
      );
      await workspace.insertBlock(math);

      final blocks = await workspace.getBlocksForPage(page.id);
      expect(blocks.first.content, equals(formula));
    });

    test('F07-4: Update code block snippet content', () async {
      setUp();
      final page = await workspace.createPage(title: 'CS');
      final code = BlockEntity(
        id: 'code_upd',
        pageId: page.id,
        type: BlockType.code,
        content: 'int x = 1;',
        metadata: {'language': 'java'},
      );
      await workspace.insertBlock(code);

      await workspace.updateBlock(code.copyWith(content: 'int x = 42; // updated'));
      final blocks = await workspace.getBlocksForPage(page.id);
      expect(blocks.first.content, contains('42'));
    });

    test('F07-5: Switch code block programming language metadata', () async {
      setUp();
      final page = await workspace.createPage(title: 'CS');
      final code = BlockEntity(
        id: 'code_lang',
        pageId: page.id,
        type: BlockType.code,
        content: 'print("Hello")',
        metadata: {'language': 'python'},
      );
      await workspace.insertBlock(code);

      await workspace.updateBlock(code.copyWith(metadata: {'language': 'ruby'}));
      final blocks = await workspace.getBlocksForPage(page.id);
      expect(blocks.first.metadata['language'], equals('ruby'));
    });
  });
}
