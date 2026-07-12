import 'package:eduself_study_app/core/error/result.dart';
import 'package:eduself_study_app/core/network/api_client.dart';
import 'package:eduself_study_app/features/student/domain/entities/student_profile.dart';
import 'package:eduself_study_app/features/student/domain/repositories/student_repository.dart';

class StudentRepositoryImpl implements StudentRepository {
  StudentRepositoryImpl({required ApiClient api}) : _api = api;

  final ApiClient _api;

  @override
  Future<Result<StudentProfile>> getProfile() async {
    final result = await _api.get('/profile');
    return switch (result) {
      Success(:final value) => _parse(value),
      FailureResult(:final failure) => FailureResult(failure),
    };
  }

  @override
  Future<Result<StudentProfile>> updateProfile(
    UpdateStudentProfileInput input,
  ) async {
    final result = await _api.patch('/profile', body: input.toJson());
    return switch (result) {
      Success(:final value) => _parse(value),
      FailureResult(:final failure) => FailureResult(failure),
    };
  }

  Result<StudentProfile> _parse(Map<String, dynamic> envelope) {
    final data = envelope['data'];
    if (data is! Map<String, dynamic>) {
      return const FailureResult(ApiFailure('Invalid profile response.'));
    }
    return Success(StudentProfile.fromJson(data));
  }
}
