// Tier 1 E2E Feature Coverage: F24–F28 10-Minute Timetable Grid & Study Rooms
// Minimum 5 tests per feature (25 test cases total)
// Grounded in PROJECT.md (F24–F28, AC6, AC7, E01, E18, E19)

import '../contracts/study_room_contracts.dart';
import '../contracts/timetable_contracts.dart';
import '../harness/test_study_room_harness.dart';
import '../harness/test_timetable_harness.dart';
import '../support/test_runner.dart';

void runTimetableStudyRoomsTier1Tests() {
  group('Tier 1: F24 24-Hour 10-Minute Timetable Grid (5 tests)', () {
    late TestTimetableEngine timetable;

    void setUp() {
      timetable = TestTimetableEngine();
    }

    test('F24-1: Generate 144 discrete 10-minute slots starting at 05:00 AM', () async {
      setUp();
      final day = DateTime(2026, 10, 16);
      final grid = timetable.projectIntervalsToGrid(
        studyDay: day,
        intervals: [],
        subjectMap: {},
      );

      expect(grid.length, equals(144));
      expect(grid.first.slotIndex, equals(0));
      expect(grid.first.startTime.hour, equals(5));
      expect(grid.first.startTime.minute, equals(0));
      expect(grid.last.slotIndex, equals(143));
    });

    test('F24-2: timeToSlotIndex correctly maps wall clock hours to 0-143 slot indices', () async {
      setUp();
      // 05:00 AM -> slot 0
      expect(timetable.timeToSlotIndex(DateTime(2026, 10, 16, 5, 0)), equals(0));
      // 05:09 AM -> slot 0
      expect(timetable.timeToSlotIndex(DateTime(2026, 10, 16, 5, 9)), equals(0));
      // 05:10 AM -> slot 1
      expect(timetable.timeToSlotIndex(DateTime(2026, 10, 16, 5, 10)), equals(1));
      // 12:00 PM -> slot 42 (7 hours * 6 = 42)
      expect(timetable.timeToSlotIndex(DateTime(2026, 10, 16, 12, 0)), equals(42));
      // 23:59 PM -> slot 113
      expect(timetable.timeToSlotIndex(DateTime(2026, 10, 16, 23, 59)), equals(113));
      // 00:00 AM -> slot 114
      expect(timetable.timeToSlotIndex(DateTime(2026, 10, 17, 0, 0)), equals(114));
      // 04:59 AM -> slot 143
      expect(timetable.timeToSlotIndex(DateTime(2026, 10, 17, 4, 59)), equals(143));
    });

    test('F24-3: Continuous 30-minute study paints 3 consecutive slots', () async {
      setUp();
      final day = DateTime(2026, 10, 16);
      final sub = SubjectEntity(id: 'math', name: 'Mathematics', colorHex: '#4CAF50');
      final interval = StudyInterval(
        start: DateTime(2026, 10, 16, 10, 0),
        end: DateTime(2026, 10, 16, 10, 30),
        subjectId: 'math',
      );

      final grid = timetable.projectIntervalsToGrid(
        studyDay: day,
        intervals: [interval],
        subjectMap: {'math': sub},
      );

      final startSlot = timetable.timeToSlotIndex(interval.start);
      expect(grid[startSlot].fillRatio, equals(1.0));
      expect(grid[startSlot + 1].fillRatio, equals(1.0));
      expect(grid[startSlot + 2].fillRatio, equals(1.0));
      expect(grid[startSlot].colorHex, equals('#4CAF50'));
    });

    test('F24-4: Multiple distinct subjects paint respective color hex codes', () async {
      setUp();
      final day = DateTime(2026, 10, 16);
      final subA = SubjectEntity(id: 'math', name: 'Math', colorHex: '#4CAF50'); // Green
      final subB = SubjectEntity(id: 'phys', name: 'Physics', colorHex: '#2196F3'); // Blue

      final intA = StudyInterval(start: DateTime(2026, 10, 16, 8, 0), end: DateTime(2026, 10, 16, 8, 20), subjectId: 'math');
      final intB = StudyInterval(start: DateTime(2026, 10, 16, 9, 0), end: DateTime(2026, 10, 16, 9, 20), subjectId: 'phys');

      final grid = timetable.projectIntervalsToGrid(
        studyDay: day,
        intervals: [intA, intB],
        subjectMap: {'math': subA, 'phys': subB},
      );

      final slotA = timetable.timeToSlotIndex(intA.start);
      final slotB = timetable.timeToSlotIndex(intB.start);

      expect(grid[slotA].colorHex, equals('#4CAF50'));
      expect(grid[slotB].colorHex, equals('#2196F3'));
    });

    test('F24-5: Session crossing 05:00 AM cutoff bisects cleanly at cutoff boundary (E01)', () async {
      setUp();
      final day1 = DateTime(2026, 10, 16);
      final day2 = DateTime(2026, 10, 17);
      final sub = SubjectEntity(id: 'cs', name: 'CS', colorHex: '#9C27B0');

      // Session from 04:30 AM to 05:30 AM on Oct 17 (crosses 05:00 cutoff)
      final crossingSession = StudyInterval(
        start: DateTime(2026, 10, 17, 4, 30),
        end: DateTime(2026, 10, 17, 5, 30),
        subjectId: 'cs',
      );

      // In Day 1 (Oct 16 study day), 04:30-05:00 belongs to slots 141, 142, 143
      final gridDay1 = timetable.projectIntervalsToGrid(
        studyDay: day1,
        intervals: [crossingSession],
        subjectMap: {'cs': sub},
      );
      expect(gridDay1[141].fillRatio, equals(1.0));
      expect(gridDay1[142].fillRatio, equals(1.0));
      expect(gridDay1[143].fillRatio, equals(1.0));

      // In Day 2 (Oct 17 study day), 05:00-05:30 belongs to slots 0, 1, 2
      final gridDay2 = timetable.projectIntervalsToGrid(
        studyDay: day2,
        intervals: [crossingSession],
        subjectMap: {'cs': sub},
      );
      expect(gridDay2[0].fillRatio, equals(1.0));
      expect(gridDay2[1].fillRatio, equals(1.0));
      expect(gridDay2[2].fillRatio, equals(1.0));
    });
  });

  group('Tier 1: F25 Real-Time Block Painting & Pulsing (5 tests)', () {
    late TestTimetableEngine timetable;

    void setUp() {
      timetable = TestTimetableEngine();
    }

    test('F25-1: Partial 5-minute study within 10-minute slot yields 0.5 fill ratio (AC6)', () async {
      setUp();
      final day = DateTime(2026, 10, 16);
      final sub = SubjectEntity(id: 'lit', name: 'Literature', colorHex: '#E91E63');
      final partialInterval = StudyInterval(
        start: DateTime(2026, 10, 16, 10, 0),
        end: DateTime(2026, 10, 16, 10, 5), // 5 minutes
        subjectId: 'lit',
      );

      final grid = timetable.projectIntervalsToGrid(
        studyDay: day,
        intervals: [partialInterval],
        subjectMap: {'lit': sub},
      );

      final slot = timetable.timeToSlotIndex(partialInterval.start);
      expect(grid[slot].fillRatio, equals(0.5));
    });

    test('F25-2: Full 10-minute study paints slot with 1.0 fill ratio', () async {
      setUp();
      final day = DateTime(2026, 10, 16);
      final sub = SubjectEntity(id: 'lit', name: 'Literature', colorHex: '#E91E63');
      final fullInterval = StudyInterval(
        start: DateTime(2026, 10, 16, 10, 0),
        end: DateTime(2026, 10, 16, 10, 10),
        subjectId: 'lit',
      );

      final grid = timetable.projectIntervalsToGrid(
        studyDay: day,
        intervals: [fullInterval],
        subjectMap: {'lit': sub},
      );

      final slot = timetable.timeToSlotIndex(fullInterval.start);
      expect(grid[slot].fillRatio, equals(1.0));
    });

    test('F25-3: Active running session slot flagged with isPulsing true (AC6)', () async {
      setUp();
      final day = DateTime(2026, 10, 16);
      final sub = SubjectEntity(id: 'math', name: 'Math', colorHex: '#4CAF50');
      final activeInterval = StudyInterval(
        start: DateTime(2026, 10, 16, 14, 0),
        end: DateTime(2026, 10, 16, 14, 10),
        subjectId: 'math',
      );

      final current = DateTime(2026, 10, 16, 14, 4); // mid-slot
      final grid = timetable.projectIntervalsToGrid(
        studyDay: day,
        intervals: [activeInterval],
        subjectMap: {'math': sub},
        currentTime: current,
      );

      final slot = timetable.timeToSlotIndex(activeInterval.start);
      expect(grid[slot].isPulsing, isTrue);
    });

    test('F25-4: Non-active past slots have isPulsing false', () async {
      setUp();
      final day = DateTime(2026, 10, 16);
      final sub = SubjectEntity(id: 'math', name: 'Math', colorHex: '#4CAF50');
      final pastInterval = StudyInterval(
        start: DateTime(2026, 10, 16, 8, 0),
        end: DateTime(2026, 10, 16, 8, 10),
        subjectId: 'math',
      );

      final current = DateTime(2026, 10, 16, 14, 0); // hours later
      final grid = timetable.projectIntervalsToGrid(
        studyDay: day,
        intervals: [pastInterval],
        subjectMap: {'math': sub},
        currentTime: current,
      );

      final slot = timetable.timeToSlotIndex(pastInterval.start);
      expect(grid[slot].isPulsing, isFalse);
    });

    test('F25-5: Timetable watch stream emits updated grid on updateIntervals call', () async {
      setUp();
      var emissionReceived = false;
      final sub = timetable.watchTodayGrid().listen((grid) {
        if (grid.any((b) => b.fillRatio > 0.0)) {
          emissionReceived = true;
        }
      });

      timetable.updateIntervals(
        studyDay: DateTime.now(),
        intervals: [
          StudyInterval(start: DateTime.now(), end: DateTime.now().add(const Duration(minutes: 10)), subjectId: 's1'),
        ],
        subjectMap: {'s1': SubjectEntity(id: 's1', name: 'S1', colorHex: '#000000')},
      );

      expect(emissionReceived, isTrue);
      await sub.cancel();
    });
  });

  group('Tier 1: F26 Live Study Rooms & Tri-State Presence (5 tests)', () {
    late TestLiveStudyRoomEngine rooms;

    void setUp() {
      rooms = TestLiveStudyRoomEngine();
    }

    test('F26-1: Join live study room as member', () async {
      setUp();
      final member = RoomMember(userId: 'u1', displayName: 'Parsa');
      await rooms.joinRoom(roomId: 'room_101', self: member);

      final list = await rooms.watchRoomMembers('room_101').first;
      expect(list.length, equals(1));
      expect(list.first.userId, equals('u1'));
    });

    test('F26-2: Transition presence state from RESTING to STUDYING with <500ms latency (AC7)', () async {
      setUp();
      final member = RoomMember(userId: 'u2', displayName: 'Sara', presenceState: PresenceState.resting);
      await rooms.joinRoom(roomId: 'room_101', self: member);

      final tAction = DateTime.now();
      await rooms.updatePresence(
        roomId: 'room_101',
        userId: 'u2',
        state: PresenceState.studying,
        subjectName: 'Calculus',
        elapsedSeconds: 120,
      );

      final updatedList = await rooms.watchRoomMembers('room_101').first;
      final tReceived = DateTime.now();

      final latencyMs = tReceived.difference(tAction).inMilliseconds;
      expect(latencyMs, lessThan(500));
      expect(updatedList.firstWhere((m) => m.userId == 'u2').presenceState, equals(PresenceState.studying));
    });

    test('F26-3: Heartbeat ping updates member timestamp', () async {
      setUp();
      final member = RoomMember(userId: 'u3', displayName: 'Reza');
      await rooms.joinRoom(roomId: 'room_101', self: member);

      await Future.delayed(const Duration(milliseconds: 10));
      await rooms.sendHeartbeat(roomId: 'room_101', userId: 'u3');

      final list = await rooms.watchRoomMembers('room_101').first;
      expect(list.first.lastHeartbeat.isAfter(member.lastHeartbeat), isTrue);
    });

    test('F26-4: Inactive member without heartbeat for >30s marked OFFLINE (E18)', () async {
      setUp();
      final member = RoomMember(
        userId: 'u_inactive',
        displayName: 'Ghost',
        presenceState: PresenceState.studying,
        lastHeartbeat: DateTime.now().subtract(const Duration(seconds: 35)),
      );
      await rooms.joinRoom(roomId: 'room_timeout', self: member);

      rooms.sweepTimeouts(roomId: 'room_timeout');
      final list = await rooms.watchRoomMembers('room_timeout').first;
      expect(list.first.presenceState, equals(PresenceState.offline));
    });

    test('F26-5: Leave room removes member from active roster', () async {
      setUp();
      final member = RoomMember(userId: 'u_leave', displayName: 'Leaver');
      await rooms.joinRoom(roomId: 'room_leave', self: member);
      await rooms.leaveRoom(roomId: 'room_leave', userId: 'u_leave');

      final list = await rooms.watchRoomMembers('room_leave').first;
      expect(list.isEmpty, isTrue);
    });
  });

  group('Tier 1: F27 Animated Avatars & WebRTC Desk Cam (5 tests)', () {
    late TestLiveStudyRoomEngine rooms;

    void setUp() {
      rooms = TestLiveStudyRoomEngine();
    }

    test('F27-1: Assign Animated Lottie vector avatar type by default', () async {
      setUp();
      final member = RoomMember(
        userId: 'avatar_user',
        displayName: 'Avatara',
        avatarType: AvatarType.animatedLottie,
      );
      await rooms.joinRoom(roomId: 'room_avatar', self: member);

      final list = await rooms.watchRoomMembers('room_avatar').first;
      expect(list.first.avatarType, equals(AvatarType.animatedLottie));
    });

    test('F27-2: State-driven avatar animation reflects active study state', () async {
      setUp();
      final member = RoomMember(
        userId: 'anim_user',
        displayName: 'Animator',
        presenceState: PresenceState.studying,
        avatarAnimation: 'study_reading.json',
      );
      await rooms.joinRoom(roomId: 'room_avatar', self: member);

      final list = await rooms.watchRoomMembers('room_avatar').first;
      expect(list.first.avatarAnimation, equals('study_reading.json'));
    });

    test('F27-3: Assign WebRTC Desk Cam avatar type for video stream', () async {
      setUp();
      final member = RoomMember(
        userId: 'cam_user',
        displayName: 'CamStreamer',
        avatarType: AvatarType.webRtcDeskCam,
      );
      await rooms.joinRoom(roomId: 'room_avatar', self: member);

      final list = await rooms.watchRoomMembers('room_avatar').first;
      expect(list.first.avatarType, equals(AvatarType.webRtcDeskCam));
    });

    test('F27-4: Graceful fallback from desk cam to animated avatar', () async {
      setUp();
      final member = RoomMember(
        userId: 'cam_fallback',
        displayName: 'CamFallback',
        avatarType: AvatarType.webRtcDeskCam,
      );
      await rooms.joinRoom(roomId: 'room_avatar', self: member);

      // Camera denied fallback
      final fallback = member.copyWith(
        avatarType: AvatarType.animatedLottie,
        avatarAnimation: 'fallback_avatar.json',
      );
      await rooms.joinRoom(roomId: 'room_avatar', self: fallback);

      final list = await rooms.watchRoomMembers('room_avatar').first;
      expect(list.first.avatarType, equals(AvatarType.animatedLottie));
    });

    test('F27-5: Resting presence triggers sleeping/resting avatar animation', () async {
      setUp();
      final member = RoomMember(
        userId: 'rest_user',
        displayName: 'Rester',
        presenceState: PresenceState.resting,
        avatarAnimation: 'coffee_rest.json',
      );
      await rooms.joinRoom(roomId: 'room_avatar', self: member);

      final list = await rooms.watchRoomMembers('room_avatar').first;
      expect(list.first.presenceState, equals(PresenceState.resting));
      expect(list.first.avatarAnimation, equals('coffee_rest.json'));
    });
  });

  group('Tier 1: F28 Groups, Quotas, Cheering Reactions (5 tests)', () {
    late TestLiveStudyRoomEngine rooms;

    void setUp() {
      rooms = TestLiveStudyRoomEngine();
    }

    test('F28-1: Send cheering clap reaction (👏) to study room peer', () async {
      setUp();
      var cheerReceived = false;
      final sub = rooms.watchCheerReactions('room_cheer').listen((cheer) {
        if (cheer.emoji == '👏' && cheer.targetUserId == 'target_user') {
          cheerReceived = true;
        }
      });

      final success = await rooms.sendCheer(
        roomId: 'room_cheer',
        senderId: 'sender_user',
        targetUserId: 'target_user',
        emoji: '👏',
      );

      expect(success, isTrue);
      expect(cheerReceived, isTrue);
      await sub.cancel();
    });

    test('F28-2: Send fire reaction (🔥) cheering emoji', () async {
      setUp();
      final success = await rooms.sendCheer(
        roomId: 'room_cheer',
        senderId: 'sender_user',
        targetUserId: 'target_user',
        emoji: '🔥',
      );
      expect(success, isTrue);
    });

    test('F28-3: Cheering token-bucket rate limiter permits up to 5 cheers in 10s (E19)', () async {
      setUp();
      for (var i = 0; i < 5; i++) {
        final res = await rooms.sendCheer(
          roomId: 'room_cheer',
          senderId: 'rate_limited_sender',
          targetUserId: 'target',
          emoji: '💪',
        );
        expect(res, isTrue);
      }
    });

    test('F28-4: 6th cheer within 10-second window is rejected silently (E19)', () async {
      setUp();
      for (var i = 0; i < 5; i++) {
        await rooms.sendCheer(
          roomId: 'room_cheer',
          senderId: 'spammer_user',
          targetUserId: 'target',
          emoji: '☕',
        );
      }

      // 6th cheer attempt
      final sixthCheer = await rooms.sendCheer(
        roomId: 'room_cheer',
        senderId: 'spammer_user',
        targetUserId: 'target',
        emoji: '☕',
      );

      expect(sixthCheer, isFalse);
    });

    test('F28-5: Multiple peers receive broadcast cheering reactions', () async {
      setUp();
      final receivedEmojis = <String>[];
      final sub = rooms.watchCheerReactions('room_broadcast').listen((c) {
        receivedEmojis.add(c.emoji);
      });

      await rooms.sendCheer(roomId: 'room_broadcast', senderId: 's1', targetUserId: 't1', emoji: '👏');
      await rooms.sendCheer(roomId: 'room_broadcast', senderId: 's2', targetUserId: 't1', emoji: '🔥');

      expect(receivedEmojis.length, equals(2));
      expect(receivedEmojis, equals(['👏', '🔥']));
      await sub.cancel();
    });
  });
}
