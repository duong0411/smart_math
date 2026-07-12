import 'package:eduself_study_app/core/error/result.dart';
import 'package:eduself_study_app/core/network/api_client.dart';
import 'package:eduself_study_app/features/assessments/domain/entities/assessment_enums.dart';
import 'package:eduself_study_app/features/exam_matrices/domain/entities/exam_matrix.dart';
import 'package:eduself_study_app/features/exam_matrices/domain/repositories/exam_matrices_repository.dart';

class ExamMatricesRepositoryImpl implements ExamMatricesRepository {
  ExamMatricesRepositoryImpl({required this._api});

  final ApiClient _api;

  @override
  Future<Result<List<ExamMatrix>>> list() async {
    final result = await _api.get('/exam-matrices');
    return switch (result) {
      Success(:final value) => _parseList(value, ExamMatrix.fromJson),
      FailureResult(:final failure) => FailureResult(failure),
    };
  }

  @override
  Future<Result<ExamMatrix>> create({
    required String title,
    String? subject,
    int? gradeLevel,
    String? description,
  }) async {
    final body = <String, dynamic>{'title': title.trim()};
    if (subject != null && subject.trim().isNotEmpty) {
      body['subject'] = subject.trim();
    }
    if (gradeLevel != null) body['gradeLevel'] = gradeLevel;
    if (description != null && description.trim().isNotEmpty) {
      body['description'] = description.trim();
    }
    final result = await _api.post('/exam-matrices', body: body);
    return switch (result) {
      Success(:final value) => _parseOne(value, ExamMatrix.fromJson),
      FailureResult(:final failure) => FailureResult(failure),
    };
  }

  @override
  Future<Result<ExamMatrixDetail>> get(int id) async {
    final result = await _api.get('/exam-matrices/$id');
    return switch (result) {
      Success(:final value) => _parseOne(value, ExamMatrixDetail.fromJson),
      FailureResult(:final failure) => FailureResult(failure),
    };
  }

