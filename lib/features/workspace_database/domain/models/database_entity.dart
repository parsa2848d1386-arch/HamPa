class DatabaseEntity {
  final String id;
  final String title;
  final String pageId;

  const DatabaseEntity({
    required this.id,
    required this.title,
    required this.pageId,
  });

  DatabaseEntity copyWith({String? id, String? title, String? pageId}) {
    return DatabaseEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      pageId: pageId ?? this.pageId,
    );
  }
}
