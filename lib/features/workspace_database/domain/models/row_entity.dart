class RowEntity {
  final String id;
  final String databaseId;
  final String pageId; // 1:1 dual identity page ID
  final DateTime createdAt;
  final DateTime updatedAt;

  RowEntity({
    required this.id,
    required this.databaseId,
    required this.pageId,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  RowEntity copyWith({
    String? id,
    String? databaseId,
    String? pageId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RowEntity(
      id: id ?? this.id,
      databaseId: databaseId ?? this.databaseId,
      pageId: pageId ?? this.pageId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
