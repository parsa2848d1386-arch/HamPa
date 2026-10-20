import 'package:flutter/material.dart';
import '../../domain/models/timetable_state.dart';

/// High-performance CustomPainter rendering 144 10-minute blocks (05:00 AM - 05:00 AM next day)
/// with subject color coding, border grid, and pulsing active slot animation.
class TimetablePainter extends CustomPainter {
  final TimetableState timetable;
  final double pulseValue;
  final int activeSlotIndex;
  final bool isDarkMode;
  final Color emptySlotColor;
  final Color borderColor;

  TimetablePainter({
    required this.timetable,
    required this.pulseValue,
    required this.activeSlotIndex,
    required this.isDarkMode,
    required this.emptySlotColor,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double hourLabelWidth = 48.0;
    final double rowHeight = size.height / 24.0;
    final double availableWidth = (size.width - hourLabelWidth).clamp(1.0, double.infinity);
    final double slotWidth = availableWidth / 6.0;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final labelStyle = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      color: isDarkMode ? Colors.white60 : Colors.black54,
    );

    for (int hourRow = 0; hourRow < 24; hourRow++) {
      final double rowTop = hourRow * rowHeight;
      final int displayHour = (5 + hourRow) % 24;
      final String hourLabel = '${displayHour.toString().padLeft(2, '0')}:00';

      // 1. Paint hour label
      final textSpan = TextSpan(text: hourLabel, style: labelStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(2.0, rowTop + (rowHeight - textPainter.height) / 2.0),
      );

      // 2. Paint 6 10-minute slots for this hour
      for (int slot = 0; slot < 6; slot++) {
        final int blockIndex = (hourRow * 6) + slot;
        final TimetableBlock block = timetable.blocks[blockIndex];
        final bool hasStudy = block.color != null;
        final bool isPulsing = block.isPulsing || blockIndex == activeSlotIndex;

        final double slotLeft = hourLabelWidth + (slot * slotWidth) + 1.5;
        final double slotTop = rowTop + 2.0;
        final double slotW = (slotWidth - 3.0).clamp(1.0, double.infinity);
        final double slotH = (rowHeight - 4.0).clamp(1.0, double.infinity);

        final cellRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(slotLeft, slotTop, slotW, slotH),
          const Radius.circular(3.0),
        );

        // Fill background
        if (hasStudy) {
          final fillPaint = Paint()
            ..color = block.color!
            ..style = PaintingStyle.fill;
          canvas.drawRRect(cellRect, fillPaint);
        } else {
          final emptyPaint = Paint()
            ..color = emptySlotColor
            ..style = PaintingStyle.fill;
          canvas.drawRRect(cellRect, emptyPaint);
        }

        // Draw border
        canvas.drawRRect(cellRect, borderPaint);

        // Active pulsing animation overlay
        if (isPulsing) {
          final Color pulseColor = (block.color ?? Colors.blueAccent)
              .withValues(alpha: 0.25 + 0.45 * pulseValue);
          final pulseFillPaint = Paint()
            ..color = pulseColor
            ..style = PaintingStyle.fill;
          canvas.drawRRect(cellRect, pulseFillPaint);

          final pulseBorderPaint = Paint()
            ..color = (isDarkMode ? Colors.white : Colors.blue.shade700)
                .withValues(alpha: 0.5 + 0.5 * pulseValue)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6;
          canvas.drawRRect(cellRect, pulseBorderPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant TimetablePainter oldDelegate) {
    return oldDelegate.timetable != timetable ||
        oldDelegate.pulseValue != pulseValue ||
        oldDelegate.activeSlotIndex != activeSlotIndex ||
        oldDelegate.isDarkMode != isDarkMode ||
        oldDelegate.emptySlotColor != emptySlotColor ||
        oldDelegate.borderColor != borderColor;
  }
}

class VisualTimetableWidget extends StatefulWidget {
  final TimetableState timetable;
  final void Function(TimetableBlock block)? onBlockTap;
  final int? activeSlotIndex;

  const VisualTimetableWidget({
    super.key,
    required this.timetable,
    this.onBlockTap,
    this.activeSlotIndex,
  });

  @override
  State<VisualTimetableWidget> createState() => _VisualTimetableWidgetState();
}

class _VisualTimetableWidgetState extends State<VisualTimetableWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final emptyColor = theme.dividerColor.withValues(alpha: 0.15);
    final borderColor = theme.dividerColor.withValues(alpha: 0.35);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '24-Hour Timetable (05:00 AM - 05:00 AM)',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8.0),
              Flexible(
                child: Text(
                  '144 Blocks (10 min/block)',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double height = (constraints.maxHeight.isFinite && constraints.maxHeight > 200)
                  ? constraints.maxHeight
                  : 648.0;

              return AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return GestureDetector(
                    onTapUp: (details) {
                      const double hourLabelWidth = 48.0;
                      final double rowHeight = height / 24.0;
                      final double availableWidth =
                          (constraints.maxWidth - hourLabelWidth).clamp(1.0, double.infinity);
                      final double slotWidth = availableWidth / 6.0;

                      final localPos = details.localPosition;
                      if (localPos.dx >= hourLabelWidth) {
                        final row = (localPos.dy / rowHeight).floor().clamp(0, 23);
                        final col =
                            ((localPos.dx - hourLabelWidth) / slotWidth).floor().clamp(0, 5);
                        final slotIndex = (row * 6) + col;
                        if (slotIndex >= 0 && slotIndex < 144) {
                          widget.onBlockTap?.call(widget.timetable.blocks[slotIndex]);
                        }
                      }
                    },
                    child: CustomPaint(
                      size: Size(constraints.maxWidth, height),
                      painter: TimetablePainter(
                        timetable: widget.timetable,
                        pulseValue: _pulseController.value,
                        activeSlotIndex: widget.activeSlotIndex ??
                            TimetableState.timeToSlotIndex(DateTime.now()),
                        isDarkMode: isDark,
                        emptySlotColor: emptyColor,
                        borderColor: borderColor,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
