// Test Reference Harness: Workspace Engine
// Grounded in PROJECT.md (F01–F07, AC1, AC3)

import 'dart:async';
import '../contracts/workspace_contracts.dart';

class TestWorkspaceEngine implements IWorkspaceRepository {
  final Map<String, PageEntity> _pages = {};
  final Map<String, BlockEntity> _blocks = {};
  final Set<String> _pendingSyncItemIds = {};
  bool _isOnline = true;

  final StreamController<List<PageEntity>> _pageTreeController =
      StreamController<List<PageEntity>>.broadcast();
  final Map<String, StreamController<List<BlockEntity>>> _pageBlockControllers = {};

  TestWorkspaceEngine() {
    _notifyPageTree();
  }

  void _notifyPageTree() {
    final list = _pages.values.toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    _pageTreeController.add(list);
  }

  void _notifyPageBlocks(String pageId) {
    if (_pageBlockControllers.containsKey(pageId)) {
      final list = _blocks.values
          .where((b) => b.pageId == pageId)
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      _pageBlockControllers[pageId]!.add(list);
    }
  }

  @override
  bool get isOnline => _isOnline;

  @override
  void setNetworkOnline(bool isOnline) {
    _isOnline = isOnline;
  }

  @override
  Stream<List<PageEntity>> watchPageTree() => _pageTreeController.stream;

  @override
  Future<PageEntity> createPage({
    String? parentPageId,
    required String title,
    String? icon,
    bool isDatabaseRow = false,
  }) async {
    final id = 'page_${DateTime.now().microsecondsSinceEpoch}_${_pages.length}';
    final page = PageEntity(
      id: id,
      parentPageId: parentPageId,
      title: title,
      icon: icon,
      isDatabaseRow: isDatabaseRow,
      sortOrder: _pages.length.toDouble(),
    );
    _pages[id] = page;
    _pendingSyncItemIds.add(id);
    _notifyPageTree();
    return page;
  }

  @override
  Future<void> updatePageParent({
    required String pageId,
    String? newParentPageId,
    required double newSortOrder,
  }) async {
    final target = _pages[pageId];
    if (target == null) throw ArgumentError('Page not found: $pageId');

    // Cycle detection: cannot move page into its own descendant or itself
    if (newParentPageId != null) {
      if (newParentPageId == pageId) {
        throw StateError('Circular parenting detected: page cannot be its own parent');
      }
      var current = _pages[newParentPageId];
      while (current != null && current.parentPageId != null) {
        if (current.parentPageId == pageId) {
          throw StateError('Circular parenting detected: cannot move into descendant');
        }
        current = _pages[current.parentPageId];
      }
    }

    _pages[pageId] = target.copyWith(
      parentPageId: newParentPageId,
      clearParent: newParentPageId == null,
      sortOrder: newSortOrder,
    );
    _pendingSyncItemIds.add(pageId);
    _notifyPageTree();
  }

  @override
  Future<PageEntity?> getPage(String pageId) async => _pages[pageId];

  @override
  Future<List<PageEntity>> getChildPages(String? parentPageId) async {
    return _pages.values
        .where((p) => p.parentPageId == parentPageId)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  @override
  Future<void> deletePage(String pageId) async {
    // Delete page and cascade delete children
    final toDelete = <String>{pageId};
    void collectDescendants(String pid) {
      for (final p in _pages.values) {
        if (p.parentPageId == pid) {
          toDelete.add(p.id);
          collectDescendants(p.id);
        }
      }
    }
    collectDescendants(pageId);

    for (final id in toDelete) {
      _pages.remove(id);
      _blocks.removeWhere((k, b) => b.pageId == id);
      _pendingSyncItemIds.add(id);
    }
    _notifyPageTree();
  }

  @override
  Stream<List<BlockEntity>> watchBlocksForPage(String pageId) {
    if (!_pageBlockControllers.containsKey(pageId)) {
      _pageBlockControllers[pageId] = StreamController<List<BlockEntity>>.broadcast();
    }
    _notifyPageBlocks(pageId);
    return _pageBlockControllers[pageId]!.stream;
  }

  @override
  Future<List<BlockEntity>> getBlocksForPage(String pageId) async {
    return _blocks.values
        .where((b) => b.pageId == pageId)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  @override
  Future<void> insertBlock(BlockEntity block) async {
    _blocks[block.id] = block;
    _pendingSyncItemIds.add(block.id);
    _notifyPageBlocks(block.pageId);
  }

  @override
  Future<void> updateBlock(BlockEntity block) async {
    if (!_blocks.containsKey(block.id)) {
      throw ArgumentError('Block not found: ${block.id}');
    }
    _blocks[block.id] = block;
    _pendingSyncItemIds.add(block.id);
    _notifyPageBlocks(block.pageId);
  }

  @override
  Future<void> deleteBlock(String blockId) async {
    final block = _blocks.remove(blockId);
    if (block != null) {
      _pendingSyncItemIds.add(blockId);
      _notifyPageBlocks(block.pageId);
    }
  }

  @override
  Future<int> getPendingSyncCount() async => _pendingSyncItemIds.length;

  @override
  Future<void> triggerSync() async {
    if (!_isOnline) return;
    _pendingSyncItemIds.clear();
  }
}
