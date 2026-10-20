import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:hampa/features/workspace_database/domain/models/property_type.dart';
import 'package:hampa/features/workspace_database/presentation/controllers/database_view_cubit.dart';
import 'package:hampa/features/workspace_database/presentation/controllers/database_view_state.dart';

class TimelineViewWidget extends StatelessWidget {
  final void Function(String pageId)? onOpenRowPage;

  const TimelineViewWidget({super.key, this.onOpenRowPage});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<DatabaseViewCubit, DatabaseViewState>(
      builder: (context, state) {
        final dateProp = state.properties.where((p) => p.type == PropertyType.date).firstOrNull;
        final titleProp = state.properties.where((p) => p.type == PropertyType.title).firstOrNull;

        if (state.visibleRows.isEmpty) {
          return const Center(child: Text('No rows in database.'));
        }

        // Timeline base epoch: today minus 7 days to today plus 21 days (30 days total)
        final now = DateTime.now();
        final startEpoch = DateTime(now.year, now.month, now.day - 7);
        const dayWidth = 44.0;
        const totalDays = 30;

        const totalTimelineWidth = totalDays * dayWidth;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: totalTimelineWidth,
            child: Column(
              children: [
                // Top Date Header Ruler
                SizedBox(
                  height: 36,
                  child: Row(
                    children: List.generate(totalDays, (i) {
                  final day = startEpoch.add(Duration(days: i));
                  final isToday = day.year == now.year && day.month == now.month && day.day == now.day;

                  return Container(
                    width: dayWidth,
                    decoration: BoxDecoration(
                      color: isToday ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3) : Colors.transparent,
                      border: Border(
                        right: BorderSide(color: theme.dividerColor.withValues(alpha: 0.3)),
                        bottom: BorderSide(color: theme.dividerColor),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${day.day}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                            color: isToday ? theme.colorScheme.primary : null,
                          ),
                        ),
                        Text(
                          _weekdayShort(day.weekday),
                          style: const TextStyle(fontSize: 9, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),

            // Tasks and Horizontal Bars
            Expanded(
              child: ListView.builder(
                itemCount: state.visibleRows.length,
                itemBuilder: (context, index) {
                  final row = state.visibleRows[index];
                  final title = titleProp != null
                      ? (state.getCellValue(row.id, titleProp.id)?.toString() ?? 'Untitled')
                      : 'Untitled';

                  // Calculate bar offset and width from date property
                  double leftOffset = dayWidth * 7; // Default to 'Today'
                  double barWidth = dayWidth * 2;   // Default 2 days span

                  if (dateProp != null) {
                    final dateVal = state.getCellValue(row.id, dateProp.id);
                    if (dateVal != null) {
                      final parsed = DateTime.tryParse(dateVal.toString());
                      if (parsed != null) {
                        final diffDays = parsed.difference(startEpoch).inDays;
                        leftOffset = (diffDays * dayWidth).clamp(0.0, totalDays * dayWidth);
                      }
                    }
                  }

                  return Container(
                    height: 40,
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.2))),
                    ),
                    child: Stack(
                      children: [
                        // Background grid vertical day lines
                        Row(
                          children: List.generate(totalDays, (i) {
                            return Container(
                              width: dayWidth,
                              decoration: BoxDecoration(
                                border: Border(right: BorderSide(color: theme.dividerColor.withValues(alpha: 0.15))),
                              ),
                            );
                          }),
                        ),

                        // Task Duration Bar
                        Positioned(
                          left: leftOffset,
                          top: 6,
                          child: InkWell(
                            onTap: () => onOpenRowPage?.call(row.pageId),
                            child: Container(
                              width: barWidth,
                              height: 28,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 2,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              alignment: Alignment.centerLeft,
                              child: Text(
                                title,
                                style: TextStyle(
                                  color: theme.colorScheme.onPrimary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  },
);
  }

  String _weekdayShort(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }
}
