import '../models/subject_entity.dart';

abstract class ISubjectsRepository {
  Stream<List<SubjectEntity>> watchActiveSubjects();
  Future<List<SubjectEntity>> getActiveSubjects();
  Future<SubjectEntity?> getSubjectById(String id);
  Future<void> seedDefaultSubjects();
}
