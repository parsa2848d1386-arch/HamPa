import 'package:drift/drift.dart';

/// Table representing Notion-like hierarchical pages.
/// Also serves as the 1:1 dual identity backing store for relational database rows.
@TableIndex(name: 'idx_pages_parent', columns: {#parentPageId})
@TableIndex(name: 'idx_pages_parent_sort', columns: {#parentPageId, #sortOrder})
@DataClassName('PageEntry')
class Pages extends Table {
  TextColumn get id => text()();
  TextColumn get parentPageId => text().nullable()();
  TextColumn get title => text().withDefault(const Constant('Untitled'))();
  TextColumn get icon => text().nullable()();
  TextColumn get coverImageUrl => text().nullable()();
  BoolColumn get isDatabaseRow => boolean().withDefault(const Constant(false))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  RealColumn get sortOrder => real().withDefault(const Constant(0.0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (parent_page_id) REFERENCES pages(id) ON DELETE CASCADE',
  ];
}
