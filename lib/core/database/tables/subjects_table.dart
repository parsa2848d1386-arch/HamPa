import 'package:drift/drift.dart';

/// Table representing study subjects with color branding and daily goals.
@TableIndex(name: 'idx_subjects_sort', columns: {#sortOrder})
@DataClassName('SubjectEntry')
class Subjects extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get colorHex => text()(); // e.g. '#3B82F6'
  TextColumn get icon => text().nullable()();
  IntColumn get dailyGoalMinutes => integer().withDefault(const Constant(60))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  RealColumn get sortOrder => real().withDefault(const Constant(0.0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
