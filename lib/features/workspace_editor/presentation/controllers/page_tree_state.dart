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
