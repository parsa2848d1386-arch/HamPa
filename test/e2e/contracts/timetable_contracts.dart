// E2E Contract Definitions: 24-Hour 10-Minute Timetable Grid
// Grounded in PROJECT.md and ORIGINAL_REQUEST.md (R2, AC6)

class SubjectEntity {
  final String id;
  final String name;
  final String colorHex;

  SubjectEntity({
    required this.id,
    required this.name,
    required this.colorHex,
  });
}

class GridBlockState {
  final int slotIndex; // 0 to 143 (144 blocks of 10 min each, starting at 05:00 AM)
  final DateTime startTime;
  final DateTime endTime;
  final String? subjectId;
  final String? colorHex;
  final double fillRatio; // 0.0 to 1.0
  final bool isPulsing;

  GridBlockState({
    required this.slotIndex,
    required this.startTime,
    required this.endTime,
    this.subjectId,
    this.colorHex,
    this.fillRatio = 0.0,
    this.isPulsing = false,
  });

  GridBlockState copyWith({
    int? slotIndex,
    DateTime? startTime,
    DateTime? endTime,
    String? subjectId,
    String? colorHex,
    double? fillRatio,
    bool? isPulsing,
  }) {
    return GridBlockState(
      slotIndex: slotIndex ?? this.slotIndex,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      subjectId: subjectId ?? this.subjectId,
      colorHex: colorHex ?? this.colorHex,
      fillRatio: fillRatio ?? this.fillRatio,
      isPulsing: isPulsing ?? this.isPulsing,
    );
  }
}

class StudyInterval {
  final DateTime start;
  final DateTime end;
  final String subjectId;

  StudyInterval({
    required this.start,
    required this.end,
    required this.subjectId,
  });

  Duration get duration => end.difference(start);
}

abstract class ITimetableProjectionEngine {
  /// Converts a wall clock DateTime into the 0-143 slot index based on 05:00 AM day demarcation.
  int timeToSlotIndex(DateTime time, {int cutoffHour = 5});

  /// Projects a list of study session intervals onto the 144-slot daily timetable.
  /// Automatically bisects intervals crossing the 05:00 AM day-cutoff boundary.
  List<GridBlockState> projectIntervalsToGrid({
    required DateTime studyDay,
    required List<StudyInterval> intervals,
    required Map<String, SubjectEntity> subjectMap,
    DateTime? currentTime,
    int cutoffHour = 5,
  });

  Stream<List<GridBlockState>> watchTodayGrid();
}
