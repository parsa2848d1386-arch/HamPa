import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/study_sessions_dao.dart';
import '../../domain/models/focus_session_state.dart';

class FocusTimerCubit extends Cubit<FocusSessionState> with WidgetsBindingObserver {
  final StudySessionsDao studySessionsDao;
  Timer? _ticker;
  Timer? _graceTimer;
  DateTime? _pauseStartTime;
  DateTime? _backgroundTime;
  bool _interruptionLoggedForCurrentOutage = false;
  final Stopwatch _stopwatch = Stopwatch();

  FocusTimerCubit({required this.studySessionsDao}) : super(const FocusSessionState()) {
    try {
      WidgetsBinding.instance.addObserver(this);
    } catch (_) {
      // In headless unit test environments, WidgetsBinding might not be initialized
    }
  }

  /// Starts or resumes a focus timer with monotonic delta time computation
  void startTimer({
    required String subjectId,
    String? subjectName,
    String? pageId,
    String? taskTitle,
    String? databaseId,
    String? rowId,
    TimerMode mode = TimerMode.stopwatch,
    int? targetSeconds,
    bool strictLock = false,
  }) {
    _ticker?.cancel();
    _graceTimer?.cancel();
    _stopwatch.reset();
    _stopwatch.start();

    final now = DateTime.now();
    final sessionId = 'session_${now.millisecondsSinceEpoch}';
    final resolvedRowId = rowId ?? pageId;
    final resolvedSubjectName = subjectName ??
        (subjectId.startsWith('sub_') ? subjectId.substring(4) : subjectId);

    emit(state.copyWith(
      activeSessionId: sessionId,
      activeSubjectId: subjectId,
      activePageId: resolvedRowId,
      taskTitle: taskTitle,
      databaseId: databaseId,
      rowId: resolvedRowId,
      subjectName: resolvedSubjectName,
      mode: mode,
      status: TimerStatus.running,
      startTime: now,
      elapsedSeconds: 0,
      targetSeconds: targetSeconds ?? (mode == TimerMode.pomodoro ? 1500 : 3600),
      pauseAccumulatedSeconds: 0,
      laps: [],
      isStrictLockActive: strictLock,
      interruptionCount: 0,
      interruptionDurationSeconds: 0,
      isGracePeriodActive: false,
      graceRemainingSeconds: 0,
    ));

    _startTicker();
  }

  void pauseTimer() {
    if (!state.isRunning) return;
    _ticker?.cancel();
    _stopwatch.stop();
    _pauseStartTime = DateTime.now();
    emit(state.copyWith(status: TimerStatus.paused));
  }

  void resumeTimer() {
    if (!state.isPaused) return;
    final now = DateTime.now();
    int additionalPause = 0;
    if (_pauseStartTime != null) {
      additionalPause = now.difference(_pauseStartTime!).inSeconds;
    }
    _pauseStartTime = null;

    _stopwatch.start();

    emit(state.copyWith(
      status: TimerStatus.running,
      pauseAccumulatedSeconds: state.pauseAccumulatedSeconds + additionalPause,
    ));

    _startTicker();
  }

  void recordLap() {
    if (!state.isRunning) return;
    final updatedLaps = List<int>.from(state.laps)..add(state.elapsedSeconds);
    emit(state.copyWith(laps: updatedLaps));
  }

  void toggleStrictLock() {
    final newStrictLock = !state.isStrictLockActive;
    if (!newStrictLock) {
      _graceTimer?.cancel();
      _graceTimer = null;
      _backgroundTime = null;
      _interruptionLoggedForCurrentOutage = false;
      emit(state.copyWith(
        isStrictLockActive: false,
        isGracePeriodActive: false,
        graceRemainingSeconds: 0,
      ));
    } else {
      emit(state.copyWith(isStrictLockActive: true));
    }
  }

