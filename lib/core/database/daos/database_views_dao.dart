import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/database_views_table.dart';

part 'database_views_dao.g.dart';

@DriftAccessor(tables: [DatabaseViewsTable])
class DatabaseViewsDao extends DatabaseAccessor<AppDatabase> with _$DatabaseViewsDaoMixin {
  DatabaseViewsDao(super.db);

  Stream<List<DatabaseViewEntry>> watchViewsForDatabase(String databaseId) {
    return (select(databaseViewsTable)
          ..where((tbl) => tbl.databaseId.equals(databaseId))
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.sortOrder, mode: OrderingMode.asc)]))
        .watch();
  }

  Future<List<DatabaseViewEntry>> getViewsForDatabase(String databaseId) {
    return (select(databaseViewsTable)
          ..where((tbl) => tbl.databaseId.equals(databaseId))
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.sortOrder, mode: OrderingMode.asc)]))
        .get();
  }

  Future<DatabaseViewEntry?> getViewById(String id) {
    return (select(databaseViewsTable)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  Future<int> insertView(DatabaseViewsTableCompanion entry) {
    return into(databaseViewsTable).insert(entry);
  }

  Future<bool> updateView(DatabaseViewsTableCompanion entry) {
    return update(databaseViewsTable).replace(entry);
  }

  Future<int> deleteView(String id) {
    return (delete(databaseViewsTable)..where((tbl) => tbl.id.equals(id))).go();
  }

  Future<void> batchUpdateSortOrders(Map<String, double> viewSortOrders) async {
    await batch((b) {
      for (final entry in viewSortOrders.entries) {
        b.update(
          databaseViewsTable,
          DatabaseViewsTableCompanion(
            sortOrder: Value(entry.value),
            updatedAt: Value(DateTime.now()),
          ),
          where: (tbl) => tbl.id.equals(entry.key),
        );
      }
    });
  }
}
