class StreakResult {
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastStudyDate;
  final bool isFrozen;

  const StreakResult({
    required this.currentStreak,
    required this.longestStreak,
    this.lastStudyDate,
    this.isFrozen = false,
  });
}
