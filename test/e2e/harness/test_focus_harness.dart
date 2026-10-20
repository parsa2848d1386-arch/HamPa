// Test Reference Harness: Focus Engine, Monotonic Stopwatch & Strict Lock
// Grounded in PROJECT.md (F17–F23, AC4, AC5)

import 'dart:async';
import '../contracts/focus_contracts.dart';

class TestFocusEngine implements IFocusEngineService {
  FocusSession? _session;
  final StreamController<FocusSession> _sessionController =
      StreamController<FocusSession>.broadcast();

  bool _isStrictLockEnabled = false;
  int _interruptionsCount = 0;
  int _interruptionDurationSeconds = 0;
  DateTime? _lastBackgroundEpoch;
  final Set<String> _allowlistPackages = {
    'com.hampa.scratchpad',
    'com.android.calculator2',
    'com.hampa.ambient_sound',
  };

  bool _isFlippedFaceDown = false;
  DateTime? _lastFlipTriggerEpoch;

  final Map<String, double> _ambientVolumes = {
    'rain': 0.0,
    'white_noise': 0.0,
    'cafe': 0.0,
    'library': 0.0,
    'waves': 0.0,
  };

  // Simulated monotonic clock offset (for testing time transitions)
  int _timeOffsetMs = 0;

  int _nowMs() => DateTime.now().millisecondsSinceEpoch + _timeOffsetMs;

  void advanceTimeSeconds(int seconds) {
    _timeOffsetMs += seconds * 1000;
    _updateElapsed();
  }

  void _notifySession() {
    if (_session != null) {
      _sessionController.add(_session!);
    }
  }

  void _updateElapsed() {
    if (_session != null && _session!.status == FocusState.running) {
      final now = _nowMs();
      final currentIntervalElapsed = (now - _session!.startEpochMs) ~/ 1000;
      final totalElapsed = currentIntervalElapsed - (_session!.pausedDurationMs ~/ 1000);
      _session = _session!.copyWith(
        totalElapsedSeconds: totalElapsed > 0 ? totalElapsed : 0,
      );
      _notifySession();
    }
  }

  @override
  Stream<FocusSession> get sessionStream => _sessionController.stream;

  @override
  FocusSession? get currentSession => _session;

  @override
  bool get isStrictLockActive => _isStrictLockEnabled;

  @override
  int get activeInterruptionCount => _interruptionsCount;

  @override
  bool get isFlippedFaceDown => _isFlippedFaceDown;

  @override
  void setStrictLock(bool enabled) {
    _isStrictLockEnabled = enabled;
  }

  @override
  Future<FocusSession> startSession({
    required String subjectId,
    required SessionType sessionType,
    FocusContext? linkedContext,
    int? targetDurationSeconds,
  }) async {
    final now = _nowMs();
    final session = FocusSession(
      id: 'session_${DateTime.now().microsecondsSinceEpoch}',
      subjectId: subjectId,
      sessionType: sessionType,
      linkedContext: linkedContext,
      startEpochMs: now,
      targetDurationSeconds: targetDurationSeconds,
      status: FocusState.running,
      intervals: [
        FocusInterval(
          startEpochMs: now,
          durationSeconds: 0,
        ),
      ],
    );
    _session = session;
    _interruptionsCount = 0;
    _interruptionDurationSeconds = 0;
    _notifySession();
    return session;
  }

  @override
  Future<void> pauseSession() async {
    if (_session == null || _session!.status != FocusState.running) return;
    final now = _nowMs();
    _updateElapsed();

    // Close active interval
    final currentInterval = _session!.intervals.last;
    final intervalDuration = (now - currentInterval.startEpochMs) ~/ 1000;
    final updatedInterval = FocusInterval(
      startEpochMs: currentInterval.startEpochMs,
      endEpochMs: now,
      durationSeconds: intervalDuration > 0 ? intervalDuration : 0,
    );

    final intervals = List<FocusInterval>.from(_session!.intervals)
      ..removeLast()
      ..add(updatedInterval);

    _session = _session!.copyWith(
      status: FocusState.paused,
      intervals: intervals,
    );
    _notifySession();
  }

