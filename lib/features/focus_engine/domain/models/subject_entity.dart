class SubjectEntity {
  final String id;
  final String name;
  final String colorHex;
  final String? icon;
  final int dailyGoalMinutes;
  final bool isArchived;
  final double sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SubjectEntity({
    required this.id,
    required this.name,
    required this.colorHex,
    this.icon,
    this.dailyGoalMinutes = 60,
    this.isArchived = false,
    this.sortOrder = 0.0,
    required this.createdAt,
    required this.updatedAt,
  });

  SubjectEntity copyWith({
    String? id,
    String? name,
    String? colorHex,
    String? icon,
    int? dailyGoalMinutes,
    bool? isArchived,
    double? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SubjectEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      colorHex: colorHex ?? this.colorHex,
      icon: icon ?? this.icon,
      dailyGoalMinutes: dailyGoalMinutes ?? this.dailyGoalMinutes,
      isArchived: isArchived ?? this.isArchived,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
