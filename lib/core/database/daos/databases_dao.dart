import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/databases_table.dart';

part 'databases_dao.g.dart';

@DriftAccessor(tables: [DatabasesTable])
class DatabasesDao extends DatabaseAccessor<AppDatabase> with _$DatabasesDaoMixin {
  DatabasesDao(super.db);

  Stream<DatabaseEntry?> watchDatabaseById(String id) {
    return (select(databasesTable)..where((tbl) => tbl.id.equals(id))).watchSingleOrNull();
  }

  Stream<List<DatabaseEntry>> watchDatabasesForPage(String pageId) {
    return (select(databasesTable)
          ..where((tbl) => tbl.pageId.equals(pageId) & tbl.isArchived.equals(false))
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.createdAt)]))
        .watch();
  }

  Future<DatabaseEntry?> getDatabaseById(String id) {
    return (select(databasesTable)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  Future<int> insertDatabase(DatabasesTableCompanion entry) {
    return into(databasesTable).insert(entry);
  }

  Future<bool> updateDatabase(DatabasesTableCompanion entry) {
    return update(databasesTable).replace(entry);
  }

  Future<int> deleteDatabase(String id) {
    return (delete(databasesTable)..where((tbl) => tbl.id.equals(id))).go();
  }
}
