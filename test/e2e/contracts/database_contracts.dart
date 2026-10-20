// E2E Contract Definitions: Relational Database Engine & 6 Views
// Grounded in PROJECT.md and ORIGINAL_REQUEST.md (R1, AC2, AC8)

enum PropertyType {
  title,
  text,
  number,
  select,
  multiSelect,
  status,
  date,
  checkbox,
  relation,
  formula,
  rollup,
}

enum RollupFunction {
  sum,
  average,
  min,
  max,
  count,
  percentChecked,
}

enum DatabaseViewType {
  table,
  kanban,
  calendar,
  timeline,
  list,
  gallery,
}

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

class DatabaseEntity {
  final String id;
  final String title;
  final String pageId;

  DatabaseEntity({
    required this.id,
    required this.title,
    required this.pageId,
  });
}

class RowEntity {
  final String id;
  final String databaseId;
  final String pageId; // 1:1 dual identity page id
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
}

class CellEntity {
  final String id;
  final String rowId;
  final String propertyId;
  final dynamic value;

  CellEntity({
    required this.id,
    required this.rowId,
    required this.propertyId,
    this.value,
  });

  CellEntity copyWith({
    String? id,
    String? rowId,
    String? propertyId,
    dynamic value,
  }) {
    return CellEntity(
      id: id ?? this.id,
      rowId: rowId ?? this.rowId,
      propertyId: propertyId ?? this.propertyId,
      value: value ?? this.value,
    );
  }
}

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

abstract class IDatabaseEngineRepository {
  Stream<DatabaseEntity> watchDatabase(String databaseId);
  Stream<List<PropertyEntity>> watchProperties(String databaseId);
  Stream<List<RowEntity>> watchRows(String databaseId);
  Stream<List<CellEntity>> watchCells(String databaseId);
  Stream<List<ViewEntity>> watchViews(String databaseId);

  Future<DatabaseEntity> createDatabase({required String title, required String pageId});
  Future<PropertyEntity> addProperty({
    required String databaseId,
    required String name,
    required PropertyType type,
    Map<String, dynamic>? config,
  });
  Future<String> createRow(String databaseId);
  Future<void> updatePropertyValue({
    required String rowId,
    required String propertyId,
    dynamic value,
  });
  Future<dynamic> getPropertyValue({
    required String rowId,
    required String propertyId,
  });
  Future<void> deleteRow(String rowId);

  Future<ViewEntity> createView({
    required String databaseId,
    required String name,
    required DatabaseViewType type,
    Map<String, dynamic>? config,
  });

  // Formula evaluation and cycle detection
  Future<dynamic> evaluateFormula({
    required String rowId,
    required String expression,
  });

  // Rollup calculation across related databases
  Future<dynamic> computeRollup({
    required String rowId,
    required String relationPropertyId,
    required String targetPropertyId,
    required RollupFunction function,
  });
}
