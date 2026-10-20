import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/study_sessions_table.dart';

part 'study_sessions_dao.g.dart';

@DriftAccessor(tables: [StudySessionsTable])
class StudySessionsDao extends DatabaseAccessor<AppDatabase> with _$StudySessionsDaoMixin {
  StudySessionsDao(super.db);

  Future<void> insertSession(StudySessionsTableCompanion session) {
    return into(studySessionsTable).insert(session, mode: InsertMode.insertOrReplace);
  }

  Future<void> updateSession(StudySessionsTableCompanion session) {
    return update(studySessionsTable).replace(session);
  }

  Future<StudySessionEntry?> getSessionById(String id) {
    return (select(studySessionsTable)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<List<StudySessionEntry>> getSessionsForSubject(String subjectId) {
    return (select(studySessionsTable)
          ..where((t) => t.subjectId.equals(subjectId))
          ..orderBy([(t) => OrderingTerm.desc(t.startTime)]))
        .get();
  }

  Future<List<StudySessionEntry>> getSessionsInDateRange(DateTime start, DateTime end) {
    return (select(studySessionsTable)
          ..where((t) => t.startTime.isBiggerOrEqualValue(start) & t.startTime.isSmallerOrEqualValue(end))
          ..orderBy([(t) => OrderingTerm.asc(t.startTime)]))
        .get();
  }

  Stream<List<StudySessionEntry>> watchSessionsInDateRange(DateTime start, DateTime end) {
    return (select(studySessionsTable)
          ..where((t) => t.startTime.isBiggerOrEqualValue(start) & t.startTime.isSmallerOrEqualValue(end))
          ..orderBy([(t) => OrderingTerm.asc(t.startTime)]))
        .watch();
  }

  Future<int> getTotalDurationForSubject(String subjectId) async {
    final query = selectOnly(studySessionsTable)
      ..where(studySessionsTable.subjectId.equals(subjectId) & studySessionsTable.isDiscarded.equals(false))
      ..addColumns([studySessionsTable.durationSeconds.sum()]);
    final result = await query.getSingle();
    return result.read(studySessionsTable.durationSeconds.sum()) ?? 0;
  }
}
