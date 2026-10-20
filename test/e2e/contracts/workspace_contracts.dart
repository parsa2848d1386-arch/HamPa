// E2E Contract Definitions: Workspace & Notion Block Editor
// Grounded in PROJECT.md and ORIGINAL_REQUEST.md (R1, AC1, AC3)

enum BlockType {
  text,
  heading1,
  heading2,
  heading3,
  todo,
  callout,
  toggle,
  code,
  latexMath,
  database,
}

class PageEntity {
  final String id;
  final String? parentPageId;
  final String title;
  final String? icon;
  final bool isDatabaseRow;
  final double sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  PageEntity({
    required this.id,
    this.parentPageId,
    required this.title,
    this.icon,
    this.isDatabaseRow = false,
    this.sortOrder = 0.0,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  PageEntity copyWith({
    String? id,
    String? parentPageId,
    bool clearParent = false,
    String? title,
    String? icon,
    bool? isDatabaseRow,
    double? sortOrder,
    DateTime? updatedAt,
  }) {
    return PageEntity(
      id: id ?? this.id,
      parentPageId: clearParent ? null : (parentPageId ?? this.parentPageId),
      title: title ?? this.title,
      icon: icon ?? this.icon,
      isDatabaseRow: isDatabaseRow ?? this.isDatabaseRow,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

class BlockEntity {
  final String id;
  final String pageId;
  final BlockType type;
  final String content;
  final bool checked;
  final String? parentBlockId;
  final double sortOrder;
  final Map<String, dynamic> metadata;

  BlockEntity({
    required this.id,
    required this.pageId,
    required this.type,
    required this.content,
    this.checked = false,
    this.parentBlockId,
    this.sortOrder = 0.0,
    Map<String, dynamic>? metadata,
  }) : metadata = metadata ?? {};

  BlockEntity copyWith({
    String? id,
    String? pageId,
    BlockType? type,
    String? content,
    bool? checked,
    String? parentBlockId,
    double? sortOrder,
    Map<String, dynamic>? metadata,
  }) {
    return BlockEntity(
      id: id ?? this.id,
      pageId: pageId ?? this.pageId,
      type: type ?? this.type,
      content: content ?? this.content,
      checked: checked ?? this.checked,
      parentBlockId: parentBlockId ?? this.parentBlockId,
      sortOrder: sortOrder ?? this.sortOrder,
      metadata: metadata ?? Map.from(this.metadata),
    );
  }
}

abstract class IWorkspaceRepository {
  Stream<List<PageEntity>> watchPageTree();
  Future<PageEntity> createPage({
    String? parentPageId,
    required String title,
    String? icon,
    bool isDatabaseRow = false,
  });
  Future<void> updatePageParent({
    required String pageId,
    String? newParentPageId,
    required double newSortOrder,
  });
  Future<PageEntity?> getPage(String pageId);
  Future<List<PageEntity>> getChildPages(String? parentPageId);
  Future<void> deletePage(String pageId);

  Stream<List<BlockEntity>> watchBlocksForPage(String pageId);
  Future<List<BlockEntity>> getBlocksForPage(String pageId);
  Future<void> insertBlock(BlockEntity block);
  Future<void> updateBlock(BlockEntity block);
  Future<void> deleteBlock(String blockId);

  // Offline sync queue inspection
  Future<int> getPendingSyncCount();
  Future<void> triggerSync();
  void setNetworkOnline(bool isOnline);
  bool get isOnline;
}
