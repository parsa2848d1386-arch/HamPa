# Technical Implementation Plan & Handoff Report: Milestone 1 Hierarchical Page Tree & Navigation

**Agent**: `explorer_m1_tree` (Page Tree & Workspace Navigation Explorer)  
**Working Directory**: `c:\parsa\HamPA\.agents\teamwork\explorer_m1_tree`  
**Parent Orchestrator**: `22d8faaf-eb90-463c-99a6-32a4eb94320e`  
**Date**: 2026-10-16T17:15:00Z  

---

## 1. Observation

### 1.1 Direct Observations & Examined Sources
1. **`c:\parsa\HamPA\.agents\teamwork\ORIGINAL_REQUEST.md`**:
   - Lines 12–13: "R1. Block-Based Workspace & Relational Database System (Notion Core) - Hierarchical page tree supporting arbitrary nesting and drag-and-drop organization."
   - Line 40: "Acceptance Criteria - Nested sub-pages can be created, edited, and rearranged without state loss (AC1)."
2. **`c:\parsa\HamPA\PROJECT.md`**:
   - Lines 22–24: Feature F01: "Hierarchical Page Tree - Arbitrary depth nesting of pages and sub-pages in sidebar navigation" (M1 / AC1).
   - Line 23: Feature F02: "Drag-and-Drop Page Tree - Reorder pages and re-parent by dragging in navigation tree" (M1 / AC1).
   - Lines 77–87: Interface Contract `IWorkspaceRepository`:
     ```dart
     abstract class IWorkspaceRepository {
       Stream<List<PageEntity>> watchPageTree();
       Future<PageEntity> createPage({String? parentPageId, required String title, String? icon, bool isDatabaseRow = false});
       Future<void> updatePageParent({required String pageId, String? newParentPageId, required double newSortOrder});
       Stream<List<BlockEntity>> watchBlocksForPage(String pageId);
       Future<void> insertBlock(BlockEntity block);
       Future<void> updateBlock(BlockEntity block);
       Future<void> deleteBlock(String blockId);
     }
     ```
   - Lines 172–174: Code layout assigns `lib/features/workspace_editor/` for M1 Notion Page Tree & Block Editor.
3. **`c:\parsa\HamPA\.agents\teamwork\explorer_survey_arch\handoff.md`**:
   - Lines 137–150: Schema for `pages` table in Drift SQLite:
     - `id TEXT NOT NULL PRIMARY KEY`
     - `parent_page_id TEXT REFERENCES pages(id) ON DELETE CASCADE`
     - `title TEXT NOT NULL`
     - `icon TEXT`
     - `cover_image_url TEXT`
     - `is_database_row BOOLEAN NOT NULL DEFAULT FALSE`
     - `is_archived BOOLEAN NOT NULL DEFAULT FALSE`
     - `sort_order REAL NOT NULL DEFAULT 0.0`
     - `created_at INTEGER NOT NULL`
     - `updated_at INTEGER NOT NULL`
   - Line 161 & 743: `lib/core/utils/fractional_indexer.dart` specifies pure Dart LexoRank algorithm for $O(1)$ reordering and drag-and-drop sort positioning.
4. **`c:\parsa\HamPA\.agents\teamwork\explorer_survey_env\handoff.md`**:
   - Dependencies available: `flutter_bloc: ^9.1.1`, `provider: ^6.1.5`, `uuid: ^4.6.0`, `intl: ^0.20.3`, `drift: ^2.24.0`, `mocktail: ^1.0.5`, `flutter_test`.

---

## 2. Logic Chain

1. **Hierarchy Representation**:
   - The database stores pages as an adjacency list (`parent_page_id`), where root pages have `parent_page_id = NULL`.
   - In the presentation layer, the UI requires an N-ary tree data structure (`PageTreeNode`) where each node contains its `PageEntity`, depth, expansion state, and list of child `PageTreeNode`s sorted by `sort_order`.
   - Converting the flat stream `Stream<List<PageEntity>>` into `List<PageTreeNode>` must be pure, synchronous, and instantaneous ($O(N)$ via map grouping).

2. **Cycle Prevention in Directed Hierarchies**:
   - An adjacency list tree can easily become corrupted if a page $A$ is dragged into its own descendant $B$ (forming a directed cycle $A \to \dots \to B \to A$), detaching the subtree from root and causing infinite recursion or lost data.
   - Cycle prevention check: For any proposed drag of `movingPageId` to `targetParentId`, we must verify that `targetParentId != movingPageId` AND `movingPageId` is NOT an ancestor of `targetParentId`.
   - This check must execute synchronously during `onWillAcceptWithDetails` in Flutter's `DragTarget` so that forbidden drop targets are rejected before drop execution.

3. **Fractional Indexing ($O(1)$ Reordering)**:
   - When moving a page between sibling $S_i$ and sibling $S_{i+1}$, re-numbering all subsequent siblings $S_{i+2} \dots S_N$ causes $O(N)$ database updates and lock contention.
   - Fractional indexing computes `newSortOrder = (S_i.sort_order + S_{i+1}.sort_order) / 2.0`.
   - To support both `sort_order REAL` in `pages` and `order_key TEXT` in `blocks`, HamPA requires a dual-engine `FractionalIndexer`:
     - `DoubleFractionalIndexer`: Fast IEEE-754 floating-point midpoint with automatic rebalance threshold detection (`delta < 1e-6`).
     - `StringLexoRank`: Infinite-precision base-36 string midpoint generator for Notion blocks and properties without rebalance limits.

4. **Multi-Zone Drag-and-Drop UX**:
   - When dragging page $A$ onto tree item $B$, the user may want one of three actions:
     1. Place $A$ immediately **before** $B$ (sibling before).
     2. Place $A$ **inside** $B$ (re-parent as child of $B$).
     3. Place $A$ immediately **after** $B$ (sibling after).
   - Dividing the item's vertical height into 3 active drop zones (Top 25% = Before, Center 50% = Inside/Reparent, Bottom 25% = After) provides clear visual affordance (top line, whole item highlight, bottom line) and intuitive manipulation.

5. **Reactivity & State Synchronization**:
   - The UI must react automatically whenever Drift SQLite emits a new page list (e.g. from sub-page creation, rename, or background sync).
   - `PageTreeCubit` maintains the UI state (`PageTreeState`), including:
     - `rootNodes`: Processed tree structure.
     - `selectedPageId`: Currently open page in workspace.
     - `expandedPageIds`: Set of page IDs currently expanded in the sidebar.
     - `searchQuery`: Quick filter query (automatically expands ancestors of matching pages).

---

## 3. Caveats

1. **Rebalancing Limit on Doubles**:
   - IEEE 754 64-bit doubles provide 53 bits of precision (~15-17 significant decimal digits). Consecutive insertions at the exact same location after ~50 drag operations will hit machine precision limit. `DoubleFractionalIndexer.needsRebalance` detects when `|next - prev| < 1e-6`, and triggers a batch re-spread `(i + 1) * 1000.0`.
