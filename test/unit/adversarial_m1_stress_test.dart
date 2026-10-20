import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' as drift;
import 'package:hampa/core/database/app_database.dart';
import 'package:hampa/core/utils/fractional_indexer.dart';
import 'package:hampa/features/workspace_editor/domain/models/page_entity.dart';
import 'package:hampa/features/workspace_editor/domain/utils/page_tree_utils.dart';

void main() {
  late AppDatabase db;
  const treeUtils = PageTreeUtils();

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('CHALLENGE 1: Arbitrary Deep Tree Nesting (15+ levels)', () {
    test('Persists, queries, and builds a 25-level deep page tree in SQLite & PageTreeUtils', () async {
      const depth = 25;
      final now = DateTime(2026, 3, 15);

      // 1. Insert 25 nested pages into SQLite (page_0 -> page_1 -> ... -> page_24)
      for (int i = 0; i < depth; i++) {
        final parentId = i == 0 ? null : 'deep_page_${i - 1}';
        await db.pagesDao.insertPage(PagesCompanion.insert(
          id: 'deep_page_$i',
          parentPageId: drift.Value(parentId),
          title: drift.Value('Level $i Page'),
          sortOrder: drift.Value(i * 10.0),
          createdAt: now,
          updatedAt: now,
        ));
      }

      // 2. Retrieve all pages from DAO
      final allPagesFromDb = await db.pagesDao.watchPageTree().first;
      expect(allPagesFromDb.length, equals(depth));

      // Map to domain PageEntity
      final pageEntities = allPagesFromDb
          .map((e) => PageEntity(
                id: e.id,
                parentPageId: e.parentPageId,
                title: e.title,
                sortOrder: e.sortOrder,
                createdAt: e.createdAt,
                updatedAt: e.updatedAt,
              ))
          .toList();

      // 3. Build tree with all expanded
      final allIds = pageEntities.map((p) => p.id).toSet();
      final rootNodes = treeUtils.buildTree(
        pages: pageEntities,
        expandedPageIds: allIds,
      );

      // Verify single root
      expect(rootNodes.length, equals(1));
      expect(rootNodes.first.page.id, equals('deep_page_0'));
      expect(rootNodes.first.depth, equals(0));

      // 4. Flatten tree and verify every level 0..24 is present in sequential order
      final flattened = treeUtils.flattenTree(rootNodes);
      expect(flattened.length, equals(depth));
      for (int i = 0; i < depth; i++) {
        expect(flattened[i].page.id, equals('deep_page_$i'));
        expect(flattened[i].depth, equals(i));
      }

      // 5. Breadcrumb verification from bottom-most leaf
      final pageMap = {for (final p in pageEntities) p.id: p};
      final crumbs = treeUtils.getBreadcrumbs(pageId: 'deep_page_${depth - 1}', pageMap: pageMap);
      expect(crumbs.length, equals(depth));
      expect(crumbs.first.id, equals('deep_page_0'));
      expect(crumbs.last.id, equals('deep_page_${depth - 1}'));

      // 6. Search query targeting the deepest leaf auto-expands all 24 ancestors
      final searchTree = treeUtils.buildTree(
        pages: pageEntities,
        searchQuery: 'Level ${depth - 1}',
      );
      expect(searchTree.length, equals(1));
      var current = searchTree.first;
      for (int i = 0; i < depth - 1; i++) {
        expect(current.isExpanded, isTrue, reason: 'Ancestor at level $i must be auto-expanded');
        expect(current.children.length, equals(1));
        current = current.children.first;
      }
      expect(current.page.id, equals('deep_page_${depth - 1}'));
    });
  });

  group('CHALLENGE 2: Adversarial Injection of Parent-Child Cycles', () {
    test('PagesDao rejects direct self-parenting', () async {
      final now = DateTime.now();
      await db.pagesDao.insertPage(PagesCompanion.insert(
        id: 'node_alpha',
        title: const drift.Value('Alpha'),
        createdAt: now,
        updatedAt: now,
      ));

      expect(
        () => db.pagesDao.updatePageParent(
          pageId: 'node_alpha',
          newParentPageId: 'node_alpha',
          newSortOrder: 1.0,
        ),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('A page cannot be its own parent'),
        )),
      );
    });

    test('PagesDao and PageTreeUtils reject moving root into its multi-tier grandchild', () async {
      final now = DateTime.now();
      // Setup Root -> Child -> Grandchild -> GreatGrandchild
      final nodes = ['root', 'child', 'grandchild', 'great_grandchild'];
      for (int i = 0; i < nodes.length; i++) {
        await db.pagesDao.insertPage(PagesCompanion.insert(
          id: nodes[i],
          parentPageId: drift.Value(i == 0 ? null : nodes[i - 1]),
          title: drift.Value('Node ${nodes[i]}'),
          createdAt: now,
          updatedAt: now,
        ));
      }

      final pageList = (await db.pagesDao.watchPageTree().first)
          .map((e) => PageEntity(
                id: e.id,
                parentPageId: e.parentPageId,
                title: e.title,
                createdAt: e.createdAt,
                updatedAt: e.updatedAt,
              ))
          .toList();
      final pageMap = {for (final p in pageList) p.id: p};

      // 1. Check canReparent utility
      expect(
        treeUtils.canReparent(
          movingPageId: 'root',
          targetParentId: 'great_grandchild',
          pageMap: pageMap,
        ),
        isFalse,
      );
      expect(
        treeUtils.canReparent(
          movingPageId: 'child',
          targetParentId: 'great_grandchild',
          pageMap: pageMap,
        ),
        isFalse,
      );

      // 2. Check PagesDao rejection at DB level
      expect(
        () => db.pagesDao.updatePageParent(
          pageId: 'root',
          newParentPageId: 'great_grandchild',
          newSortOrder: 100.0,
        ),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('Cannot move a page under its own descendant'),
        )),
      );
      expect(
        () => db.pagesDao.updatePageParent(
          pageId: 'child',
          newParentPageId: 'great_grandchild',
          newSortOrder: 100.0,
        ),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('Cannot move a page under its own descendant'),
        )),
      );

      // Ensure root still has null parent after rejected operations
      final rootEntry = await db.pagesDao.getPageById('root');
      expect(rootEntry?.parentPageId, isNull);
    });

    test('Corrupt cycle tolerance: buildTree handles cyclical parent pointers without crashing', () {
      final now = DateTime.now();
      // Suppose corrupted data has A -> B -> C -> A
      final cyclicalPages = [
        PageEntity(id: 'cA', parentPageId: 'cC', title: 'Cyclic A', createdAt: now, updatedAt: now),
        PageEntity(id: 'cB', parentPageId: 'cA', title: 'Cyclic B', createdAt: now, updatedAt: now),
        PageEntity(id: 'cC', parentPageId: 'cB', title: 'Cyclic C', createdAt: now, updatedAt: now),
      ];

      // Since none have parentPageId == null and all parents are in pageMap,
      // parentGrouped[null] is empty. It should return empty list and not hang or loop.
      final tree = treeUtils.buildTree(pages: cyclicalPages);
      expect(tree, isEmpty);
    });
  });

  group('CHALLENGE 3: Cascade Deletion of Root Page with Deep Nested Children & Blocks', () {
    test('Hard delete of root cascades through 20 levels of pages and 100+ blocks in SQLite', () async {
      const depth = 20;
      final now = DateTime(2026, 3, 15);

      // 1. Create 20 levels of pages
      for (int i = 0; i < depth; i++) {
        final parentId = i == 0 ? null : 'casc_page_${i - 1}';
        await db.pagesDao.insertPage(PagesCompanion.insert(
          id: 'casc_page_$i',
          parentPageId: drift.Value(parentId),
          title: drift.Value('Page $i'),
          createdAt: now,
          updatedAt: now,
        ));

        // Under each page, insert 3 blocks: a heading, a checklist, and a toggle
        await db.blocksDao.insertBlock(BlocksCompanion.insert(
          id: 'block_${i}_h',
          pageId: 'casc_page_$i',
          blockType: 'heading_1',
          orderKey: 'a0',
          contentJson: drift.Value('{"text": "Heading $i"}'),
          createdAt: now,
          updatedAt: now,
        ));
        await db.blocksDao.insertBlock(BlocksCompanion.insert(
          id: 'block_${i}_c',
          pageId: 'casc_page_$i',
          blockType: 'checklist',
          orderKey: 'a1',
          contentJson: drift.Value('{"text": "Task $i", "isCompleted": false}'),
          createdAt: now,
          updatedAt: now,
        ));
        await db.blocksDao.insertBlock(BlocksCompanion.insert(
          id: 'block_${i}_t',
          pageId: 'casc_page_$i',
          blockType: 'toggle',
          orderKey: 'a2',
          contentJson: drift.Value('{"title": "Toggle $i"}'),
          createdAt: now,
          updatedAt: now,
        ));

        // Under the toggle block, add 2 nested child blocks
        await db.blocksDao.insertBlock(BlocksCompanion.insert(
          id: 'nested_${i}_1',
          pageId: 'casc_page_$i',
          parentBlockId: drift.Value('block_${i}_t'),
          blockType: 'text',
          orderKey: 'a2:a0',
          contentJson: drift.Value('{"text": "Nested block $i.1"}'),
          createdAt: now,
          updatedAt: now,
        ));
        await db.blocksDao.insertBlock(BlocksCompanion.insert(
          id: 'nested_${i}_2',
          pageId: 'casc_page_$i',
          parentBlockId: drift.Value('block_${i}_t'),
          blockType: 'code',
          orderKey: 'a2:a1',
          contentJson: const drift.Value('{"language": "dart", "code": "void main() {}"}'),
          createdAt: now,
          updatedAt: now,
        ));
      }

      // Verify initial state
      final pagesBefore = await (db.select(db.pages)).get();
      final blocksBefore = await (db.select(db.blocks)).get();
      expect(pagesBefore.length, equals(depth));
      expect(blocksBefore.length, equals(depth * 5)); // 20 * 5 = 100 blocks

      // 2. HARD DELETE the root page
      final deletedCount = await db.pagesDao.deletePage('casc_page_0');
      expect(deletedCount, equals(1));

      // 3. Verify that ALL 20 pages were cleanly removed by SQLite ON DELETE CASCADE
      final pagesAfter = await (db.select(db.pages)).get();
      expect(pagesAfter, isEmpty, reason: 'All 20 nested pages must be deleted by cascade');

      // 4. Verify that ALL 100 blocks were cleanly removed by SQLite ON DELETE CASCADE
      final blocksAfter = await (db.select(db.blocks)).get();
      expect(blocksAfter, isEmpty, reason: 'All 100 blocks across all pages must be deleted by cascade');
    });
  });

  group('CHALLENGE 4: Float64 FractionalIndexer Stress & Rebalance', () {
    test('Float64 FractionalIndexer: 30 consecutive midpoint insertions between tight bounds', () {
      double left = 1000.0;
      double right = 1001.0;

      final List<double> inserted = [];
      for (int i = 0; i < 30; i++) {
        final mid = FractionalIndexer.betweenDoubles(left, right);
        expect(mid, greaterThan(left));
        expect(mid, lessThan(right));
        inserted.add(mid);
        // Repeatedly squeeze into the tighter left half
        right = mid;
      }

      // Check if rebalance detection triggers when delta is smaller than 1e-6
      expect(FractionalIndexer.needsRebalance(left, right), isTrue);

      // Rebalancing restores clean steps
      final rebalanced = FractionalIndexer.rebalanceDoubles(inserted.length);
      expect(rebalanced.length, equals(inserted.length));
      for (int i = 0; i < rebalanced.length - 1; i++) {
        expect(rebalanced[i + 1] - rebalanced[i], equals(FractionalIndexer.defaultStep));
      }
    });
  });

  group('CHALLENGE 5: Empirical Adversarial Failure Modes in StringLexoRank', () {
    test('StringLexoRank maintains strict monotonic order across 30 consecutive midpoint insertions', () {
      String left = 'a';
      String right = 'b';

      for (int i = 0; i < 30; i++) {
        final mid = StringLexoRank.between(left, right);
        expect(mid.compareTo(left), greaterThan(0),
            reason: 'Iteration $i: "$mid" must be strictly greater than left "$left"');
        expect(mid.compareTo(right), lessThan(0),
            reason: 'Iteration $i: "$mid" must be strictly less than right "$right"');
        // Repeatedly squeeze into tighter left half
        right = mid;
      }
    });

    test('StringLexoRank accurately produces midpoints for tight prefix cases', () {
      // Iteration 5: between('a', 'a1') must produce 'a0i'
      final m = StringLexoRank.between('a', 'a1');
      expect(m, equals('a0i'));
      expect(m.compareTo('a'), greaterThan(0));
      expect(m.compareTo('a1'), lessThan(0));

      // Iteration 6: between('a', 'a0i') must produce 'a09'
      final m2 = StringLexoRank.between('a', 'a0i');
      expect(m2, equals('a09'));
      expect(m2.compareTo('a'), greaterThan(0));
      expect(m2.compareTo('a0i'), lessThan(0));
    });

    test('StringLexoRank generates a key strictly less than "0" when prepending before "0"', () {
      final beforeZero = StringLexoRank.between(null, '0');
      expect(beforeZero, equals('/m'));
      expect(beforeZero.compareTo('0'), lessThan(0));

      final beforeBeforeZero = StringLexoRank.between(null, beforeZero);
      expect(beforeBeforeZero, equals('/b'));
      expect(beforeBeforeZero.compareTo(beforeZero), lessThan(0));

      final betweenNegativeAndZero = StringLexoRank.between(beforeZero, '0');
      expect(betweenNegativeAndZero.compareTo(beforeZero), greaterThan(0));
      expect(betweenNegativeAndZero.compareTo('0'), lessThan(0));
    });

    test('PageTreeUtils.buildTree safely handles search query on cyclical ancestor chains without infinite loop', () {
      final now = DateTime.now();
      final cyclicalPages = [
        PageEntity(id: 'cA', parentPageId: 'cB', title: 'Target Cyclic Search', createdAt: now, updatedAt: now),
        PageEntity(id: 'cB', parentPageId: 'cA', title: 'Cyclic B', createdAt: now, updatedAt: now),
      ];

      // Must complete immediately without timing out or hanging
      final tree = treeUtils.buildTree(
        pages: cyclicalPages,
        searchQuery: 'Target',
      );
      expect(tree, isEmpty);
    });

    test('EXTENDED EMPIRICAL STRESS: StringLexoRank 60 consecutive tight left-squeeze insertions', () {
      String left = 'a';
      String right = 'b';

      for (int i = 0; i < 60; i++) {
        final mid = StringLexoRank.between(left, right);
        expect(mid.compareTo(left), greaterThan(0),
            reason: 'Iteration $i: "$mid" must be strictly greater than left "$left"');
        expect(mid.compareTo(right), lessThan(0),
            reason: 'Iteration $i: "$mid" must be strictly less than right "$right"');
        right = mid;
      }
    });

    test('EXTENDED EMPIRICAL STRESS: StringLexoRank 60 consecutive tight right-squeeze insertions', () {
      String left = 'a';
      String right = 'b';

      for (int i = 0; i < 60; i++) {
        final mid = StringLexoRank.between(left, right);
        expect(mid.compareTo(left), greaterThan(0),
            reason: 'Iteration $i: "$mid" must be strictly greater than left "$left"');
        expect(mid.compareTo(right), lessThan(0),
            reason: 'Iteration $i: "$mid" must be strictly less than right "$right"');
        left = mid;
      }
    });

    test('EXTENDED EMPIRICAL STRESS: StringLexoRank 60 alternating squeeze insertions', () {
      String left = 'a';
      String right = 'b';

      for (int i = 0; i < 60; i++) {
        final mid = StringLexoRank.between(left, right);
        expect(mid.compareTo(left), greaterThan(0),
            reason: 'Iteration $i: "$mid" must be strictly greater than left "$left"');
        expect(mid.compareTo(right), lessThan(0),
            reason: 'Iteration $i: "$mid" must be strictly less than right "$right"');
        if (i % 2 == 0) {
          right = mid;
        } else {
          left = mid;
        }
      }
    });

    test('EXTENDED EMPIRICAL STRESS: 50 consecutive prepends below "0"', () {
      String current = '0';
      for (int i = 0; i < 50; i++) {
        final prepended = StringLexoRank.between(null, current);
        expect(prepended.compareTo(current), lessThan(0),
            reason: 'Iteration $i: "$prepended" must be strictly less than current "$current"');
        current = prepended;
      }
    });

    test('EXTENDED EMPIRICAL STRESS: PageTreeUtils handles 100-node cycle with search query', () {
      final now = DateTime.now();
      const count = 100;
      final pages = List.generate(count, (i) {
        final nextId = (i + 1) % count;
        return PageEntity(
          id: 'cycle_node_$i',
          parentPageId: 'cycle_node_$nextId',
          title: 'Node $i',
          createdAt: now,
          updatedAt: now,
        );
      });

      final result = treeUtils.buildTree(
        pages: pages,
        searchQuery: 'Node 50',
      );
      expect(result, isEmpty);
    });

    test('EXTENDED EMPIRICAL STRESS: PageTreeUtils handles mixed valid tree and disconnected cycle with search query', () {
      final now = DateTime.now();
      final pages = [
        // Valid tree: root -> child -> leaf
        PageEntity(id: 'root', parentPageId: null, title: 'Valid Root', sortOrder: 100.0, createdAt: now, updatedAt: now),
        PageEntity(id: 'child', parentPageId: 'root', title: 'Valid Child', sortOrder: 100.0, createdAt: now, updatedAt: now),
        PageEntity(id: 'leaf', parentPageId: 'child', title: 'Target Search Leaf', sortOrder: 100.0, createdAt: now, updatedAt: now),
        // Disconnected cycle: c1 <-> c2
        PageEntity(id: 'c1', parentPageId: 'c2', title: 'Target Search Cyclic C1', sortOrder: 100.0, createdAt: now, updatedAt: now),
        PageEntity(id: 'c2', parentPageId: 'c1', title: 'Cyclic C2', sortOrder: 100.0, createdAt: now, updatedAt: now),
      ];

      final result = treeUtils.buildTree(
        pages: pages,
        searchQuery: 'Target Search',
      );

      // Valid tree must be preserved and expanded to the matching leaf
      expect(result.length, equals(1));
      expect(result.first.page.id, equals('root'));
      expect(result.first.isExpanded, isTrue);
      expect(result.first.children.length, equals(1));
      expect(result.first.children.first.page.id, equals('child'));
      expect(result.first.children.first.isExpanded, isTrue);
      expect(result.first.children.first.children.length, equals(1));
      expect(result.first.children.first.children.first.page.id, equals('leaf'));
    });
  });
}

