import 'package:flutter/material.dart';
import '../../../domain/models/block_type.dart';
import 'slash_command_item.dart';

class SlashCommandMenu extends StatefulWidget {
  final String filterQuery;
  final ValueChanged<BlockType> onSelect;
  final VoidCallback onDismiss;

  const SlashCommandMenu({
    super.key,
    required this.filterQuery,
    required this.onSelect,
    required this.onDismiss,
  });

  @override
  State<SlashCommandMenu> createState() => _SlashCommandMenuState();
}

class _SlashCommandMenuState extends State<SlashCommandMenu> {
  final int _selectedIndex = 0;

  static const List<SlashCommandItem> allItems = [
    SlashCommandItem(
      type: BlockType.text,
      title: 'Text',
      subtitle: 'Just start writing with plain text.',
      icon: Icons.short_text,
    ),
    SlashCommandItem(
      type: BlockType.heading1,
      title: 'Heading 1',
      subtitle: 'Big section heading.',
      icon: Icons.title,
    ),
    SlashCommandItem(
      type: BlockType.heading2,
      title: 'Heading 2',
      subtitle: 'Medium section heading.',
      icon: Icons.format_size,
    ),
    SlashCommandItem(
      type: BlockType.heading3,
      title: 'Heading 3',
      subtitle: 'Small section heading.',
      icon: Icons.format_size,
    ),
    SlashCommandItem(
      type: BlockType.checklist,
      title: 'To-do List',
      subtitle: 'Track tasks with a to-do list.',
      icon: Icons.check_box_outlined,
    ),
    SlashCommandItem(
      type: BlockType.callout,
      title: 'Callout',
      subtitle: 'Make writing stand out with tinted box.',
      icon: Icons.lightbulb_outline,
    ),
    SlashCommandItem(
      type: BlockType.toggle,
      title: 'Toggle List',
      subtitle: 'Toggles can hide and show nested content.',
      icon: Icons.arrow_right,
    ),
    SlashCommandItem(
      type: BlockType.code,
      title: 'Code Block',
      subtitle: 'Capture a code snippet with syntax highlighting.',
      icon: Icons.code,
    ),
    SlashCommandItem(
      type: BlockType.math,
      title: 'Math Formula',
      subtitle: 'LaTeX mathematical equation.',
      icon: Icons.functions,
    ),
    SlashCommandItem(
      type: BlockType.divider,
      title: 'Divider',
      subtitle: 'Visually divide blocks with a clean line.',
      icon: Icons.horizontal_rule,
    ),
  ];

  List<SlashCommandItem> get filteredItems {
    final query = widget.filterQuery.toLowerCase().trim();
    if (query.isEmpty) return allItems;
    return allItems.where((item) {
      return item.title.toLowerCase().contains(query) ||
          item.subtitle.toLowerCase().contains(query) ||
          item.type.value.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = filteredItems;
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Text('No matching block types', style: TextStyle(color: Colors.grey)),
      );
    }

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 300,
        constraints: const BoxConstraints(maxHeight: 320),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.2)),
        ),
        child: ListView.builder(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 4),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final isSelected = index == _selectedIndex;

            return InkWell(
              onTap: () => widget.onSelect(item.type),
              child: Container(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.08)
                    : null,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(item.icon, size: 20, color: Theme.of(context).colorScheme.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          Text(
                            item.subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
