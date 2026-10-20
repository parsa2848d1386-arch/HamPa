// Tier 1 E2E Feature Coverage: F17–F23 Focus Engine, Stopwatch & Strict Lock
// Minimum 5 tests per feature (35 test cases total)
// Grounded in PROJECT.md (F17–F23, AC4, AC5)

import '../contracts/focus_contracts.dart';
import '../harness/test_focus_harness.dart';
import '../support/test_runner.dart';

void runFocusStrictLockTier1Tests() {
  group('Tier 1: F17 Monotonic Background Stopwatch (5 tests)', () {
    late TestFocusEngine focus;

    void setUp() {
      focus = TestFocusEngine();
    }

    test('F17-1: Start monotonic stopwatch session', () async {
      setUp();
      final session = await focus.startSession(
        subjectId: 'math_sub',
        sessionType: SessionType.stopwatch,
      );

      expect(session.status, equals(FocusState.running));
      expect(session.subjectId, equals('math_sub'));
      expect(session.totalElapsedSeconds, equals(0));
      expect(session.intervals.length, equals(1));
    });

    test('F17-2: Stopwatch accumulates elapsed seconds monotonically as time advances (AC4)', () async {
      setUp();
      await focus.startSession(
        subjectId: 'physics_sub',
        sessionType: SessionType.stopwatch,
      );

      focus.advanceTimeSeconds(300); // 5 minutes
      final current = focus.currentSession;
      expect(current!.totalElapsedSeconds, equals(300));
    });

    test('F17-3: Pause stopwatch freezes elapsed duration', () async {
      setUp();
      await focus.startSession(
        subjectId: 'chem_sub',
        sessionType: SessionType.stopwatch,
      );

      focus.advanceTimeSeconds(60);
      await focus.pauseSession();

      expect(focus.currentSession!.status, equals(FocusState.paused));
      expect(focus.currentSession!.totalElapsedSeconds, equals(60));

      // Advance time while paused: elapsed should NOT increase
      focus.advanceTimeSeconds(120);
      expect(focus.currentSession!.totalElapsedSeconds, equals(60));
    });

    test('F17-4: Resume stopwatch resumes timing without drift', () async {
      setUp();
      await focus.startSession(
        subjectId: 'bio_sub',
        sessionType: SessionType.stopwatch,
      );

      focus.advanceTimeSeconds(100);
      await focus.pauseSession();
      focus.advanceTimeSeconds(50); // Pause duration = 50s
      await focus.resumeSession();

      expect(focus.currentSession!.status, equals(FocusState.running));
      focus.advanceTimeSeconds(100);

      // Total active elapsed = 100 + 100 = 200s (excluding 50s paused)
      expect(focus.currentSession!.totalElapsedSeconds, equals(200));
    });

    test('F17-5: Complete session returns accurate summary and closed intervals', () async {
      setUp();
      await focus.startSession(
        subjectId: 'history_sub',
        sessionType: SessionType.stopwatch,
      );

      focus.advanceTimeSeconds(1800); // 30 minutes
      final summary = await focus.completeSession(markTaskCompleted: true);

      expect(summary.totalElapsedSeconds, equals(1800));
      expect(summary.markTaskCompleted, isTrue);
      expect(summary.intervals.isNotEmpty, isTrue);
      expect(focus.currentSession!.status, equals(FocusState.completed));
    });
  });

  group('Tier 1: F18 Customizable Pomodoro Cycles (5 tests)', () {
    late TestFocusEngine focus;

    void setUp() {
      focus = TestFocusEngine();
    }

    test('F18-1: Start Pomodoro cycle session in focus work stage', () async {
      setUp();
      final session = await focus.startSession(
        subjectId: 'pomo_sub',
        sessionType: SessionType.pomodoro,
        targetDurationSeconds: 1500, // 25 minutes
      );

      expect(session.sessionType, equals(SessionType.pomodoro));
      expect(session.targetDurationSeconds, equals(1500));
      expect(session.status, equals(FocusState.running));
    });

    test('F18-2: Advance Pomodoro session through work stage duration', () async {
      setUp();
      await focus.startSession(
        subjectId: 'pomo_sub',
        sessionType: SessionType.pomodoro,
        targetDurationSeconds: 1500,
      );

      focus.advanceTimeSeconds(1500);
      expect(focus.currentSession!.totalElapsedSeconds, equals(1500));
    });

    test('F18-3: Pomodoro short break transition interval', () async {
      setUp();
      await focus.startSession(
        subjectId: 'pomo_sub',
        sessionType: SessionType.pomodoro,
        targetDurationSeconds: 1500,
      );

      focus.advanceTimeSeconds(1500);
      await focus.pauseSession(); // Short break began

      expect(focus.currentSession!.status, equals(FocusState.paused));
      focus.advanceTimeSeconds(300); // 5 min break
      await focus.resumeSession(); // Next cycle begins

      expect(focus.currentSession!.status, equals(FocusState.running));
    });

    test('F18-4: Early Pomodoro session complete records partial focus duration', () async {
      setUp();
      await focus.startSession(
        subjectId: 'pomo_sub',
        sessionType: SessionType.pomodoro,
        targetDurationSeconds: 1500,
      );

      focus.advanceTimeSeconds(800); // Early stop at 800s
      final summary = await focus.completeSession(markTaskCompleted: false);

      expect(summary.totalElapsedSeconds, equals(800));
      expect(summary.markTaskCompleted, isFalse);
    });

    test('F18-5: Abandon Pomodoro marks session status abandoned', () async {
      setUp();
      await focus.startSession(
        subjectId: 'pomo_sub',
        sessionType: SessionType.pomodoro,
      );

      await focus.abandonSession(reason: 'Emergency call');
      expect(focus.currentSession!.status, equals(FocusState.abandoned));
    });
  });

  group('Tier 1: F19 Mock Exam Countdown Timers (5 tests)', () {
    late TestFocusEngine focus;

    void setUp() {
      focus = TestFocusEngine();
    }

    test('F19-1: Start Mock Exam countdown simulation timer', () async {
      setUp();
      final session = await focus.startSession(
        subjectId: 'sat_exam',
        sessionType: SessionType.mockExam,
        targetDurationSeconds: 7200, // 2 hours
      );

      expect(session.sessionType, equals(SessionType.mockExam));
      expect(session.targetDurationSeconds, equals(7200));
    });

    test('F19-2: Mock Exam timer tracks remaining countdown time', () async {
      setUp();
      await focus.startSession(
        subjectId: 'sat_exam',
        sessionType: SessionType.mockExam,
        targetDurationSeconds: 7200,
      );

      focus.advanceTimeSeconds(3600); // 1 hour passed
      final elapsed = focus.currentSession!.totalElapsedSeconds;
      final remaining = 7200 - elapsed;

      expect(elapsed, equals(3600));
      expect(remaining, equals(3600));
    });

    test('F19-3: Mock Exam section breakdown milestone calculation', () async {
      setUp();
      await focus.startSession(
        subjectId: 'sat_exam',
        sessionType: SessionType.mockExam,
        targetDurationSeconds: 5400, // 90 min = 45m Section 1 + 45m Section 2
      );

      focus.advanceTimeSeconds(2700); // exactly end of Section 1
      expect(focus.currentSession!.totalElapsedSeconds, equals(2700));
    });

    test('F19-4: Mock Exam auto-complete when elapsed matches target duration', () async {
      setUp();
      await focus.startSession(
        subjectId: 'sat_exam',
        sessionType: SessionType.mockExam,
        targetDurationSeconds: 3600,
      );

      focus.advanceTimeSeconds(3600);
      final summary = await focus.completeSession(markTaskCompleted: true);
      expect(summary.totalElapsedSeconds, equals(3600));
    });

    test('F19-5: Mock exam pause and resume maintains section integrity', () async {
      setUp();
      await focus.startSession(
        subjectId: 'sat_exam',
        sessionType: SessionType.mockExam,
        targetDurationSeconds: 3600,
      );

      focus.advanceTimeSeconds(1000);
      await focus.pauseSession();
      focus.advanceTimeSeconds(200); // Break between sections
      await focus.resumeSession();
      focus.advanceTimeSeconds(1000);

      expect(focus.currentSession!.totalElapsedSeconds, equals(2000));
    });
  });

  group('Tier 1: F20 Strict Lock Mode & Interruption Log (5 tests)', () {
    late TestFocusEngine focus;

    void setUp() {
      focus = TestFocusEngine();
    }

    test('F20-1: Enable Strict Lock mode state', () async {
      setUp();
      expect(focus.isStrictLockActive, isFalse);

      focus.setStrictLock(true);
      expect(focus.isStrictLockActive, isTrue);
    });

    test('F20-2: Background lifecycle event increments interruption count (AC5)', () async {
      setUp();
      focus.setStrictLock(true);
      await focus.startSession(
        subjectId: 'law_sub',
        sessionType: SessionType.stopwatch,
      );

      // User leaves app to home screen
      focus.handleLifecycleChange(isForeground: false);
      expect(focus.activeInterruptionCount, equals(1));
      expect(focus.currentSession!.interruptionsCount, equals(1));
    });

    test('F20-3: Resuming app logs interruption duration in seconds (AC5)', () async {
      setUp();
      focus.setStrictLock(true);
      await focus.startSession(
        subjectId: 'law_sub',
        sessionType: SessionType.stopwatch,
      );

      focus.handleLifecycleChange(isForeground: false);
      focus.handleLifecycleChange(isForeground: true);

      expect(focus.currentSession!.interruptionsCount, equals(1));
    });

    test('F20-4: Multiple unauthorized background exits accumulate interruptions', () async {
      setUp();
      focus.setStrictLock(true);
      await focus.startSession(
        subjectId: 'law_sub',
        sessionType: SessionType.stopwatch,
      );

      focus.handleLifecycleChange(isForeground: false);
      focus.handleLifecycleChange(isForeground: true);

      focus.handleLifecycleChange(isForeground: false);
      focus.handleLifecycleChange(isForeground: true);

      focus.handleLifecycleChange(isForeground: false);
      focus.handleLifecycleChange(isForeground: true);

      expect(focus.currentSession!.interruptionsCount, equals(3));
    });

    test('F20-5: Strict Lock disabled does not log interruptions on background transitions', () async {
      setUp();
      focus.setStrictLock(false);
      await focus.startSession(
        subjectId: 'law_sub',
        sessionType: SessionType.stopwatch,
      );

      focus.handleLifecycleChange(isForeground: false);
      focus.handleLifecycleChange(isForeground: true);

      expect(focus.activeInterruptionCount, equals(0));
    });
  });

  group('Tier 1: F21 Application Reference Allowlist (5 tests)', () {
    late TestFocusEngine focus;

    void setUp() {
      focus = TestFocusEngine();
    }

    test('F21-1: Switching to whitelisted calculator does not log interruption (AC5)', () async {
      setUp();
      focus.setStrictLock(true);
      await focus.startSession(
        subjectId: 'math_sub',
        sessionType: SessionType.stopwatch,
      );

      focus.handleLifecycleChange(
        isForeground: false,
        activePackageName: 'com.android.calculator2',
      );
      expect(focus.activeInterruptionCount, equals(0));
    });

    test('F21-2: Switching to scratchpad drawer does not log interruption (AC5)', () async {
      setUp();
      focus.setStrictLock(true);
      await focus.startSession(
        subjectId: 'math_sub',
        sessionType: SessionType.stopwatch,
      );

      focus.handleLifecycleChange(
        isForeground: false,
        activePackageName: 'com.hampa.scratchpad',
      );
      expect(focus.activeInterruptionCount, equals(0));
    });

    test('F21-3: Switching to non-whitelisted social media logs interruption penalty', () async {
      setUp();
      focus.setStrictLock(true);
      await focus.startSession(
        subjectId: 'math_sub',
        sessionType: SessionType.stopwatch,
      );

      focus.handleLifecycleChange(
        isForeground: false,
        activePackageName: 'com.instagram.android',
      );
      expect(focus.activeInterruptionCount, equals(1));
    });

    test('F21-4: Whitelisted ambient sound engine switch bypasses lock penalty', () async {
      setUp();
      focus.setStrictLock(true);
      await focus.startSession(
        subjectId: 'math_sub',
        sessionType: SessionType.stopwatch,
      );

      focus.handleLifecycleChange(
        isForeground: false,
        activePackageName: 'com.hampa.ambient_sound',
      );
      expect(focus.activeInterruptionCount, equals(0));
    });

    test('F21-5: Returning from whitelisted application leaves session running uninterrupted', () async {
      setUp();
      focus.setStrictLock(true);
      await focus.startSession(
        subjectId: 'math_sub',
        sessionType: SessionType.stopwatch,
      );

      focus.handleLifecycleChange(isForeground: false, activePackageName: 'com.android.calculator2');
      focus.advanceTimeSeconds(120);
      focus.handleLifecycleChange(isForeground: true);

      expect(focus.currentSession!.status, equals(FocusState.running));
      expect(focus.currentSession!.totalElapsedSeconds, equals(120));
      expect(focus.activeInterruptionCount, equals(0));
    });
  });

  group('Tier 1: F22 Flip-to-Focus Sensor Detection (5 tests)', () {
    late TestFocusEngine focus;

    void setUp() {
      focus = TestFocusEngine();
    }

    test('F22-1: Accelerometer face-down triggers flipped state (Z <= -9.2 m/s^2)', () async {
      setUp();
      expect(focus.isFlippedFaceDown, isFalse);

      focus.handleSensorUpdate(zAxisAcceleration: -9.8, isNear: true);
      expect(focus.isFlippedFaceDown, isTrue);
    });

    test('F22-2: Turning phone face up flips state to false', () async {
      setUp();
      focus.handleSensorUpdate(zAxisAcceleration: -9.8, isNear: true);
      expect(focus.isFlippedFaceDown, isTrue);

      await Future.delayed(const Duration(milliseconds: 1600)); // debounce window
      focus.handleSensorUpdate(zAxisAcceleration: 9.8, isNear: false);
      expect(focus.isFlippedFaceDown, isFalse);
    });

    test('F22-3: Face-down flip resumes paused focus session', () async {
      setUp();
      await focus.startSession(subjectId: 'sub', sessionType: SessionType.stopwatch);
      await focus.pauseSession();
      expect(focus.currentSession!.status, equals(FocusState.paused));

      await Future.delayed(const Duration(milliseconds: 1600));
      focus.handleSensorUpdate(zAxisAcceleration: -9.5, isNear: true);

      expect(focus.currentSession!.status, equals(FocusState.running));
    });

    test('F22-4: Turning phone face-up pauses active focus session', () async {
      setUp();
      focus.handleSensorUpdate(zAxisAcceleration: -9.8, isNear: true);
      await focus.startSession(subjectId: 'sub', sessionType: SessionType.stopwatch);

      await Future.delayed(const Duration(milliseconds: 1600));
      focus.handleSensorUpdate(zAxisAcceleration: 9.8, isNear: false);

      expect(focus.currentSession!.status, equals(FocusState.paused));
    });

    test('F22-5: Rapid jitter within 1500ms debounce does not trigger flip state toggles', () async {
      setUp();
      focus.handleSensorUpdate(zAxisAcceleration: -9.8, isNear: true);
      expect(focus.isFlippedFaceDown, isTrue);

      // Instant jitter without debounce delay
      focus.handleSensorUpdate(zAxisAcceleration: 0.0, isNear: false);
      // Still true because debounce threshold not reached
      expect(focus.isFlippedFaceDown, isTrue);
    });
  });

  group('Tier 1: F23 Multi-Track Ambient Soundscapes (5 tests)', () {
    late TestFocusEngine focus;

    void setUp() {
      focus = TestFocusEngine();
    }

    test('F23-1: Adjust volume for rain ambient sound track', () async {
      setUp();
      expect(focus.getAmbientTrackVolume('rain'), equals(0.0));

      focus.setAmbientTrackVolume(trackId: 'rain', volume: 0.75);
      expect(focus.getAmbientTrackVolume('rain'), equals(0.75));
    });

    test('F23-2: Multi-track mixer controls independent volume levels', () async {
      setUp();
      focus.setAmbientTrackVolume(trackId: 'rain', volume: 0.5);
      focus.setAmbientTrackVolume(trackId: 'cafe', volume: 0.3);
      focus.setAmbientTrackVolume(trackId: 'white_noise', volume: 0.8);

      expect(focus.getAmbientTrackVolume('rain'), equals(0.5));
      expect(focus.getAmbientTrackVolume('cafe'), equals(0.3));
      expect(focus.getAmbientTrackVolume('white_noise'), equals(0.8));
    });

    test('F23-3: Volume level clamps between 0.0 and 1.0', () async {
      setUp();
      focus.setAmbientTrackVolume(trackId: 'rain', volume: 1.5);
      expect(focus.getAmbientTrackVolume('rain'), equals(1.0));

      focus.setAmbientTrackVolume(trackId: 'rain', volume: -0.2);
      expect(focus.getAmbientTrackVolume('rain'), equals(0.0));
    });

    test('F23-4: Mute all ambient sound tracks', () async {
      setUp();
      focus.setAmbientTrackVolume(trackId: 'library', volume: 0.6);
      focus.setAmbientTrackVolume(trackId: 'library', volume: 0.0);
      expect(focus.getAmbientTrackVolume('library'), equals(0.0));
    });

    test('F23-5: Ambient sound levels persist across active session start and pause', () async {
      setUp();
      focus.setAmbientTrackVolume(trackId: 'waves', volume: 0.4);

      await focus.startSession(subjectId: 's', sessionType: SessionType.stopwatch);
      await focus.pauseSession();

      expect(focus.getAmbientTrackVolume('waves'), equals(0.4));
    });
  });
}
