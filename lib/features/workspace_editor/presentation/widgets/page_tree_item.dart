import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/models/page_entity.dart';
import '../../domain/models/page_tree_node.dart';
import '../../domain/utils/page_tree_utils.dart';
import '../controllers/page_tree_cubit.dart';
import 'page_action_dialogs.dart';

class PageDragData {
  final String pageId;
  const PageDragData(this.pageId);
}

class PageTreeItem extends StatefulWidget {
  final PageTreeNode node;
  final bool isSelected;
  final Map<String, PageEntity> pageMap;

  const PageTreeItem({
    super.key,
    required this.node,
    required this.isSelected,
    required this.pageMap,
  });

  @override
  State<PageTreeItem> createState() => _PageTreeItemState();
}

class _PageTreeItemState extends State<PageTreeItem> {
  bool _isHovered = false;
  DropPosition? _activeDropPosition;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final page = widget.node.page;
    final cubit = context.read<PageTreeCubit>();
    const treeUtils = PageTreeUtils();

    // Visual drop feedback
    BoxDecoration? targetDecoration;
    if (_activeDropPosition == DropPosition.inside) {
      targetDecoration = BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: theme.colorScheme.primary, width: 1.5),
      );
    }

    final double indent = (widget.node.depth * 16.0) + 8.0;

    return DragTarget<PageDragData>(
      onWillAcceptWithDetails: (details) {
        final draggedId = details.data.pageId;
        if (draggedId == page.id) return false; // Cannot drop on self

        // Cycle check: cannot drop onto any descendant
        final isDescendant = treeUtils.isDescendant(
          candidateChildId: page.id,
          candidateAncestorId: draggedId,
          pageMap: widget.pageMap,
        );
        return !isDescendant;
      },
      onMove: (details) {
        final renderBox = context.findRenderObject() as RenderBox?;
        if (renderBox == null) return;
        final localOffset = renderBox.globalToLocal(details.offset);
        final height = renderBox.size.height;

        DropPosition newPos;
        if (localOffset.dy < height * 0.25) {
          newPos = DropPosition.before;
        } else if (localOffset.dy > height * 0.75) {
          newPos = DropPosition.after;
        } else {
          newPos = DropPosition.inside;
        }

        if (_activeDropPosition != newPos) {
          setState(() => _activeDropPosition = newPos);
        }
      },
      onLeave: (_) {
        setState(() => _activeDropPosition = null);
      },
      onAcceptWithDetails: (details) {
        final pos = _activeDropPosition ?? DropPosition.inside;
        setState(() => _activeDropPosition = null);
        cubit.handleDrop(
          movingPageId: details.data.pageId,
          targetPageId: page.id,
          position: pos,
        );
      },
      builder: (context, candidateData, rejectedData) {
        return Stack(
          children: [
            MouseRegion(
              onEnter: (_) => setState(() => _isHovered = true),
              onExit: (_) => setState(() => _isHovered = false),
              child: LongPressDraggable<PageDragData>(
                data: PageDragData(page.id),
                delay: const Duration(milliseconds: 150),
                feedback: Material(
                  elevation: 6,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: theme.colorScheme.primary, width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(page.icon ?? '📄', style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        Text(
                          page.title.isEmpty ? 'Untitled' : page.title,
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                childWhenDragging: Opacity(
                  opacity: 0.3,
                  child: _buildItemRow(context, indent, targetDecoration),
                ),
                child: _buildItemRow(context, indent, targetDecoration),
              ),
            ),

            // Top Drop Indicator Line (DropPosition.before)
            if (_activeDropPosition == DropPosition.before)
              Positioned(
                top: 0,
                left: indent,
                right: 8,
                child: Container(height: 2.5, color: theme.colorScheme.primary),
              ),

            // Bottom Drop Indicator Line (DropPosition.after)
            if (_activeDropPosition == DropPosition.after)
              Positioned(
                bottom: 0,
                left: indent,
                right: 8,
                child: Container(height: 2.5, color: theme.colorScheme.primary),
              ),
          ],
        );
      },
    );
  }

  Widget _buildItemRow(BuildContext context, double indent, BoxDecoration? targetDecoration) {
    final theme = Theme.of(context);
    final page = widget.node.page;
    final cubit = context.read<PageTreeCubit>();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: targetDecoration ??
          BoxDecoration(
            color: widget.isSelected
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.6)
                : (_isHovered ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3) : Colors.transparent),
            borderRadius: BorderRadius.circular(6),
          ),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () => cubit.selectPage(page.id),
        child: Padding(
          padding: EdgeInsets.fromLTRB(indent, 4, 8, 4),
          child: Row(
            children: [
              // Chevron Toggle
              SizedBox(
                width: 22,
                height: 22,
                child: widget.node.hasChildren
                    ? IconButton(
                        padding: EdgeInsets.zero,
                        iconSize: 16,
                        icon: AnimatedRotation(
                          turns: widget.node.isExpanded ? 0.25 : 0.0,
                          duration: const Duration(milliseconds: 180),
                          child: const Icon(Icons.chevron_right),
                        ),
                        onPressed: () => cubit.toggleNodeExpanded(page.id),
                      )
                    : const SizedBox.shrink(),
              ),

              const SizedBox(width: 4),

              // Page Icon / Emoji
              GestureDetector(
                onTap: () => PageActionDialogs.showEmojiPicker(context, page),
                child: Text(
                  page.icon ?? '📄',
                  style: const TextStyle(fontSize: 15),
                ),
              ),

              const SizedBox(width: 8),

              // Page Title
              Expanded(
                child: Text(
                  page.title.isEmpty ? 'Untitled' : page.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: widget.isSelected ? theme.colorScheme.primary : null,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Database Row indicator badge if applicable
              if (page.isDatabaseRow)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('ROW', style: TextStyle(fontSize: 9, color: theme.colorScheme.onSecondaryContainer)),
                ),

              // Action Buttons (visible on hover or selection)
              if (_isHovered || widget.isSelected) ...[
                IconButton(
                  icon: const Icon(Icons.add, size: 16),
                  tooltip: 'Add sub-page',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                  onPressed: () => cubit.createSubPage(parentPageId: page.id),
                ),
                IconButton(
                  icon: const Icon(Icons.more_horiz, size: 16),
                  tooltip: 'Page options',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                  onPressed: () => PageActionDialogs.showPageMenu(context, page),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
