// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pages_dao.dart';

// ignore_for_file: type=lint
mixin _$PagesDaoMixin on DatabaseAccessor<AppDatabase> {
  $PagesTable get pages => attachedDatabase.pages;
  PagesDaoManager get managers => PagesDaoManager(this);
}

class PagesDaoManager {
  final _$PagesDaoMixin _db;
  PagesDaoManager(this._db);
  $$PagesTableTableManager get pages =>
      $$PagesTableTableManager(_db.attachedDatabase, _db.pages);
}
