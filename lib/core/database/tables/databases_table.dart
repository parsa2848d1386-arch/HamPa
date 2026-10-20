import 'package:drift/drift.dart';

/// Table representing relational database containers in HamPA.
/// A database belongs to an enclosing Page document via [pageId].
@TableIndex(name: 'idx_databases_page_id', columns: {#pageId})
@DataClassName('DatabaseEntry')
class DatabasesTable extends Table {
  @override
  String get tableName => 'databases';

  TextColumn get id => text()();
  TextColumn get pageId => text()(); // Enclosing page ID
  TextColumn get title => text().withDefault(const Constant('Untitled Database'))();
  TextColumn get icon => text().nullable()();
  TextColumn get coverImageUrl => text().nullable()();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (page_id) REFERENCES pages(id) ON DELETE CASCADE',
  ];
}
