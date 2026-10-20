import '../models/page_entity.dart';
import '../models/block_entity.dart';

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

  /// Watches all blocks for a page reactively.
  Stream<List<BlockEntity>> watchBlocksForPage(String pageId);

  /// Inserts a new block.
  Future<void> insertBlock(BlockEntity block);

  /// Updates a block's content or state.
  Future<void> updateBlock(BlockEntity block);

  /// Deletes a block.
  Future<void> deleteBlock(String blockId);
}
