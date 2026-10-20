import '../../../../core/database/daos/subjects_dao.dart';
import '../../../../core/database/app_database.dart';
import '../../domain/models/subject_entity.dart';
import '../../domain/repositories/subjects_repository.dart';

class SubjectsRepositoryImpl implements ISubjectsRepository {
  final SubjectsDao _subjectsDao;

  SubjectsRepositoryImpl({required SubjectsDao subjectsDao}) : _subjectsDao = subjectsDao;

  @override
  Stream<List<SubjectEntity>> watchActiveSubjects() {
    return _subjectsDao.watchActiveSubjects().map((entries) => entries.map(_mapSubject).toList());
  }

  @override
  Future<List<SubjectEntity>> getActiveSubjects() async {
    final entries = await _subjectsDao.getActiveSubjects();
    return entries.map(_mapSubject).toList();
  }

  @override
  Future<SubjectEntity?> getSubjectById(String id) async {
    final entry = await _subjectsDao.getSubjectById(id);
    return entry != null ? _mapSubject(entry) : null;
  }

  @override
  Future<void> seedDefaultSubjects() {
    return _subjectsDao.seedDefaultSubjects();
  }

  SubjectEntity _mapSubject(SubjectEntry entry) {
    return SubjectEntity(
      id: entry.id,
      name: entry.name,
      colorHex: entry.colorHex,
      icon: entry.icon,
      dailyGoalMinutes: entry.dailyGoalMinutes,
      isArchived: entry.isArchived,
      sortOrder: entry.sortOrder,
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
    );
  }
}
