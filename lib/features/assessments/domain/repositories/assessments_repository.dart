import 'package:eduself_study_app/core/error/result.dart';
import 'package:eduself_study_app/features/assessments/domain/entities/assessment_enums.dart';
import 'package:eduself_study_app/features/assessments/domain/entities/assessment_models.dart';

abstract class AssessmentsRepository {
  Future<Result<List<AssessmentSummary>>> listAssessments();

  /// Owned + classroom-assigned assessments for the assessments hub.
  Future<Result<List<AssessmentSummary>>> listDiscoverableAssessments();

  Future<Result<AssessmentDetail>> getAssessment(int id);

  Future<Result<AssessmentAttempt>> startAttempt(int assessmentId);

  Future<Result<AttemptAnswer>> saveAnswer({
    required int attemptId,
    required int itemId,
    required Map<String, dynamic> response,
  });

  Future<Result<AssessmentAttempt>> submitAttempt(int attemptId);

  Future<Result<AssessmentAttempt>> getAttempt(int attemptId);

  /// Current user's attempt for [assessmentId], or null if not started.
  Future<Result<AssessmentAttempt?>> getMyAttempt(int assessmentId);

  Future<Result<AssessmentSummary>> createAssessment({
    required String title,
    String? subject,
    int? gradeLevel,
  });

  Future<Result<AssessmentSummary>> updateAssessment({
    required int id,
    String? title,
    String? subject,
    int? gradeLevel,
  });

  Future<Result<AssessmentSummary>> publishAssessment(int id);

  Future<Result<AssessmentItem>> addItem({
    required int assessmentId,
    required AssessmentItemType itemType,
    required String prompt,
    Map<String, dynamic>? options,
    required Map<String, dynamic> answerKey,
    double? points,
    int? sortOrder,
  });

  Future<Result<AssessmentItem>> updateItem({
    required int assessmentId,
    required int itemId,
    String? prompt,
    Map<String, dynamic>? options,
    Map<String, dynamic>? answerKey,
    double? points,
    int? sortOrder,
  });

  Future<Result<void>> deleteItem({
    required int assessmentId,
    required int itemId,
  });

  Future<Result<AssessmentAttempt>> gradeAnswer({
    required int attemptId,
    required int answerId,
    required double pointsAwarded,
    String? feedback,
    bool? isCorrect,
  });
}
