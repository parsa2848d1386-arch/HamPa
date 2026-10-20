import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:hampa/features/workspace_database/domain/models/aggregation_type.dart';
import 'package:hampa/features/workspace_database/domain/models/property_entity.dart';
import 'package:hampa/features/workspace_database/domain/models/property_type.dart';
import 'package:hampa/features/workspace_database/presentation/controllers/database_view_cubit.dart';
import 'package:hampa/features/workspace_database/presentation/controllers/database_view_state.dart';
import 'package:hampa/features/workspace_database/presentation/widgets/cell_editors/inline_cell_editor.dart';

class TableViewWidget extends StatelessWidget {
  final void Function(String pageId)? onOpenRowPage;

  const TableViewWidget({super.key, this.onOpenRowPage});

  IconData _iconForProp(PropertyType type) {
    switch (type) {
      case PropertyType.title:
        return Icons.title;
      case PropertyType.text:
        return Icons.text_fields;
      case PropertyType.number:
        return Icons.numbers;
      case PropertyType.select:
      case PropertyType.status:
        return Icons.arrow_drop_down_circle_outlined;
      case PropertyType.multiSelect:
        return Icons.checklist;
      case PropertyType.date:
        return Icons.calendar_today;
      case PropertyType.checkbox:
        return Icons.check_box_outlined;
      case PropertyType.relation:
        return Icons.link;
      case PropertyType.rollup:
        return Icons.calculate_outlined;
      case PropertyType.formula:
        return Icons.functions;
      default:
        return Icons.more_horiz;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DatabaseViewCubit>();
    final theme = Theme.of(context);

    return BlocBuilder<DatabaseViewCubit, DatabaseViewState>(
      builder: (context, state) {
        if (state.properties.isEmpty) {
          return const Center(child: Text('No properties defined.'));
        }

        // Visible properties ordered by layout
        final sortedProps = List<PropertyEntity>.from(state.properties);
        sortedProps.sort((a, b) {
          final orderA = state.columnLayouts[a.id]?.orderIndex ?? 0;
          final orderB = state.columnLayouts[b.id]?.orderIndex ?? 0;
          return orderA.compareTo(orderB);
        });

        final visibleProps = sortedProps.where((p) {
          return state.columnLayouts[p.id]?.isVisible ?? true;
        }).toList();

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: visibleProps.fold<double>(
              0.0,
              (acc, p) => acc + (state.columnLayouts[p.id]?.width ?? 160.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Row
                Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    border: Border(bottom: BorderSide(color: theme.dividerColor)),
                  ),
                  child: Row(
                    children: visibleProps.map((prop) {
                      final width = state.columnLayouts[prop.id]?.width ?? 160.0;
                      return SizedBox(
                        width: width,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            children: [
                              Icon(_iconForProp(prop.type), size: 14, color: theme.colorScheme.primary),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  prop.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                // Data Rows
                Expanded(
                  child: ListView.builder(
                    itemCount: state.visibleRows.length,
                    itemBuilder: (context, index) {
                      final row = state.visibleRows[index];
                      return Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: index.isEven ? theme.colorScheme.surface : theme.colorScheme.surfaceContainerLowest,
                          border: Border(bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5))),
                        ),
                        child: Row(
                          children: visibleProps.map((prop) {
                            final width = state.columnLayouts[prop.id]?.width ?? 160.0;
                            final cellVal = state.getCellValue(row.id, prop.id);

                            return SizedBox(
                              width: width,
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border(right: BorderSide(color: theme.dividerColor.withValues(alpha: 0.3))),
                                ),
                                child: InlineCellEditor(
                                  property: prop,
                                  rowId: row.id,
                                  value: cellVal,
                                  onValueChanged: (val) {
                                    cubit.updateCellValue(
                                      rowId: row.id,
                                      propertyId: prop.id,
                                      value: val,
                                    );
                                  },
                                  onOpenDocument: () => onOpenRowPage?.call(row.pageId),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                ),

                // Footer Aggregations Row
                Container(
                  height: 36,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    border: Border(top: BorderSide(color: theme.dividerColor, width: 1.2)),
                  ),
                  child: Row(
                    children: visibleProps.map((prop) {
                      final width = state.columnLayouts[prop.id]?.width ?? 160.0;
                      final aggType = state.footerAggregations[prop.id] ?? AggregationType.none;

                      // Extract all values for column
                      final values = state.visibleRows
                          .map((r) => state.getCellValue(r.id, prop.id))
                          .where((v) => v != null)
                          .toList();

                      final aggResult = aggType.compute(values);

                      return SizedBox(
                        width: width,
                        child: InkWell(
                          onTap: () => _showAggregationPicker(context, cubit, prop),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    aggType == AggregationType.none
                                        ? 'Calculate'
                                        : '${aggType.name}: ${aggType.formatResult(aggResult)}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: aggType == AggregationType.none ? Colors.grey : theme.colorScheme.primary,
                                      fontWeight: aggType == AggregationType.none ? FontWeight.normal : FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Icon(Icons.arrow_drop_down, size: 14, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAggregationPicker(BuildContext context, DatabaseViewCubit cubit, PropertyEntity prop) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return ListView(
          shrinkWrap: true,
          children: AggregationType.values.map((agg) {
            return ListTile(
              title: Text(agg.name),
              onTap: () {
                cubit.setFooterAggregation(prop.id, agg);
                Navigator.pop(ctx);
              },
            );
          }).toList(),
        );
      },
    );
  }
}
