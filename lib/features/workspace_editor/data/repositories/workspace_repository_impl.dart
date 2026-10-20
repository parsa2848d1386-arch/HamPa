import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/pages_dao.dart';
import '../../../../core/database/daos/blocks_dao.dart';
import '../../domain/models/page_entity.dart';
import '../../domain/models/block_entity.dart';
import '../../domain/models/block_type.dart';
import '../../domain/repositories/i_workspace_repository.dart';
import '../../domain/repositories/block_repository.dart';

class WorkspaceRepositoryImpl implements IWorkspaceRepository, IBlockRepository {
  final PagesDao _pagesDao;
  final BlocksDao _blocksDao;
  final _uuid = const Uuid();

  WorkspaceRepositoryImpl({
    required PagesDao pagesDao,
    required BlocksDao blocksDao,
  })  : _pagesDao = pagesDao,
        _blocksDao = blocksDao;

  @override
  Stream<List<PageEntity>> watchPageTree() {
    return _pagesDao.watchPageTree().map((entries) => entries.map(_mapPageEntryToEntity).toList());
  }

  @override
  Future<PageEntity> createPage({
    String? parentPageId,
    required String title,
    String? icon,
    bool isDatabaseRow = false,
    double? sortOrder,
  }) async {
    final now = DateTime.now();
    final newId = _uuid.v4();
    final effectiveSortOrder = sortOrder ?? 0.0;
    final entry = PagesCompanion.insert(
      id: newId,
      parentPageId: Value(parentPageId),
      title: Value(title),
      icon: Value(icon),
      isDatabaseRow: Value(isDatabaseRow),
      sortOrder: Value(effectiveSortOrder),
      createdAt: now,
      updatedAt: now,
    );
    await _pagesDao.insertPage(entry);
    return PageEntity(
      id: newId,
      parentPageId: parentPageId,
      title: title,
      icon: icon,
      isDatabaseRow: isDatabaseRow,
      sortOrder: effectiveSortOrder,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Future<void> updatePageParent({
    required String pageId,
    String? newParentPageId,
    required double newSortOrder,
  }) {
    return _pagesDao.updatePageParent(
      pageId: pageId,
      newParentPageId: newParentPageId,
      newSortOrder: newSortOrder,
    );
  }

  @override
  Future<void> updatePageTitle({
    required String pageId,
    required String title,
  }) {
    return _pagesDao.updatePageTitle(pageId, title);
  }

  @override
  Future<void> updatePageIcon({
    required String pageId,
    String? icon,
  }) {
    return _pagesDao.updatePageIcon(pageId, icon);
  }

  @override
  Future<void> archivePage({
    required String pageId,
  }) async {
    await _pagesDao.archivePage(pageId);
  }

  @override
  Future<void> batchUpdateSortOrders(Map<String, double> pageSortOrders) {
    return _pagesDao.batchUpdateSortOrders(pageSortOrders);
  }

  @override
  Stream<List<BlockEntity>> watchBlocksForPage(String pageId) {
    return _blocksDao.watchBlocksForPage(pageId).map((entries) => entries.map(_mapBlockEntryToEntity).toList());
  }

  @override
  Future<List<BlockEntity>> getBlocksForPage(String pageId) async {
    final entries = await _blocksDao.getBlocksForPage(pageId);
    return entries.map(_mapBlockEntryToEntity).toList();
  }

  @override
  Future<void> insertBlock(BlockEntity block) {
    return _blocksDao.insertBlock(BlocksCompanion.insert(
      id: block.id,
      pageId: block.pageId,
      parentBlockId: Value(block.parentBlockId),
      blockType: block.type.toDbString(),
      orderKey: block.orderKey,
      contentJson: Value(block.contentJson),
      isArchived: Value(block.isArchived),
      createdAt: block.createdAt,
      updatedAt: block.updatedAt,
    ));
  }

  @override
  Future<void> updateBlock(BlockEntity block) {
    return _blocksDao.updateBlockEntry(BlocksCompanion(
      id: Value(block.id),
      pageId: Value(block.pageId),
      parentBlockId: Value(block.parentBlockId),
      blockType: Value(block.type.toDbString()),
      orderKey: Value(block.orderKey),
      contentJson: Value(block.contentJson),
      isArchived: Value(block.isArchived),
      createdAt: Value(block.createdAt),
      updatedAt: Value(DateTime.now()),
    ));
  }

  @override
  Future<void> deleteBlock(String blockId) {
    return _blocksDao.deleteBlock(blockId);
  }

  @override
  Future<void> reorderBlock({
    required String blockId,
    required String newOrderKey,
    String? newParentBlockId,
  }) {
    return _blocksDao.updateBlockParent(
      id: blockId,
      newParentBlockId: newParentBlockId,
      newOrderKey: newOrderKey,
    );
  }

  PageEntity _mapPageEntryToEntity(PageEntry entry) {
    return PageEntity(
      id: entry.id,
      parentPageId: entry.parentPageId,
      title: entry.title,
      icon: entry.icon,
      coverImageUrl: entry.coverImageUrl,
      isDatabaseRow: entry.isDatabaseRow,
      isArchived: entry.isArchived,
      sortOrder: entry.sortOrder,
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
    );
  }

  BlockEntity _mapBlockEntryToEntity(BlockEntry entry) {
    Map<String, dynamic> contentMap;
    try {
      contentMap = jsonDecode(entry.contentJson) as Map<String, dynamic>;
    } catch (_) {
      contentMap = {'text': entry.contentJson};
    }
    return BlockEntity(
      id: entry.id,
      pageId: entry.pageId,
      parentBlockId: entry.parentBlockId,
      type: BlockType.fromDbString(entry.blockType),
      orderKey: entry.orderKey,
      content: contentMap,
      isArchived: entry.isArchived,
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
    );
  }
}
