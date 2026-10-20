import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/database_rows_table.dart';

part 'database_rows_dao.g.dart';

@DriftAccessor(tables: [DatabaseRowsTable])
class DatabaseRowsDao extends DatabaseAccessor<AppDatabase> with _$DatabaseRowsDaoMixin {
  DatabaseRowsDao(super.db);

  Stream<List<DatabaseRowEntry>> watchRowsForDatabase(String databaseId) {
    return (select(databaseRowsTable)
          ..where((tbl) => tbl.databaseId.equals(databaseId))
          ..orderBy([
            (tbl) => OrderingTerm(expression: tbl.sortOrder, mode: OrderingMode.asc),
            (tbl) => OrderingTerm(expression: tbl.createdAt, mode: OrderingMode.asc),
          ]))
        .watch();
  }

  Future<List<DatabaseRowEntry>> getRowsForDatabase(String databaseId) {
    return (select(databaseRowsTable)
          ..where((tbl) => tbl.databaseId.equals(databaseId))
          ..orderBy([
            (tbl) => OrderingTerm(expression: tbl.sortOrder, mode: OrderingMode.asc),
            (tbl) => OrderingTerm(expression: tbl.createdAt, mode: OrderingMode.asc),
          ]))
        .get();
  }

  Future<DatabaseRowEntry?> getRowById(String id) {
    return (select(databaseRowsTable)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  Future<DatabaseRowEntry?> getRowByPageId(String pageId) {
    return (select(databaseRowsTable)..where((tbl) => tbl.pageId.equals(pageId))).getSingleOrNull();
  }

  Future<int> insertRow(DatabaseRowsTableCompanion entry) {
    return into(databaseRowsTable).insert(entry);
  }

  Future<bool> updateRow(DatabaseRowsTableCompanion entry) {
    return update(databaseRowsTable).replace(entry);
  }

  Future<int> deleteRow(String id) {
    return (delete(databaseRowsTable)..where((tbl) => tbl.id.equals(id))).go();
  }

  Future<void> batchUpdateSortOrders(Map<String, double> rowSortOrders) async {
    await batch((b) {
      for (final entry in rowSortOrders.entries) {
        b.update(
          databaseRowsTable,
          DatabaseRowsTableCompanion(
            sortOrder: Value(entry.value),
            updatedAt: Value(DateTime.now()),
          ),
          where: (tbl) => tbl.id.equals(entry.key),
        );
      }
    });
  }
}