2. **Deeply Nested Virtualization**:
   - Flutter's `ListView.builder` renders virtualized flat lists. If an expanded tree contains hundreds of nodes, nesting multiple `Column`s recursively causes unvirtualized layout thrashing. Therefore, `PageTreeUtils.flattenTree` flattens the expanded nodes into a 1D list with indentation padding, maintaining 60fps scrolling on mobile and desktop.
3. **Persisting Expansion State**:
   - In-memory expansion state is held in `PageTreeState.expandedPageIds`. For cross-session persistence, implementers can optionally persist this set into `shared_preferences`.

---

## 4. Conclusion & File-by-File Implementation Plan

### 4.1 Summary of Modules to Implement
| File Path | Layer | Responsibility |
|---|---|---|
| `lib/features/workspace_editor/domain/models/page_entity.dart` | Domain | Immutable domain entity for Notion pages |
| `lib/features/workspace_editor/domain/models/page_tree_node.dart` | Domain | Recursive N-ary tree node with depth and expansion flags |
| `lib/features/workspace_editor/domain/utils/page_tree_utils.dart` | Domain | Tree builder, flattener, cycle detector, and breadcrumbs |
| `lib/core/utils/fractional_indexer.dart` | Core | Pure Dart LexoRank: double & base-36 string midpoint engine |
| `lib/features/workspace_editor/domain/repositories/i_workspace_repository.dart` | Domain | Repository contract for pages and blocks |
| `lib/features/workspace_editor/presentation/controllers/page_tree_state.dart` | Presentation | Immutable state for tree navigation and search |
| `lib/features/workspace_editor/presentation/controllers/page_tree_cubit.dart` | Presentation | Reactive BLoC/Cubit for tree operations and drag-and-drop |
| `lib/features/workspace_editor/presentation/widgets/page_tree_sidebar.dart` | Presentation | Complete sidebar widget with header, search, list, footer |
| `lib/features/workspace_editor/presentation/widgets/page_tree_item.dart` | Presentation | Interactive row with 3-zone drop target and hover actions |
| `lib/features/workspace_editor/presentation/widgets/page_breadcrumbs.dart` | Presentation | Breadcrumb path with clickable ancestors and overflow |
| `lib/features/workspace_editor/presentation/widgets/page_action_dialogs.dart` | Presentation | Dialogs for Rename, Icon/Emoji picker, and Delete confirmation |
| `test/widget/page_tree_test.dart` | Test | Widget test suite verifying AC1 (nesting, drag-drop, cycle prevention) |
| `test/unit/fractional_indexer_test.dart` | Test | Unit tests for LexoRank and midpoint calculations |
| `test/unit/page_tree_utils_test.dart` | Test | Unit tests for tree building, breadcrumbs, and cycle detection |

---

### 4.2 Complete Code Templates

#### File 1: `lib/features/workspace_editor/domain/models/page_entity.dart`
```dart
import 'package:flutter/foundation.dart';

@immutable
class PageEntity {
  final String id;
  final String? parentPageId;
  final String title;
  final String? icon;
  final String? coverImageUrl;
  final bool isDatabaseRow;
  final bool isArchived;
  final double sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PageEntity({
    required this.id,
    this.parentPageId,
    required this.title,
    this.icon,
    this.coverImageUrl,
    this.isDatabaseRow = false,
    this.isArchived = false,
    this.sortOrder = 0.0,
    required this.createdAt,
    required this.updatedAt,
  });

  PageEntity copyWith({
    String? id,
    String? parentPageId,
    bool clearParentPageId = false,
    String? title,
    String? icon,
    bool clearIcon = false,
    String? coverImageUrl,
    bool clearCoverImageUrl = false,
    bool? isDatabaseRow,
    bool? isArchived,
    double? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PageEntity(
      id: id ?? this.id,
      parentPageId: clearParentPageId ? null : (parentPageId ?? this.parentPageId),
      title: title ?? this.title,
      icon: clearIcon ? null : (icon ?? this.icon),
      coverImageUrl: clearCoverImageUrl ? null : (coverImageUrl ?? this.coverImageUrl),
      isDatabaseRow: isDatabaseRow ?? this.isDatabaseRow,
      isArchived: isArchived ?? this.isArchived,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PageEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          parentPageId == other.parentPageId &&
          title == other.title &&
          icon == other.icon &&
          coverImageUrl == other.coverImageUrl &&
          isDatabaseRow == other.isDatabaseRow &&
          isArchived == other.isArchived &&
          sortOrder == other.sortOrder;

  @override
  int get hashCode =>
      id.hashCode ^
      parentPageId.hashCode ^
      title.hashCode ^
      icon.hashCode ^
      coverImageUrl.hashCode ^
      isDatabaseRow.hashCode ^
      isArchived.hashCode ^
      sortOrder.hashCode;
}
```

---

#### File 2: `lib/features/workspace_editor/domain/models/page_tree_node.dart`
```dart
import 'package:flutter/foundation.dart';
import 'page_entity.dart';

@immutable
class PageTreeNode {
  final PageEntity page;
  final List<PageTreeNode> children;
  final int depth;
  final bool isExpanded;

  const PageTreeNode({
    required this.page,
    this.children = const [],
    this.depth = 0,
    this.isExpanded = false,
  });

  bool get hasChildren => children.isNotEmpty;

  PageTreeNode copyWith({
    PageEntity? page,
    List<PageTreeNode>? children,
    int? depth,
    bool? isExpanded,
  }) {
    return PageTreeNode(
      page: page ?? this.page,
      children: children ?? this.children,
      depth: depth ?? this.depth,
      isExpanded: isExpanded ?? this.isExpanded,
    );
  }
}
```

---

#### File 3: `lib/features/workspace_editor/domain/utils/page_tree_utils.dart`
```dart
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
          while (currentParentId != null && pageMap.containsKey(currentParentId)) {
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
```

---

