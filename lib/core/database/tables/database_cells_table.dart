import 'package:drift/drift.dart';

/// Table representing individual cell values for (row, property) intersections.
/// Stores typed serialized JSON values with full referential cascading.
@TableIndex(name: 'idx_cells_row_property', columns: {#rowId, #propertyId}, unique: true)
@TableIndex(name: 'idx_cells_property', columns: {#propertyId})
@DataClassName('DatabaseCellEntry')
class DatabaseCellsTable extends Table {
  @override
  String get tableName => 'database_cells';

  TextColumn get id => text()();
  TextColumn get rowId => text()();
  TextColumn get propertyId => text()();
  TextColumn get valueJson => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (row_id) REFERENCES database_rows(id) ON DELETE CASCADE',
    'FOREIGN KEY (property_id) REFERENCES database_properties(id) ON DELETE CASCADE',
  ];
}
