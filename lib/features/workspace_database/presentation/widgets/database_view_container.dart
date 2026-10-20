import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/database_view_type.dart';
import '../../domain/models/filter_criteria.dart';
import '../../domain/models/sort_criteria.dart';
import '../controllers/database_view_cubit.dart';
import '../controllers/database_view_state.dart';
import 'view_switcher/view_switcher_toolbar.dart';
import 'views/table/table_view_widget.dart';
import 'views/kanban/kanban_view_widget.dart';
import 'views/calendar/calendar_view_widget.dart';
import 'views/timeline/timeline_view_widget.dart';
import 'views/list/list_view_widget.dart';
import 'views/gallery/gallery_view_widget.dart';

class DatabaseViewContainer extends StatelessWidget {
  final void Function(String pageId)? onOpenRowPage;

  const DatabaseViewContainer({super.key, this.onOpenRowPage});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DatabaseViewCubit>();

    return BlocBuilder<DatabaseViewCubit, DatabaseViewState>(
      builder: (context, state) {
        if (state.status == DatabaseViewStatus.loading && state.database == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.status == DatabaseViewStatus.error && state.errorMessage != null) {
          return Center(child: Text('Error: ${state.errorMessage}'));
        }

        final activeType = state.activeView?.type ?? DatabaseViewType.table;

        return Column(
          children: [
            // Top Toolbar: View Switcher, Search, Filter, Sort, New
            ViewSwitcherToolbar(
              onOpenFilter: () => _showFilterDialog(context, cubit, state),
              onOpenSort: () => _showSortDialog(context, cubit, state),
              onOpenProperties: () => _showPropertiesSheet(context, cubit, state),
            ),

            // Active View Body
            Expanded(
              child: _buildActiveView(activeType),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActiveView(DatabaseViewType type) {
    switch (type) {
      case DatabaseViewType.table:
        return TableViewWidget(onOpenRowPage: onOpenRowPage);
      case DatabaseViewType.kanban:
        return KanbanViewWidget(onOpenRowPage: onOpenRowPage);
      case DatabaseViewType.calendar:
        return CalendarViewWidget(onOpenRowPage: onOpenRowPage);
      case DatabaseViewType.timeline:
        return TimelineViewWidget(onOpenRowPage: onOpenRowPage);
      case DatabaseViewType.list:
        return ListViewWidget(onOpenRowPage: onOpenRowPage);
      case DatabaseViewType.gallery:
        return GalleryViewWidget(onOpenRowPage: onOpenRowPage);
    }
  }

  void _showFilterDialog(BuildContext context, DatabaseViewCubit cubit, DatabaseViewState state) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Filters'),
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (state.filters.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('No active filters.'),
                  )
                else
                  ...state.filters.map((f) {
                    final prop = state.properties.where((p) => p.id == f.propertyId).firstOrNull;
                    return ListTile(
                      dense: true,
                      title: Text('${prop?.name ?? 'Property'} ${f.operator.name} ${f.value ?? ''}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: () => cubit.removeFilter(f.id),
                      ),
                    );
                  }),
                const Divider(),
                if (state.properties.isNotEmpty)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Filter'),
                    onPressed: () {
                      final p = state.properties.first;
                      cubit.addFilter(FilterCriteria(
                        id: 'filter_${DateTime.now().millisecondsSinceEpoch}',
                        propertyId: p.id,
                        operator: FilterOperator.isNotEmpty,
                      ));
                      Navigator.pop(ctx);
                    },
                  ),
              ],
            ),
          ),
          actions: [
            if (state.filters.isNotEmpty)
              TextButton(
                onPressed: () {
                  cubit.clearFilters();
                  Navigator.pop(ctx);
                },
                child: const Text('Clear All'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showSortDialog(BuildContext context, DatabaseViewCubit cubit, DatabaseViewState state) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Sorts'),
          content: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (state.sorts.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('No active sorts.'),
                  )
                else
                  ...state.sorts.map((s) {
                    final prop = state.properties.where((p) => p.id == s.propertyId).firstOrNull;
                    return ListTile(
                      dense: true,
                      title: Text('${prop?.name ?? 'Property'} (${s.direction.name})'),
                    );
                  }),
                const Divider(),
                if (state.properties.isNotEmpty)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Sort'),
                    onPressed: () {
                      final p = state.properties.first;
                      cubit.setSorts([
                        SortCriteria(propertyId: p.id, direction: SortDirection.ascending),
                      ]);
                      Navigator.pop(ctx);
                    },
                  ),
              ],
            ),
          ),
          actions: [
            if (state.sorts.isNotEmpty)
              TextButton(
                onPressed: () {
                  cubit.setSorts([]);
                  Navigator.pop(ctx);
                },
                child: const Text('Clear All'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showPropertiesSheet(BuildContext context, DatabaseViewCubit cubit, DatabaseViewState state) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Property Visibility',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            ...state.properties.map((p) {
              final isVisible = state.columnLayouts[p.id]?.isVisible ?? true;
              return SwitchListTile(
                title: Text(p.name),
                subtitle: Text(p.type.name),
                value: isVisible,
                onChanged: (_) => cubit.togglePropertyVisibility(p.id),
              );
            }),
          ],
        );
      },
    );
  }
}