#### File 4: `lib/core/utils/fractional_indexer.dart`
```dart
import 'dart:math';

/// High-performance Fractional Indexing & LexoRank Utility in pure Dart.
///
/// Provides:
/// 1. [DoubleFractionalIndexer] for Float64 database columns (`pages.sort_order`).
/// 2. [StringLexoRank] for infinite-precision string keys (`blocks.order_key`).
class FractionalIndexer {
  static const double defaultStep = 1000.0;
  static const double initialOrder = 1000.0;
  static const double minRebalanceDelta = 1e-6;

  /// Generates a midpoint double sort order between [prev] and [next].
  static double betweenDoubles(double? prev, double? next) {
    if (prev == null && next == null) {
      return initialOrder;
    }
    if (prev == null && next != null) {
      return next <= 0 ? next - defaultStep : next / 2.0;
    }
    if (prev != null && next == null) {
      return prev + defaultStep;
    }
    // Both non-null
    final p = prev!;
    final n = next!;
    if (p >= n) {
      // Degenerate condition: fallback to offset
      return p + (defaultStep / 2.0);
    }
    return (p + n) / 2.0;
  }

  /// Determines if precision limit is reached between siblings, requiring a rebalance.
  static bool needsRebalance(double prev, double next, {double minDelta = minRebalanceDelta}) {
    return (next - prev).abs() < minDelta;
  }

  /// Rebalances an entire sibling group evenly.
  static List<double> rebalanceDoubles(int count, {double start = defaultStep, double step = defaultStep}) {
    return List.generate(count, (index) => start + (index * step));
  }
}

/// Pure Dart Base-36 LexoRank string generator for Notion blocks & custom properties.
class StringLexoRank {
  static const String alphabet = '0123456789abcdefghijklmnopqrstuvwxyz';
  static const int base = 36;
  static const String initial = 'm';

  static final Map<String, int> _charToVal = {
    for (int i = 0; i < alphabet.length; i++) alphabet[i]: i,
  };

  /// Generates a lexicographical midpoint string between [prev] and [next].
  static String between(String? prev, String? next) {
    if (prev == null && next == null) return initial;
    if (prev == null && next != null) return _before(next);
    if (prev != null && next == null) return _after(prev);

    final p = prev!;
    final n = next!;
    assert(p.compareTo(n) < 0, 'prev "$p" must be lexicographically smaller than next "$n"');

    int index = 0;
    while (index < p.length && index < n.length && p[index] == n[index]) {
      index++;
    }

    final pVal = (index < p.length) ? _charToVal[p[index]]! : 0;
    final nVal = (index < n.length) ? _charToVal[n[index]]! : base;

    if (nVal - pVal > 1) {
      // Middle character available at this index
      final midVal = (pVal + nVal) ~/ 2;
      return p.substring(0, index) + alphabet[midVal];
    }

    // Consecutive characters: append midpoint of remaining suffix
    if (index + 1 < p.length) {
      final subMid = between(p.substring(index + 1), null);
      return p.substring(0, index + 1) + subMid;
    }

    return p + alphabet[base ~/ 2];
  }

  static String _before(String next) {
    if (next.isEmpty) return initial;
    final firstCharVal = _charToVal[next[0]]!;
    if (firstCharVal > 0) {
      final mid = firstCharVal ~/ 2;
      return alphabet[mid];
    }
    // Starts with '0', prepend or divide
    return '0' + between(null, next.substring(1));
  }

  static String _after(String prev) {
    if (prev.isEmpty) return initial;
    final lastCharVal = _charToVal[prev[prev.length - 1]]!;
    if (lastCharVal < base - 1) {
      final mid = (lastCharVal + base) ~/ 2;
      return prev.substring(0, prev.length - 1) + alphabet[mid];
    }
    return prev + alphabet[base ~/ 2];
  }
}
```

---

#### File 5: `lib/features/workspace_editor/domain/repositories/i_workspace_repository.dart`
```dart
import '../models/page_entity.dart';

abstract class IWorkspaceRepository {
  /// Watches all pages in the workspace reactively.
  Stream<List<PageEntity>> watchPageTree();

  /// Creates a new page.
  Future<PageEntity> createPage({
    String? parentPageId,
    required String title,
    String? icon,
    bool isDatabaseRow = false,
    double? sortOrder,
  });

  /// Updates page hierarchy and sort order (drag-and-drop re-parenting).
  Future<void> updatePageParent({
    required String pageId,
    String? newParentPageId,
    required double newSortOrder,
  });

  /// Renames a page.
  Future<void> updatePageTitle({
    required String pageId,
    required String title,
  });

  /// Updates a page's icon or emoji.
  Future<void> updatePageIcon({
    required String pageId,
    String? icon,
  });

  /// Archives or soft-deletes a page and all its descendants.
  Future<void> archivePage({
    required String pageId,
  });

  /// Batch re-balances sort orders of siblings when precision delta is exceeded.
  Future<void> batchUpdateSortOrders(Map<String, double> pageSortOrders);
}
```

---

#### File 6: `lib/features/workspace_editor/presentation/controllers/page_tree_state.dart`
```dart
import 'package:flutter/foundation.dart';
import '../../domain/models/page_entity.dart';
import '../../domain/models/page_tree_node.dart';

enum PageTreeStatus { initial, loading, loaded, error }

@immutable
class PageTreeState {
  final PageTreeStatus status;
  final List<PageEntity> allPages;
  final List<PageTreeNode> rootNodes;
  final List<PageTreeNode> flattenedNodes;
  final String? selectedPageId;
  final Set<String> expandedPageIds;
  final String searchQuery;
  final String? errorMessage;

  const PageTreeState({
    this.status = PageTreeStatus.initial,
    this.allPages = const [],
    this.rootNodes = const [],
    this.flattenedNodes = const [],
    this.selectedPageId,
    this.expandedPageIds = const {},
    this.searchQuery = '',
    this.errorMessage,
  });

  Map<String, PageEntity> get pageMap => {
        for (final p in allPages) p.id: p,
      };

  PageEntity? get selectedPage =>
      selectedPageId != null ? pageMap[selectedPageId] : null;

  PageTreeState copyWith({
    PageTreeStatus? status,
    List<PageEntity>? allPages,
    List<PageTreeNode>? rootNodes,
    List<PageTreeNode>? flattenedNodes,
    String? selectedPageId,
    bool clearSelectedPageId = false,
    Set<String>? expandedPageIds,
    String? searchQuery,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return PageTreeState(
      status: status ?? this.status,
      allPages: allPages ?? this.allPages,
      rootNodes: rootNodes ?? this.rootNodes,
      flattenedNodes: flattenedNodes ?? this.flattenedNodes,
      selectedPageId: clearSelectedPageId ? null : (selectedPageId ?? this.selectedPageId),
      expandedPageIds: expandedPageIds ?? this.expandedPageIds,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
```

---

