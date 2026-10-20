enum LeaderboardTier {
  national,
  group,
  peer,
}

class LeaderboardEntry {
  final int rank;
  final String userId;
  final String displayName;
  final int totalSeconds;
  final bool isAnonymous;
  final String? subjectName;
  final LeaderboardTier tier;

  const LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.displayName,
    required this.totalSeconds,
    this.isAnonymous = false,
    this.subjectName,
    this.tier = LeaderboardTier.national,
  });

  String get formattedDuration {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  LeaderboardEntry copyWith({
    int? rank,
    String? userId,
    String? displayName,
    int? totalSeconds,
    bool? isAnonymous,
    String? subjectName,
    LeaderboardTier? tier,
  }) {
    return LeaderboardEntry(
      rank: rank ?? this.rank,
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      subjectName: subjectName ?? this.subjectName,
      tier: tier ?? this.tier,
    );
  }
}
