import 'package:flutter/material.dart';
import '../../domain/models/block_entity.dart';
import '../../domain/models/block_type.dart';
import '../controllers/block_editor_notifier.dart';
import 'renderers/callout_block_renderer.dart';
import 'renderers/checklist_block_renderer.dart';
import 'renderers/code_block_renderer.dart';
import 'renderers/divider_block_renderer.dart';
import 'renderers/math_block_renderer.dart';
import 'renderers/text_block_renderer.dart';
import 'renderers/toggle_block_renderer.dart';
import 'slash_menu/slash_command_menu.dart';

class BlockEditorView extends StatefulWidget {
  final BlockEditorNotifier notifier;

  const BlockEditorView({super.key, required this.notifier});

  @override
  State<BlockEditorView> createState() => _BlockEditorViewState();
}

class _BlockEditorViewState extends State<BlockEditorView> {
  String? _slashBlockId;
  String _slashQuery = '';
  OverlayEntry? _slashOverlayEntry;
  final LayerLink _layerLink = LayerLink();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.notifier,
      builder: (context, _) {
        final state = widget.notifier.state;
        final blocks = state.topLevelBlocks;

        return Stack(
          children: [
            CompositedTransformTarget(
              link: _layerLink,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                itemCount: blocks.length,
                itemBuilder: (context, index) {
                  final block = blocks[index];
                  return _buildBlockItem(block);
                },
              ),
            ),
            if (state.isSaving)
              Positioned(
                top: 8,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('Saving...', style: TextStyle(color: Colors.white, fontSize: 11)),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildBlockItem(BlockEntity block) {
    return Padding(
      key: ValueKey(block.id),
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reorder / Action Handle
          MouseRegion(
            cursor: SystemMouseCursors.grab,
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.drag_indicator, size: 18, color: Colors.grey),
              padding: EdgeInsets.zero,
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'add_below', child: Text('Add block below')),
                const PopupMenuItem(value: 'delete', child: Text('Delete block', style: TextStyle(color: Colors.red))),
              ],
              onSelected: (val) {
                if (val == 'add_below') {
                  widget.notifier.insertBlockAfter(afterBlockId: block.id);
                } else if (val == 'delete') {
                  widget.notifier.deleteBlock(block.id);
                }
              },
            ),
          ),
          const SizedBox(width: 4),
          // Block Content
          Expanded(child: _renderBlock(block)),
        ],
      ),
    );
  }

  Widget _renderBlock(BlockEntity block) {
    switch (block.type) {
      case BlockType.text:
      case BlockType.heading1:
      case BlockType.heading2:
      case BlockType.heading3:
      case BlockType.quote:
        return TextBlockRenderer(
          block: block,
          onChanged: (content) => widget.notifier.updateBlockContent(
            blockId: block.id,
            newContent: content,
          ),
          onEnter: () => widget.notifier.insertBlockAfter(afterBlockId: block.id),
          onBackspaceEmpty: () => widget.notifier.deleteBlock(block.id),
          onSlashTriggered: (query) => _showSlashMenu(block.id, query),
          onSlashDismissed: () {
            if (_slashBlockId == block.id) {
              _hideSlashMenu();
            }
          },
        );
      case BlockType.checklist:
        return ChecklistBlockRenderer(
          block: block,
          onToggle: () => widget.notifier.toggleChecklist(block.id),
          onChanged: (content) => widget.notifier.updateBlockContent(
            blockId: block.id,
            newContent: content,
          ),
          onEnter: () => widget.notifier.insertBlockAfter(
            afterBlockId: block.id,
            type: BlockType.checklist,
          ),
          onBackspaceEmpty: () => widget.notifier.convertBlockType(
            blockId: block.id,
            newType: BlockType.text,
          ),
        );
      case BlockType.callout:
        return CalloutBlockRenderer(
          block: block,
          onChanged: (content) => widget.notifier.updateBlockContent(
            blockId: block.id,
            newContent: content,
          ),
        );
      case BlockType.toggle:
        final children = widget.notifier.state.getChildrenOf(block.id);
        return ToggleBlockRenderer(
          block: block,
          onToggle: () => widget.notifier.toggleCollapse(block.id),
          onChanged: (content) => widget.notifier.updateBlockContent(
            blockId: block.id,
            newContent: content,
          ),
          childBlocksWidget: Column(
            children: children.map((c) => _buildBlockItem(c)).toList(),
          ),
        );
      case BlockType.code:
        return CodeBlockRenderer(
          block: block,
          onChanged: (content) => widget.notifier.updateBlockContent(
            blockId: block.id,
            newContent: content,
          ),
        );
      case BlockType.math:
        return MathBlockRenderer(
          block: block,
          onChanged: (content) => widget.notifier.updateBlockContent(
            blockId: block.id,
            newContent: content,
          ),
        );
      case BlockType.divider:
        return const DividerBlockRenderer();
      case BlockType.databaseInline:
        return const SizedBox.shrink();
    }
  }

  void _showSlashMenu(String blockId, String query) {
    _slashBlockId = blockId;
    _slashQuery = query;

    _slashOverlayEntry?.remove();
    _slashOverlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: 300,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(30, 40),
          child: SlashCommandMenu(
            filterQuery: _slashQuery,
            onSelect: (newType) {
              final targetId = _slashBlockId;
              _hideSlashMenu();
              if (targetId != null) {
                widget.notifier.convertBlockType(
                  blockId: targetId,
                  newType: newType,
                );
              }
            },
            onDismiss: _hideSlashMenu,
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_slashOverlayEntry!);
  }

  void _hideSlashMenu() {
    _slashOverlayEntry?.remove();
    _slashOverlayEntry = null;
    _slashBlockId = null;
    _slashQuery = '';
  }

  @override
  void dispose() {
    _slashOverlayEntry?.remove();
    super.dispose();
  }
}
