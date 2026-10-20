class DDayEntity {
  final String id;
  final String title;
  final DateTime targetDate;
  final String? linkedDatabaseId;
  final String? linkedPropertyId;

  const DDayEntity({
    required this.id,
    required this.title,
    required this.targetDate,
    this.linkedDatabaseId,
    this.linkedPropertyId,
  });

  int daysRemaining({DateTime? referenceDate}) {
    final now = referenceDate ?? DateTime.now();
    final cleanTarget = DateTime(targetDate.year, targetDate.month, targetDate.day);
    final cleanNow = DateTime(now.year, now.month, now.day);
    return cleanTarget.difference(cleanNow).inDays;
  }

  String formatDDay({DateTime? referenceDate}) {
    final diff = daysRemaining(referenceDate: referenceDate);
    if (diff == 0) return 'D-Day';
    if (diff > 0) return 'D-$diff';
    return 'D+${diff.abs()}';
  }

  DDayEntity copyWith({
    String? id,
    String? title,
    DateTime? targetDate,
    String? linkedDatabaseId,
    String? linkedPropertyId,
  }) {
    return DDayEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      targetDate: targetDate ?? this.targetDate,
      linkedDatabaseId: linkedDatabaseId ?? this.linkedDatabaseId,
      linkedPropertyId: linkedPropertyId ?? this.linkedPropertyId,
    );
  }
}
