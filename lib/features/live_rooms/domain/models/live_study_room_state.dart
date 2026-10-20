enum PeerPresenceStatus {
  studying,
  resting,
  offline,
}

class StudyPeer {
  final String id;
  final String displayName;
  final String avatarUrl;
  final PeerPresenceStatus status;
  final String? activeSubject;
  final int elapsedSeconds;
  final int cheersReceived;

  const StudyPeer({
    required this.id,
    required this.displayName,
    this.avatarUrl = '',
    this.status = PeerPresenceStatus.studying,
    this.activeSubject,
    this.elapsedSeconds = 0,
    this.cheersReceived = 0,
  });

  StudyPeer copyWith({
    String? id,
    String? displayName,
    String? avatarUrl,
    PeerPresenceStatus? status,
    String? activeSubject,
    int? elapsedSeconds,
    int? cheersReceived,
  }) {
    return StudyPeer(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      status: status ?? this.status,
      activeSubject: activeSubject ?? this.activeSubject,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      cheersReceived: cheersReceived ?? this.cheersReceived,
    );
  }
}

class LiveStudyRoomState {
  final String roomId;
  final String roomName;
  final List<StudyPeer> peers;

  const LiveStudyRoomState({
    required this.roomId,
    required this.roomName,
    this.peers = const [],
  });

  LiveStudyRoomState withCheer(String peerId) {
    final updated = peers.map((p) {
      if (p.id == peerId) {
        return p.copyWith(cheersReceived: p.cheersReceived + 1);
      }
      return p;
    }).toList();
    return LiveStudyRoomState(roomId: roomId, roomName: roomName, peers: updated);
  }
}
