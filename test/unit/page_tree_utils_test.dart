import 'package:flutter_test/flutter_test.dart';
import 'package:hampa/features/workspace_editor/domain/models/page_entity.dart';
import 'package:hampa/features/workspace_editor/domain/models/page_tree_node.dart';
import 'package:hampa/features/workspace_editor/domain/utils/page_tree_utils.dart';

void main() {
  const treeUtils = PageTreeUtils();
  final now = DateTime(2026, 1, 1);

  PageEntity createPage({
    required String id,
    String? parentPageId,
    required String title,
    double sortOrder = 0.0,
    bool isArchived = false,
  }) {
    return PageEntity(
      id: id,
      parentPageId: parentPageId,
      title: title,
      sortOrder: sortOrder,
      isArchived: isArchived,
      createdAt: now,
      updatedAt: now,
    );
  }

  group('PageTreeUtils.buildTree', () {
    test('returns empty list for empty page collection', () {
      final tree = treeUtils.buildTree(pages: []);
      expect(tree, isEmpty);
    });

    test('ignores archived pages', () {
      final pages = [
        createPage(id: 'p1', title: 'Active'),
        createPage(id: 'p2', title: 'Archived', isArchived: true),
      ];

      final tree = treeUtils.buildTree(pages: pages);
      expect(tree.length, equals(1));
      expect(tree.first.page.id, equals('p1'));
    });

    test('sorts root and sibling nodes by sortOrder ascending', () {
      final pages = [
        createPage(id: 'root_c', title: 'Root C', sortOrder: 3.0),
        createPage(id: 'root_a', title: 'Root A', sortOrder: 1.0),
        createPage(id: 'root_b', title: 'Root B', sortOrder: 2.0),
        createPage(id: 'child_2', parentPageId: 'root_a', title: 'Child 2', sortOrder: 20.0),
        createPage(id: 'child_1', parentPageId: 'root_a', title: 'Child 1', sortOrder: 10.0),
      ];

      final tree = treeUtils.buildTree(pages: pages);
      expect(tree.map((n) => n.page.id).toList(), equals(['root_a', 'root_b', 'root_c']));

      final rootANode = tree.first;
      expect(rootANode.children.map((c) => c.page.id).toList(), equals(['child_1', 'child_2']));
    });

    test('builds multi-level hierarchy with accurate depths', () {
      final pages = [
        createPage(id: 'root', title: 'Root', sortOrder: 1.0),
        createPage(id: 'sub', parentPageId: 'root', title: 'Sub', sortOrder: 1.0),
        createPage(id: 'leaf', parentPageId: 'sub', title: 'Leaf', sortOrder: 1.0),
      ];

      final tree = treeUtils.buildTree(pages: pages);
      expect(tree.length, equals(1));
      expect(tree.first.depth, equals(0));
      expect(tree.first.children.length, equals(1));
      expect(tree.first.children.first.depth, equals(1));
      expect(tree.first.children.first.children.length, equals(1));
      expect(tree.first.children.first.children.first.depth, equals(2));
      expect(tree.first.children.first.children.first.page.id, equals('leaf'));
    });

    test('treats orphan page with missing parent as root', () {
      final pages = [
        createPage(id: 'p1', parentPageId: 'non_existent_parent', title: 'Orphan'),
      ];

      final tree = treeUtils.buildTree(pages: pages);
      expect(tree.length, equals(1));
      expect(tree.first.page.id, equals('p1'));
      expect(tree.first.depth, equals(0));
    });

    test('marks nodes expanded based on expandedPageIds set', () {
      final pages = [
        createPage(id: 'p1', title: 'P1'),
        createPage(id: 'p2', title: 'P2'),
      ];

      final tree = treeUtils.buildTree(
        pages: pages,
        expandedPageIds: {'p1'},
      );

      expect(tree[0].isExpanded, isTrue);
      expect(tree[1].isExpanded, isFalse);
    });

    test('searchQuery filters matching nodes and auto-expands ancestors', () {
      final pages = [
        createPage(id: 'work', title: 'Workspace Root'),
        createPage(id: 'proj', parentPageId: 'work', title: 'Flutter Projects'),
        createPage(id: 'target', parentPageId: 'proj', title: 'HamPA App'),
        createPage(id: 'other', title: 'Unrelated Personal Notes'),
      ];

      final tree = treeUtils.buildTree(
        pages: pages,
        searchQuery: 'hampa',
      );

      // Only 'work' branch should remain; 'other' should be filtered out
      expect(tree.length, equals(1));
      expect(tree.first.page.id, equals('work'));
      // Ancestors should be auto-expanded to reveal the search match
      expect(tree.first.isExpanded, isTrue);
      expect(tree.first.children.first.page.id, equals('proj'));
      expect(tree.first.children.first.isExpanded, isTrue);
      expect(tree.first.children.first.children.first.page.id, equals('target'));
    });
  });

  group('PageTreeUtils.flattenTree', () {
    test('returns only root nodes when all nodes are collapsed', () {
      final rootA = PageTreeNode(
        page: createPage(id: 'a', title: 'A'),
        isExpanded: false,
        children: [
          PageTreeNode(page: createPage(id: 'a1', parentPageId: 'a', title: 'A1')),
        ],
      );
      final rootB = PageTreeNode(
        page: createPage(id: 'b', title: 'B'),
        isExpanded: false,
      );

      final flattened = treeUtils.flattenTree([rootA, rootB]);
      expect(flattened.map((n) => n.page.id).toList(), equals(['a', 'b']));
    });

    test('returns preorder traversal when nodes are expanded', () {
      final leaf = PageTreeNode(
        page: createPage(id: 'child_deep', parentPageId: 'child_1', title: 'Deep'),
        depth: 2,
      );
      final child1 = PageTreeNode(
        page: createPage(id: 'child_1', parentPageId: 'root', title: 'Child 1'),
        depth: 1,
        isExpanded: true,
        children: [leaf],
      );
      final child2 = PageTreeNode(
        page: createPage(id: 'child_2', parentPageId: 'root', title: 'Child 2'),
        depth: 1,
      );
      final root = PageTreeNode(
        page: createPage(id: 'root', title: 'Root'),
        depth: 0,
        isExpanded: true,
        children: [child1, child2],
      );

      final flattened = treeUtils.flattenTree([root]);
      expect(
        flattened.map((n) => n.page.id).toList(),
        equals(['root', 'child_1', 'child_deep', 'child_2']),
      );
    });
  });

  group('PageTreeUtils.isDescendant', () {
    final pageMap = {
      'root': createPage(id: 'root', title: 'Root'),
      'c1': createPage(id: 'c1', parentPageId: 'root', title: 'C1'),
      'c2': createPage(id: 'c2', parentPageId: 'root', title: 'C2'),
      'gc1': createPage(id: 'gc1', parentPageId: 'c1', title: 'GC1'),
      'ggc1': createPage(id: 'ggc1', parentPageId: 'gc1', title: 'GGC1'),
    };

    test('returns true when candidate child equals candidate ancestor (self check)', () {
      expect(
        treeUtils.isDescendant(
          candidateChildId: 'c1',
          candidateAncestorId: 'c1',
          pageMap: pageMap,
        ),
        isTrue,
      );
    });

    test('returns true for direct child', () {
      expect(
        treeUtils.isDescendant(
          candidateChildId: 'c1',
          candidateAncestorId: 'root',
          pageMap: pageMap,
        ),
        isTrue,
      );
    });

    test('returns true for multi-tier descendant', () {
      expect(
        treeUtils.isDescendant(
          candidateChildId: 'ggc1',
          candidateAncestorId: 'root',
          pageMap: pageMap,
        ),
        isTrue,
      );
      expect(
        treeUtils.isDescendant(
          candidateChildId: 'ggc1',
          candidateAncestorId: 'c1',
          pageMap: pageMap,
        ),
        isTrue,
      );
    });

    test('returns false for siblings', () {
      expect(
        treeUtils.isDescendant(
          candidateChildId: 'c2',
          candidateAncestorId: 'c1',
          pageMap: pageMap,
        ),
        isFalse,
      );
    });

    test('returns false when child is tested as ancestor of its parent', () {
      expect(
        treeUtils.isDescendant(
          candidateChildId: 'root',
          candidateAncestorId: 'c1',
          pageMap: pageMap,
        ),
        isFalse,
      );
    });
  });

  group('PageTreeUtils.canReparent', () {
    final pageMap = {
      'root': createPage(id: 'root', title: 'Root'),
      'folder': createPage(id: 'folder', parentPageId: 'root', title: 'Folder'),
      'doc': createPage(id: 'doc', parentPageId: 'folder', title: 'Doc'),
      'unrelated': createPage(id: 'unrelated', title: 'Unrelated'),
    };

    test('returns true when moving to root (targetParentId is null)', () {
      expect(
        treeUtils.canReparent(
          movingPageId: 'doc',
          targetParentId: null,
          pageMap: pageMap,
        ),
        isTrue,
      );
    });

    test('returns false when moving node into itself', () {
      expect(
        treeUtils.canReparent(
          movingPageId: 'folder',
          targetParentId: 'folder',
          pageMap: pageMap,
        ),
        isFalse,
      );
    });

    test('returns false when moving node into its own descendant', () {
      // Trying to move 'folder' under 'doc'
      expect(
        treeUtils.canReparent(
          movingPageId: 'folder',
          targetParentId: 'doc',
          pageMap: pageMap,
        ),
        isFalse,
      );
    });

    test('returns true when moving node under unrelated parent or sibling', () {
      expect(
        treeUtils.canReparent(
          movingPageId: 'doc',
          targetParentId: 'unrelated',
          pageMap: pageMap,
        ),
        isTrue,
      );
    });
  });

  group('PageTreeUtils.getBreadcrumbs', () {
    final pageMap = {
      'root': createPage(id: 'root', title: 'Root'),
      'folder': createPage(id: 'folder', parentPageId: 'root', title: 'Folder'),
      'doc': createPage(id: 'doc', parentPageId: 'folder', title: 'Doc'),
    };

    test('returns single page for root page', () {
      final crumbs = treeUtils.getBreadcrumbs(pageId: 'root', pageMap: pageMap);
      expect(crumbs.length, equals(1));
      expect(crumbs.first.id, equals('root'));
    });

    test('returns path from root down to leaf in correct order', () {
      final crumbs = treeUtils.getBreadcrumbs(pageId: 'doc', pageMap: pageMap);
      expect(crumbs.map((c) => c.id).toList(), equals(['root', 'folder', 'doc']));
    });

    test('returns empty list for non-existent page', () {
      final crumbs = treeUtils.getBreadcrumbs(pageId: 'unknown', pageMap: pageMap);
      expect(crumbs, isEmpty);
    });
  });
}
