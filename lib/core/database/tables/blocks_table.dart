import 'package:drift/drift.dart';

/// Table representing modular blocks within a page.
/// Supports arbitrary nesting (toggles) and fractional indexing (LexoRank).
@TableIndex(name: 'idx_blocks_page_order', columns: {#pageId, #orderKey})
@TableIndex(name: 'idx_blocks_parent', columns: {#parentBlockId})
@DataClassName('BlockEntry')
class Blocks extends Table {
  TextColumn get id => text()();
  TextColumn get pageId => text()();
  TextColumn get parentBlockId => text().nullable()();
  TextColumn get blockType => text()(); // 'text', 'heading_1', 'heading_2', 'heading_3', 'checklist', 'callout', 'toggle', 'code', 'math', 'divider', 'quote'
  TextColumn get orderKey => text()(); // LexoRank string for O(1) drag-and-drop ordering
  TextColumn get contentJson => text().withDefault(const Constant('{}'))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (page_id) REFERENCES pages(id) ON DELETE CASCADE',
    'FOREIGN KEY (parent_block_id) REFERENCES blocks(id) ON DELETE CASCADE',
  ];
}
