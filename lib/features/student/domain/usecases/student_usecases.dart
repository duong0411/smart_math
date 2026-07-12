import 'package:eduself_study_app/core/error/result.dart';
import 'package:eduself_study_app/features/student/domain/entities/student_profile.dart';
import 'package:eduself_study_app/features/student/domain/repositories/student_repository.dart';

class GetStudentProfile {
  const GetStudentProfile(this._repo);
  final StudentRepository _repo;
  Future<Result<StudentProfile>> call() => _repo.getProfile();
}

class UpdateStudentProfile {
  const UpdateStudentProfile(this._repo);
  final StudentRepository _repo;
  Future<Result<StudentProfile>> call(UpdateStudentProfileInput input) =>
      _repo.updateProfile(input);
}