  void toggleAmbientSound(String? trackName) {
    if (state.isAmbientSoundPlaying && state.activeSoundTrack == trackName) {
      emit(state.copyWith(isAmbientSoundPlaying: false, activeSoundTrack: null));
    } else {
      emit(state.copyWith(isAmbientSoundPlaying: true, activeSoundTrack: trackName ?? 'White Noise'));
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    handleLifecycleTransition(state);
  }

  /// Handles app lifecycle transitions for Strict Anti-Distraction Lock with 10s grace period
  void handleLifecycleTransition(AppLifecycleState lifecycleState) {
    if (!state.isRunning || !state.isStrictLockActive) {
      return;
    }

    if (lifecycleState == AppLifecycleState.resumed) {
      // User returned to foreground
      _graceTimer?.cancel();
      _graceTimer = null;

      int additionalInterruptionSeconds = 0;
      if (_backgroundTime != null && _interruptionLoggedForCurrentOutage) {
        final now = DateTime.now();
        additionalInterruptionSeconds = now.difference(_backgroundTime!).inSeconds;
      }
      _backgroundTime = null;
      _interruptionLoggedForCurrentOutage = false;

      emit(state.copyWith(
        isGracePeriodActive: false,
        graceRemainingSeconds: 0,
        interruptionDurationSeconds: state.interruptionDurationSeconds + additionalInterruptionSeconds,
      ));
    } else {
      // App navigated away (paused, inactive, hidden, detached)
      if (_backgroundTime != null) return; // already tracking outage

      _backgroundTime = DateTime.now();
      _interruptionLoggedForCurrentOutage = false;

      emit(state.copyWith(
        isGracePeriodActive: true,
        graceRemainingSeconds: 10,
      ));

      _graceTimer?.cancel();
      int remaining = 10;
      _graceTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        remaining--;
        if (remaining <= 0) {
          timer.cancel();
          _graceTimer = null;
          _interruptionLoggedForCurrentOutage = true;
          emit(state.copyWith(
            isGracePeriodActive: false,
            graceRemainingSeconds: 0,
            interruptionCount: state.interruptionCount + 1,
          ));
        } else {
          emit(state.copyWith(
            isGracePeriodActive: true,
            graceRemainingSeconds: remaining,
          ));
        }
      });
    }
  }

  /// Manually log an interruption event
  void recordInterruption({int durationSeconds = 0}) {
    emit(state.copyWith(
      interruptionCount: state.interruptionCount + 1,
      interruptionDurationSeconds: state.interruptionDurationSeconds + durationSeconds,
    ));
  }

  /// Completes session and writes directly to local-first SQLite
  Future<void> completeSession({String? notes}) async {
    _ticker?.cancel();
    _graceTimer?.cancel();
    _stopwatch.stop();

    final now = DateTime.now();
    final finalDuration = state.elapsedSeconds;
    int totalPause = state.pauseAccumulatedSeconds;
    if (_pauseStartTime != null) {
      totalPause += now.difference(_pauseStartTime!).inSeconds;
      _pauseStartTime = null;
    }

    if (state.activeSessionId != null && state.activeSubjectId != null && finalDuration > 0) {
      await studySessionsDao.insertSession(StudySessionsTableCompanion(
        id: Value(state.activeSessionId!),
        subjectId: Value(state.activeSubjectId!),
        pageId: Value(state.activePageId),
        sessionType: Value(state.mode.name),
        startTime: Value(state.startTime ?? now),
        endTime: Value(now),
        durationSeconds: Value(finalDuration),
        targetSeconds: Value(state.targetSeconds),
        pauseDurationSeconds: Value(totalPause),
        lapCount: Value(state.laps.length),
        isCompleted: const Value(true),
        isDiscarded: const Value(false),
        notes: Value(notes),
        createdAt: Value(now),
      ));
    }

    emit(state.copyWith(
      status: TimerStatus.completed,
      pauseAccumulatedSeconds: totalPause,
    ));
  }

  void discardSession() {
    _ticker?.cancel();
    _graceTimer?.cancel();
    _stopwatch.reset();
    _stopwatch.stop();
    _pauseStartTime = null;
    _backgroundTime = null;
    _interruptionLoggedForCurrentOutage = false;
    emit(const FocusSessionState(status: TimerStatus.initial));
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.startTime == null || !state.isRunning) return;

      // Monotonic Delta Formula backed by high-precision monotonic stopwatch
      final stopwatchElapsed = _stopwatch.elapsed.inSeconds;
      final currentElapsed = stopwatchElapsed.clamp(0, 86400 * 7);

      if (state.mode == TimerMode.pomodoro || state.mode == TimerMode.exam) {
        if (currentElapsed >= state.targetSeconds) {
          emit(state.copyWith(
            elapsedSeconds: state.targetSeconds,
            status: TimerStatus.completed,
          ));
          completeSession();
          return;
        }
      }

      emit(state.copyWith(elapsedSeconds: currentElapsed));
    });
  }

  @override
  Future<void> close() {
    try {
      WidgetsBinding.instance.removeObserver(this);
    } catch (_) {}
    _ticker?.cancel();
    _graceTimer?.cancel();
    _stopwatch.stop();
    return super.close();
  }
}
