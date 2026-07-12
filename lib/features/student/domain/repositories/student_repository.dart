import 'package:eduself_study_app/core/error/result.dart';
import 'package:eduself_study_app/features/student/domain/entities/student_profile.dart';

abstract class StudentRepository {
  Future<Result<StudentProfile>> getProfile();
  Future<Result<StudentProfile>> updateProfile(UpdateStudentProfileInput input);
}
