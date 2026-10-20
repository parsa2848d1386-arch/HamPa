import '../models/block_entity.dart';

abstract class IBlockRepository {
  Stream<List<BlockEntity>> watchBlocksForPage(String pageId);
  Future<List<BlockEntity>> getBlocksForPage(String pageId);
  Future<void> insertBlock(BlockEntity block);
  Future<void> updateBlock(BlockEntity block);
  Future<void> deleteBlock(String blockId);
  Future<void> reorderBlock({
    required String blockId,
    required String newOrderKey,
    String? newParentBlockId,
  });
}
