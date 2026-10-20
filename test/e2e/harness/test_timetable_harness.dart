// Test Reference Harness: 24-Hour 10-Minute Timetable Grid
// Grounded in PROJECT.md (F24, F25, AC6, E01)

import 'dart:async';
import '../contracts/timetable_contracts.dart';

class TestTimetableEngine implements ITimetableProjectionEngine {
  final StreamController<List<GridBlockState>> _gridController =
      StreamController<List<GridBlockState>>.broadcast();

  List<StudyInterval> _currentDayIntervals = [];
  Map<String, SubjectEntity> _subjectMap = {};
  DateTime _studyDay = DateTime.now();

  TestTimetableEngine() {
    _notifyGrid();
  }

  void _notifyGrid() {
    final grid = projectIntervalsToGrid(
      studyDay: _studyDay,
      intervals: _currentDayIntervals,
      subjectMap: _subjectMap,
    );
    _gridController.add(grid);
  }

  @override
  Stream<List<GridBlockState>> watchTodayGrid() => _gridController.stream;

  void updateIntervals({
    required DateTime studyDay,
    required List<StudyInterval> intervals,
    required Map<String, SubjectEntity> subjectMap,
  }) {
    _studyDay = studyDay;
    _currentDayIntervals = intervals;
    _subjectMap = subjectMap;
    _notifyGrid();
  }

  @override
  int timeToSlotIndex(DateTime time, {int cutoffHour = 5}) {
    // 05:00 AM is minute 0 of the study day (total 1440 minutes)
    final totalMinutesSinceMidnight = time.hour * 60 + time.minute;
    final cutoffMinutes = cutoffHour * 60; // 300 minutes (05:00)

    int minutesSinceCutoff;
    if (totalMinutesSinceMidnight >= cutoffMinutes) {
      minutesSinceCutoff = totalMinutesSinceMidnight - cutoffMinutes;
    } else {
      minutesSinceCutoff = totalMinutesSinceMidnight + (1440 - cutoffMinutes);
    }

    final slot = minutesSinceCutoff ~/ 10;
    return slot.clamp(0, 143);
  }

  @override
  List<GridBlockState> projectIntervalsToGrid({
    required DateTime studyDay,
    required List<StudyInterval> intervals,
    required Map<String, SubjectEntity> subjectMap,
    DateTime? currentTime,
    int cutoffHour = 5,
  }) {
    // Build 144 empty slots starting at 05:00 AM on studyDay
    final studyDayStart = DateTime(studyDay.year, studyDay.month, studyDay.day, cutoffHour, 0, 0);
    final studyDayEnd = studyDayStart.add(const Duration(hours: 24));

    final grid = List<GridBlockState>.generate(144, (index) {
      final slotStart = studyDayStart.add(Duration(minutes: index * 10));
      final slotEnd = slotStart.add(const Duration(minutes: 10));
      return GridBlockState(
        slotIndex: index,
        startTime: slotStart,
        endTime: slotEnd,
      );
    });

    // Project each interval onto the grid
    for (final interval in intervals) {
      // Bisect interval if it crosses boundaries
      final effectiveStart = interval.start.isBefore(studyDayStart) ? studyDayStart : interval.start;
      final effectiveEnd = interval.end.isAfter(studyDayEnd) ? studyDayEnd : interval.end;

      if (effectiveEnd.isBefore(effectiveStart) || effectiveStart.isAfter(studyDayEnd)) {
        continue; // Outside this study day window
      }

      final startSlot = timeToSlotIndex(effectiveStart, cutoffHour: cutoffHour);
      final endSlot = timeToSlotIndex(
        effectiveEnd.subtract(const Duration(milliseconds: 1)),
        cutoffHour: cutoffHour,
      );

      final subject = subjectMap[interval.subjectId];
      final color = subject?.colorHex ?? '#2196F3';

      for (var slot = startSlot; slot <= endSlot; slot++) {
        final currentSlotState = grid[slot];
        final slotStart = currentSlotState.startTime;
        final slotEnd = currentSlotState.endTime;

        // Calculate overlap
        final overlapStart = effectiveStart.isAfter(slotStart) ? effectiveStart : slotStart;
        final overlapEnd = effectiveEnd.isBefore(slotEnd) ? effectiveEnd : slotEnd;
        final overlapMs = overlapEnd.difference(overlapStart).inMilliseconds;
        final ratio = (overlapMs / (10 * 60 * 1000)).clamp(0.0, 1.0);

        final isPulsing = currentTime != null &&
            (currentTime.isAfter(slotStart) && currentTime.isBefore(slotEnd));

        grid[slot] = currentSlotState.copyWith(
          subjectId: interval.subjectId,
          colorHex: color,
          fillRatio: (currentSlotState.fillRatio + ratio).clamp(0.0, 1.0),
          isPulsing: isPulsing,
        );
      }
    }

    return grid;
  }
}
