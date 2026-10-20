import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/models/page_entity.dart';
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
      newParentId = targetPage.id;

      // Cycle prevention
      if (!_treeUtils.canReparent(movingPageId: movingPageId, targetParentId: newParentId, pageMap: pageMap)) {
        emit(state.copyWith(errorMessage: 'Cannot move a page into its own descendant!'));
        return;
      }

      final children = state.allPages
          .where((p) => p.parentPageId == targetPage.id && p.id != movingPageId && !p.isArchived)
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      final lastOrder = children.isNotEmpty ? children.last.sortOrder : null;
      newSortOrder = FractionalIndexer.betweenDoubles(lastOrder, null);

      final updatedExpanded = Set<String>.from(state.expandedPageIds)..add(targetPage.id);
      emit(state.copyWith(expandedPageIds: updatedExpanded));
    } else {
      // Re-parent as sibling of targetPage (before or after)
      newParentId = targetPage.parentPageId;

      // Cycle prevention
      if (!_treeUtils.canReparent(movingPageId: movingPageId, targetParentId: newParentId, pageMap: pageMap)) {
        emit(state.copyWith(errorMessage: 'Cannot move a page into its own descendant!'));
        return;
      }

      final siblings = state.allPages
          .where((p) => p.parentPageId == newParentId && p.id != movingPageId && !p.isArchived)
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      final targetIdx = siblings.indexWhere((p) => p.id == targetPageId);
      if (targetIdx == -1) return;

      if (position == DropPosition.before) {
        final prevOrder = targetIdx > 0 ? siblings[targetIdx - 1].sortOrder : null;
        final nextOrder = siblings[targetIdx].sortOrder;
        newSortOrder = FractionalIndexer.betweenDoubles(prevOrder, nextOrder);
      } else {
        // after
        final prevOrder = siblings[targetIdx].sortOrder;
        final nextOrder = targetIdx < siblings.length - 1 ? siblings[targetIdx + 1].sortOrder : null;
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
      emit(state.copyWith(errorMessage: 'Failed to move page: $e'));
    }
  }

  /// Renames a page.
  Future<void> renamePage({required String pageId, required String newTitle}) async {
    try {
      await _repository.updatePageTitle(pageId: pageId, title: newTitle);
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to rename page: $e'));
    }
  }

  /// Updates page icon.
  Future<void> updatePageIcon({required String pageId, String? newIcon}) async {
    try {
      await _repository.updatePageIcon(pageId: pageId, icon: newIcon);
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to update icon: $e'));
    }
  }

  /// Archives a page.
  Future<void> archivePage(String pageId) async {
    try {
      await _repository.archivePage(pageId: pageId);
      if (state.selectedPageId == pageId) {
        emit(state.copyWith(clearSelectedPageId: true));
      }
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to archive page: $e'));
    }
  }

  @override
  Future<void> close() {
    _treeSubscription?.cancel();
    return super.close();
  }
}