  @override
  Future<Result<ExamMatrix>> update({
    required int id,
    String? title,
    String? subject,
    int? gradeLevel,
    String? description,
  }) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title.trim();
    if (subject != null) body['subject'] = subject;
    if (gradeLevel != null) body['gradeLevel'] = gradeLevel;
    if (description != null) body['description'] = description;
    final result = await _api.patch('/exam-matrices/$id', body: body);
    return switch (result) {
      Success(:final value) => _parseOne(value, ExamMatrix.fromJson),
      FailureResult(:final failure) => FailureResult(failure),
    };
  }

  @override
  Future<Result<void>> delete(int id) async {
    final result = await _api.delete('/exam-matrices/$id');
    return switch (result) {
      Success() => const Success(null),
      FailureResult(:final failure) => FailureResult(failure),
    };
  }

  @override
  Future<Result<ExamMatrixOutcome>> addOutcome({
    required int matrixId,
    required String code,
    required String title,
    String? description,
    int? sortOrder,
  }) async {
    final body = <String, dynamic>{
      'code': code.trim(),
      'title': title.trim(),
    };
    if (description != null) body['description'] = description;
    if (sortOrder != null) body['sortOrder'] = sortOrder;
    final result =
        await _api.post('/exam-matrices/$matrixId/outcomes', body: body);
    return switch (result) {
      Success(:final value) => _parseOne(value, ExamMatrixOutcome.fromJson),
      FailureResult(:final failure) => FailureResult(failure),
    };
  }

  @override
  Future<Result<ExamMatrixOutcome>> updateOutcome({
    required int matrixId,
    required int outcomeId,
    String? code,
    String? title,
    String? description,
    int? sortOrder,
  }) async {
    final body = <String, dynamic>{};
    if (code != null) body['code'] = code.trim();
    if (title != null) body['title'] = title.trim();
    if (description != null) body['description'] = description;
    if (sortOrder != null) body['sortOrder'] = sortOrder;
    final result = await _api.patch(
      '/exam-matrices/$matrixId/outcomes/$outcomeId',
      body: body,
    );
    return switch (result) {
      Success(:final value) => _parseOne(value, ExamMatrixOutcome.fromJson),
      FailureResult(:final failure) => FailureResult(failure),
    };
  }

  @override
  Future<Result<void>> deleteOutcome({
    required int matrixId,
    required int outcomeId,
  }) async {
    final result =
        await _api.delete('/exam-matrices/$matrixId/outcomes/$outcomeId');
    return switch (result) {
      Success() => const Success(null),
      FailureResult(:final failure) => FailureResult(failure),
    };
  }

  @override
  Future<Result<ExamMatrixCell>> addCell({
    required int matrixId,
    required int outcomeId,
    required AssessmentItemType itemType,
    int? targetCount,
    double? targetPoints,
    int? sortOrder,
  }) async {
    final body = <String, dynamic>{
      'outcomeId': outcomeId,
      'itemType': itemType.apiValue,
    };
    if (targetCount != null) body['targetCount'] = targetCount;
    if (targetPoints != null) body['targetPoints'] = targetPoints;
    if (sortOrder != null) body['sortOrder'] = sortOrder;
    final result =
        await _api.post('/exam-matrices/$matrixId/cells', body: body);
    return switch (result) {
      Success(:final value) => _parseOne(value, ExamMatrixCell.fromJson),
      FailureResult(:final failure) => FailureResult(failure),
    };
  }

  @override
  Future<Result<ExamMatrixCell>> updateCell({
    required int matrixId,
    required int cellId,
    int? targetCount,
    double? targetPoints,
    int? sortOrder,
  }) async {
    final body = <String, dynamic>{};
    if (targetCount != null) body['targetCount'] = targetCount;
    if (targetPoints != null) body['targetPoints'] = targetPoints;
    if (sortOrder != null) body['sortOrder'] = sortOrder;
    final result = await _api.patch(
      '/exam-matrices/$matrixId/cells/$cellId',
      body: body,
    );
    return switch (result) {
      Success(:final value) => _parseOne(value, ExamMatrixCell.fromJson),
      FailureResult(:final failure) => FailureResult(failure),
    };
  }

  @override
  Future<Result<void>> deleteCell({
    required int matrixId,
    required int cellId,
  }) async {
    final result =
        await _api.delete('/exam-matrices/$matrixId/cells/$cellId');
    return switch (result) {
      Success() => const Success(null),
      FailureResult(:final failure) => FailureResult(failure),
    };
  }

  @override
  Future<Result<void>> linkAssessment({
    required int matrixId,
    required int assessmentId,
  }) async {
    final result = await _api.post(
      '/exam-matrices/$matrixId/assessments',
      body: {'assessmentId': assessmentId},
    );
    return switch (result) {
      Success() => const Success(null),
      FailureResult(:final failure) => FailureResult(failure),
    };
  }

  @override
  Future<Result<void>> unlinkAssessment({
    required int matrixId,
    required int assessmentId,
  }) async {
    final result = await _api.delete(
      '/exam-matrices/$matrixId/assessments/$assessmentId',
    );
    return switch (result) {
      Success() => const Success(null),
      FailureResult(:final failure) => FailureResult(failure),
    };
  }

  @override
  Future<Result<MatrixCoverage>> coverage({
    required int matrixId,
    required int assessmentId,
  }) async {
    final result = await _api.get(
      '/exam-matrices/$matrixId/coverage?assessmentId=$assessmentId',
    );
    return switch (result) {
      Success(:final value) => _parseOne(value, MatrixCoverage.fromJson),
      FailureResult(:final failure) => FailureResult(failure),
    };
  }

  @override
  Future<Result<void>> tagItemOutcome({
    required int assessmentId,
    required int itemId,
    required int outcomeId,
  }) async {
    final result = await _api.post(
      '/exam-matrices/item-outcomes',
      body: {
        'assessmentId': assessmentId,
        'itemId': itemId,
        'outcomeId': outcomeId,
      },
    );
    return switch (result) {
      Success() => const Success(null),
      FailureResult(:final failure) => FailureResult(failure),
    };
  }

  @override
  Future<Result<void>> untagItemOutcome({
    required int assessmentId,
    required int itemId,
    required int outcomeId,
  }) async {
    final result = await _api.delete(
      '/exam-matrices/item-outcomes'
      '?assessmentId=$assessmentId&itemId=$itemId&outcomeId=$outcomeId',
    );
    return switch (result) {
      Success() => const Success(null),
      FailureResult(:final failure) => FailureResult(failure),
    };
  }

  Result<T> _parseOne<T>(
    Map<String, dynamic> envelope,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final data = envelope['data'];
    if (data is! Map<String, dynamic>) {
      return const FailureResult(ApiFailure('Invalid exam matrix response.'));
    }
    return Success(fromJson(data));
  }

  Result<List<T>> _parseList<T>(
    Map<String, dynamic> envelope,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final data = envelope['data'];
    if (data is! List) {
      return const FailureResult(ApiFailure('Invalid exam matrices list.'));
    }
    return Success([
      for (final item in data)
        if (item is Map<String, dynamic>) fromJson(item),
    ]);
  }
}
