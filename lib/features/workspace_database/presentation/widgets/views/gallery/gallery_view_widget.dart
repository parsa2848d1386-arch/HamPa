import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:hampa/features/workspace_database/domain/models/property_type.dart';
import 'package:hampa/features/workspace_database/presentation/controllers/database_view_cubit.dart';
import 'package:hampa/features/workspace_database/presentation/controllers/database_view_state.dart';

class GalleryViewWidget extends StatelessWidget {
  final void Function(String pageId)? onOpenRowPage;

  const GalleryViewWidget({super.key, this.onOpenRowPage});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<DatabaseViewCubit, DatabaseViewState>(
      builder: (context, state) {
        if (state.visibleRows.isEmpty) {
          return const Center(child: Text('No rows in database.'));
        }

        final titleProp = state.properties.where((p) => p.type == PropertyType.title).firstOrNull;
        final previewProps = state.properties.where((p) => p.type != PropertyType.title).take(2).toList();

        // Cross axis count and aspect ratio based on card size
        int crossAxisCount = 3;
        double childAspectRatio = 0.9;
        if (state.galleryCardSize == 'small') {
          crossAxisCount = 4;
          childAspectRatio = 1.0;
        } else if (state.galleryCardSize == 'large') {
          crossAxisCount = 2;
          childAspectRatio = 1.1;
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final effectiveCount = constraints.maxWidth < 600 ? 2 : crossAxisCount;

            return GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: effectiveCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: childAspectRatio,
              ),
              itemCount: state.visibleRows.length,
              itemBuilder: (context, index) {
                final row = state.visibleRows[index];
                final title = titleProp != null
                    ? (state.getCellValue(row.id, titleProp.id)?.toString() ?? 'Untitled')
                    : 'Untitled';

                return Card(
                  clipBehavior: Clip.antiAlias,
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  child: InkWell(
                    onTap: () => onOpenRowPage?.call(row.pageId),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Card Cover Top
                        Expanded(
                          flex: 3,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
                                  theme.colorScheme.secondaryContainer.withValues(alpha: 0.4),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.article_outlined,
                                size: 32,
                                color: theme.colorScheme.primary.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        ),

                        // Card Body
                        Expanded(
                          flex: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 4,
                                  children: previewProps.map((p) {
                                    final val = state.getCellValue(row.id, p.id);
                                    if (val == null || val.toString().isEmpty) return const SizedBox.shrink();
                                    return Text(
                                      '${p.name}: $val',
                                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
