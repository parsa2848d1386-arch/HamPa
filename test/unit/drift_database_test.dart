import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' as drift;
import 'package:hampa/core/database/app_database.dart';
import 'package:hampa/features/workspace_editor/data/repositories/workspace_repository_impl.dart';
import 'package:hampa/features/workspace_editor/domain/models/block_entity.dart';
import 'package:hampa/features/workspace_editor/domain/models/block_type.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    // In-memory isolated database instance per test with foreign keys enforced
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('PagesDao & Hierarchical Page Tree', () {
    test('insertPage inserts and watchPageTree emits newly created root page', () async {
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

    test('updatePageTitle and updatePageIcon update page fields', () async {
      final now = DateTime.now();
      await db.pagesDao.insertPage(PagesCompanion.insert(
        id: 'p_edit',
        title: const drift.Value('Original Title'),
        createdAt: now,
        updatedAt: now,
      ));

      await db.pagesDao.updatePageTitle('p_edit', 'Updated Title');
      await db.pagesDao.updatePageIcon('p_edit', '🌟');

      final page = await db.pagesDao.getPageById('p_edit');
      expect(page?.title, equals('Updated Title'));
      expect(page?.icon, equals('🌟'));
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

    test('updatePageParent prevents cycle when node attempts to become its own parent', () async {
      final now = DateTime.now();
      await db.pagesDao.insertPage(PagesCompanion.insert(
        id: 'self_node',
        title: const drift.Value('Self Node'),
        createdAt: now,
        updatedAt: now,
      ));

      expect(
        () => db.pagesDao.updatePageParent(
          pageId: 'self_node',
          newParentPageId: 'self_node',
          newSortOrder: 1.0,
        ),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('A page cannot be its own parent'),
        )),
      );
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
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('Cannot move a page under its own descendant'),
        )),
      );
    });

    test('batchUpdateSortOrders updates multiple sibling sort orders', () async {
      final now = DateTime.now();
      await db.pagesDao.insertPage(PagesCompanion.insert(id: 'p1', title: const drift.Value('P1'), sortOrder: const drift.Value(1.0), createdAt: now, updatedAt: now));
      await db.pagesDao.insertPage(PagesCompanion.insert(id: 'p2', title: const drift.Value('P2'), sortOrder: const drift.Value(2.0), createdAt: now, updatedAt: now));

      await db.pagesDao.batchUpdateSortOrders({'p1': 20.0, 'p2': 10.0});

      final p1 = await db.pagesDao.getPageById('p1');
      final p2 = await db.pagesDao.getPageById('p2');
      expect(p1?.sortOrder, equals(20.0));
      expect(p2?.sortOrder, equals(10.0));
    });

    test('getBreadcrumbs traverses ancestor path from root to leaf', () async {
      final now = DateTime.now();
      await db.pagesDao.insertPage(PagesCompanion.insert(id: 'l1', title: const drift.Value('Level 1'), createdAt: now, updatedAt: now));
      await db.pagesDao.insertPage(PagesCompanion.insert(id: 'l2', parentPageId: const drift.Value('l1'), title: const drift.Value('Level 2'), createdAt: now, updatedAt: now));
      await db.pagesDao.insertPage(PagesCompanion.insert(id: 'l3', parentPageId: const drift.Value('l2'), title: const drift.Value('Level 3'), createdAt: now, updatedAt: now));

      final breadcrumbs = await db.pagesDao.getBreadcrumbs('l3');
      expect(breadcrumbs.length, equals(3));
      expect(breadcrumbs.map((b) => b.id).toList(), equals(['l1', 'l2', 'l3']));
    });

    test('archivePage soft deletes page and hides it from watchPageTree', () async {
      final now = DateTime.now();
      await db.pagesDao.insertPage(PagesCompanion.insert(id: 'p_arch', title: const drift.Value('To Archive'), createdAt: now, updatedAt: now));

      await db.pagesDao.archivePage('p_arch');

      final activePages = await db.pagesDao.watchPageTree().first;
      expect(activePages.any((p) => p.id == 'p_arch'), isFalse);

      final page = await db.pagesDao.getPageById('p_arch');
      expect(page?.isArchived, isTrue);
    });

    test('cascade delete removes child pages and page blocks when parent page is deleted', () async {
      final now = DateTime.now();
      await db.pagesDao.insertPage(PagesCompanion.insert(id: 'p_parent', title: const drift.Value('Parent'), createdAt: now, updatedAt: now));
      await db.pagesDao.insertPage(PagesCompanion.insert(id: 'p_child', parentPageId: const drift.Value('p_parent'), title: const drift.Value('Child'), createdAt: now, updatedAt: now));
      await db.blocksDao.insertBlock(BlocksCompanion.insert(
        id: 'b_parent',
        pageId: 'p_parent',
        blockType: 'text',
        orderKey: 'a0',
        contentJson: const drift.Value('{"text": "Parent Block"}'),
        createdAt: now,
        updatedAt: now,
      ));

      // Hard delete parent page
      await db.pagesDao.deletePage('p_parent');

      expect(await db.pagesDao.getPageById('p_parent'), isNull);
      expect(await db.pagesDao.getPageById('p_child'), isNull);
      expect(await db.blocksDao.getBlockById('b_parent'), isNull);
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

    test('updateBlockOrderKey and updateBlockParent update ordering and nesting', () async {
      final now = DateTime.now();
      await db.pagesDao.insertPage(PagesCompanion.insert(id: 'p1', title: const drift.Value('Doc'), createdAt: now, updatedAt: now));
      await db.blocksDao.insertBlock(BlocksCompanion.insert(
        id: 'b_toggle',
        pageId: 'p1',
        blockType: 'toggle',
        orderKey: 'a0',
        createdAt: now,
        updatedAt: now,
      ));
      await db.blocksDao.insertBlock(BlocksCompanion.insert(
        id: 'b_child',
        pageId: 'p1',
        blockType: 'text',
        orderKey: 'a1',
        createdAt: now,
        updatedAt: now,
      ));

      await db.blocksDao.updateBlockParent(id: 'b_child', newParentBlockId: 'b_toggle', newOrderKey: 'a0:a0');
      final child = await db.blocksDao.getBlockById('b_child');
      expect(child?.parentBlockId, equals('b_toggle'));
      expect(child?.orderKey, equals('a0:a0'));

      await db.blocksDao.updateBlockOrderKey('b_child', 'a0:a1');
      final reorderedChild = await db.blocksDao.getBlockById('b_child');
      expect(reorderedChild?.orderKey, equals('a0:a1'));
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
      expect(await db.blocksDao.getBlockById('child_block_1'), isNull);
    });

    test('batchUpsertBlocks inserts and updates in a single batch', () async {
      final now = DateTime.now();
      await db.pagesDao.insertPage(PagesCompanion.insert(id: 'p1', title: const drift.Value('Doc'), createdAt: now, updatedAt: now));

      await db.blocksDao.batchUpsertBlocks([
        BlocksCompanion.insert(id: 'b1', pageId: 'p1', blockType: 'text', orderKey: 'a0', contentJson: const drift.Value('{"text": "Initial 1"}'), createdAt: now, updatedAt: now),
        BlocksCompanion.insert(id: 'b2', pageId: 'p1', blockType: 'text', orderKey: 'a1', contentJson: const drift.Value('{"text": "Initial 2"}'), createdAt: now, updatedAt: now),
      ]);

      var blocks = await db.blocksDao.getBlocksForPage('p1');
      expect(blocks.length, equals(2));

      await db.blocksDao.batchUpsertBlocks([
        BlocksCompanion.insert(id: 'b1', pageId: 'p1', blockType: 'text', orderKey: 'a0', contentJson: const drift.Value('{"text": "Updated 1"}'), createdAt: now, updatedAt: now),
        BlocksCompanion.insert(id: 'b3', pageId: 'p1', blockType: 'text', orderKey: 'a2', contentJson: const drift.Value('{"text": "Initial 3"}'), createdAt: now, updatedAt: now),
      ]);

      blocks = await db.blocksDao.getBlocksForPage('p1');
      expect(blocks.length, equals(3));
      final b1 = await db.blocksDao.getBlockById('b1');
      expect(b1?.contentJson, contains('Updated 1'));
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

    test('getSubjectById and updateSubjectEntry', () async {
      await db.subjectsDao.seedDefaultSubjects();
      final sub = await db.subjectsDao.getSubjectById('sub_math');
      expect(sub, isNotNull);
      expect(sub?.name, equals('Mathematics'));

      final now = DateTime.now();
      await db.subjectsDao.updateSubjectEntry(
        SubjectsCompanion(
          id: const drift.Value('sub_math'),
          name: const drift.Value('Advanced Math'),
          colorHex: const drift.Value('#2563EB'),
          dailyGoalMinutes: const drift.Value(120),
          createdAt: drift.Value(now),
          updatedAt: drift.Value(now),
        ),
      );

      final updated = await db.subjectsDao.getSubjectById('sub_math');
      expect(updated?.name, equals('Advanced Math'));
      expect(updated?.dailyGoalMinutes, equals(120));
    });
  });

  group('AC3 Offline Persistence & Transaction Atomicity', () {
    test('foreign keys are active in SQLite connection', () async {
      final result = await db.customSelect('PRAGMA foreign_keys;').getSingle();
      expect(result.data['foreign_keys'], equals(1));
    });

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
