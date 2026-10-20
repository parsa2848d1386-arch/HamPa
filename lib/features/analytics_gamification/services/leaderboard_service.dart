import '../domain/models/leaderboard_entry.dart';

class LeaderboardService {
  /// Generates a sorted and ranked leaderboard list from raw stats.
  /// Supports anonymized mode (masks displayName and subjectName).
  List<LeaderboardEntry> generateLeaderboard({
    required List<Map<String, dynamic>> rawUserStats,
    LeaderboardTier tier = LeaderboardTier.national,
    bool anonymizedMode = false,
  }) {
    final list = List<Map<String, dynamic>>.from(rawUserStats)
      ..sort((a, b) => (b['totalSeconds'] as int).compareTo(a['totalSeconds'] as int));

    return List.generate(list.length, (index) {
      final item = list[index];
      final isAnon = anonymizedMode || (item['isAnonymous'] as bool? ?? false);
      final userId = item['userId'] as String;
      final displayName = isAnon
          ? 'Anonymous #${userId.hashCode.abs().toString().padLeft(4, '0').substring(0, 4)}'
          : (item['displayName'] as String);
      final subjectName = isAnon ? 'General Study' : (item['subjectName'] as String?);

      return LeaderboardEntry(
        rank: index + 1,
        userId: userId,
        displayName: displayName,
        totalSeconds: item['totalSeconds'] as int,
        isAnonymous: isAnon,
        subjectName: subjectName,
        tier: tier,
      );
    });
  }
}