  @override
  Future<void> resumeSession() async {
    if (_session == null || _session!.status != FocusState.paused) return;
    final now = _nowMs();

    // Calculate pause duration since last interval closed
    final lastEnd = _session!.intervals.last.endEpochMs ?? now;
    final pauseDelta = now - lastEnd;

    final intervals = List<FocusInterval>.from(_session!.intervals)
      ..add(FocusInterval(startEpochMs: now, durationSeconds: 0));

    _session = _session!.copyWith(
      status: FocusState.running,
      pausedDurationMs: _session!.pausedDurationMs + (pauseDelta > 0 ? pauseDelta : 0),
      intervals: intervals,
    );
    _notifySession();
  }

  @override
  Future<FocusSessionSummary> completeSession({required bool markTaskCompleted}) async {
    if (_session == null) throw StateError('No active focus session to complete');
    final now = _nowMs();
    _updateElapsed();

    // Close last open interval
    if (_session!.intervals.isNotEmpty && _session!.intervals.last.endEpochMs == null) {
      final currentInterval = _session!.intervals.last;
      final intervalDuration = (now - currentInterval.startEpochMs) ~/ 1000;
      final updatedInterval = FocusInterval(
        startEpochMs: currentInterval.startEpochMs,
        endEpochMs: now,
        durationSeconds: intervalDuration > 0 ? intervalDuration : 0,
      );
      final intervals = List<FocusInterval>.from(_session!.intervals)
        ..removeLast()
        ..add(updatedInterval);
      _session = _session!.copyWith(intervals: intervals);
    }

    final summary = FocusSessionSummary(
      sessionId: _session!.id,
      totalElapsedSeconds: _session!.totalElapsedSeconds,
      markTaskCompleted: markTaskCompleted,
      intervals: _session!.intervals,
      interruptionsCount: _interruptionsCount,
      interruptionSeconds: _interruptionDurationSeconds,
    );

    _session = _session!.copyWith(status: FocusState.completed);
    _notifySession();
    return summary;
  }

  @override
  Future<void> abandonSession({required String reason}) async {
    if (_session == null) return;
    _session = _session!.copyWith(status: FocusState.abandoned);
    _notifySession();
  }

  @override
  void handleLifecycleChange({required bool isForeground, String? activePackageName}) {
    if (!_isStrictLockEnabled || _session == null || _session!.status != FocusState.running) {
      return;
    }

    final now = DateTime.now();

    if (!isForeground) {
      // Backgrounded: check if active package is whitelisted
      if (activePackageName != null && _allowlistPackages.contains(activePackageName)) {
        return; // Whitelisted, no interruption
      }
      _lastBackgroundEpoch = now;
      _interruptionsCount++;
    } else {
      // Foreground resumed
      if (_lastBackgroundEpoch != null) {
        final duration = now.difference(_lastBackgroundEpoch!).inSeconds;
        _interruptionDurationSeconds += duration;
        _lastBackgroundEpoch = null;
      }
    }

    _session = _session!.copyWith(
      interruptionsCount: _interruptionsCount,
      interruptionDurationSeconds: _interruptionDurationSeconds,
    );
    _notifySession();
  }

  @override
  void handleSensorUpdate({required double zAxisAcceleration, required bool isNear}) {
    final now = DateTime.now();
    // Phone face-down condition: Z <= -9.2 m/s^2 and proximity near
    final isDown = zAxisAcceleration <= -9.2 && isNear;

    if (isDown != _isFlippedFaceDown) {
      // Debounce threshold: 1500ms
      if (_lastFlipTriggerEpoch == null ||
          now.difference(_lastFlipTriggerEpoch!).inMilliseconds >= 1500) {
        _isFlippedFaceDown = isDown;
        _lastFlipTriggerEpoch = now;

        if (_isFlippedFaceDown) {
          if (_session != null && _session!.status == FocusState.paused) {
            resumeSession();
          }
        } else {
          if (_session != null && _session!.status == FocusState.running) {
            pauseSession();
          }
        }
      }
    }
  }

  @override
  void setAmbientTrackVolume({required String trackId, required double volume}) {
    _ambientVolumes[trackId] = volume.clamp(0.0, 1.0);
  }

  @override
  double getAmbientTrackVolume(String trackId) => _ambientVolumes[trackId] ?? 0.0;
}
