import 'package:drift/drift.dart';

/// Table representing rows within a relational database.
/// Enforces the Dual Identity Paradigm: [pageId] references an underlying Page
/// with a 1:1 unique constraint, ensuring each row is a full modular document.
@TableIndex(name: 'idx_rows_database_sort', columns: {#databaseId, #sortOrder})
@TableIndex(name: 'idx_rows_page_id', columns: {#pageId}, unique: true)
@DataClassName('DatabaseRowEntry')
class DatabaseRowsTable extends Table {
  @override
  String get tableName => 'database_rows';

  TextColumn get id => text()();
  TextColumn get databaseId => text()();
  TextColumn get pageId => text()(); // 1:1 Dual Identity Page reference
  RealColumn get sortOrder => real().withDefault(const Constant(0.0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (database_id) REFERENCES databases(id) ON DELETE CASCADE',
    'FOREIGN KEY (page_id) REFERENCES pages(id) ON DELETE CASCADE',
  ];
}
