import 'package:drift/drift.dart';

/// Table representing dynamic column/property schemas of a database.
/// Supports 16 rich property types, fractional ordering, and JSON configuration.
@TableIndex(name: 'idx_properties_database_sort', columns: {#databaseId, #sortOrder})
@DataClassName('DatabasePropertyEntry')
class DatabasePropertiesTable extends Table {
  @override
  String get tableName => 'database_properties';

  TextColumn get id => text()();
  TextColumn get databaseId => text()();
  TextColumn get name => text()();
  TextColumn get propertyType => text()(); // 'title', 'text', 'number', 'select', etc.
  RealColumn get sortOrder => real().withDefault(const Constant(0.0))();
  TextColumn get configJson => text().withDefault(const Constant('{}'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (database_id) REFERENCES databases(id) ON DELETE CASCADE',
  ];
}
