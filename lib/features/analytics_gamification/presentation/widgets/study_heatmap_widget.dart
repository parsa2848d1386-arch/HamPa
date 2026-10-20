import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../domain/models/streak_engine.dart';

enum HeatmapViewMode {
  annual,
  monthly,
}

class HeatmapPainter extends CustomPainter {
  final List<List<int>> weekColumns;
  final Color emptyColor;
  final Color level1Color;
  final Color level2Color;
  final Color level3Color;
  final Color level4Color;
  final double cellSpacing;
  final double cornerRadius;

  HeatmapPainter({
    required this.weekColumns,
    required this.emptyColor,
    required this.level1Color,
    required this.level2Color,
    required this.level3Color,
    required this.level4Color,
    this.cellSpacing = 3.0,
    this.cornerRadius = 2.5,
  });

  Color _colorForLevel(int level) {
    switch (level) {
      case 1:
        return level1Color;
      case 2:
        return level2Color;
      case 3:
        return level3Color;
      case 4:
        return level4Color;
      default:
        return emptyColor;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (weekColumns.isEmpty) return;

    final numWeeks = weekColumns.length;
    final cellWidth = (size.width - (numWeeks - 1) * cellSpacing) / numWeeks;
    final cellHeight = (size.height - 6 * cellSpacing) / 7;
    final cellSize = math.max(4.0, math.min(cellWidth, cellHeight));

    final paint = Paint()..style = PaintingStyle.fill;

    for (var w = 0; w < numWeeks; w++) {
      final days = weekColumns[w];
      for (var d = 0; d < days.length && d < 7; d++) {
        final level = days[d];
        paint.color = _colorForLevel(level);

        final x = w * (cellSize + cellSpacing);
        final y = d * (cellSize + cellSpacing);
        final rect = Rect.fromLTWH(x, y, cellSize, cellSize);
        final rrect = RRect.fromRectAndRadius(rect, Radius.circular(cornerRadius));

        canvas.drawRRect(rrect, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant HeatmapPainter oldDelegate) {
    return oldDelegate.weekColumns != weekColumns ||
        oldDelegate.emptyColor != emptyColor ||
        oldDelegate.level1Color != level1Color ||
        oldDelegate.level2Color != level2Color ||
        oldDelegate.level3Color != level3Color ||
        oldDelegate.level4Color != level4Color ||
        oldDelegate.cellSpacing != cellSpacing ||
        oldDelegate.cornerRadius != cornerRadius;
  }
}

class StudyHeatmapWidget extends StatefulWidget {
  final Map<DateTime, int> minutesByDate;
  final int currentStreak;
  final HeatmapViewMode initialViewMode;
  final ValueChanged<HeatmapViewMode>? onViewModeChanged;

  const StudyHeatmapWidget({
    super.key,
    required this.minutesByDate,
    required this.currentStreak,
    this.initialViewMode = HeatmapViewMode.annual,
    this.onViewModeChanged,
  });

  @override
  State<StudyHeatmapWidget> createState() => _StudyHeatmapWidgetState();
}

class _StudyHeatmapWidgetState extends State<StudyHeatmapWidget> {
  late HeatmapViewMode _viewMode;

  @override
  void initState() {
    super.initState();
    _viewMode = widget.initialViewMode;
  }

  List<List<int>> _buildWeekColumns(DateTime today, int weeksCount) {
    final totalDays = weeksCount * 7;
    final startDay = today.subtract(Duration(days: totalDays - 1));

    final columns = <List<int>>[];
    for (var w = 0; w < weeksCount; w++) {
      final weekDays = <int>[];
      for (var d = 0; d < 7; d++) {
        final currentDay = startDay.add(Duration(days: (w * 7) + d));
        final dateKey = DateTime(currentDay.year, currentDay.month, currentDay.day);
        final minutes = widget.minutesByDate[dateKey] ?? 0;
        final level = HeatmapDayEntry.computeIntensity(minutes);
        weekDays.add(level);
      }
      columns.add(weekDays);
    }
    return columns;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = DateTime.now();
    final weeksCount = _viewMode == HeatmapViewMode.annual ? 52 : 5;
    final weekColumns = _buildWeekColumns(today, weeksCount);

    final emptyColor = theme.dividerColor.withValues(alpha: 0.15);
    final l1Color = Colors.green.shade200;
    final l2Color = Colors.green.shade400;
    final l3Color = Colors.green.shade600;
    final l4Color = Colors.green.shade900;

    const cellSize = 13.0;
    const cellSpacing = 3.0;
    final gridWidth = weeksCount * (cellSize + cellSpacing);
    const gridHeight = 7 * (cellSize + cellSpacing);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Streak & View Mode Switcher
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.local_fire_department, color: Colors.orange, size: 24),
                    const SizedBox(width: 6),
                    Text(
                      '${widget.currentStreak} Day Streak',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                // Toggle Button for Annual vs Monthly view mode
                SegmentedButton<HeatmapViewMode>(
                  segments: const [
                    ButtonSegment(
                      value: HeatmapViewMode.annual,
                      label: Text('Annual', style: TextStyle(fontSize: 12)),
                    ),
                    ButtonSegment(
                      value: HeatmapViewMode.monthly,
                      label: Text('Monthly', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                  selected: {_viewMode},
                  onSelectionChanged: (Set<HeatmapViewMode> newSelection) {
                    setState(() {
                      _viewMode = newSelection.first;
                    });
                    widget.onViewModeChanged?.call(_viewMode);
                  },
                  showSelectedIcon: false,
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Heatmap Canvas using CustomPainter
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true, // Scroll to recent days by default
              child: SizedBox(
                width: gridWidth,
                height: gridHeight,
                child: CustomPaint(
                  painter: HeatmapPainter(
                    weekColumns: weekColumns,
                    emptyColor: emptyColor,
                    level1Color: l1Color,
                    level2Color: l2Color,
                    level3Color: l3Color,
                    level4Color: l4Color,
                    cellSpacing: cellSpacing,
                    cornerRadius: 2.5,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Cutoff: 05:00 AM',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
                Row(
                  children: [
                    Text('Less', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                    const SizedBox(width: 4),
                    _LegendBox(color: emptyColor),
                    _LegendBox(color: l1Color),
                    _LegendBox(color: l2Color),
                    _LegendBox(color: l3Color),
                    _LegendBox(color: l4Color),
                    const SizedBox(width: 4),
                    Text('More', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendBox extends StatelessWidget {
  final Color color;
  const _LegendBox({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      margin: const EdgeInsets.symmetric(horizontal: 1.5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
