import '../models/page_entity.dart';
import '../models/page_tree_node.dart';

class PageTreeUtils {
  const PageTreeUtils();

  /// Builds a hierarchical list of root [PageTreeNode]s from a flat list of pages.
  List<PageTreeNode> buildTree({
    required List<PageEntity> pages,
    Set<String> expandedPageIds = const {},
    String? searchQuery,
  }) {
    final activePages = pages.where((p) => !p.isArchived).toList();
    final Map<String, PageEntity> pageMap = {
      for (final p in activePages) p.id: p,
    };

    // Group pages by parentPageId
    final Map<String?, List<PageEntity>> parentGrouped = {};
    for (final page in activePages) {
      // If parentPageId does not exist in activePages, treat as root orphan
      final effectiveParentId = (page.parentPageId != null && pageMap.containsKey(page.parentPageId))
          ? page.parentPageId
          : null;
      parentGrouped.putIfAbsent(effectiveParentId, () => []).add(page);
    }

    // Sort each sibling group by sortOrder ascending
    for (final group in parentGrouped.values) {
      group.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    }

    // If search query is present, find matching pages and their ancestors
    Set<String> searchMatchedIds = {};
    Set<String> autoExpandedIds = Set.from(expandedPageIds);

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final cleanQuery = searchQuery.trim().toLowerCase();
      for (final page in activePages) {
        if (page.title.toLowerCase().contains(cleanQuery)) {
          searchMatchedIds.add(page.id);
          // Expand all ancestors of matching child
          var currentParentId = page.parentPageId;
          final Set<String> visited = {page.id};
          while (currentParentId != null &&
              pageMap.containsKey(currentParentId) &&
              !visited.contains(currentParentId)) {
            visited.add(currentParentId);
            autoExpandedIds.add(currentParentId);
            currentParentId = pageMap[currentParentId]?.parentPageId;
          }
        }
      }
    }

    // Recursively construct nodes
    List<PageTreeNode> buildChildren(String? parentId, int depth) {
      final siblings = parentGrouped[parentId] ?? [];
      final List<PageTreeNode> nodes = [];

      for (final page in siblings) {
        final children = buildChildren(page.id, depth + 1);

        // If search filtering is active, only include if matches or has matching children
        if (searchQuery != null && searchQuery.trim().isNotEmpty) {
          final isDirectMatch = searchMatchedIds.contains(page.id);
          final hasMatchingDescendant = children.isNotEmpty;
          if (!isDirectMatch && !hasMatchingDescendant) {
            continue;
          }
        }

        final isExpanded = autoExpandedIds.contains(page.id);
        nodes.add(PageTreeNode(
          page: page,
          children: children,
          depth: depth,
          isExpanded: isExpanded,
        ));
      }
      return nodes;
    }

    return buildChildren(null, 0);
  }

  /// Flattens the visible tree nodes for virtualized ListView rendering.
  List<PageTreeNode> flattenTree(List<PageTreeNode> rootNodes) {
    final List<PageTreeNode> result = [];

    void traverse(PageTreeNode node) {
      result.add(node);
      if (node.isExpanded) {
        for (final child in node.children) {
          traverse(child);
        }
      }
    }

    for (final root in rootNodes) {
      traverse(root);
    }
    return result;
  }

  /// Checks if [candidateChildId] is a descendant of [candidateAncestorId].
  /// Prevents cycle creation when re-parenting.
  bool isDescendant({
    required String candidateChildId,
    required String candidateAncestorId,
    required Map<String, PageEntity> pageMap,
  }) {
    if (candidateChildId == candidateAncestorId) return true;

    final Set<String> visited = {candidateChildId};
    var currentParentId = pageMap[candidateChildId]?.parentPageId;

    while (currentParentId != null) {
      if (currentParentId == candidateAncestorId) return true;
      if (visited.contains(currentParentId)) break; // Prevent cycle loops
      visited.add(currentParentId);
      currentParentId = pageMap[currentParentId]?.parentPageId;
    }
    return false;
  }

  /// Validates whether a page can be moved to [targetParentId].
  bool canReparent({
    required String movingPageId,
    required String? targetParentId,
    required Map<String, PageEntity> pageMap,
  }) {
    if (targetParentId == null) return true; // Moving to root is always valid
    if (movingPageId == targetParentId) return false; // Cannot be parent of itself
    if (isDescendant(candidateChildId: targetParentId, candidateAncestorId: movingPageId, pageMap: pageMap)) {
      return false; // Cannot move page into its own descendant!
    }
    return true;
  }

  /// Constructs the ordered breadcrumb path from workspace root down to [pageId].
  List<PageEntity> getBreadcrumbs({
    required String pageId,
    required Map<String, PageEntity> pageMap,
  }) {
    final List<PageEntity> path = [];
    final Set<String> visited = {};
    var currentId = pageId;

    while (pageMap.containsKey(currentId) && !visited.contains(currentId)) {
      visited.add(currentId);
      final page = pageMap[currentId]!;
      path.add(page);
      if (page.parentPageId == null) break;
      currentId = page.parentPageId!;
    }

    return path.reversed.toList();
  }
}
