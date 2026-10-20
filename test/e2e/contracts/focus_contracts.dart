// E2E Contract Definitions: Focus Engine, Monotonic Stopwatch, Pomodoro, Exam Timer, Strict Lock
// Grounded in PROJECT.md and ORIGINAL_REQUEST.md (R2, AC4, AC5)

enum SessionType {
  stopwatch,
  pomodoro,
  mockExam,
}

enum FocusState {
  idle,
  running,
  paused,
  completed,
  abandoned,
}

enum PomodoroStage {
  work,
  shortBreak,
  longBreak,
}

class FocusContext {
  final String taskId;
  final String? rowId;
  final String? pageId;
  final String title;
  final String? subjectId;

  FocusContext({
    required this.taskId,
    this.rowId,
    this.pageId,
    required this.title,
    this.subjectId,
  });
}

class FocusInterval {
  final int startEpochMs;
  final int? endEpochMs;
  final int durationSeconds;

  FocusInterval({
    required this.startEpochMs,
    this.endEpochMs,
    required this.durationSeconds,
  });
}

class FocusSession {
  final String id;
  final String subjectId;
  final SessionType sessionType;
  final FocusContext? linkedContext;
  final int startEpochMs;
  final int? targetDurationSeconds;
  final int totalElapsedSeconds;
  final int pausedDurationMs;
  final int interruptionsCount;
  final int interruptionDurationSeconds;
  final FocusState status;
  final List<FocusInterval> intervals;

  FocusSession({
    required this.id,
    required this.subjectId,
    required this.sessionType,
    this.linkedContext,
    required this.startEpochMs,
    this.targetDurationSeconds,
    this.totalElapsedSeconds = 0,
    this.pausedDurationMs = 0,
    this.interruptionsCount = 0,
    this.interruptionDurationSeconds = 0,
    this.status = FocusState.idle,
    List<FocusInterval>? intervals,
  }) : intervals = intervals ?? [];

  FocusSession copyWith({
    String? id,
    String? subjectId,
    SessionType? sessionType,
    FocusContext? linkedContext,
    int? startEpochMs,
    int? targetDurationSeconds,
    int? totalElapsedSeconds,
    int? pausedDurationMs,
    int? interruptionsCount,
    int? interruptionDurationSeconds,
    FocusState? status,
    List<FocusInterval>? intervals,
  }) {
    return FocusSession(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      sessionType: sessionType ?? this.sessionType,
      linkedContext: linkedContext ?? this.linkedContext,
      startEpochMs: startEpochMs ?? this.startEpochMs,
      targetDurationSeconds: targetDurationSeconds ?? this.targetDurationSeconds,
      totalElapsedSeconds: totalElapsedSeconds ?? this.totalElapsedSeconds,
      pausedDurationMs: pausedDurationMs ?? this.pausedDurationMs,
      interruptionsCount: interruptionsCount ?? this.interruptionsCount,
      interruptionDurationSeconds:
          interruptionDurationSeconds ?? this.interruptionDurationSeconds,
      status: status ?? this.status,
      intervals: intervals ?? List.from(this.intervals),
    );
  }
}

class FocusSessionSummary {
  final String sessionId;
  final int totalElapsedSeconds;
  final bool markTaskCompleted;
  final List<FocusInterval> intervals;
  final int interruptionsCount;
  final int interruptionSeconds;

  FocusSessionSummary({
    required this.sessionId,
    required this.totalElapsedSeconds,
    required this.markTaskCompleted,
    required this.intervals,
    this.interruptionsCount = 0,
    this.interruptionSeconds = 0,
  });
}

class StrictLockConfig {
  final bool isStrictLockEnabled;
  final int gracePeriodSeconds;
  final Set<String> allowlistPackages;

  StrictLockConfig({
    this.isStrictLockEnabled = false,
    this.gracePeriodSeconds = 10,
    Set<String>? allowlistPackages,
  }) : allowlistPackages = allowlistPackages ?? {'com.hampa.scratchpad', 'com.android.calculator2'};
}

abstract class IFocusEngineService {
  Stream<FocusSession> get sessionStream;
  FocusSession? get currentSession;

  Future<FocusSession> startSession({
    required String subjectId,
    required SessionType sessionType,
    FocusContext? linkedContext,
    int? targetDurationSeconds,
  });
  Future<void> pauseSession();
  Future<void> resumeSession();
  Future<FocusSessionSummary> completeSession({required bool markTaskCompleted});
  Future<void> abandonSession({required String reason});

  // Strict Lock & Interruption tracking
  void handleLifecycleChange({required bool isForeground, String? activePackageName});
  void setStrictLock(bool enabled);
  bool get isStrictLockActive;
  int get activeInterruptionCount;

  // Sensor Flip-to-Focus
  void handleSensorUpdate({required double zAxisAcceleration, required bool isNear});
  bool get isFlippedFaceDown;

  // Ambient soundscape
  void setAmbientTrackVolume({required String trackId, required double volume});
  double getAmbientTrackVolume(String trackId);
}
