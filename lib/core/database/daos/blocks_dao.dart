import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/blocks_table.dart';

part 'blocks_dao.g.dart';

@DriftAccessor(tables: [Blocks])
class BlocksDao extends DatabaseAccessor<AppDatabase> with _$BlocksDaoMixin {
  BlocksDao(super.db);

  /// Watches all blocks for a page ordered by orderKey
  Stream<List<BlockEntry>> watchBlocksForPage(String pageId) {
    return (select(blocks)
          ..where((tbl) => tbl.pageId.equals(pageId) & tbl.isArchived.equals(false))
          ..orderBy([
            (tbl) => OrderingTerm(expression: tbl.orderKey, mode: OrderingMode.asc),
          ]))
        .watch();
  }

  /// Watches nested blocks inside a toggle container
  Stream<List<BlockEntry>> watchChildBlocks(String parentBlockId) {
    return (select(blocks)
          ..where((tbl) =>
              tbl.parentBlockId.equals(parentBlockId) & tbl.isArchived.equals(false))
          ..orderBy([
            (tbl) => OrderingTerm(expression: tbl.orderKey, mode: OrderingMode.asc),
          ]))
        .watch();
  }

  /// One-shot retrieval of page blocks
  Future<List<BlockEntry>> getBlocksForPage(String pageId) {
    return (select(blocks)
          ..where((tbl) => tbl.pageId.equals(pageId) & tbl.isArchived.equals(false))
          ..orderBy([
            (tbl) => OrderingTerm(expression: tbl.orderKey, mode: OrderingMode.asc),
          ]))
        .get();
  }

  Future<BlockEntry?> getBlockById(String id) {
    return (select(blocks)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  Future<int> insertBlock(BlocksCompanion entry) {
    return into(blocks).insert(entry);
  }

  /// Updates block entry columns that are present in [entry] matching [entry.id].
  /// Uses write() to only update specified columns, preserving absent fields.
  Future<bool> updateBlockEntry(BlocksCompanion entry) async {
    assert(entry.id.present, 'Block id must be present for update');
    final count = await (update(blocks)..where((tbl) => tbl.id.equals(entry.id.value))).write(entry);
    return count > 0;
  }

  /// Explicitly updates blockType, contentJson, and updatedAt.
  Future<int> updateBlockContentAndType({
    required String id,
    required String blockType,
    required String contentJson,
    DateTime? updatedAt,
  }) {
    return (update(blocks)..where((tbl) => tbl.id.equals(id))).write(
      BlocksCompanion(
        blockType: Value(blockType),
        contentJson: Value(contentJson),
        updatedAt: Value(updatedAt ?? DateTime.now()),
      ),
    );
  }

  Future<int> updateBlockContent(String id, String contentJson) {
    return (update(blocks)..where((tbl) => tbl.id.equals(id))).write(
      BlocksCompanion(
        contentJson: Value(contentJson),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> updateBlockOrderKey(String id, String newOrderKey) {
    return (update(blocks)..where((tbl) => tbl.id.equals(id))).write(
      BlocksCompanion(
        orderKey: Value(newOrderKey),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> updateBlockParent({
    required String id,
    String? newParentBlockId,
    required String newOrderKey,
  }) {
    return (update(blocks)..where((tbl) => tbl.id.equals(id))).write(
      BlocksCompanion(
        parentBlockId: Value(newParentBlockId),
        orderKey: Value(newOrderKey),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> deleteBlock(String id) {
    return (delete(blocks)..where((tbl) => tbl.id.equals(id))).go();
  }

  Future<void> batchUpsertBlocks(List<BlocksCompanion> entries) async {
    await batch((b) {
      b.insertAllOnConflictUpdate(blocks, entries);
    });
  }
}
