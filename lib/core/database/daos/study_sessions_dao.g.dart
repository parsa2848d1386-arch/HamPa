// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'study_sessions_dao.dart';

// ignore_for_file: type=lint
mixin _$StudySessionsDaoMixin on DatabaseAccessor<AppDatabase> {
  $StudySessionsTableTable get studySessionsTable =>
      attachedDatabase.studySessionsTable;
  StudySessionsDaoManager get managers => StudySessionsDaoManager(this);
}

class StudySessionsDaoManager {
  final _$StudySessionsDaoMixin _db;
  StudySessionsDaoManager(this._db);
  $$StudySessionsTableTableTableManager get studySessionsTable =>
      $$StudySessionsTableTableTableManager(
          _db.attachedDatabase, _db.studySessionsTable);
}
