import 'package:flutter/material.dart';

class TimetableBlock {
  final int index; // 0 to 143 (144 blocks of 10-min in 24 hours, starting 05:00 AM)
  final String? subjectId;
  final String? subjectName;
  final Color? color;
  final int minutesStudied;
  final double fillRatio;
  final bool isPulsing;

  const TimetableBlock({
    required this.index,
    this.subjectId,
    this.subjectName,
    this.color,
    this.minutesStudied = 0,
    this.fillRatio = 1.0,
    this.isPulsing = false,
  });

  DateTime get blockStartTime {
    return DateTime(2026, 1, 1, 5, 0).add(Duration(minutes: index * 10));
  }

  DateTime calculateStartTime(DateTime baseDate) {
    return DateTime(baseDate.year, baseDate.month, baseDate.day, 5, 0)
        .add(Duration(minutes: index * 10));
  }

  TimetableBlock copyWith({
    int? index,
    String? subjectId,
    String? subjectName,
    Color? color,
    int? minutesStudied,
    double? fillRatio,
    bool? isPulsing,
  }) {
    return TimetableBlock(
      index: index ?? this.index,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      color: color ?? this.color,
      minutesStudied: minutesStudied ?? this.minutesStudied,
      fillRatio: fillRatio ?? this.fillRatio,
      isPulsing: isPulsing ?? this.isPulsing,
    );
  }
}

class TimetableState {
  final DateTime date;
  final List<TimetableBlock> blocks;

  const TimetableState({
    required this.date,
    required this.blocks,
  });

  factory TimetableState.empty(DateTime date) {
    return TimetableState(
      date: date,
      blocks: List.generate(
        144,
        (i) => TimetableBlock(index: i),
      ),
    );
  }

  /// Projects a study session starting at [start] onto the 144 10-minute blocks
  /// with 05:00 AM cutoff handling (preserves sessions between 00:00 and 04:59).
  TimetableState withSession({
    required String subjectId,
    required String subjectName,
    required Color color,
    required DateTime start,
    required int durationSeconds,
  }) {
    final totalMinutesSinceMidnight = start.hour * 60 + start.minute;
    const cutoffMinutes = 5 * 60; // 300 minutes (05:00 AM)

    int minutesSinceCutoff;
    if (totalMinutesSinceMidnight >= cutoffMinutes) {
      minutesSinceCutoff = totalMinutesSinceMidnight - cutoffMinutes;
    } else {
      minutesSinceCutoff = totalMinutesSinceMidnight + (1440 - cutoffMinutes);
    }

    final startIndex = (minutesSinceCutoff ~/ 10).clamp(0, 143);
    final blockSpan = ((durationSeconds / 60) / 10).ceil().clamp(1, 144 - startIndex);

    final updatedBlocks = List<TimetableBlock>.from(blocks);
    for (int i = 0; i < blockSpan; i++) {
      final targetIdx = startIndex + i;
      if (targetIdx < 144) {
        updatedBlocks[targetIdx] = TimetableBlock(
          index: targetIdx,
          subjectId: subjectId,
          subjectName: subjectName,
          color: color,
          minutesStudied: 10,
          fillRatio: 1.0,
        );
      }
    }

    return TimetableState(date: date, blocks: updatedBlocks);
  }

  /// Helper to get current active slot index based on time
  static int timeToSlotIndex(DateTime time, {int cutoffHour = 5}) {
    final totalMinutesSinceMidnight = time.hour * 60 + time.minute;
    final cutoffMinutes = cutoffHour * 60;

    int minutesSinceCutoff;
    if (totalMinutesSinceMidnight >= cutoffMinutes) {
      minutesSinceCutoff = totalMinutesSinceMidnight - cutoffMinutes;
    } else {
      minutesSinceCutoff = totalMinutesSinceMidnight + (1440 - cutoffMinutes);
    }

    final slot = minutesSinceCutoff ~/ 10;
    return slot.clamp(0, 143);
  }
}
