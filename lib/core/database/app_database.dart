import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'tables/pages_table.dart';
import 'tables/blocks_table.dart';
import 'tables/subjects_table.dart';
import 'tables/databases_table.dart';
import 'tables/database_properties_table.dart';
import 'tables/database_rows_table.dart';
import 'tables/database_cells_table.dart';
import 'tables/database_views_table.dart';
import 'tables/study_sessions_table.dart';
import 'daos/pages_dao.dart';
import 'daos/blocks_dao.dart';
import 'daos/subjects_dao.dart';
import 'daos/databases_dao.dart';
import 'daos/database_properties_dao.dart';
import 'daos/database_rows_dao.dart';
import 'daos/database_cells_dao.dart';
import 'daos/database_views_dao.dart';
import 'daos/study_sessions_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Pages,
    Blocks,
    Subjects,
    DatabasesTable,
    DatabasePropertiesTable,
    DatabaseRowsTable,
    DatabaseCellsTable,
    DatabaseViewsTable,
    StudySessionsTable,
  ],
  daos: [
    PagesDao,
    BlocksDao,
    SubjectsDao,
    DatabasesDao,
    DatabasePropertiesDao,
    DatabaseRowsDao,
    DatabaseCellsDao,
    DatabaseViewsDao,
    StudySessionsDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 3;

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'hampa_db',
      native: const DriftNativeOptions(
        shareAcrossIsolates: true,
      ),
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('sqlite3.wasm'),
        onResult: (result) {
          if (result.missingFeatures.isNotEmpty) {
            debugPrint('Using fallback storage for web database: ${result.missingFeatures}');
          }
        },
      ),
    );
  }

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.createTable(databasesTable);
          await m.createTable(databasePropertiesTable);
          await m.createTable(databaseRowsTable);
          await m.createTable(databaseCellsTable);
          await m.createTable(databaseViewsTable);
        }
      },
      beforeOpen: (details) async {
        if (!kIsWeb) {
          // Enforce foreign keys and configure WAL mode for zero-latency concurrent operations
          await customStatement('PRAGMA foreign_keys = ON;');
          await customStatement('PRAGMA journal_mode = WAL;');
          await customStatement('PRAGMA synchronous = NORMAL;');
        }
      },
    );
  }
}
