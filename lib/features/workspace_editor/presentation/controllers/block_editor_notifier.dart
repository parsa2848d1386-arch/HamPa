import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/block_entity.dart';
import '../../domain/models/block_type.dart';
import '../../domain/repositories/block_repository.dart';
import '../../../../core/utils/fractional_indexer.dart';
import 'block_editor_state.dart';

class BlockEditorNotifier extends ChangeNotifier {
  final IBlockRepository repository;
  final String pageId;

  BlockEditorState _state;
  BlockEditorState get state => _state;

  StreamSubscription<List<BlockEntity>>? _blocksSubscription;
  Timer? _debounceSaveTimer;
  final Map<String, BlockEntity> _dirtyBlocks = {};
  static const _uuid = Uuid();

  BlockEditorNotifier({
    required this.repository,
    required this.pageId,
  }) : _state = BlockEditorState.initial(pageId) {
    _init();
  }

  void _init() {
    _state = _state.copyWith(status: BlockEditorStatus.loading);
    notifyListeners();

    _blocksSubscription = repository.watchBlocksForPage(pageId).listen(
      (blocks) {
        if (blocks.isEmpty) {
          createInitialBlock();
        } else {
          _state = _state.copyWith(
            status: BlockEditorStatus.loaded,
            blocks: blocks,
          );
          notifyListeners();
        }
      },
      onError: (err) {
        _state = _state.copyWith(
          status: BlockEditorStatus.error,
          errorMessage: err.toString(),
        );
        notifyListeners();
      },
    );
  }

