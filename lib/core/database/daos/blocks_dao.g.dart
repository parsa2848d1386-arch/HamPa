// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'blocks_dao.dart';

// ignore_for_file: type=lint
mixin _$BlocksDaoMixin on DatabaseAccessor<AppDatabase> {
  $BlocksTable get blocks => attachedDatabase.blocks;
  BlocksDaoManager get managers => BlocksDaoManager(this);
}

class BlocksDaoManager {
  final _$BlocksDaoMixin _db;
  BlocksDaoManager(this._db);
  $$BlocksTableTableManager get blocks =>
      $$BlocksTableTableManager(_db.attachedDatabase, _db.blocks);
}
