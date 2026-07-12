import 'package:eduself_study_app/core/error/result.dart';
import 'package:eduself_study_app/core/network/api_client.dart';
import 'package:eduself_study_app/features/assessments/domain/entities/assessment_enums.dart';
import 'package:eduself_study_app/features/assessments/domain/entities/assessment_models.dart';
import 'package:eduself_study_app/features/assessments/domain/repositories/assessments_repository.dart';

class AssessmentsRepositoryImpl implements AssessmentsRepository {
  AssessmentsRepositoryImpl({required this._api});

  final ApiClient _api;

  @override
  Future<Result<List<AssessmentSummary>>> listAssessments() async {
    final result = await _api.get('/assessments');
    return switch (result) {
      Success(:final value) => _parseSummaryList(value),
      FailureResult(:final failure) => FailureResult(failure),
    };
  }

  @override
  Future<Result<List<AssessmentSummary>>> listDiscoverableAssessments() async {
    final owned = await listAssessments();
    if (owned is FailureResult<List<AssessmentSummary>>) return owned;

    // Only classrooms the user belongs to (API: teacher-owned or student-joined).
    final classrooms = await _api.get('/classrooms');
    final assigned = <AssessmentSummary>[];
    if (classrooms is Success<Map<String, dynamic>>) {
      final data = classrooms.value['data'];
      if (data is List) {
        for (final item in data) {
          if (item is! Map<String, dynamic>) continue;
          final classroomId = item['id'] as int?;
          final classroomName = item['name'] as String?;
          if (classroomId == null) continue;
          final assignments =
              await _api.get('/classrooms/$classroomId/assignments');
          if (assignments is! Success<Map<String, dynamic>>) continue;
          final list = assignments.value['data'];
          if (list is! List) continue;
          for (final a in list) {
            if (a is! Map<String, dynamic>) continue;
            final assignment = ClassroomAssignment.fromJson(a);
            assigned.add(
              assignment.toSummary(classroomName: classroomName),
            );
          }
        }
      }
    }

    // Prefer assigned entry (with classroom context) over bare owned duplicate.
    final byId = <int, AssessmentSummary>{
      for (final s in owned.valueOrNull ?? const <AssessmentSummary>[]) s.id: s,
    };
    for (final a in assigned) {
      byId[a.id] = a;
    }
    final merged = byId.values.toList()
      ..sort((a, b) => b.createdAtUtc.compareTo(a.createdAtUtc));
    return Success(merged);
  }

  @override
  Future<Result<AssessmentDetail>> getAssessment(int id) async {
    final result = await _api.get('/assessments/$id');
    return switch (result) {
      Success(:final value) => _parseDetail(value),
      FailureResult(:final failure) => FailureResult(failure),
    };
  }

  @override
  Future<Result<AssessmentAttempt>> startAttempt(int assessmentId) async {
    final result = await _api.post('/assessments/$assessmentId/attempts');
    return switch (result) {
      Success(:final value) => _parseAttempt(value),
      FailureResult(:final failure) => FailureResult(failure),
    };
  }

  @override
  Future<Result<AttemptAnswer>> saveAnswer({
    required int attemptId,
    required int itemId,
    required Map<String, dynamic> response,
  }) async {
    final result = await _api.post(
      '/assessments/attempts/$attemptId/answers',
      body: {'itemId': itemId, 'response': response},
    );
    return switch (result) {
      Success(:final value) => _parseAnswer(value),
      FailureResult(:final failure) => FailureResult(failure),
    };
  }

  @override
  Future<Result<AssessmentAttempt>> submitAttempt(int attemptId) async {
    final result = await _api.post('/assessments/attempts/$attemptId/submit');
    return switch (result) {
      Success(:final value) => _parseAttempt(value),
      FailureResult(:final failure) => FailureResult(failure),
    };
  }

  @override
  Future<Result<AssessmentAttempt>> getAttempt(int attemptId) async {
    final result = await _api.get('/assessments/attempts/$attemptId');
    return switch (result) {
      Success(:final value) => _parseAttempt(value),
      FailureResult(:final failure) => FailureResult(failure),
    };
  }

  @override
  Future<Result<AssessmentAttempt?>> getMyAttempt(int assessmentId) async {
    final result = await _api.get('/assessments/$assessmentId/my-attempt');
    return switch (result) {
      Success(:final value) => _parseOptionalAttempt(value),
      FailureResult(:final failure) => FailureResult(failure),
    };
  }

  @override
  Future<Result<AssessmentSummary>> createAssessment({
    required String title,
    String? subject,
    int? gradeLevel,
  }) async {
    final body = <String, dynamic>{'title': title.trim()};
    if (subject != null && subject.trim().isNotEmpty) {
      body['subject'] = subject.trim();
    }
    if (gradeLevel != null) body['gradeLevel'] = gradeLevel;
    final result = await _api.post('/assessments', body: body);
    return switch (result) {
      Success(:final value) => _parseSummary(value),
      FailureResult(:final failure) => FailureResult(failure),
    };
  }

