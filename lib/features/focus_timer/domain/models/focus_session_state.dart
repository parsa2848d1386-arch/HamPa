enum TimerMode {
  stopwatch,
  pomodoro,
  exam,
}

enum TimerStatus {
  initial,
  running,
  paused,
  completed,
}

class FocusSessionState {
  final String? activeSessionId;
  final String? activeSubjectId;
  final String? activePageId;
  final String? taskTitle;
  final String? databaseId;
  final String? rowId;
  final String? subjectName;
  final TimerMode mode;
  final TimerStatus status;
  final DateTime? startTime;
  final int elapsedSeconds;
  final int targetSeconds;
  final int pauseAccumulatedSeconds;
  final List<int> laps;
  final bool isStrictLockActive;
  final bool isAmbientSoundPlaying;
  final String? activeSoundTrack;
  final int interruptionCount;
  final int interruptionDurationSeconds;
  final bool isGracePeriodActive;
  final int graceRemainingSeconds;

  const FocusSessionState({
    this.activeSessionId,
    this.activeSubjectId,
    this.activePageId,
    this.taskTitle,
    this.databaseId,
    this.rowId,
    this.subjectName,
    this.mode = TimerMode.stopwatch,
    this.status = TimerStatus.initial,
    this.startTime,
    this.elapsedSeconds = 0,
    this.targetSeconds = 1500, // 25 min default
    this.pauseAccumulatedSeconds = 0,
    this.laps = const [],
    this.isStrictLockActive = false,
    this.isAmbientSoundPlaying = false,
    this.activeSoundTrack,
    this.interruptionCount = 0,
    this.interruptionDurationSeconds = 0,
    this.isGracePeriodActive = false,
    this.graceRemainingSeconds = 0,
  });

  bool get isRunning => status == TimerStatus.running;
  bool get isPaused => status == TimerStatus.paused;

  FocusSessionState copyWith({
    String? activeSessionId,
    String? activeSubjectId,
    String? activePageId,
    String? taskTitle,
    String? databaseId,
    String? rowId,
    String? subjectName,
    TimerMode? mode,
    TimerStatus? status,
    DateTime? startTime,
    int? elapsedSeconds,
    int? targetSeconds,
    int? pauseAccumulatedSeconds,
    List<int>? laps,
    bool? isStrictLockActive,
    bool? isAmbientSoundPlaying,
    String? activeSoundTrack,
    bool clearActiveSoundTrack = false,
    int? interruptionCount,
    int? interruptionDurationSeconds,
    bool? isGracePeriodActive,
    int? graceRemainingSeconds,
  }) {
    return FocusSessionState(
      activeSessionId: activeSessionId ?? this.activeSessionId,
      activeSubjectId: activeSubjectId ?? this.activeSubjectId,
      activePageId: activePageId ?? this.activePageId,
      taskTitle: taskTitle ?? this.taskTitle,
      databaseId: databaseId ?? this.databaseId,
      rowId: rowId ?? this.rowId,
      subjectName: subjectName ?? this.subjectName,
      mode: mode ?? this.mode,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      targetSeconds: targetSeconds ?? this.targetSeconds,
      pauseAccumulatedSeconds: pauseAccumulatedSeconds ?? this.pauseAccumulatedSeconds,
      laps: laps ?? this.laps,
      isStrictLockActive: isStrictLockActive ?? this.isStrictLockActive,
      isAmbientSoundPlaying: isAmbientSoundPlaying ?? this.isAmbientSoundPlaying,
      activeSoundTrack: clearActiveSoundTrack ? null : (activeSoundTrack ?? this.activeSoundTrack),
      interruptionCount: interruptionCount ?? this.interruptionCount,
      interruptionDurationSeconds: interruptionDurationSeconds ?? this.interruptionDurationSeconds,
      isGracePeriodActive: isGracePeriodActive ?? this.isGracePeriodActive,
      graceRemainingSeconds: graceRemainingSeconds ?? this.graceRemainingSeconds,
    );
  }
}
