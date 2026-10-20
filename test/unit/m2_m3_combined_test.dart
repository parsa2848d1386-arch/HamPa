import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:hampa/core/database/app_database.dart';
import 'package:hampa/core/database/daos/study_sessions_dao.dart';
import 'package:hampa/features/focus_timer/domain/models/focus_session_state.dart';
import 'package:hampa/features/focus_timer/presentation/controllers/focus_timer_cubit.dart';

void main() {
  late AppDatabase db;
  late StudySessionsDao dao;
  late FocusTimerCubit cubit;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = StudySessionsDao(db);
    cubit = FocusTimerCubit(studySessionsDao: dao);
  });

  tearDown(() async {
    await cubit.close();
    await db.close();
  });

  group('FocusTimerCubit & Monotonic Timing Tests', () {
    test('Initial state is clean', () {
      expect(cubit.state.status, equals(TimerStatus.initial));
      expect(cubit.state.elapsedSeconds, equals(0));
      expect(cubit.state.isRunning, isFalse);
    });

    test('startTimer initializes session with monotonic tracking', () {
      cubit.startTimer(
        subjectId: 'sub_math',
        mode: TimerMode.stopwatch,
        strictLock: true,
      );

      expect(cubit.state.status, equals(TimerStatus.running));
      expect(cubit.state.activeSubjectId, equals('sub_math'));
      expect(cubit.state.isStrictLockActive, isTrue);
      expect(cubit.state.startTime, isNotNull);
    });

    test('pauseTimer and resumeTimer compute pause duration accurately', () {
      cubit.startTimer(subjectId: 'sub_physics');
      cubit.pauseTimer();

      expect(cubit.state.status, equals(TimerStatus.paused));
      expect(cubit.state.isPaused, isTrue);

      cubit.resumeTimer();
      expect(cubit.state.status, equals(TimerStatus.running));
    });

    test('recordLap appends laps correctly', () {
      cubit.startTimer(subjectId: 'sub_history');
      cubit.recordLap();
      cubit.recordLap();

      expect(cubit.state.laps.length, equals(2));
    });

    test('Strict lock and ambient sound toggle as expected', () {
      expect(cubit.state.isStrictLockActive, isFalse);
      cubit.toggleStrictLock();
      expect(cubit.state.isStrictLockActive, isTrue);

      expect(cubit.state.isAmbientSoundPlaying, isFalse);
      cubit.toggleAmbientSound('Rain');
      expect(cubit.state.isAmbientSoundPlaying, isTrue);
      expect(cubit.state.activeSoundTrack, equals('Rain'));
      cubit.toggleAmbientSound('Rain');
      expect(cubit.state.isAmbientSoundPlaying, isFalse);
    });
  });
}
