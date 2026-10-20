// Test Reference Harness: Live Study Rooms & Social Presence
// Grounded in PROJECT.md (F26–F28, AC7, E18, E19)

import 'dart:async';
import '../contracts/study_room_contracts.dart';

class TestLiveStudyRoomEngine implements ILiveStudyRoomService {
  final Map<String, Map<String, RoomMember>> _roomMembers = {};
  final Map<String, StreamController<List<RoomMember>>> _memberControllers = {};
  final Map<String, StreamController<CheerReaction>> _cheerControllers = {};

  // Rate limiter: senderId -> List of cheer timestamps
  final Map<String, List<DateTime>> _cheerRateLimits = {};

  void _notifyMembers(String roomId) {
    if (_memberControllers.containsKey(roomId)) {
      final list = (_roomMembers[roomId] ?? {}).values.toList();
      _memberControllers[roomId]!.add(list);
    }
  }

  @override
  Stream<List<RoomMember>> watchRoomMembers(String roomId) {
    _memberControllers.putIfAbsent(roomId, () => StreamController.broadcast());
    _notifyMembers(roomId);
    return _memberControllers[roomId]!.stream;
  }

  @override
  Stream<CheerReaction> watchCheerReactions(String roomId) {
    _cheerControllers.putIfAbsent(roomId, () => StreamController.broadcast());
    return _cheerControllers[roomId]!.stream;
  }

  @override
  Future<void> joinRoom({required String roomId, required RoomMember self}) async {
    _roomMembers.putIfAbsent(roomId, () => {});
    _roomMembers[roomId]![self.userId] = self.copyWith(lastHeartbeat: DateTime.now());
    _notifyMembers(roomId);
  }

  @override
  Future<void> updatePresence({
    required String roomId,
    required String userId,
    required PresenceState state,
    String? subjectName,
    int? elapsedSeconds,
  }) async {
    final members = _roomMembers[roomId];
    if (members != null && members.containsKey(userId)) {
      final member = members[userId]!;
      members[userId] = member.copyWith(
        presenceState: state,
        activeSubjectName: subjectName ?? member.activeSubjectName,
        elapsedSeconds: elapsedSeconds ?? member.elapsedSeconds,
        lastHeartbeat: DateTime.now(),
      );
      _notifyMembers(roomId);
    }
  }

  @override
  Future<void> sendHeartbeat({required String roomId, required String userId}) async {
    final members = _roomMembers[roomId];
    if (members != null && members.containsKey(userId)) {
      members[userId] = members[userId]!.copyWith(lastHeartbeat: DateTime.now());
    }
  }

  void sweepTimeouts({required String roomId, DateTime? currentTime}) {
    final now = currentTime ?? DateTime.now();
    final members = _roomMembers[roomId];
    if (members == null) return;

    var changed = false;
    for (final userId in members.keys) {
      final member = members[userId]!;
      if (member.presenceState != PresenceState.offline) {
        if (now.difference(member.lastHeartbeat).inSeconds > 30) {
          members[userId] = member.copyWith(presenceState: PresenceState.offline);
          changed = true;
        }
      }
    }
    if (changed) {
      _notifyMembers(roomId);
    }
  }

  @override
  Future<bool> sendCheer({
    required String roomId,
    required String senderId,
    required String targetUserId,
    required String emoji,
  }) async {
    final now = DateTime.now();
    final timestamps = _cheerRateLimits.putIfAbsent(senderId, () => []);

    // Clean timestamps older than 10 seconds
    timestamps.removeWhere((t) => now.difference(t).inSeconds >= 10);

    // Limit: max 5 cheering reactions per 10-second window
    if (timestamps.length >= 5) {
      return false; // Rate limit exceeded (silent drop)
    }

    timestamps.add(now);
    final cheer = CheerReaction(
      senderId: senderId,
      targetUserId: targetUserId,
      emoji: emoji,
      timestamp: now,
    );

    if (_cheerControllers.containsKey(roomId)) {
      _cheerControllers[roomId]!.add(cheer);
    }
    return true;
  }

  @override
  Future<void> leaveRoom({required String roomId, required String userId}) async {
    final members = _roomMembers[roomId];
    if (members != null) {
      members.remove(userId);
      _notifyMembers(roomId);
    }
  }
}
