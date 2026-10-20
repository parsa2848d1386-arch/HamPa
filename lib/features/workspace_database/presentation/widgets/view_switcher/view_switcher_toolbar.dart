import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/database_view_type.dart';
import '../../controllers/database_view_cubit.dart';
import '../../controllers/database_view_state.dart';

class ViewSwitcherToolbar extends StatelessWidget {
  final VoidCallback? onOpenFilter;
  final VoidCallback? onOpenSort;
  final VoidCallback? onOpenProperties;

  const ViewSwitcherToolbar({
    super.key,
    this.onOpenFilter,
    this.onOpenSort,
    this.onOpenProperties,
  });

  IconData _iconForViewType(DatabaseViewType type) {
    switch (type) {
      case DatabaseViewType.table:
        return Icons.table_chart;
      case DatabaseViewType.kanban:
        return Icons.view_kanban;
      case DatabaseViewType.calendar:
        return Icons.calendar_month;
      case DatabaseViewType.timeline:
        return Icons.view_timeline;
      case DatabaseViewType.list:
        return Icons.format_list_bulleted;
      case DatabaseViewType.gallery:
        return Icons.grid_view;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cubit = context.read<DatabaseViewCubit>();

    return BlocBuilder<DatabaseViewCubit, DatabaseViewState>(
      builder: (context, state) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              bottom: BorderSide(color: theme.dividerColor, width: 0.8),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top View Tabs Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    ...state.views.map((view) {
                      final isActive = state.activeView?.id == view.id;
                      return Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: ChoiceChip(
                          avatar: Icon(
                            _iconForViewType(view.type),
                            size: 16,
                            color: isActive
                                ? theme.colorScheme.onPrimaryContainer
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                          label: Text(view.name),
                          selected: isActive,
                          onSelected: (_) => cubit.selectView(view.id),
                          selectedColor: theme.colorScheme.primaryContainer,
                          visualDensity: VisualDensity.compact,
                        ),
                      );
                    }),
                    // "+ Add View"
                    IconButton(
                      icon: const Icon(Icons.add, size: 18),
                      tooltip: 'Add View',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _showAddViewDialog(context, cubit),
                    ),
                  ],
                ),
              ),

              // Action Bar: Search, Filter, Sort, Properties, + New Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Row(
                  children: [
                    // Search box
                    SizedBox(
                      width: 180,
                      height: 32,
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search...',
                          prefixIcon: const Icon(Icons.search, size: 16),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 6),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        style: const TextStyle(fontSize: 12),
                        onChanged: (val) => cubit.setSearchQuery(val),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Filter Button
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      icon: const Icon(Icons.filter_list, size: 16),
                      label: Text(
                        state.filters.isNotEmpty
                            ? 'Filter (${state.filters.length})'
                            : 'Filter',
                        style: const TextStyle(fontSize: 12),
                      ),
                      onPressed: onOpenFilter,
                    ),
                    const SizedBox(width: 6),

                    // Sort Button
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      icon: const Icon(Icons.sort, size: 16),
                      label: Text(
                        state.sorts.isNotEmpty
                            ? 'Sort (${state.sorts.length})'
                            : 'Sort',
                        style: const TextStyle(fontSize: 12),
                      ),
                      onPressed: onOpenSort,
                    ),
                    const Spacer(),

                    // "+ New" Row Button
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('New', style: TextStyle(fontSize: 12)),
                      onPressed: () => cubit.addNewRow(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddViewDialog(BuildContext context, DatabaseViewCubit cubit) {
    showDialog(
      context: context,
      builder: (ctx) {
        String name = 'New View';
        DatabaseViewType selectedType = DatabaseViewType.table;

        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: const Text('Add View'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: const InputDecoration(labelText: 'View Name'),
                    onChanged: (val) => name = val,
                  ),
                  const SizedBox(height: 12),
                  DropdownButton<DatabaseViewType>(
                    value: selectedType,
                    isExpanded: true,
                    items: DatabaseViewType.values.map((t) {
                      return DropdownMenuItem(
                        value: t,
                        child: Text(t.name.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => selectedType = val);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    cubit.createView(name: name, type: selectedType);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