#### File 7: `lib/features/workspace_editor/presentation/controllers/page_tree_cubit.dart`
```dart
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/models/page_entity.dart';
import '../../domain/models/page_tree_node.dart';
import '../../domain/repositories/i_workspace_repository.dart';
import '../../domain/utils/page_tree_utils.dart';
import '../../../../core/utils/fractional_indexer.dart';
import 'page_tree_state.dart';

enum DropPosition { before, inside, after }

class PageTreeCubit extends Cubit<PageTreeState> {
  final IWorkspaceRepository _repository;
  final PageTreeUtils _treeUtils;
  StreamSubscription<List<PageEntity>>? _treeSubscription;

  PageTreeCubit({
    required IWorkspaceRepository repository,
    PageTreeUtils treeUtils = const PageTreeUtils(),
  })  : _repository = repository,
        _treeUtils = treeUtils,
        super(const PageTreeState()) {
    _init();
  }

  void _init() {
    emit(state.copyWith(status: PageTreeStatus.loading));
    _treeSubscription = _repository.watchPageTree().listen(
      (pages) {
        _rebuildTree(pages: pages);
      },
      onError: (error) {
        emit(state.copyWith(
          status: PageTreeStatus.error,
          errorMessage: error.toString(),
        ));
      },
    );
  }

  void _rebuildTree({
    List<PageEntity>? pages,
    Set<String>? expandedIds,
    String? query,
  }) {
    final effectivePages = pages ?? state.allPages;
    final effectiveExpandedIds = expandedIds ?? state.expandedPageIds;
    final effectiveQuery = query ?? state.searchQuery;

    final roots = _treeUtils.buildTree(
      pages: effectivePages,
      expandedPageIds: effectiveExpandedIds,
      searchQuery: effectiveQuery,
    );
    final flattened = _treeUtils.flattenTree(roots);

    emit(state.copyWith(
      status: PageTreeStatus.loaded,
      allPages: effectivePages,
      rootNodes: roots,
      flattenedNodes: flattened,
      expandedPageIds: effectiveExpandedIds,
      searchQuery: effectiveQuery,
      clearErrorMessage: true,
    ));
  }

  /// Selects a page and ensures all its ancestors are expanded in the sidebar.
  void selectPage(String pageId) {
    final updatedExpanded = Set<String>.from(state.expandedPageIds);
    var currentParentId = state.pageMap[pageId]?.parentPageId;
    while (currentParentId != null && state.pageMap.containsKey(currentParentId)) {
      updatedExpanded.add(currentParentId);
      currentParentId = state.pageMap[currentParentId]?.parentPageId;
    }

    emit(state.copyWith(
      selectedPageId: pageId,
      expandedPageIds: updatedExpanded,
    ));
    _rebuildTree(expandedIds: updatedExpanded);
  }

  /// Toggles node expansion (chevron click).
  void toggleNodeExpanded(String pageId) {
    final updated = Set<String>.from(state.expandedPageIds);
    if (updated.contains(pageId)) {
      updated.remove(pageId);
    } else {
      updated.add(pageId);
    }
    _rebuildTree(expandedIds: updated);
  }

  /// Sets search query and filters tree.
  void setSearchQuery(String query) {
    _rebuildTree(query: query);
  }

  /// Creates a new sub-page.
  Future<PageEntity?> createSubPage({
    String? parentPageId,
    String title = 'Untitled',
    String? icon = '📄',
  }) async {
    try {
      // Find maximum sort order among current siblings
      final siblings = state.allPages
          .where((p) => p.parentPageId == parentPageId && !p.isArchived)
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      final lastOrder = siblings.isNotEmpty ? siblings.last.sortOrder : null;
      final newSortOrder = FractionalIndexer.betweenDoubles(lastOrder, null);

      final newPage = await _repository.createPage(
        parentPageId: parentPageId,
        title: title,
        icon: icon,
        sortOrder: newSortOrder,
      );

      // Auto-expand parent and select new page
      final updatedExpanded = Set<String>.from(state.expandedPageIds);
      if (parentPageId != null) updatedExpanded.add(parentPageId);

      emit(state.copyWith(
        selectedPageId: newPage.id,
        expandedPageIds: updatedExpanded,
      ));
      return newPage;
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to create page: $e'));
      return null;
    }
  }

  /// Handles drag-and-drop reordering and re-parenting.
  Future<void> handleDrop({
    required String movingPageId,
    required String targetPageId,
    required DropPosition position,
  }) async {
    final pageMap = state.pageMap;
    final movingPage = pageMap[movingPageId];
    final targetPage = pageMap[targetPageId];

    if (movingPage == null || targetPage == null) return;
    if (movingPageId == targetPageId) return;

    String? newParentId;
    double newSortOrder;

    if (position == DropPosition.inside) {
      // Re-parent as child of targetPage
      newParentId = targetPage.id;

      // Cycle prevention
      if (!_treeUtils.canReparent(movingPageId: movingPageId, targetParentId: newParentId, pageMap: pageMap)) {
        emit(state.copyWith(errorMessage: 'Cannot move a page into its own descendant!'));
        return;
      }

      // Find last child under targetPage
      final children = state.allPages
          .where((p) => p.parentPageId == targetPage.id && p.id != movingPageId && !p.isArchived)
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      final lastChildOrder = children.isNotEmpty ? children.last.sortOrder : null;
      newSortOrder = FractionalIndexer.betweenDoubles(lastChildOrder, null);

      // Auto-expand target page
      final updatedExpanded = Set<String>.from(state.expandedPageIds)..add(targetPage.id);
      emit(state.copyWith(expandedPageIds: updatedExpanded));
    } else {
      // Sibling insertion (before or after targetPage)
      newParentId = targetPage.parentPageId;

      // Cycle prevention
      if (!_treeUtils.canReparent(movingPageId: movingPageId, targetParentId: newParentId, pageMap: pageMap)) {
        emit(state.copyWith(errorMessage: 'Cannot move page into descendant hierarchy!'));
        return;
      }

      final siblings = state.allPages
          .where((p) => p.parentPageId == newParentId && p.id != movingPageId && !p.isArchived)
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      final targetIndex = siblings.indexWhere((p) => p.id == targetPageId);
      if (targetIndex == -1) return;

      if (position == DropPosition.before) {
        final prevOrder = targetIndex > 0 ? siblings[targetIndex - 1].sortOrder : null;
        final nextOrder = siblings[targetIndex].sortOrder;
        newSortOrder = FractionalIndexer.betweenDoubles(prevOrder, nextOrder);
      } else {
        // after
        final prevOrder = siblings[targetIndex].sortOrder;
        final nextOrder = (targetIndex + 1 < siblings.length) ? siblings[targetIndex + 1].sortOrder : null;
        newSortOrder = FractionalIndexer.betweenDoubles(prevOrder, nextOrder);
      }
    }

    try {
      await _repository.updatePageParent(
        pageId: movingPageId,
        newParentPageId: newParentId,
        newSortOrder: newSortOrder,
      );
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to update page position: $e'));
    }
  }

  /// Renames a page.
  Future<void> renamePage(String pageId, String newTitle) async {
    try {
      await _repository.updatePageTitle(pageId: pageId, title: newTitle);
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to rename page: $e'));
    }
  }

  /// Updates page icon / emoji.
  Future<void> updateIcon(String pageId, String? icon) async {
    try {
      await _repository.updatePageIcon(pageId: pageId, icon: icon);
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to update icon: $e'));
    }
  }

  /// Deletes / archives a page.
  Future<void> deletePage(String pageId) async {
    try {
      await _repository.archivePage(pageId: pageId);
      if (state.selectedPageId == pageId) {
        emit(state.copyWith(clearSelectedPageId: true));
      }
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to delete page: $e'));
    }
  }

  @override
  Future<void> close() {
    _treeSubscription?.cancel();
    return super.close();
  }
}
```

---

