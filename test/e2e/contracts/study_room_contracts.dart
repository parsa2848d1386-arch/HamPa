// E2E Contract Definitions: Live Study Rooms, Tri-State Presence & Cheering
// Grounded in PROJECT.md and ORIGINAL_REQUEST.md (R2, AC7)

enum PresenceState {
  studying,
  resting,
  offline,
}

enum AvatarType {
  animatedLottie,
  webRtcDeskCam,
}

class RoomMember {
  final String userId;
  final String displayName;
  final PresenceState presenceState;
  final String? activeSubjectName;
  final int elapsedSeconds;
  final DateTime lastHeartbeat;
  final AvatarType avatarType;
  final String? avatarAnimation;

  RoomMember({
    required this.userId,
    required this.displayName,
    this.presenceState = PresenceState.offline,
    this.activeSubjectName,
    this.elapsedSeconds = 0,
    DateTime? lastHeartbeat,
    this.avatarType = AvatarType.animatedLottie,
    this.avatarAnimation,
  }) : lastHeartbeat = lastHeartbeat ?? DateTime.now();

  RoomMember copyWith({
    String? userId,
    String? displayName,
    PresenceState? presenceState,
    String? activeSubjectName,
    int? elapsedSeconds,
    DateTime? lastHeartbeat,
    AvatarType? avatarType,
    String? avatarAnimation,
  }) {
    return RoomMember(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      presenceState: presenceState ?? this.presenceState,
      activeSubjectName: activeSubjectName ?? this.activeSubjectName,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      lastHeartbeat: lastHeartbeat ?? this.lastHeartbeat,
      avatarType: avatarType ?? this.avatarType,
      avatarAnimation: avatarAnimation ?? this.avatarAnimation,
    );
  }
}

class CheerReaction {
  final String senderId;
  final String targetUserId;
  final String emoji; // 👏, 🔥, 💪, ☕
  final DateTime timestamp;

  CheerReaction({
    required this.senderId,
    required this.targetUserId,
    required this.emoji,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

abstract class ILiveStudyRoomService {
  Stream<List<RoomMember>> watchRoomMembers(String roomId);
  Stream<CheerReaction> watchCheerReactions(String roomId);

  Future<void> joinRoom({required String roomId, required RoomMember self});
  Future<void> updatePresence({
    required String roomId,
    required String userId,
    required PresenceState state,
    String? subjectName,
    int? elapsedSeconds,
  });
  Future<void> sendHeartbeat({required String roomId, required String userId});
  Future<bool> sendCheer({
    required String roomId,
    required String senderId,
    required String targetUserId,
    required String emoji,
  });
  Future<void> leaveRoom({required String roomId, required String userId});
}
