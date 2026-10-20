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
