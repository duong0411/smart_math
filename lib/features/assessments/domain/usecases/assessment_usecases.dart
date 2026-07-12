import 'package:eduself_study_app/core/error/result.dart';
import 'package:eduself_study_app/features/assessments/domain/entities/assessment_models.dart';
import 'package:eduself_study_app/features/assessments/domain/repositories/assessments_repository.dart';

class ListDiscoverableAssessments {
  const ListDiscoverableAssessments(this._repo);
  final AssessmentsRepository _repo;
  Future<Result<List<AssessmentSummary>>> call() =>
      _repo.listDiscoverableAssessments();
}

class GetAssessment {
  const GetAssessment(this._repo);
  final AssessmentsRepository _repo;
  Future<Result<AssessmentDetail>> call(int id) => _repo.getAssessment(id);
}

class StartAssessmentAttempt {
  const StartAssessmentAttempt(this._repo);
  final AssessmentsRepository _repo;
  Future<Result<AssessmentAttempt>> call(int assessmentId) =>
      _repo.startAttempt(assessmentId);
}

class SaveAssessmentAnswer {
  const SaveAssessmentAnswer(this._repo);
  final AssessmentsRepository _repo;
  Future<Result<AttemptAnswer>> call({
    required int attemptId,
    required int itemId,
    required Map<String, dynamic> response,
  }) =>
      _repo.saveAnswer(
        attemptId: attemptId,
        itemId: itemId,
        response: response,
      );
}

class SubmitAssessmentAttempt {
  const SubmitAssessmentAttempt(this._repo);
  final AssessmentsRepository _repo;
  Future<Result<AssessmentAttempt>> call(int attemptId) =>
      _repo.submitAttempt(attemptId);
}

class GetAssessmentAttempt {
  const GetAssessmentAttempt(this._repo);
  final AssessmentsRepository _repo;
  Future<Result<AssessmentAttempt>> call(int attemptId) =>
      _repo.getAttempt(attemptId);
}

class GetMyAssessmentAttempt {
  const GetMyAssessmentAttempt(this._repo);
  final AssessmentsRepository _repo;
  Future<Result<AssessmentAttempt?>> call(int assessmentId) =>
      _repo.getMyAttempt(assessmentId);
}