#### File 8: `lib/features/workspace_editor/presentation/widgets/page_tree_sidebar.dart`
```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../controllers/page_tree_cubit.dart';
import '../controllers/page_tree_state.dart';
import 'page_tree_item.dart';

class PageTreeSidebar extends StatelessWidget {
  final VoidCallback? onNewPagePressed;

  const PageTreeSidebar({
    super.key,
    this.onNewPagePressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: theme.dividerColor.withOpacity(0.15),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Workspace Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('هم‌پا', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'HamPA Workspace',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 20),
                  tooltip: 'New Root Page',
                  onPressed: () {
                    context.read<PageTreeCubit>().createSubPage(parentPageId: null);
                  },
                ),
              ],
            ),
          ),

          // 2. Search / Quick Filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search pages...',
                prefixIcon: const Icon(Icons.search, size: 18),
                isDense: true,
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (query) {
                context.read<PageTreeCubit>().setSearchQuery(query);
              },
            ),
          ),

          const Divider(height: 16),

          // 3. Tree Node List (Virtualized Flattened View)
          Expanded(
            child: BlocConsumer<PageTreeCubit, PageTreeState>(
              listener: (context, state) {
                if (state.errorMessage != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.errorMessage!),
                      backgroundColor: theme.colorScheme.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state.status == PageTreeStatus.loading && state.allPages.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.flattenedNodes.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.note_alt_outlined, size: 40, color: theme.disabledColor),
                          const SizedBox(height: 8),
                          Text(
                            state.searchQuery.isNotEmpty
                                ? 'No pages match "${state.searchQuery}"'
                                : 'No pages yet',
                            style: theme.textTheme.bodyMedium?.copyWith(color: theme.disabledColor),
                            textAlign: TextAlign.center,
                          ),
                          if (state.searchQuery.isEmpty) ...[
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Create a page'),
                              onPressed: () {
                                context.read<PageTreeCubit>().createSubPage(parentPageId: null);
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: state.flattenedNodes.length,
                  itemBuilder: (context, index) {
                    final node = state.flattenedNodes[index];
                    return PageTreeItem(
                      key: ValueKey(node.page.id),
                      node: node,
                      isSelected: state.selectedPageId == node.page.id,
                      pageMap: state.pageMap,
                    );
                  },
                );
              },
            ),
          ),

          // 4. Footer
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: theme.dividerColor.withOpacity(0.1))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add page'),
                    style: TextButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      foregroundColor: theme.textTheme.bodyMedium?.color,
                    ),
                    onPressed: () {
                      context.read<PageTreeCubit>().createSubPage(parentPageId: null);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

---

#### File 9: `lib/features/workspace_editor/presentation/widgets/page_tree_item.dart`
```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/models/page_entity.dart';
import '../../domain/models/page_tree_node.dart';
import '../../domain/utils/page_tree_utils.dart';
import '../controllers/page_tree_cubit.dart';
import 'page_action_dialogs.dart';

class PageDragData {
  final String pageId;
  const PageDragData(this.pageId);
}

class PageTreeItem extends StatefulWidget {
  final PageTreeNode node;
  final bool isSelected;
  final Map<String, PageEntity> pageMap;

  const PageTreeItem({
    super.key,
    required this.node,
    required this.isSelected,
    required this.pageMap,
  });

  @override
  State<PageTreeItem> createState() => _PageTreeItemState();
}

class _PageTreeItemState extends State<PageTreeItem> {
  bool _isHovered = false;
  DropPosition? _activeDropPosition;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final page = widget.node.page;
    final cubit = context.read<PageTreeCubit>();
    final treeUtils = const PageTreeUtils();