  @override
  Future<Result<AssessmentSummary>> updateAssessment({
    required int id,
    String? title,
    String? subject,
    int? gradeLevel,
  }) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title.trim();
    if (subject != null) body['subject'] = subject.trim();
    if (gradeLevel != null) body['gradeLevel'] = gradeLevel;
    final result = await _api.patch('/assessments/$id', body: body);
    return switch (result) {
      Success(:final value) => _parseSummary(value),
      FailureResult(:final failure) => FailureResult(failure),
    };
  }

  @override
  Future<Result<AssessmentSummary>> publishAssessment(int id) async {
    final result = await _api.post('/assessments/$id/publish', body: {});
    return switch (result) {
      Success(:final value) => _parseSummary(value),
      FailureResult(:final failure) => FailureResult(failure),
    };
  }

  @override
  Future<Result<AssessmentItem>> addItem({
    required int assessmentId,
    required AssessmentItemType itemType,
    required String prompt,
    Map<String, dynamic>? options,
    required Map<String, dynamic> answerKey,
    double? points,
    int? sortOrder,
  }) async {
    final body = <String, dynamic>{
      'itemType': itemType.apiValue,
      'prompt': prompt,
      'answerKey': answerKey,
    };
    if (options != null) body['options'] = options;
    if (points != null) body['points'] = points;
    if (sortOrder != null) body['sortOrder'] = sortOrder;
    final result = await _api.post(
      '/assessments/$assessmentId/items',
      body: body,
    );
    return switch (result) {
      Success(:final value) => _parseItem(value),
      FailureResult(:final failure) => FailureResult(failure),
    };
  }

  @override
  Future<Result<AssessmentItem>> updateItem({
    required int assessmentId,
    required int itemId,
    String? prompt,
    Map<String, dynamic>? options,
    Map<String, dynamic>? answerKey,
    double? points,
    int? sortOrder,
  }) async {
    final body = <String, dynamic>{};
    if (prompt != null) body['prompt'] = prompt;
    if (options != null) body['options'] = options;
    if (answerKey != null) body['answerKey'] = answerKey;
    if (points != null) body['points'] = points;
    if (sortOrder != null) body['sortOrder'] = sortOrder;
    final result = await _api.patch(
      '/assessments/$assessmentId/items/$itemId',
      body: body,
    );
    return switch (result) {
      Success(:final value) => _parseItem(value),
      FailureResult(:final failure) => FailureResult(failure),
    };
  }

  @override
  Future<Result<void>> deleteItem({
    required int assessmentId,
    required int itemId,
  }) async {
    final result =
        await _api.delete('/assessments/$assessmentId/items/$itemId');
    return switch (result) {
      Success() => const Success(null),
      FailureResult(:final failure) => FailureResult(failure),
    };
  }

  @override
  Future<Result<AssessmentAttempt>> gradeAnswer({
    required int attemptId,
    required int answerId,
    required double pointsAwarded,
    String? feedback,
    bool? isCorrect,
  }) async {
    final body = <String, dynamic>{'pointsAwarded': pointsAwarded};
    if (feedback != null) body['feedback'] = feedback;
    if (isCorrect != null) body['isCorrect'] = isCorrect;
    final result = await _api.patch(
      '/assessments/attempts/$attemptId/answers/$answerId',
      body: body,
    );
    return switch (result) {
      Success(:final value) => _parseAttempt(value),
      FailureResult(:final failure) => FailureResult(failure),
    };
  }

  Result<AssessmentSummary> _parseSummary(Map<String, dynamic> envelope) {
    final data = envelope['data'];
    if (data is! Map<String, dynamic>) {
      return const FailureResult(ApiFailure('Invalid assessment response.'));
    }
    return Success(AssessmentSummary.fromJson(data));
  }

  Result<AssessmentItem> _parseItem(Map<String, dynamic> envelope) {
    final data = envelope['data'];
    if (data is! Map<String, dynamic>) {
      return const FailureResult(ApiFailure('Invalid item response.'));
    }
    return Success(AssessmentItem.fromJson(data));
  }

  Result<List<AssessmentSummary>> _parseSummaryList(
    Map<String, dynamic> envelope,
  ) {
    final data = envelope['data'];
    if (data is! List) {
      return const FailureResult(ApiFailure('Invalid assessments response.'));
    }
    return Success([
      for (final item in data)
        if (item is Map<String, dynamic>) AssessmentSummary.fromJson(item),
    ]);
  }

  Result<AssessmentDetail> _parseDetail(Map<String, dynamic> envelope) {
    final data = envelope['data'];
    if (data is! Map<String, dynamic>) {
      return const FailureResult(ApiFailure('Invalid assessment detail.'));
    }
    return Success(AssessmentDetail.fromJson(data));
  }

  Result<AssessmentAttempt> _parseAttempt(Map<String, dynamic> envelope) {
    final data = envelope['data'];
    if (data is! Map<String, dynamic>) {
      return const FailureResult(ApiFailure('Invalid attempt response.'));
    }
    return Success(AssessmentAttempt.fromJson(data));
  }

  Result<AssessmentAttempt?> _parseOptionalAttempt(
    Map<String, dynamic> envelope,
  ) {
    final data = envelope['data'];
    if (data == null) return const Success(null);
    if (data is! Map<String, dynamic>) {
      return const FailureResult(ApiFailure('Invalid attempt response.'));
    }
    return Success(AssessmentAttempt.fromJson(data));
  }

  Result<AttemptAnswer> _parseAnswer(Map<String, dynamic> envelope) {
    final data = envelope['data'];
    if (data is! Map<String, dynamic>) {
      return const FailureResult(ApiFailure('Invalid answer response.'));
    }
    return Success(AttemptAnswer.fromJson(data));
  }
}
