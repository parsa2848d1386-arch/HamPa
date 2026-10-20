import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:hampa/features/workspace_database/domain/models/property_type.dart';
import 'package:hampa/features/workspace_database/presentation/controllers/database_view_cubit.dart';
import 'package:hampa/features/workspace_database/presentation/controllers/database_view_state.dart';

class ListViewWidget extends StatelessWidget {
  final void Function(String pageId)? onOpenRowPage;

  const ListViewWidget({super.key, this.onOpenRowPage});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cubit = context.read<DatabaseViewCubit>();

    return BlocBuilder<DatabaseViewCubit, DatabaseViewState>(
      builder: (context, state) {
        if (state.visibleRows.isEmpty) {
          return const Center(child: Text('No rows in database.'));
        }

        final titleProp = state.properties.where((p) => p.type == PropertyType.title).firstOrNull;
        final checkProp = state.properties.where((p) => p.type == PropertyType.checkbox).firstOrNull;
        final secondaryProps = state.properties.where((p) => p.type != PropertyType.title && p.type != PropertyType.checkbox).toList();

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          itemCount: state.visibleRows.length,
          separatorBuilder: (context, index) => Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.3)),
          itemBuilder: (context, index) {
            final row = state.visibleRows[index];
            final title = titleProp != null
                ? (state.getCellValue(row.id, titleProp.id)?.toString() ?? 'Untitled')
                : 'Untitled';

            final isChecked = checkProp != null
                ? (state.getCellValue(row.id, checkProp.id) == true)
                : false;

            return InkWell(
              onTap: () => onOpenRowPage?.call(row.pageId),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Row(
                  children: [
                    if (checkProp != null)
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: isChecked,
                          visualDensity: VisualDensity.compact,
                          onChanged: (val) {
                            cubit.updateCellValue(
                              rowId: row.id,
                              propertyId: checkProp.id,
                              value: val,
                            );
                          },
                        ),
                      ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          decoration: isChecked ? TextDecoration.lineThrough : null,
                          color: isChecked ? Colors.grey : null,
                        ),
                      ),
                    ),
                    // Secondary property pills
                    ...secondaryProps.take(3).map((prop) {
                      final val = state.getCellValue(row.id, prop.id);
                      if (val == null || val.toString().isEmpty) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Chip(
                          label: Text(
                            val.toString(),
                            style: const TextStyle(fontSize: 10),
                          ),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      );
                    }),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
