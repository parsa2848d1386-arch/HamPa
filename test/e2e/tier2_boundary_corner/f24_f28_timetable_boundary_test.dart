// Tier 2 E2E Boundary & Corner Cases: F24–F28 10-Minute Timetable Grid & Study Rooms
// Minimum 5 tests per feature (25 test cases total)
// Grounded in PROJECT.md (F24–F28, AC6, AC7, E01, E18, E19)

import '../contracts/study_room_contracts.dart';
import '../contracts/timetable_contracts.dart';
import '../harness/test_study_room_harness.dart';
import '../harness/test_timetable_harness.dart';
import '../support/test_runner.dart';

void runTimetableStudyRoomsTier2Tests() {
  group('Tier 2: F24 10-Minute Timetable Grid Boundaries (5 tests)', () {
    late TestTimetableEngine timetable;

    void setUp() {
      timetable = TestTimetableEngine();
    }

    test('F24-B1: Session starting at 04:59:59 AM maps to final slot 143', () async {
      setUp();
      final dt = DateTime(2026, 10, 17, 4, 59, 59);
      expect(timetable.timeToSlotIndex(dt), equals(143));
    });

    test('F24-B2: Session starting at 05:00:00 AM maps to initial slot 0', () async {
      setUp();
      final dt = DateTime(2026, 10, 16, 5, 0, 0);
      expect(timetable.timeToSlotIndex(dt), equals(0));
    });

    test('F24-B3: Zero-duration session (start == end) yields 0.0 fill ratio', () async {
      setUp();
      final day = DateTime(2026, 10, 16);
      final sub = SubjectEntity(id: 's', name: 'S', colorHex: '#000000');
      final interval = StudyInterval(
        start: DateTime(2026, 10, 16, 10, 0),
        end: DateTime(2026, 10, 16, 10, 0), // 0 duration
        subjectId: 's',
      );

      final grid = timetable.projectIntervalsToGrid(
        studyDay: day,
        intervals: [interval],
        subjectMap: {'s': sub},
      );

      final slot = timetable.timeToSlotIndex(interval.start);
      expect(grid[slot].fillRatio, equals(0.0));
    });

    test('F24-B4: 24-hour continuous study session completely fills all 144 slots (1.0 ratio)', () async {
      setUp();
      final day = DateTime(2026, 10, 16);
      final sub = SubjectEntity(id: 'iron', name: 'Ironman', colorHex: '#FF0000');
      final fullDayInterval = StudyInterval(
        start: DateTime(2026, 10, 16, 5, 0),
        end: DateTime(2026, 10, 17, 5, 0), // 24 hours
        subjectId: 'iron',
      );

      final grid = timetable.projectIntervalsToGrid(
        studyDay: day,
        intervals: [fullDayInterval],
        subjectMap: {'iron': sub},
      );

      expect(grid.length, equals(144));
      expect(grid.every((b) => b.fillRatio == 1.0), isTrue);
    });

    test('F24-B5: Session entirely outside study day window ignored in grid projection', () async {
      setUp();
      final day = DateTime(2026, 10, 16);
      final sub = SubjectEntity(id: 's', name: 'S', colorHex: '#000000');
      final outsideInterval = StudyInterval(
        start: DateTime(2026, 10, 20, 10, 0), // 4 days later
        end: DateTime(2026, 10, 20, 11, 0),
        subjectId: 's',
      );

      final grid = timetable.projectIntervalsToGrid(
        studyDay: day,
        intervals: [outsideInterval],
        subjectMap: {'s': sub},
      );

      expect(grid.every((b) => b.fillRatio == 0.0), isTrue);
    });
  });

  group('Tier 2: F25 Real-Time Block Painting Boundaries (5 tests)', () {
    late TestTimetableEngine timetable;

    void setUp() {
      timetable = TestTimetableEngine();
    }

    test('F25-B1: Overlapping intervals in same slot clamp total fill ratio to 1.0 max', () async {
      setUp();
      final day = DateTime(2026, 10, 16);
      final sub = SubjectEntity(id: 's', name: 'S', colorHex: '#000000');
      final intA = StudyInterval(
        start: DateTime(2026, 10, 16, 10, 0),
        end: DateTime(2026, 10, 16, 10, 8), // 8 min
        subjectId: 's',
      );
      final intB = StudyInterval(
        start: DateTime(2026, 10, 16, 10, 4),
        end: DateTime(2026, 10, 16, 10, 10), // 6 min
        subjectId: 's',
      );

      final grid = timetable.projectIntervalsToGrid(
        studyDay: day,
        intervals: [intA, intB],
        subjectMap: {'s': sub},
      );

      final slot = timetable.timeToSlotIndex(intA.start);
      expect(grid[slot].fillRatio, equals(1.0)); // clamped at 1.0
    });

    test('F25-B2: Pulsing calculation with null currentTime evaluates to isPulsing false', () async {
      setUp();
      final day = DateTime(2026, 10, 16);
      final sub = SubjectEntity(id: 's', name: 'S', colorHex: '#000000');
      final interval = StudyInterval(
        start: DateTime(2026, 10, 16, 10, 0),
        end: DateTime(2026, 10, 16, 10, 10),
        subjectId: 's',
      );

      final grid = timetable.projectIntervalsToGrid(
        studyDay: day,
        intervals: [interval],
        subjectMap: {'s': sub},
        currentTime: null,
      );

      final slot = timetable.timeToSlotIndex(interval.start);
      expect(grid[slot].isPulsing, isFalse);
    });

    test('F25-B3: 1-second micro-interval calculates fractional fill ratio without division error', () async {
      setUp();
      final day = DateTime(2026, 10, 16);
      final sub = SubjectEntity(id: 's', name: 'S', colorHex: '#000000');
      final microInterval = StudyInterval(
        start: DateTime(2026, 10, 16, 10, 0, 0),
        end: DateTime(2026, 10, 16, 10, 0, 1), // 1 second
        subjectId: 's',
      );

      final grid = timetable.projectIntervalsToGrid(
        studyDay: day,
        intervals: [microInterval],
        subjectMap: {'s': sub},
      );

      final slot = timetable.timeToSlotIndex(microInterval.start);
      expect(grid[slot].fillRatio, greaterThan(0.0));
      expect(grid[slot].fillRatio, lessThan(0.01));
    });

    test('F25-B4: Current time before slot does not pulse', () async {
      setUp();
      final day = DateTime(2026, 10, 16);
      final sub = SubjectEntity(id: 's', name: 'S', colorHex: '#000000');
      final interval = StudyInterval(
        start: DateTime(2026, 10, 16, 12, 0),
        end: DateTime(2026, 10, 16, 12, 10),
        subjectId: 's',
      );

      final grid = timetable.projectIntervalsToGrid(
        studyDay: day,
        intervals: [interval],
        subjectMap: {'s': sub},
        currentTime: DateTime(2026, 10, 16, 11, 0), // before
      );

      final slot = timetable.timeToSlotIndex(interval.start);
      expect(grid[slot].isPulsing, isFalse);
    });

    test('F25-B5: Unknown subject ID in interval defaults to fallback blue color', () async {
      setUp();
      final day = DateTime(2026, 10, 16);
      final interval = StudyInterval(
        start: DateTime(2026, 10, 16, 10, 0),
        end: DateTime(2026, 10, 16, 10, 10),
        subjectId: 'unknown_subject_id',
      );

      final grid = timetable.projectIntervalsToGrid(
        studyDay: day,
        intervals: [interval],
        subjectMap: {}, // empty map
      );

      final slot = timetable.timeToSlotIndex(interval.start);
      expect(grid[slot].colorHex, equals('#2196F3'));
    });
  });

  group('Tier 2: F26 Live Study Rooms Boundaries (5 tests)', () {
    late TestLiveStudyRoomEngine rooms;

    void setUp() {
      rooms = TestLiveStudyRoomEngine();
    }

    test('F26-B1: Member exactly at 30 seconds since heartbeat remains online (E18)', () async {
      setUp();
      final now = DateTime.now();
      final member = RoomMember(
        userId: 'u_exact',
        displayName: 'Exact',
        presenceState: PresenceState.studying,
        lastHeartbeat: now.subtract(const Duration(seconds: 30)),
      );
      await rooms.joinRoom(roomId: 'r1', self: member);

      rooms.sweepTimeouts(roomId: 'r1', currentTime: now);
      final list = await rooms.watchRoomMembers('r1').first;
      expect(list.first.presenceState, equals(PresenceState.studying));
    });

    test('F26-B2: Member at 31 seconds since heartbeat transitioned to offline (E18)', () async {
      setUp();
      final now = DateTime.now();
      final member = RoomMember(
        userId: 'u_expired',
        displayName: 'Expired',
        presenceState: PresenceState.studying,
        lastHeartbeat: now.subtract(const Duration(seconds: 31)),
      );
      await rooms.joinRoom(roomId: 'r1', self: member);

      rooms.sweepTimeouts(roomId: 'r1', currentTime: now);
      final list = await rooms.watchRoomMembers('r1').first;
      expect(list.first.presenceState, equals(PresenceState.offline));
    });

    test('F26-B3: Member re-sending heartbeat after timeout restores online studying state', () async {
      setUp();
      final now = DateTime.now();
      final member = RoomMember(
        userId: 'u_reconnect',
        displayName: 'Reconnect',
        presenceState: PresenceState.offline,
        lastHeartbeat: now.subtract(const Duration(seconds: 60)),
      );
      await rooms.joinRoom(roomId: 'r1', self: member);

      await rooms.updatePresence(roomId: 'r1', userId: 'u_reconnect', state: PresenceState.studying);
      final list = await rooms.watchRoomMembers('r1').first;
      expect(list.first.presenceState, equals(PresenceState.studying));
    });

    test('F26-B4: Updating presence for non-existent user in room is safely ignored', () async {
      setUp();
      await rooms.updatePresence(roomId: 'r1', userId: 'ghost_user', state: PresenceState.studying);
      final list = await rooms.watchRoomMembers('r1').first;
      expect(list.isEmpty, isTrue);
    });

    test('F26-B5: 100 members in same study room roster tracked accurately', () async {
      setUp();
      for (var i = 0; i < 100; i++) {
        await rooms.joinRoom(
          roomId: 'mega_room',
          self: RoomMember(userId: 'u_$i', displayName: 'Student $i'),
        );
      }

      final list = await rooms.watchRoomMembers('mega_room').first;
      expect(list.length, equals(100));
    });
  });

  group('Tier 2: F27 Animated Avatars Boundaries (5 tests)', () {
    late TestLiveStudyRoomEngine rooms;

    void setUp() {
      rooms = TestLiveStudyRoomEngine();
    }

    test('F27-B1: Member without avatarAnimation string defaults gracefully', () async {
      setUp();
      final member = RoomMember(userId: 'u_no_anim', displayName: 'NoAnim');
      await rooms.joinRoom(roomId: 'r', self: member);

      final list = await rooms.watchRoomMembers('r').first;
      expect(list.first.avatarAnimation, isNull);
    });

    test('F27-B2: Offline member state reflects offline avatar presentation', () async {
      setUp();
      final member = RoomMember(
        userId: 'u_off',
        displayName: 'OfflineGuy',
        presenceState: PresenceState.offline,
        avatarAnimation: 'offline_sleep.json',
      );
      await rooms.joinRoom(roomId: 'r', self: member);

      final list = await rooms.watchRoomMembers('r').first;
      expect(list.first.presenceState, equals(PresenceState.offline));
      expect(list.first.avatarAnimation, equals('offline_sleep.json'));
    });

    test('F27-B3: Switch avatar type from animatedLottie to webRtcDeskCam', () async {
      setUp();
      final member = RoomMember(
        userId: 'u_switch',
        displayName: 'Switcher',
        avatarType: AvatarType.animatedLottie,
      );
      await rooms.joinRoom(roomId: 'r', self: member);

      final updated = member.copyWith(avatarType: AvatarType.webRtcDeskCam);
      await rooms.joinRoom(roomId: 'r', self: updated);

      final list = await rooms.watchRoomMembers('r').first;
      expect(list.first.avatarType, equals(AvatarType.webRtcDeskCam));
    });

    test('F27-B4: Rapid avatar animation transitions maintain member identity', () async {
      setUp();
      var member = RoomMember(userId: 'u_rapid', displayName: 'Rapid');
      await rooms.joinRoom(roomId: 'r', self: member);

      for (var i = 0; i < 10; i++) {
        member = member.copyWith(avatarAnimation: 'anim_$i.json');
        await rooms.joinRoom(roomId: 'r', self: member);
      }

      final list = await rooms.watchRoomMembers('r').first;
      expect(list.first.avatarAnimation, equals('anim_9.json'));
    });

    test('F27-B5: Long display name on avatar tile handled without string truncation error', () async {
      setUp();
      final member = RoomMember(userId: 'u_long', displayName: 'Extremely Long Student Name ' * 5);
      await rooms.joinRoom(roomId: 'r', self: member);

      final list = await rooms.watchRoomMembers('r').first;
      expect(list.first.displayName.length, greaterThan(100));
    });
  });

  group('Tier 2: F28 Groups & Cheering Rate Limiting Boundaries (5 tests)', () {
    late TestLiveStudyRoomEngine rooms;

    void setUp() {
      rooms = TestLiveStudyRoomEngine();
    }

    test('F28-B1: Spamming 100 cheering reactions within 1 second drops 95 (E19)', () async {
      setUp();
      var allowed = 0;
      var dropped = 0;

      for (var i = 0; i < 100; i++) {
        final success = await rooms.sendCheer(
          roomId: 'r_spam',
          senderId: 'spammer_bot',
          targetUserId: 'victim',
          emoji: '👏',
        );
        if (success) allowed++; else dropped++;
      }

      expect(allowed, equals(5));
      expect(dropped, equals(95));
    });

    test('F28-B2: Distinct senders have independent rate limiter token buckets (E19)', () async {
      setUp();
      // Sender 1 sends 5
      for (var i = 0; i < 5; i++) {
        final s1 = await rooms.sendCheer(roomId: 'r_multi', senderId: 'user_1', targetUserId: 'target', emoji: '👏');
        expect(s1, isTrue);
      }

      // Sender 2 sends 5: should succeed independently
      for (var i = 0; i < 5; i++) {
        final s2 = await rooms.sendCheer(roomId: 'r_multi', senderId: 'user_2', targetUserId: 'target', emoji: '🔥');
        expect(s2, isTrue);
      }
    });

    test('F28-B3: Non-standard cheering emoji unicode string supported', () async {
      setUp();
      final success = await rooms.sendCheer(
        roomId: 'r_cheer',
        senderId: 's',
        targetUserId: 't',
        emoji: '💯',
      );
      expect(success, isTrue);
    });

    test('F28-B4: Cheering oneself is permitted without exception', () async {
      setUp();
      final success = await rooms.sendCheer(
        roomId: 'r_cheer',
        senderId: 'same_user',
        targetUserId: 'same_user',
        emoji: '💪',
      );
      expect(success, isTrue);
    });

    test('F28-B5: Cheering non-existent room ID does not throw', () async {
      setUp();
      final success = await rooms.sendCheer(
        roomId: 'non_existent_room_999',
        senderId: 's',
        targetUserId: 't',
        emoji: '☕',
      );
      expect(success, isTrue);
    });
  });
}
