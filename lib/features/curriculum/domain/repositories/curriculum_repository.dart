import 'package:eduself_study_app/core/error/result.dart';
import 'package:eduself_study_app/features/curriculum/domain/entities/curriculum_subject.dart';

abstract class CurriculumRepository {
  Future<Result<List<CurriculumSubject>>> listSubjects({int? gradeLevel});
}
