import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:hampa/features/workspace_database/domain/models/property_type.dart';
import 'package:hampa/features/workspace_database/presentation/controllers/database_view_cubit.dart';
import 'package:hampa/features/workspace_database/presentation/controllers/database_view_state.dart';

class CalendarViewWidget extends StatefulWidget {
  final void Function(String pageId)? onOpenRowPage;

  const CalendarViewWidget({super.key, this.onOpenRowPage});

  @override
  State<CalendarViewWidget> createState() => _CalendarViewWidgetState();
}

class _CalendarViewWidgetState extends State<CalendarViewWidget> {
  DateTime _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DatabaseViewCubit>();
    final theme = Theme.of(context);

    return BlocBuilder<DatabaseViewCubit, DatabaseViewState>(
      builder: (context, state) {
        final dateProp = state.properties.where((p) => p.type == PropertyType.date).firstOrNull;
        final titleProp = state.properties.where((p) => p.type == PropertyType.title).firstOrNull;

        if (dateProp == null) {
          return const Center(child: Text('No Date property found in this database.'));
        }

        // Days in month
        final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
        final lastDay = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
        final startWeekday = firstDay.weekday % 7; // Sunday = 0
        final totalCells = ((startWeekday + lastDay.day) <= 35) ? 35 : 42;

        return Column(
          children: [
            // Month Navigation Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    '${_monthName(_focusedMonth.month)} ${_focusedMonth.year}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () {
                      setState(() {
                        _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.today),
                    tooltip: 'Today',
                    onPressed: () {
                      setState(() {
                        _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () {
                      setState(() {
                        _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
                      });
                    },
                  ),
                ],
              ),
            ),

            // Weekday Labels
            Row(
              children: const ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'].map((d) {
                return Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(d, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey)),
                    ),
                  ),
                );
              }).toList(),
            ),

            // Month Grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: 0.85,
                ),
                itemCount: totalCells,
                itemBuilder: (context, index) {
                  final dayOffset = index - startWeekday + 1;
                  final isCurrentMonth = dayOffset >= 1 && dayOffset <= lastDay.day;
                  final cellDate = DateTime(_focusedMonth.year, _focusedMonth.month, dayOffset);
                  final dateIso = isCurrentMonth
                      ? '${cellDate.year.toString().padLeft(4, '0')}-${cellDate.month.toString().padLeft(2, '0')}-${cellDate.day.toString().padLeft(2, '0')}'
                      : '';

                  // Find rows scheduled for this date
                  final scheduledRows = isCurrentMonth
                      ? state.visibleRows.where((r) {
                          final d = state.getCellValue(r.id, dateProp.id);
                          return d?.toString().startsWith(dateIso) ?? false;
                        }).toList()
                      : <dynamic>[];

                  final isToday = isCurrentMonth &&
                      cellDate.year == DateTime.now().year &&
                      cellDate.month == DateTime.now().month &&
                      cellDate.day == DateTime.now().day;

                  return DragTarget<String>(
                    onWillAcceptWithDetails: (details) => isCurrentMonth,
                    onAcceptWithDetails: (details) {
                      cubit.rescheduleRow(
                        rowId: details.data,
                        datePropertyId: dateProp.id,
                        newDateIso: dateIso,
                      );
                    },
                    builder: (context, candidateData, rejectedData) {
                      return Container(
                        decoration: BoxDecoration(
                          color: isCurrentMonth
                              ? (isToday ? theme.colorScheme.primaryContainer.withValues(alpha: 0.2) : theme.colorScheme.surface)
                              : theme.colorScheme.surfaceContainerLowest.withValues(alpha: 0.3),
                          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.4)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Date number
                            Padding(
                              padding: const EdgeInsets.all(4),
                              child: Text(
                                isCurrentMonth ? '$dayOffset' : '',
                                style: TextStyle(
                                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 11,
                                  color: isToday ? theme.colorScheme.primary : (isCurrentMonth ? null : Colors.grey),
                                ),
                              ),
                            ),
                            // Event chips
                            Expanded(
                              child: ListView(
                                children: scheduledRows.map<Widget>((r) {
                                  final title = titleProp != null
                                      ? (state.getCellValue(r.id, titleProp.id)?.toString() ?? 'Untitled')
                                      : 'Untitled';

                                  return Draggable<String>(
                                    data: r.id,
                                    feedback: Material(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        color: theme.colorScheme.primary,
                                        child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 11)),
                                      ),
                                    ),
                                    child: InkWell(
                                      onTap: () => widget.onOpenRowPage?.call(r.pageId),
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primaryContainer,
                                          borderRadius: BorderRadius.circular(3),
                                        ),
                                        child: Text(
                                          title,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                            color: theme.colorScheme.onPrimaryContainer,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  String _monthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}
