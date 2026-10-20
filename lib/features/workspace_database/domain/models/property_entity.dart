import 'property_type.dart';

class PropertyEntity {
  final String id;
  final String databaseId;
  final String name;
  final PropertyType type;
  final Map<String, dynamic> config;

  PropertyEntity({
    required this.id,
    required this.databaseId,
    required this.name,
    required this.type,
    Map<String, dynamic>? config,
  }) : config = config ?? {};

  PropertyEntity copyWith({
    String? id,
    String? databaseId,
    String? name,
    PropertyType? type,
    Map<String, dynamic>? config,
  }) {
    return PropertyEntity(
      id: id ?? this.id,
      databaseId: databaseId ?? this.databaseId,
      name: name ?? this.name,
      type: type ?? this.type,
      config: config ?? Map.from(this.config),
    );
  }
}