    // Visual drop feedback
    BoxDecoration? targetDecoration;
    if (_activeDropPosition == DropPosition.inside) {
      targetDecoration = BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: theme.colorScheme.primary, width: 1.5),
      );
    }

    final double indent = (widget.node.depth * 16.0) + 8.0;

    return DragTarget<PageDragData>(
      onWillAcceptWithDetails: (details) {
        final draggedId = details.data.pageId;
        if (draggedId == page.id) return false; // Cannot drop on self

        // Cycle check: cannot drop onto any descendant
        final isDescendant = treeUtils.isDescendant(
          candidateChildId: page.id,
          candidateAncestorId: draggedId,
          pageMap: widget.pageMap,
        );
        return !isDescendant;
      },
      onMove: (details) {
        final renderBox = context.findRenderObject() as RenderBox?;
        if (renderBox == null) return;
        final localOffset = renderBox.globalToLocal(details.offset);
        final height = renderBox.size.height;

        DropPosition newPos;
        if (localOffset.dy < height * 0.25) {
          newPos = DropPosition.before;
        } else if (localOffset.dy > height * 0.75) {
          newPos = DropPosition.after;
        } else {
          newPos = DropPosition.inside;
        }

        if (_activeDropPosition != newPos) {
          setState(() => _activeDropPosition = newPos);
        }
      },
      onLeave: (_) {
        setState(() => _activeDropPosition = null);
      },
      onAcceptWithDetails: (details) {
        final pos = _activeDropPosition ?? DropPosition.inside;
        setState(() => _activeDropPosition = null);
        cubit.handleDrop(
          movingPageId: details.data.pageId,
          targetPageId: page.id,
          position: pos,
        );
      },
      builder: (context, candidateData, rejectedData) {
        return Stack(
          children: [
            MouseRegion(
              onEnter: (_) => setState(() => _isHovered = true),
              onExit: (_) => setState(() => _isHovered = false),
              child: LongPressDraggable<PageDragData>(
                data: PageDragData(page.id),
                delay: const Duration(milliseconds: 150),
                feedback: Material(
                  elevation: 6,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: theme.colorScheme.primary, width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(page.icon ?? '📄', style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        Text(
                          page.title.isEmpty ? 'Untitled' : page.title,
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                childWhenDragging: Opacity(
                  opacity: 0.3,
                  child: _buildItemRow(context, indent, targetDecoration),
                ),
                child: _buildItemRow(context, indent, targetDecoration),
              ),
            ),

            // Top Drop Indicator Line (DropPosition.before)
            if (_activeDropPosition == DropPosition.before)
              Positioned(
                top: 0,
                left: indent,
                right: 8,
                child: Container(height: 2.5, color: theme.colorScheme.primary),
              ),

            // Bottom Drop Indicator Line (DropPosition.after)
            if (_activeDropPosition == DropPosition.after)
              Positioned(
                bottom: 0,
                left: indent,
                right: 8,
                child: Container(height: 2.5, color: theme.colorScheme.primary),
              ),
          ],
        );
      },
    );
  }

  Widget _buildItemRow(BuildContext context, double indent, BoxDecoration? targetDecoration) {
    final theme = Theme.of(context);
    final page = widget.node.page;
    final cubit = context.read<PageTreeCubit>();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: targetDecoration ??
          BoxDecoration(
            color: widget.isSelected
                ? theme.colorScheme.primaryContainer.withOpacity(0.6)
                : (_isHovered ? theme.colorScheme.surfaceContainerHighest.withOpacity(0.3) : Colors.transparent),
            borderRadius: BorderRadius.circular(6),
          ),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () => cubit.selectPage(page.id),
        child: Padding(
          padding: EdgeInsets.fromLTRB(indent, 4, 8, 4),
          child: Row(
            children: [
              // Chevron Toggle
              SizedBox(
                width: 22,
                height: 22,
                child: widget.node.hasChildren
                    ? IconButton(
                        padding: EdgeInsets.zero,
                        iconSize: 16,
                        icon: AnimatedRotation(
                          turns: widget.node.isExpanded ? 0.25 : 0.0,
                          duration: const Duration(milliseconds: 180),
                          child: const Icon(Icons.chevron_right),
                        ),
                        onPressed: () => cubit.toggleNodeExpanded(page.id),
                      )
                    : const SizedBox.shrink(),
              ),

              const SizedBox(width: 4),

              // Page Icon / Emoji
              GestureDetector(
                onTap: () => PageActionDialogs.showEmojiPicker(context, page),
                child: Text(
                  page.icon ?? '📄',
                  style: const TextStyle(fontSize: 15),
                ),
              ),

              const SizedBox(width: 8),

              // Page Title
              Expanded(
                child: Text(
                  page.title.isEmpty ? 'Untitled' : page.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: widget.isSelected ? theme.colorScheme.primary : null,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Database Row indicator badge if applicable
              if (page.isDatabaseRow)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('ROW', style: TextStyle(fontSize: 9, color: theme.colorScheme.onSecondaryContainer)),
                ),

              // Action Buttons (visible on hover or selection)
              if (_isHovered || widget.isSelected) ...[
                IconButton(
                  icon: const Icon(Icons.add, size: 16),
                  tooltip: 'Add sub-page',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                  onPressed: () => cubit.createSubPage(parentPageId: page.id),
                ),
                IconButton(
                  icon: const Icon(Icons.more_horiz, size: 16),
                  tooltip: 'Page options',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                  onPressed: () => PageActionDialogs.showPageMenu(context, page),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
```

---

#### File 10: `lib/features/workspace_editor/presentation/widgets/page_breadcrumbs.dart`
```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/models/page_entity.dart';
import '../../domain/utils/page_tree_utils.dart';
import '../controllers/page_tree_cubit.dart';
import '../controllers/page_tree_state.dart';

class PageBreadcrumbs extends StatelessWidget {
  const PageBreadcrumbs({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final treeUtils = const PageTreeUtils();

    return BlocBuilder<PageTreeCubit, PageTreeState>(
      buildWhen: (prev, curr) =>
          prev.selectedPageId != curr.selectedPageId || prev.allPages != curr.allPages,
      builder: (context, state) {
        if (state.selectedPageId == null) {
          return const SizedBox.shrink();
        }

        final breadcrumbs = treeUtils.getBreadcrumbs(
          pageId: state.selectedPageId!,
          pageMap: state.pageMap,
        );

        if (breadcrumbs.isEmpty) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              // Workspace root icon
              const Icon(Icons.home_outlined, size: 16, color: Colors.grey),
              const SizedBox(width: 4),

              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 4,
                  children: _buildBreadcrumbItems(context, breadcrumbs, theme),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildBreadcrumbItems(
    BuildContext context,
    List<PageEntity> items,
    ThemeData theme,
  ) {
    final List<Widget> widgets = [];
    final cubit = context.read<PageTreeCubit>();

    // Handle deep nesting (> 3 ancestors) with ellipsis dropdown
    if (items.length > 3) {
      // First item
      widgets.add(_crumbButton(context, items.first, cubit, theme));
      widgets.add(const Icon(Icons.chevron_right, size: 16, color: Colors.grey));

      // Middle collapsed dropdown
      final middleItems = items.sublist(1, items.length - 1);
      widgets.add(
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_horiz, size: 16),
          padding: EdgeInsets.zero,
          itemBuilder: (ctx) => middleItems
              .map(
                (p) => PopupMenuItem<String>(
                  value: p.id,
                  child: Row(
                    children: [
                      Text(p.icon ?? '📄'),
                      const SizedBox(width: 8),
                      Text(p.title.isEmpty ? 'Untitled' : p.title),
                    ],
                  ),
                ),
              )
              .toList(),
          onSelected: (id) => cubit.selectPage(id),
        ),
      );
      widgets.add(const Icon(Icons.chevron_right, size: 16, color: Colors.grey));

      // Last item (active)
      widgets.add(_activeCrumb(items.last, theme));
    } else {
      // 1 to 3 items
      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        final isLast = i == items.length - 1;

        if (isLast) {
          widgets.add(_activeCrumb(item, theme));
        } else {
          widgets.add(_crumbButton(context, item, cubit, theme));
          widgets.add(const Icon(Icons.chevron_right, size: 16, color: Colors.grey));
        }
      }
    }

    return widgets;
  }

  Widget _crumbButton(BuildContext context, PageEntity page, PageTreeCubit cubit, ThemeData theme) {
    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: () => cubit.selectPage(page.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(page.icon ?? '📄', style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(
              page.title.isEmpty ? 'Untitled' : page.title,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _activeCrumb(PageEntity page, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(page.icon ?? '📄', style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(
            page.title.isEmpty ? 'Untitled' : page.title,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
```

---

#### File 11: `lib/features/workspace_editor/presentation/widgets/page_action_dialogs.dart`
```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/models/page_entity.dart';
import '../controllers/page_tree_cubit.dart';

class PageActionDialogs {
  /// Opens options menu for a page.
  static void showPageMenu(BuildContext context, PageEntity page) {
    final cubit = context.read<PageTreeCubit>();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Text(page.icon ?? '📄', style: const TextStyle(fontSize: 22)),
              title: Text(page.title.isEmpty ? 'Untitled' : page.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(page.isDatabaseRow ? 'Database Record' : 'Workspace Document'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Rename page'),
              onTap: () {
                Navigator.pop(ctx);
                showRenameDialog(context, page);
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_box_outlined),
              title: const Text('Add sub-page'),
              onTap: () {
                Navigator.pop(ctx);
                cubit.createSubPage(parentPageId: page.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.emoji_emotions_outlined),
              title: const Text('Change icon'),
              onTap: () {
                Navigator.pop(ctx);
                showEmojiPicker(context, page);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete page', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                showDeleteConfirmation(context, page);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Dialog to rename a page.
  static void showRenameDialog(BuildContext context, PageEntity page) {
    final controller = TextEditingController(text: page.title);
    final cubit = context.read<PageTreeCubit>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Page'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Page Title',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              cubit.renamePage(page.id, value.trim());
              Navigator.pop(ctx);
            }
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                cubit.renamePage(page.id, controller.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  /// Emoji and icon selection sheet.
  static void showEmojiPicker(BuildContext context, PageEntity page) {
    const emojis = ['📄', '📝', '📚', '🎯', '💡', '🔬', '💻', '📅', '⏰', '⚡', '🏆', '🔥', '📊', '🎨', '🧠', '🌿'];
    final cubit = context.read<PageTreeCubit>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Choose Page Icon'),
        content: SizedBox(
          width: 280,
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: emojis
                .map(
                  (emoji) => InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      cubit.updateIcon(page.id, emoji);
                      Navigator.pop(ctx);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(emoji, style: const TextStyle(fontSize: 28)),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              cubit.updateIcon(page.id, null);
              Navigator.pop(ctx);
            },
            child: const Text('Remove Icon'),
          ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  /// Delete confirmation dialog.
  static void showDeleteConfirmation(BuildContext context, PageEntity page) {
    final cubit = context.read<PageTreeCubit>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Page?'),
        content: Text('Are you sure you want to delete "${page.title.isEmpty ? 'Untitled' : page.title}"? Sub-pages will also be archived.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              cubit.deletePage(page.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
```

---

#### File 12: `test/widget/page_tree_test.dart`
```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:hampa/features/workspace_editor/domain/models/page_entity.dart';
import 'package:hampa/features/workspace_editor/domain/repositories/i_workspace_repository.dart';
import 'package:hampa/features/workspace_editor/presentation/controllers/page_tree_cubit.dart';
import 'package:hampa/features/workspace_editor/presentation/widgets/page_tree_sidebar.dart';
import 'package:hampa/features/workspace_editor/presentation/widgets/page_breadcrumbs.dart';
import 'package:hampa/features/workspace_editor/presentation/widgets/page_tree_item.dart';

class MockWorkspaceRepository extends Mock implements IWorkspaceRepository {}

void main() {
  late MockWorkspaceRepository mockRepo;
  late StreamController<List<PageEntity>> pageStreamController;

  final testPages = [
    PageEntity(
      id: 'root_1',
      title: 'Calculus Notes',
      icon: '📚',
      sortOrder: 1000.0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    PageEntity(
      id: 'sub_1_1',
      parentPageId: 'root_1',
      title: 'Derivatives',
      icon: '📝',
      sortOrder: 1000.0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    PageEntity(
      id: 'sub_1_2',
      parentPageId: 'root_1',
      title: 'Integrals',
      icon: '📐',
      sortOrder: 2000.0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    PageEntity(
      id: 'root_2',
      title: 'Physics Mechanics',
      icon: '⚡',
      sortOrder: 2000.0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  setUp(() {
    mockRepo = MockWorkspaceRepository();
    pageStreamController = StreamController<List<PageEntity>>.broadcast();

    when(() => mockRepo.watchPageTree()).thenAnswer((_) => pageStreamController.stream);
    when(() => mockRepo.createPage(
          parentPageId: any(named: 'parentPageId'),
          title: any(named: 'title'),
          icon: any(named: 'icon'),
          sortOrder: any(named: 'sortOrder'),
        )).thenAnswer((invocation) async {
      return PageEntity(
        id: 'new_page_123',
        parentPageId: invocation.namedArguments[#parentPageId],
        title: invocation.namedArguments[#title],
        icon: invocation.namedArguments[#icon],
        sortOrder: invocation.namedArguments[#sortOrder] ?? 1000.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });
    when(() => mockRepo.updatePageParent(
          pageId: any(named: 'pageId'),
          newParentPageId: any(named: 'newParentPageId'),
          newSortOrder: any(named: 'newSortOrder'),
        )).thenAnswer((_) async {});
  });

  tearDown(() {
    pageStreamController.close();
  });

  Widget buildTestApp(PageTreeCubit cubit) {
    return MaterialApp(
      home: BlocProvider.value(
        value: cubit,
        child: const Scaffold(
          body: Row(
            children: [
              PageTreeSidebar(),
              Expanded(
                child: Column(
                  children: [
                    PageBreadcrumbs(),
                    Expanded(child: Center(child: Text('Workspace Editor Body'))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  testWidgets('AC1: Renders root pages and toggles expansion to show nested children', (tester) async {
    final cubit = PageTreeCubit(repository: mockRepo);
    await tester.pumpWidget(buildTestApp(cubit));

    // Emit test pages
    pageStreamController.add(testPages);
    await tester.pumpAndSettle();

    // Verify root pages rendered
    expect(find.text('Calculus Notes'), findsOneWidget);
    expect(find.text('Physics Mechanics'), findsOneWidget);

    // Verify sub-pages not visible initially (collapsed)
    expect(find.text('Derivatives'), findsNothing);
    expect(find.text('Integrals'), findsNothing);

    // Tap chevron on Calculus Notes
    final chevronFinder = find.byIcon(Icons.chevron_right).first;
    await tester.tap(chevronFinder);
    await tester.pumpAndSettle();

    // Verify sub-pages are now visible!
    expect(find.text('Derivatives'), findsOneWidget);
    expect(find.text('Integrals'), findsOneWidget);

    // Tap chevron again to collapse
    await tester.tap(chevronFinder);
    await tester.pumpAndSettle();

    expect(find.text('Derivatives'), findsNothing);
  });

  testWidgets('AC1: Selecting a nested page updates Breadcrumbs path', (tester) async {
    final cubit = PageTreeCubit(repository: mockRepo);
    await tester.pumpWidget(buildTestApp(cubit));

    pageStreamController.add(testPages);
    await tester.pumpAndSettle();

    // Expand Calculus Notes
    await tester.tap(find.byIcon(Icons.chevron_right).first);
    await tester.pumpAndSettle();

    // Tap on Derivatives
    await tester.tap(find.text('Derivatives'));
    await tester.pumpAndSettle();

    // Breadcrumbs should now display: Calculus Notes > Derivatives
    expect(find.byType(PageBreadcrumbs), findsOneWidget);
    expect(find.descendant(of: find.byType(PageBreadcrumbs), matching: find.text('Calculus Notes')), findsOneWidget);
    expect(find.descendant(of: find.byType(PageBreadcrumbs), matching: find.text('Derivatives')), findsOneWidget);
  });

  testWidgets('AC1: Search filter isolates matching pages and expands parent', (tester) async {
    final cubit = PageTreeCubit(repository: mockRepo);
    await tester.pumpWidget(buildTestApp(cubit));

    pageStreamController.add(testPages);
    await tester.pumpAndSettle();

    // Enter "Integrals" into search field
    await tester.enterText(find.byType(TextField), 'Integrals');
    await tester.pumpAndSettle();

    // Calculus Notes should be auto-expanded and show Integrals
    expect(find.text('Integrals'), findsOneWidget);
    expect(find.text('Calculus Notes'), findsOneWidget);
    // Physics Mechanics should be filtered out
    expect(find.text('Physics Mechanics'), findsNothing);
  });

  testWidgets('AC1: Cycle prevention rejects dragging parent into its own descendant', (tester) async {
    final cubit = PageTreeCubit(repository: mockRepo);
    await tester.pumpWidget(buildTestApp(cubit));

    pageStreamController.add(testPages);
    await tester.pumpAndSettle();

    // Verify cycle check logic:
    // Root_1 cannot be re-parented to sub_1_1!
    await cubit.handleDrop(
      movingPageId: 'root_1',
      targetPageId: 'sub_1_1',
      position: DropPosition.inside,
    );
    await tester.pumpAndSettle();

    // Verify repository updatePageParent was NOT called
    verifyNever(() => mockRepo.updatePageParent(
          pageId: any(named: 'pageId'),
          newParentPageId: any(named: 'newParentPageId'),
          newSortOrder: any(named: 'newSortOrder'),
        ));

    // Verify error state emitted
    expect(cubit.state.errorMessage, contains('Cannot move a page into its own descendant'));
  });

  testWidgets('AC1: Valid drag re-parenting calls repository with fractional sort order', (tester) async {
    final cubit = PageTreeCubit(repository: mockRepo);
    await tester.pumpWidget(buildTestApp(cubit));

    pageStreamController.add(testPages);
    await tester.pumpAndSettle();

    // Move 'Physics Mechanics' to be inside 'Calculus Notes'
    await cubit.handleDrop(
      movingPageId: 'root_2',
      targetPageId: 'root_1',
      position: DropPosition.inside,
    );
    await tester.pumpAndSettle();

    // Expected new sort order: after last child ('Integrals' sortOrder = 2000.0) -> 3000.0
    verify(() => mockRepo.updatePageParent(
          pageId: 'root_2',
          newParentPageId: 'root_1',
          newSortOrder: 3000.0,
        )).called(1);
  });
}
```

---

#### File 13: `test/unit/fractional_indexer_test.dart`
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hampa/core/utils/fractional_indexer.dart';

void main() {
  group('DoubleFractionalIndexer Tests', () {
    test('Calculates initial order when prev and next are null', () {
      expect(FractionalIndexer.betweenDoubles(null, null), equals(1000.0));
    });

    test('Inserts before first item', () {
      expect(FractionalIndexer.betweenDoubles(null, 1000.0), equals(500.0));
    });

    test('Inserts after last item', () {
      expect(FractionalIndexer.betweenDoubles(2000.0, null), equals(3000.0));
    });

    test('Calculates exact midpoint between siblings', () {
      expect(FractionalIndexer.betweenDoubles(1000.0, 2000.0), equals(1500.0));
      expect(FractionalIndexer.betweenDoubles(1000.0, 1500.0), equals(1250.0));
    });

    test('Detects precision rebalance threshold', () {
      expect(FractionalIndexer.needsRebalance(1.0, 1.00000001), isTrue);
      expect(FractionalIndexer.needsRebalance(1.0, 2.0), isFalse);
    });

    test('Rebalances items evenly', () {
      final rebalanced = FractionalIndexer.rebalanceDoubles(4);
      expect(rebalanced, equals([1000.0, 2000.0, 3000.0, 4000.0]));
    });
  });

  group('StringLexoRank Tests', () {
    test('Initial rank is m', () {
      expect(StringLexoRank.between(null, null), equals('m'));
    });

    test('Generates midpoint between a and c', () {
      expect(StringLexoRank.between('a', 'c'), equals('b'));
    });

    test('Generates suffix midpoint between consecutive characters a and b', () {
      final mid = StringLexoRank.between('a', 'b');
      expect(mid.compareTo('a'), greaterThan(0));
      expect(mid.compareTo('b'), lessThan(0));
      expect(mid, equals('ai'));
    });

    test('Generates order before first key', () {
      final beforeM = StringLexoRank.between(null, 'm');
      expect(beforeM.compareTo('m'), lessThan(0));
    });

    test('Generates order after last key', () {
      final afterM = StringLexoRank.between('m', null);
      expect(afterM.compareTo('m'), greaterThan(0));
    });
  });
}
```

---

#### File 14: `test/unit/page_tree_utils_test.dart`
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hampa/features/workspace_editor/domain/models/page_entity.dart';
import 'package:hampa/features/workspace_editor/domain/utils/page_tree_utils.dart';

void main() {
  const treeUtils = PageTreeUtils();

  final pages = [
    PageEntity(
      id: 'p1',
      title: 'Root 1',
      sortOrder: 100.0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    PageEntity(
      id: 'p1_1',
      parentPageId: 'p1',
      title: 'Child 1.1',
      sortOrder: 50.0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    PageEntity(
      id: 'p1_1_1',
      parentPageId: 'p1_1',
      title: 'Grandchild 1.1.1',
      sortOrder: 10.0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    PageEntity(
      id: 'p2',
      title: 'Root 2',
      sortOrder: 200.0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  final pageMap = {for (final p in pages) p.id: p};

  group('PageTreeUtils Cycle Prevention', () {
    test('Self is descendant of self', () {
      expect(treeUtils.isDescendant(candidateChildId: 'p1', candidateAncestorId: 'p1', pageMap: pageMap), isTrue);
      expect(treeUtils.canReparent(movingPageId: 'p1', targetParentId: 'p1', pageMap: pageMap), isFalse);
    });

    test('p1_1_1 is descendant of p1', () {
      expect(treeUtils.isDescendant(candidateChildId: 'p1_1_1', candidateAncestorId: 'p1', pageMap: pageMap), isTrue);
      // Cannot move p1 into p1_1_1
      expect(treeUtils.canReparent(movingPageId: 'p1', targetParentId: 'p1_1_1', pageMap: pageMap), isFalse);
    });

    test('p2 is NOT descendant of p1', () {
      expect(treeUtils.isDescendant(candidateChildId: 'p2', candidateAncestorId: 'p1', pageMap: pageMap), isFalse);
      // Can move p1 into p2
      expect(treeUtils.canReparent(movingPageId: 'p1', targetParentId: 'p2', pageMap: pageMap), isTrue);
    });
  });

  group('PageTreeUtils Breadcrumbs', () {
    test('Generates root to leaf breadcrumb path', () {
      final crumbs = treeUtils.getBreadcrumbs(pageId: 'p1_1_1', pageMap: pageMap);
      expect(crumbs.map((p) => p.id).toList(), equals(['p1', 'p1_1', 'p1_1_1']));
    });
  });

  group('PageTreeUtils Tree Builder', () {
    test('Constructs hierarchical tree with depth and sort order', () {
      final roots = treeUtils.buildTree(pages: pages, expandedPageIds: {'p1', 'p1_1'});
      expect(roots.length, equals(2));
      expect(roots[0].page.id, equals('p1'));
      expect(roots[0].depth, equals(0));
      expect(roots[0].children.length, equals(1));
      expect(roots[0].children[0].page.id, equals('p1_1'));
      expect(roots[0].children[0].depth, equals(1));
      expect(roots[0].children[0].children[0].page.id, equals('p1_1_1'));
      expect(roots[0].children[0].children[0].depth, equals(2));
    });
  });
}
```

---

## 5. Verification Method

### 5.1 Verification Commands
Once the Flutter SDK and scaffolding are generated by implementers, these tests can be run directly via:
```powershell
# 1. Run widget test suite for AC1
flutter test test/widget/page_tree_test.dart

# 2. Run unit tests for fractional indexer & LexoRank
dart test test/unit/fractional_indexer_test.dart

# 3. Run unit tests for page tree utils & cycle prevention
dart test test/unit/page_tree_utils_test.dart
```

### 5.2 Key Invalidation Conditions
- **Invalidation 1**: If cycle prevention is checked only on drop rather than in `onWillAcceptWithDetails`, the UI will allow hovering over forbidden descendants, leading to visual flickering or bad UX.
- **Invalidation 2**: If `sort_order` is computed using integer increments instead of fractional indexing, re-ordering items will trigger $O(N)$ database updates instead of $O(1)$.
- **Invalidation 3**: If nested page trees use unvirtualized recursive `Column`s, deep workspaces with >200 pages will experience severe frame drops and jank during scrolling. Using `PageTreeUtils.flattenTree` with `ListView.builder` guarantees 60fps performance.
