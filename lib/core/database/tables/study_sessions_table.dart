import 'package:drift/drift.dart';
import 'subjects_table.dart';

/// Table storing individual focus/study sessions
@TableIndex(name: 'idx_study_sessions_subject', columns: {#subjectId})
@TableIndex(name: 'idx_study_sessions_start', columns: {#startTime})
@DataClassName('StudySessionEntry')
class StudySessionsTable extends Table {
  TextColumn get id => text()();
  TextColumn get subjectId => text().references(Subjects, #id, onDelete: KeyAction.cascade)();
  TextColumn get pageId => text().nullable()(); // Linked Notion Page/Task ID
  TextColumn get sessionType => text()(); // 'stopwatch', 'pomodoro', 'exam'
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime().nullable()();
  IntColumn get durationSeconds => integer().withDefault(const Constant(0))();
  IntColumn get targetSeconds => integer().nullable()(); // For Pomodoro / Exam countdown
  IntColumn get pauseDurationSeconds => integer().withDefault(const Constant(0))();
  IntColumn get lapCount => integer().withDefault(const Constant(0))();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  BoolColumn get isDiscarded => boolean().withDefault(const Constant(false))();
  TextColumn get notes => text().nullable()(); // Scratchpad note taken during session
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
