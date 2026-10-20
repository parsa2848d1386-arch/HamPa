import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/subjects_table.dart';

part 'subjects_dao.g.dart';

@DriftAccessor(tables: [Subjects])
class SubjectsDao extends DatabaseAccessor<AppDatabase> with _$SubjectsDaoMixin {
  SubjectsDao(super.db);

  Stream<List<SubjectEntry>> watchActiveSubjects() {
    return (select(subjects)
          ..where((tbl) => tbl.isArchived.equals(false))
          ..orderBy([
            (tbl) => OrderingTerm(expression: tbl.sortOrder, mode: OrderingMode.asc),
            (tbl) => OrderingTerm(expression: tbl.name, mode: OrderingMode.asc),
          ]))
        .watch();
  }

  Future<List<SubjectEntry>> getActiveSubjects() {
    return (select(subjects)
          ..where((tbl) => tbl.isArchived.equals(false))
          ..orderBy([
            (tbl) => OrderingTerm(expression: tbl.sortOrder, mode: OrderingMode.asc),
            (tbl) => OrderingTerm(expression: tbl.name, mode: OrderingMode.asc),
          ]))
        .get();
  }

  Future<SubjectEntry?> getSubjectById(String id) {
    return (select(subjects)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  Future<int> insertSubject(SubjectsCompanion entry) {
    return into(subjects).insert(entry);
  }

  Future<bool> updateSubjectEntry(SubjectsCompanion entry) {
    return update(subjects).replace(entry);
  }

  Future<int> archiveSubject(String id) {
    return (update(subjects)..where((tbl) => tbl.id.equals(id))).write(
      SubjectsCompanion(
        isArchived: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Seeds standard subjects on first run
  Future<void> seedDefaultSubjects() async {
    final existing = await (select(subjects)..where((tbl) => tbl.isArchived.equals(false))).get();
    if (existing.isEmpty) {
      final now = DateTime.now();
      await batch((b) {
        b.insertAll(subjects, [
          SubjectsCompanion.insert(
            id: 'sub_math',
            name: 'Mathematics',
            colorHex: '#3B82F6',
            icon: const Value('calculator'),
            dailyGoalMinutes: const Value(90),
            sortOrder: const Value(0.0),
            createdAt: now,
            updatedAt: now,
          ),
          SubjectsCompanion.insert(
            id: 'sub_science',
            name: 'Science & Physics',
            colorHex: '#10B981',
            icon: const Value('atom'),
            dailyGoalMinutes: const Value(90),
            sortOrder: const Value(1.0),
            createdAt: now,
            updatedAt: now,
          ),
          SubjectsCompanion.insert(
            id: 'sub_languages',
            name: 'Languages & Literature',
            colorHex: '#F59E0B',
            icon: const Value('book'),
            dailyGoalMinutes: const Value(60),
            sortOrder: const Value(2.0),
            createdAt: now,
            updatedAt: now,
          ),
          SubjectsCompanion.insert(
            id: 'sub_general',
            name: 'General Study',
            colorHex: '#8B5CF6',
            icon: const Value('sparkles'),
            dailyGoalMinutes: const Value(60),
            sortOrder: const Value(3.0),
            createdAt: now,
            updatedAt: now,
          ),
        ]);
      });
    }
  }
}
