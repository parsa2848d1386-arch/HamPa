import 'database_view_type.dart';

class ViewEntity {
  final String id;
  final String databaseId;
  final String name;
  final DatabaseViewType type;
  final Map<String, dynamic> config;

  ViewEntity({
    required this.id,
    required this.databaseId,
    required this.name,
    required this.type,
    Map<String, dynamic>? config,
  }) : config = config ?? {};

  ViewEntity copyWith({
    String? id,
    String? databaseId,
    String? name,
    DatabaseViewType? type,
    Map<String, dynamic>? config,
  }) {
    return ViewEntity(
      id: id ?? this.id,
      databaseId: databaseId ?? this.databaseId,
      name: name ?? this.name,
      type: type ?? this.type,
      config: config ?? Map.from(this.config),
    );
  }
}
