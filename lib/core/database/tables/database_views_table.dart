import 'package:drift/drift.dart';

/// Table representing database views (Table, Kanban, Calendar, Timeline, List, Gallery).
/// Stores view configurations (filters, sorts, groupings, calendar ranges) in [configJson].
@TableIndex(name: 'idx_views_database_sort', columns: {#databaseId, #sortOrder})
@DataClassName('DatabaseViewEntry')
class DatabaseViewsTable extends Table {
  @override
  String get tableName => 'database_views';

  TextColumn get id => text()();
  TextColumn get databaseId => text()();
  TextColumn get name => text().withDefault(const Constant('Default View'))();
  TextColumn get viewType => text()(); // 'table', 'kanban', 'calendar', 'timeline', 'list', 'gallery'
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
