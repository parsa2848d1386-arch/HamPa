import '../../domain/models/block_entity.dart';

enum BlockEditorStatus { initial, loading, loaded, error }

class BlockEditorState {
  final BlockEditorStatus status;
  final String pageId;
  final List<BlockEntity> blocks;
  final String? focusedBlockId;
  final bool isSaving;
  final String? errorMessage;

  const BlockEditorState({
    required this.status,
    required this.pageId,
    this.blocks = const [],
    this.focusedBlockId,
    this.isSaving = false,
    this.errorMessage,
  });

  factory BlockEditorState.initial(String pageId) => BlockEditorState(
        status: BlockEditorStatus.initial,
        pageId: pageId,
      );

  BlockEditorState copyWith({
    BlockEditorStatus? status,
    String? pageId,
    List<BlockEntity>? blocks,
    String? focusedBlockId,
    bool? isSaving,
    String? errorMessage,
  }) {
    return BlockEditorState(
      status: status ?? this.status,
      pageId: pageId ?? this.pageId,
      blocks: blocks ?? this.blocks,
      focusedBlockId: focusedBlockId ?? this.focusedBlockId,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
    );
  }

  List<BlockEntity> get topLevelBlocks =>
      blocks.where((b) => b.parentBlockId == null && !b.isArchived).toList()
        ..sort((a, b) => a.orderKey.compareTo(b.orderKey));

  List<BlockEntity> getChildrenOf(String parentId) =>
      blocks.where((b) => b.parentBlockId == parentId && !b.isArchived).toList()
        ..sort((a, b) => a.orderKey.compareTo(b.orderKey));
}
