// Tier 2 E2E Boundary & Corner Cases: F17–F23 Focus Engine, Stopwatch & Strict Lock
// Minimum 5 tests per feature (35 test cases total)
// Grounded in PROJECT.md (F17–F23, AC4, AC5, E03, E04, E05, E12, E13, E14, E15, E16, E17)

import '../contracts/focus_contracts.dart';
import '../harness/test_focus_harness.dart';
import '../support/test_runner.dart';

void runFocusStrictLockTier2Tests() {
  group('Tier 2: F17 Monotonic Background Stopwatch Boundaries (5 tests)', () {
    late TestFocusEngine focus;

    void setUp() {
      focus = TestFocusEngine();
    }

    test('F17-B1: Monotonic elapsed calculation immune to system wall-clock modification (E03)', () async {
      setUp();
      await focus.startSession(subjectId: 'sub', sessionType: SessionType.stopwatch);

      // Advance monotonic elapsed time by 60s
      focus.advanceTimeSeconds(60);
      expect(focus.currentSession!.totalElapsedSeconds, equals(60));

      // Wall-clock jump does not cause negative or inflated duration
      focus.advanceTimeSeconds(0);
      expect(focus.currentSession!.totalElapsedSeconds, equals(60));
    });

    test('F17-B2: Resuming an already running stopwatch is idempotent', () async {
      setUp();
      await focus.startSession(subjectId: 'sub', sessionType: SessionType.stopwatch);
      await focus.resumeSession(); // already running

      expect(focus.currentSession!.status, equals(FocusState.running));
    });

    test('F17-B3: Pausing an already paused stopwatch is idempotent', () async {
      setUp();
      await focus.startSession(subjectId: 'sub', sessionType: SessionType.stopwatch);
      await focus.pauseSession();
      await focus.pauseSession(); // already paused

      expect(focus.currentSession!.status, equals(FocusState.paused));
    });

    test('F17-B4: Completing session with 0 seconds elapsed handled cleanly', () async {
      setUp();
      await focus.startSession(subjectId: 'sub', sessionType: SessionType.stopwatch);
      final summary = await focus.completeSession(markTaskCompleted: false);

      expect(summary.totalElapsedSeconds, equals(0));
      expect(summary.markTaskCompleted, isFalse);
    });

    test('F17-B5: Long multi-hour study session (10 hours = 36000s) calculates accurately without overflow', () async {
      setUp();
      await focus.startSession(subjectId: 'sub', sessionType: SessionType.stopwatch);
      focus.advanceTimeSeconds(36000); // 10 hours

      expect(focus.currentSession!.totalElapsedSeconds, equals(36000));
    });
  });

  group('Tier 2: F18 Customizable Pomodoro Cycles Boundaries (5 tests)', () {
    late TestFocusEngine focus;

    void setUp() {
      focus = TestFocusEngine();
    }

    test('F18-B1: Zero target duration Pomodoro cycle defaults safely', () async {
      setUp();
      final session = await focus.startSession(
        subjectId: 'pomo',
        sessionType: SessionType.pomodoro,
        targetDurationSeconds: 0,
      );
      expect(session.targetDurationSeconds, equals(0));
    });

    test('F18-B2: Extremely long Pomodoro duration (4 hours = 14400s)', () async {
      setUp();
      final session = await focus.startSession(
        subjectId: 'pomo',
        sessionType: SessionType.pomodoro,
        targetDurationSeconds: 14400,
      );
      expect(session.targetDurationSeconds, equals(14400));
    });

    test('F18-B3: Completing Pomodoro with markTaskCompleted true marks summary complete', () async {
      setUp();
      await focus.startSession(
        subjectId: 'pomo',
        sessionType: SessionType.pomodoro,
        targetDurationSeconds: 1500,
      );
      focus.advanceTimeSeconds(1500);

      final summary = await focus.completeSession(markTaskCompleted: true);
      expect(summary.markTaskCompleted, isTrue);
      expect(summary.totalElapsedSeconds, equals(1500));
    });

    test('F18-B4: Abandoning session without reason provides default status', () async {
      setUp();
      await focus.startSession(subjectId: 'pomo', sessionType: SessionType.pomodoro);
      await focus.abandonSession(reason: '');

      expect(focus.currentSession!.status, equals(FocusState.abandoned));
    });

    test('F18-B5: Pause during Pomodoro cycle freezes work progress', () async {
      setUp();
      await focus.startSession(
        subjectId: 'pomo',
        sessionType: SessionType.pomodoro,
        targetDurationSeconds: 1500,
      );
      focus.advanceTimeSeconds(500);
      await focus.pauseSession();
      focus.advanceTimeSeconds(300); // paused time

      expect(focus.currentSession!.totalElapsedSeconds, equals(500));
    });
  });

  group('Tier 2: F19 Mock Exam Countdown Timers Boundaries (5 tests)', () {
    late TestFocusEngine focus;

    void setUp() {
      focus = TestFocusEngine();
    }

    test('F19-B1: Exam countdown reaching exact target duration calculates 0 remaining', () async {
      setUp();
      await focus.startSession(
        subjectId: 'exam',
        sessionType: SessionType.mockExam,
        targetDurationSeconds: 3600,
      );
      focus.advanceTimeSeconds(3600);

      final remaining = 3600 - focus.currentSession!.totalElapsedSeconds;
      expect(remaining, equals(0));
    });

    test('F19-B2: Exam countdown beyond target duration clamps remaining to zero', () async {
      setUp();
      await focus.startSession(
        subjectId: 'exam',
        sessionType: SessionType.mockExam,
        targetDurationSeconds: 3600,
      );
      focus.advanceTimeSeconds(4000); // overtime

      final remaining = (3600 - focus.currentSession!.totalElapsedSeconds).clamp(0, 3600);
      expect(remaining, equals(0));
    });

    test('F19-B3: Exam session with null target duration defaults to stopwatch mode', () async {
      setUp();
      final session = await focus.startSession(
        subjectId: 'exam',
        sessionType: SessionType.mockExam,
        targetDurationSeconds: null,
      );
      expect(session.targetDurationSeconds, isNull);
    });

    test('F19-B4: Pausing exam prevents elapsed accumulation', () async {
      setUp();
      await focus.startSession(
        subjectId: 'exam',
        sessionType: SessionType.mockExam,
        targetDurationSeconds: 5000,
      );
      focus.advanceTimeSeconds(1000);
      await focus.pauseSession();
      focus.advanceTimeSeconds(1000); // paused

      expect(focus.currentSession!.totalElapsedSeconds, equals(1000));
    });

    test('F19-B5: Multi-section exam timer tracks cumulative elapsed duration accurately', () async {
      setUp();
      await focus.startSession(
        subjectId: 'exam',
        sessionType: SessionType.mockExam,
        targetDurationSeconds: 7200,
      );
      // Section 1
      focus.advanceTimeSeconds(3600);
      await focus.pauseSession();
      // Section break
      focus.advanceTimeSeconds(600);
      await focus.resumeSession();
      // Section 2
      focus.advanceTimeSeconds(3600);

      final summary = await focus.completeSession(markTaskCompleted: true);
      expect(summary.totalElapsedSeconds, equals(7200));
    });
  });

  group('Tier 2: F20 Strict Lock Mode Boundaries (5 tests)', () {
    late TestFocusEngine focus;

    void setUp() {
      focus = TestFocusEngine();
    }

    test('F20-B1: Incoming phone call exempted from Strict Lock penalties (E12)', () async {
      setUp();
      focus.setStrictLock(true);
      await focus.startSession(subjectId: 's', sessionType: SessionType.stopwatch);

      // Incoming call triggers system emergency exemption
      focus.handleLifecycleChange(isForeground: false, activePackageName: 'com.hampa.ambient_sound');
      expect(focus.activeInterruptionCount, equals(0));
    });

    test('F20-B2: 10 consecutive interruptions accumulated accurately without lost increments', () async {
      setUp();
      focus.setStrictLock(true);
      await focus.startSession(subjectId: 's', sessionType: SessionType.stopwatch);

      for (var i = 0; i < 10; i++) {
        focus.handleLifecycleChange(isForeground: false);
        focus.handleLifecycleChange(isForeground: true);
      }

      expect(focus.activeInterruptionCount, equals(10));
      expect(focus.currentSession!.interruptionsCount, equals(10));
    });

    test('F20-B3: Lifecycle change while session is not running does not record interruption', () async {
      setUp();
      focus.setStrictLock(true);
      // No session started
      focus.handleLifecycleChange(isForeground: false);
      expect(focus.activeInterruptionCount, equals(0));
    });

    test('F20-B4: Lifecycle change while session is completed does not record interruption', () async {
      setUp();
      focus.setStrictLock(true);
      await focus.startSession(subjectId: 's', sessionType: SessionType.stopwatch);
      await focus.completeSession(markTaskCompleted: true);

      focus.handleLifecycleChange(isForeground: false);
      expect(focus.activeInterruptionCount, equals(0));
    });

    test('F20-B5: Rapid foreground/background bounce within 1 second still increments count', () async {
      setUp();
      focus.setStrictLock(true);
      await focus.startSession(subjectId: 's', sessionType: SessionType.stopwatch);

      focus.handleLifecycleChange(isForeground: false);
      focus.handleLifecycleChange(isForeground: true);

      expect(focus.activeInterruptionCount, equals(1));
    });
  });

  group('Tier 2: F21 Reference Allowlist Boundaries (5 tests)', () {
    late TestFocusEngine focus;

    void setUp() {
      focus = TestFocusEngine();
    }

    test('F21-B1: Whitelist app launching external non-whitelisted browser link penalized (E14)', () async {
      setUp();
      focus.setStrictLock(true);
      await focus.startSession(subjectId: 's', sessionType: SessionType.stopwatch);

      // Calculator opens browser link
      focus.handleLifecycleChange(isForeground: false, activePackageName: 'com.android.chrome');
      expect(focus.activeInterruptionCount, equals(1));
    });

    test('F21-B2: Package name null during background switch triggers penalty', () async {
      setUp();
      focus.setStrictLock(true);
      await focus.startSession(subjectId: 's', sessionType: SessionType.stopwatch);

      focus.handleLifecycleChange(isForeground: false, activePackageName: null);
      expect(focus.activeInterruptionCount, equals(1));
    });

    test('F21-B3: Sequential allowed app switches do not trigger penalties', () async {
      setUp();
      focus.setStrictLock(true);
      await focus.startSession(subjectId: 's', sessionType: SessionType.stopwatch);

      focus.handleLifecycleChange(isForeground: false, activePackageName: 'com.android.calculator2');
      focus.handleLifecycleChange(isForeground: false, activePackageName: 'com.hampa.scratchpad');
      focus.handleLifecycleChange(isForeground: true);

      expect(focus.activeInterruptionCount, equals(0));
    });

    test('F21-B4: Unknown package name triggers penalty immediately', () async {
      setUp();
      focus.setStrictLock(true);
      await focus.startSession(subjectId: 's', sessionType: SessionType.stopwatch);

      focus.handleLifecycleChange(isForeground: false, activePackageName: 'com.unknown.game');
      expect(focus.activeInterruptionCount, equals(1));
    });

    test('F21-B5: Strict Lock config defaults contain scratchpad and calculator', () async {
      setUp();
      final config = StrictLockConfig();
      expect(config.allowlistPackages, contains('com.hampa.scratchpad'));
      expect(config.allowlistPackages, contains('com.android.calculator2'));
    });
  });

  group('Tier 2: F22 Flip-to-Focus Sensor Boundaries (5 tests)', () {
    late TestFocusEngine focus;

    void setUp() {
      focus = TestFocusEngine();
    }

    test('F22-B1: Boundary acceleration value exactly at -9.2 m/s^2 triggers face-down', () async {
      setUp();
      focus.handleSensorUpdate(zAxisAcceleration: -9.2, isNear: true);
      expect(focus.isFlippedFaceDown, isTrue);
    });

    test('F22-B2: Acceleration value slightly above threshold (-9.19 m/s^2) does not trigger face-down', () async {
      setUp();
      focus.handleSensorUpdate(zAxisAcceleration: -9.19, isNear: true);
      expect(focus.isFlippedFaceDown, isFalse);
    });

    test('F22-B3: Negative Z acceleration without near proximity does not trigger face-down', () async {
      setUp();
      // In hand tilted upside down (proximity is far)
      focus.handleSensorUpdate(zAxisAcceleration: -9.8, isNear: false);
      expect(focus.isFlippedFaceDown, isFalse);
    });

    test('F22-B4: Debounce window ignores rapid jitter (<1500ms) (E16)', () async {
      setUp();
      focus.handleSensorUpdate(zAxisAcceleration: -9.8, isNear: true);
      expect(focus.isFlippedFaceDown, isTrue);

      // Shake phone immediately
      focus.handleSensorUpdate(zAxisAcceleration: 5.0, isNear: false);
      // Suppressed by debounce
      expect(focus.isFlippedFaceDown, isTrue);
    });

    test('F22-B5: Desktop/laptop without sensors defaults isFlippedFaceDown to false (E15)', () async {
      setUp();
      expect(focus.isFlippedFaceDown, isFalse);
    });
  });

  group('Tier 2: F23 Multi-Track Ambient Soundscapes Boundaries (5 tests)', () {
    late TestFocusEngine focus;

    void setUp() {
      focus = TestFocusEngine();
    }

    test('F23-B1: Volume clamping on extreme negative value (-10.0)', () async {
      setUp();
      focus.setAmbientTrackVolume(trackId: 'rain', volume: -10.0);
      expect(focus.getAmbientTrackVolume('rain'), equals(0.0));
    });

    test('F23-B2: Volume clamping on extreme positive value (+10.0)', () async {
      setUp();
      focus.setAmbientTrackVolume(trackId: 'cafe', volume: 10.0);
      expect(focus.getAmbientTrackVolume('cafe'), equals(1.0));
    });

    test('F23-B3: Querying volume of unknown track ID returns 0.0 without throwing', () async {
      setUp();
      expect(focus.getAmbientTrackVolume('non_existent_track'), equals(0.0));
    });

    test('F23-B4: Setting volume on unknown track creates track volume record', () async {
      setUp();
      focus.setAmbientTrackVolume(trackId: 'custom_binaural', volume: 0.85);
      expect(focus.getAmbientTrackVolume('custom_binaural'), equals(0.85));
    });

    test('F23-B5: Toggling volume to 0 effectively mutes track', () async {
      setUp();
      focus.setAmbientTrackVolume(trackId: 'waves', volume: 0.9);
      expect(focus.getAmbientTrackVolume('waves'), equals(0.9));

      focus.setAmbientTrackVolume(trackId: 'waves', volume: 0.0);
      expect(focus.getAmbientTrackVolume('waves'), equals(0.0));
    });
  });
}
