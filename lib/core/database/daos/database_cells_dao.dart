import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/database_cells_table.dart';
import '../tables/database_rows_table.dart';

part 'database_cells_dao.g.dart';

@DriftAccessor(tables: [DatabaseCellsTable, DatabaseRowsTable])
class DatabaseCellsDao extends DatabaseAccessor<AppDatabase> with _$DatabaseCellsDaoMixin {
  DatabaseCellsDao(super.db);

  Stream<List<DatabaseCellEntry>> watchCellsForDatabase(String databaseId) {
    final query = select(databaseCellsTable).join([
      innerJoin(
        databaseRowsTable,
        databaseRowsTable.id.equalsExp(databaseCellsTable.rowId),
      ),
    ])..where(databaseRowsTable.databaseId.equals(databaseId));

    return query.watch().map((rows) => rows.map((r) => r.readTable(databaseCellsTable)).toList());
  }

  Stream<List<DatabaseCellEntry>> watchCellsForRow(String rowId) {
    return (select(databaseCellsTable)..where((tbl) => tbl.rowId.equals(rowId))).watch();
  }

  Future<List<DatabaseCellEntry>> getCellsForRow(String rowId) {
    return (select(databaseCellsTable)..where((tbl) => tbl.rowId.equals(rowId))).get();
  }

  Future<DatabaseCellEntry?> getCell(String rowId, String propertyId) {
    return (select(databaseCellsTable)
          ..where((tbl) => tbl.rowId.equals(rowId) & tbl.propertyId.equals(propertyId)))
        .getSingleOrNull();
  }

  Future<void> upsertCell({
    required String rowId,
    required String propertyId,
    required String? valueJson,
  }) async {
    final cellId = 'cell_${rowId}_$propertyId';
    await into(databaseCellsTable).insertOnConflictUpdate(
      DatabaseCellsTableCompanion(
        id: Value(cellId),
        rowId: Value(rowId),
        propertyId: Value(propertyId),
        valueJson: Value(valueJson),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> deleteCellsForRow(String rowId) {
    return (delete(databaseCellsTable)..where((tbl) => tbl.rowId.equals(rowId))).go();
  }

  Future<int> deleteCellsForProperty(String propertyId) {
    return (delete(databaseCellsTable)..where((tbl) => tbl.propertyId.equals(propertyId))).go();
  }

  /// Searches for relation cells containing a given target rowId for referential cleanup
  Future<List<DatabaseCellEntry>> findRelationCellsContaining(String targetRowId) {
    return (select(databaseCellsTable)
          ..where((tbl) => tbl.valueJson.like('%$targetRowId%')))
        .get();
  }
}
