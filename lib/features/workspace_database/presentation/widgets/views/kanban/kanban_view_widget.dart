import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:hampa/features/workspace_database/domain/models/property_entity.dart';
import 'package:hampa/features/workspace_database/domain/models/property_type.dart';
import 'package:hampa/features/workspace_database/presentation/controllers/database_view_cubit.dart';
import 'package:hampa/features/workspace_database/presentation/controllers/database_view_state.dart';

class KanbanViewWidget extends StatelessWidget {
  final void Function(String pageId)? onOpenRowPage;

  const KanbanViewWidget({super.key, this.onOpenRowPage});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DatabaseViewCubit>();
    final theme = Theme.of(context);

    return BlocBuilder<DatabaseViewCubit, DatabaseViewState>(
      builder: (context, state) {
        // Find group-by property: either configured, or first select/status property, or title
        final groupByProp = _resolveGroupByProperty(state);
        if (groupByProp == null) {
          return const Center(child: Text('No groupable (select/status) property found.'));
        }

        final titleProp = state.properties.where((p) => p.type == PropertyType.title).firstOrNull;

        // Resolve lanes
        final List<String?> laneValues = [];
        final options = (groupByProp.config['options'] as List?)?.cast<String>() ?? [];
        laneValues.addAll(options);
        laneValues.add(null); // 'No Status'

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: laneValues.map((laneVal) {
              final laneKey = laneVal ?? 'no_status';
              final isCollapsed = state.collapsedKanbanLanes.contains(laneKey);

              // Filter rows belonging to this lane
              final laneRows = state.visibleRows.where((r) {
                final val = state.getCellValue(r.id, groupByProp.id);
                if (laneVal == null) {
                  return val == null || val.toString().trim().isEmpty;
                }
                return val?.toString().toLowerCase() == laneVal.toLowerCase();
              }).toList();

              return Container(
                width: isCollapsed ? 48 : 260,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Lane Header
                    InkWell(
                      onTap: () => cubit.toggleKanbanLaneCollapse(laneKey),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                        ),
                        child: Row(
                          children: [
                            if (!isCollapsed) ...[
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: laneVal != null ? theme.colorScheme.primary : Colors.grey,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  laneVal ?? 'No Status',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${laneRows.length}',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ] else ...[
                              const RotatedBox(
                                quarterTurns: 1,
                                child: Icon(Icons.arrow_right, size: 16),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    if (!isCollapsed)
                      // Drag target area for dropping cards into lane
                      DragTarget<String>(
                        onWillAcceptWithDetails: (details) => details.data.isNotEmpty,
                        onAcceptWithDetails: (details) {
                          cubit.moveKanbanCard(
                            rowId: details.data,
                            groupByPropertyId: groupByProp.id,
                            newLaneValue: laneVal,
                          );
                        },
                        builder: (context, candidateData, rejectedData) {
                          final isOver = candidateData.isNotEmpty;
                          return Container(
                            constraints: const BoxConstraints(minHeight: 120),
                            color: isOver ? theme.colorScheme.primary.withValues(alpha: 0.1) : Colors.transparent,
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              children: [
                                ...laneRows.map((row) {
                                  final rowTitle = titleProp != null
                                      ? state.getCellValue(row.id, titleProp.id)?.toString()
                                      : null;

                                  return Draggable<String>(
                                    data: row.id,
                                    feedback: Material(
                                      elevation: 4,
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        width: 240,
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.surface,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: theme.colorScheme.primary),
                                        ),
                                        child: Text(
                                          rowTitle ?? 'Untitled',
                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                        ),
                                      ),
                                    ),
                                    childWhenDragging: Opacity(
                                      opacity: 0.3,
                                      child: _buildCard(context, row.id, row.pageId, rowTitle ?? 'Untitled', theme),
                                    ),
                                    child: _buildCard(context, row.id, row.pageId, rowTitle ?? 'Untitled', theme),
                                  );
                                }),
                                // "+ Add Item" in lane
                                InkWell(
                                  onTap: () async {
                                    final newRowId = await cubit.addNewRow();
                                    if (laneVal != null) {
                                      await cubit.moveKanbanCard(
                                        rowId: newRowId,
                                        groupByPropertyId: groupByProp.id,
                                        newLaneValue: laneVal,
                                      );
                                    }
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                    child: Row(
                                      children: [
                                        Icon(Icons.add, size: 16, color: theme.colorScheme.primary),
                                        const SizedBox(width: 4),
                                        Text(
                                          'New',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildCard(BuildContext context, String rowId, String pageId, String title, ThemeData theme) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
              InkWell(
                onTap: () => onOpenRowPage?.call(pageId),
                child: const Icon(Icons.open_in_new, size: 14, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  PropertyEntity? _resolveGroupByProperty(DatabaseViewState state) {
    // Look for status or select property first
    final selectProp = state.properties.where(
      (p) => p.type == PropertyType.status || p.type == PropertyType.select,
    ).firstOrNull;
    if (selectProp != null) return selectProp;
    return state.properties.firstOrNull;
  }
}
