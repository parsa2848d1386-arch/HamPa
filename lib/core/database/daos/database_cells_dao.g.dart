// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database_cells_dao.dart';

// ignore_for_file: type=lint
mixin _$DatabaseCellsDaoMixin on DatabaseAccessor<AppDatabase> {
  $DatabaseCellsTableTable get databaseCellsTable =>
      attachedDatabase.databaseCellsTable;
  $DatabaseRowsTableTable get databaseRowsTable =>
      attachedDatabase.databaseRowsTable;
  DatabaseCellsDaoManager get managers => DatabaseCellsDaoManager(this);
}

class DatabaseCellsDaoManager {
  final _$DatabaseCellsDaoMixin _db;
  DatabaseCellsDaoManager(this._db);
  $$DatabaseCellsTableTableTableManager get databaseCellsTable =>
      $$DatabaseCellsTableTableTableManager(
          _db.attachedDatabase, _db.databaseCellsTable);
  $$DatabaseRowsTableTableTableManager get databaseRowsTable =>
      $$DatabaseRowsTableTableTableManager(
          _db.attachedDatabase, _db.databaseRowsTable);
}
