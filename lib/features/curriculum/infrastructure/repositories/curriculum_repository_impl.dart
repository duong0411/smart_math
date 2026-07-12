import 'package:eduself_study_app/core/error/result.dart';
import 'package:eduself_study_app/core/network/api_client.dart';
import 'package:eduself_study_app/features/curriculum/domain/entities/curriculum_subject.dart';
import 'package:eduself_study_app/features/curriculum/domain/repositories/curriculum_repository.dart';

class CurriculumRepositoryImpl implements CurriculumRepository {
  CurriculumRepositoryImpl({required ApiClient api}) : _api = api;

  final ApiClient _api;

  @override
  Future<Result<List<CurriculumSubject>>> listSubjects({
    int? gradeLevel,
  }) async {
    final query = gradeLevel == null ? '' : '?gradeLevel=$gradeLevel';
    final result = await _api.get('/curriculum/subjects$query');
    return switch (result) {
      Success(:final value) => _parseList(value),
      FailureResult(:final failure) => FailureResult(failure),
    };
  }

  Result<List<CurriculumSubject>> _parseList(Map<String, dynamic> envelope) {
    final data = envelope['data'];
    if (data is! List) {
      return const FailureResult(ApiFailure('Invalid subjects response.'));
    }
    return Success([
      for (final item in data)
        if (item is Map<String, dynamic>) CurriculumSubject.fromJson(item),
    ]);
  }
}
