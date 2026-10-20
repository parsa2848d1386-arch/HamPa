import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/database_properties_table.dart';

part 'database_properties_dao.g.dart';

@DriftAccessor(tables: [DatabasePropertiesTable])
class DatabasePropertiesDao extends DatabaseAccessor<AppDatabase> with _$DatabasePropertiesDaoMixin {
  DatabasePropertiesDao(super.db);

  Stream<List<DatabasePropertyEntry>> watchPropertiesForDatabase(String databaseId) {
    return (select(databasePropertiesTable)
          ..where((tbl) => tbl.databaseId.equals(databaseId))
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.sortOrder, mode: OrderingMode.asc)]))
        .watch();
  }

  Future<List<DatabasePropertyEntry>> getPropertiesForDatabase(String databaseId) {
    return (select(databasePropertiesTable)
          ..where((tbl) => tbl.databaseId.equals(databaseId))
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.sortOrder, mode: OrderingMode.asc)]))
        .get();
  }

  Future<DatabasePropertyEntry?> getPropertyById(String id) {
    return (select(databasePropertiesTable)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  Future<int> insertProperty(DatabasePropertiesTableCompanion entry) {
    return into(databasePropertiesTable).insert(entry);
  }

  Future<bool> updateProperty(DatabasePropertiesTableCompanion entry) {
    return update(databasePropertiesTable).replace(entry);
  }

  Future<int> deleteProperty(String id) {
    return (delete(databasePropertiesTable)..where((tbl) => tbl.id.equals(id))).go();
  }

  Future<void> batchUpdateSortOrders(Map<String, double> propertySortOrders) async {
    await batch((b) {
      for (final entry in propertySortOrders.entries) {
        b.update(
          databasePropertiesTable,
          DatabasePropertiesTableCompanion(
            sortOrder: Value(entry.value),
            updatedAt: Value(DateTime.now()),
          ),
          where: (tbl) => tbl.id.equals(entry.key),
        );
      }
    });
  }
}