  Future<void> createInitialBlock() async {
    final block = BlockEntity(
      id: _uuid.v4(),
      pageId: pageId,
      type: BlockType.text,
      orderKey: 'a0',
      content: {'text': ''},
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await repository.insertBlock(block);
  }

  void updateBlockContent({
    required String blockId,
    required Map<String, dynamic> newContent,
  }) {
    final index = _state.blocks.indexWhere((b) => b.id == blockId);
    if (index == -1) return;

    final updated = _state.blocks[index].copyWith(
      content: newContent,
      updatedAt: DateTime.now(),
    );

    final updatedList = List<BlockEntity>.from(_state.blocks);
    updatedList[index] = updated;

    _dirtyBlocks[blockId] = updated;
    _state = _state.copyWith(blocks: updatedList, isSaving: true);
    notifyListeners();

    _scheduleDebouncedSave();
  }

  void _scheduleDebouncedSave() {
    _debounceSaveTimer?.cancel();
    _debounceSaveTimer = Timer(const Duration(milliseconds: 300), () async {
      await flushDirtyBlocks();
    });
  }

  Future<void> flushDirtyBlocks() async {
    _debounceSaveTimer?.cancel();
    _debounceSaveTimer = null;

    if (_dirtyBlocks.isEmpty) {
      if (_state.isSaving && hasListeners) {
        _state = _state.copyWith(isSaving: false);
        notifyListeners();
      }
      return;
    }

    final toSave = Map<String, BlockEntity>.from(_dirtyBlocks);
    _dirtyBlocks.clear();

    for (final block in toSave.values) {
      await repository.updateBlock(block);
    }

    if (hasListeners) {
      _state = _state.copyWith(isSaving: false);
      notifyListeners();
    }
  }

  Future<void> insertBlockAfter({
    required String afterBlockId,
    BlockType type = BlockType.text,
    String? parentBlockId,
  }) async {
    await flushDirtyBlocks();

    BlockEntity? afterBlock;
    for (final b in _state.blocks) {
      if (b.id == afterBlockId) {
        afterBlock = b;
        break;
      }
    }

    final effectiveParentId = parentBlockId ?? afterBlock?.parentBlockId;

    final currentBlocks = effectiveParentId == null
        ? _state.topLevelBlocks
        : _state.getChildrenOf(effectiveParentId);

    final currentIndex = currentBlocks.indexWhere((b) => b.id == afterBlockId);
    String newOrderKey;

    if (currentIndex == -1 || currentIndex == currentBlocks.length - 1) {
      final lastKey = currentBlocks.isNotEmpty ? currentBlocks.last.orderKey : null;
      newOrderKey = StringLexoRank.between(lastKey, null);
    } else {
      final currentKey = currentBlocks[currentIndex].orderKey;
      final nextKey = currentBlocks[currentIndex + 1].orderKey;
      newOrderKey = StringLexoRank.between(currentKey, nextKey);
    }

    final newBlock = BlockEntity(
      id: _uuid.v4(),
      pageId: pageId,
      parentBlockId: effectiveParentId,
      type: type,
      orderKey: newOrderKey,
      content: _getInitialContentFor(type),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await repository.insertBlock(newBlock);
    _state = _state.copyWith(focusedBlockId: newBlock.id);
    notifyListeners();
  }

  Future<void> convertBlockType({
    required String blockId,
    required BlockType newType,
  }) async {
    final index = _state.blocks.indexWhere((b) => b.id == blockId);
    if (index == -1) return;

    final oldBlock = _state.blocks[index];
    final String rawText = (oldBlock.content['text'] ?? oldBlock.content['title'] ?? '').toString();
    final String currentText = rawText.startsWith('/') ? '' : rawText;

    final Map<String, dynamic> newContent = _convertContent(currentText, newType);

    final updated = oldBlock.copyWith(
      type: newType,
      content: newContent,
      updatedAt: DateTime.now(),
    );

    final updatedList = List<BlockEntity>.from(_state.blocks);
    updatedList[index] = updated;
    _state = _state.copyWith(blocks: updatedList);
    notifyListeners();

    _dirtyBlocks[blockId] = updated;
    await flushDirtyBlocks();
  }

  Map<String, dynamic> _convertContent(String existingText, BlockType newType) {
    switch (newType) {
      case BlockType.text:
      case BlockType.heading1:
      case BlockType.heading2:
      case BlockType.heading3:
        return {'text': existingText};
      case BlockType.checklist:
        return {'text': existingText, 'isCompleted': false};
      case BlockType.callout:
        return {'text': existingText, 'icon': '💡', 'colorTheme': 'amber'};
      case BlockType.toggle:
        return {'title': existingText.isEmpty ? 'Toggle' : existingText, 'isOpen': false};
      case BlockType.code:
        return {'code': existingText, 'language': 'dart', 'showLineNumbers': true};
      case BlockType.math:
        return {'latex': existingText.isEmpty ? 'E = mc^2' : existingText, 'isDisplayMode': true};
      case BlockType.divider:
        return {};
      case BlockType.quote:
        return {'text': existingText};
      case BlockType.databaseInline:
        return {};
    }
  }

  Map<String, dynamic> _getInitialContentFor(BlockType type) {
    return _convertContent('', type);
  }

  Future<void> toggleChecklist(String blockId) async {
    final index = _state.blocks.indexWhere((b) => b.id == blockId);
    if (index == -1) return;

    final block = _state.blocks[index];
    final currentCompleted = block.content['isCompleted'] as bool? ?? false;
    final newCompleted = !currentCompleted;

    final newContent = Map<String, dynamic>.from(block.content)
      ..['isCompleted'] = newCompleted
      ..['checkedAt'] = newCompleted ? DateTime.now().millisecondsSinceEpoch : null;

    updateBlockContent(blockId: blockId, newContent: newContent);
    await flushDirtyBlocks();
  }

  Future<void> toggleCollapse(String blockId) async {
    final index = _state.blocks.indexWhere((b) => b.id == blockId);
    if (index == -1) return;

    final block = _state.blocks[index];
    final currentOpen = block.content['isOpen'] as bool? ?? false;

    final newContent = Map<String, dynamic>.from(block.content)
      ..['isOpen'] = !currentOpen;

    updateBlockContent(blockId: blockId, newContent: newContent);
    await flushDirtyBlocks();
  }

  Future<void> deleteBlock(String blockId) async {
    await flushDirtyBlocks();
    await repository.deleteBlock(blockId);
  }

  Future<void> reorderBlock({
    required String blockId,
    required String? prevOrderKey,
    required String? nextOrderKey,
    String? newParentBlockId,
  }) async {
    await flushDirtyBlocks();
    final newOrderKey = StringLexoRank.between(prevOrderKey, nextOrderKey);
    await repository.reorderBlock(
      blockId: blockId,
      newOrderKey: newOrderKey,
      newParentBlockId: newParentBlockId,
    );
  }

  @override
  void dispose() {
    _debounceSaveTimer?.cancel();
    _debounceSaveTimer = null;
    if (_dirtyBlocks.isNotEmpty) {
      final toSave = Map<String, BlockEntity>.from(_dirtyBlocks);
      _dirtyBlocks.clear();
      for (final block in toSave.values) {
        repository.updateBlock(block);
      }
    }
    _blocksSubscription?.cancel();
    super.dispose();
  }
}
