import 'package:eduself_study_app/core/error/result.dart';
import 'package:eduself_study_app/core/network/api_client.dart';
import 'package:eduself_study_app/features/assessments/domain/entities/assessment_models.dart';
import 'package:eduself_study_app/features/classrooms/domain/entities/assignment_progress_row.dart';
import 'package:eduself_study_app/features/classrooms/domain/entities/classroom_member.dart';
import 'package:eduself_study_app/features/classrooms/domain/entities/classroom_summary.dart';
import 'package:eduself_study_app/features/classrooms/domain/repositories/classrooms_repository.dart';

class ClassroomsRepositoryImpl implements ClassroomsRepository {
  ClassroomsRepositoryImpl({required this._api});

  final ApiClient _api;

  @override
  Future<Result<List<ClassroomSummary>>> listClassrooms() async {
    final result = await _api.get('/classrooms');
    return switch (result) {
      Success(:final value) => _parseList(value, ClassroomSummary.fromJson),
      FailureResult(:final failure) => FailureResult(failure),
    };
  }

  @override
  Future<Result<void>> joinClassroom(String joinCode) async {
    final result = await _api.post(
      '/classrooms/join',
      body: {'joinCode': joinCode.trim()},
    );
    return switch (result) {
      Success() => const Success(null),
      FailureResult(:final failure) => FailureResult(failure),
    };
  }

  @override
  Future<Result<ClassroomSummary>> createClassroom(String name) async {
    final result = await _api.post(
      '/classrooms',
      body: {'name': name.trim()},
    );
    return switch (result) {
      Success(:final value) => _parseOne(value, ClassroomSummary.fromJson),
      FailureResult(:final failure) => FailureResult(failure),
    };
  }

  @override
  Future<Result<ClassroomSummary>> getClassroom(int id) async {
    final result = await _api.get('/classrooms/$id');
    return switch (result) {
      Success(:final value) => _parseOne(value, ClassroomSummary.fromJson),
      FailureResult(:final failure) => FailureResult(failure),
    };
  }

  @override
  Future<Result<List<ClassroomMember>>> listMembers(int classroomId) async {
    final result = await _api.get('/classrooms/$classroomId/members');
    return switch (result) {
      Success(:final value) => _parseList(value, ClassroomMember.fromJson),
      FailureResult(:final failure) => FailureResult(failure),
    };
  }

  @override
  Future<Result<ClassroomMember>> updateMemberGrade({
    required int classroomId,
    required int userId,
    required int? gradeLevel,
  }) async {
    final result = await _api.patch(
      '/classrooms/$classroomId/members/$userId',
      body: {'gradeLevel': gradeLevel},
    );
    return switch (result) {
      Success(:final value) => _parseOne(value, ClassroomMember.fromJson),
      FailureResult(:final failure) => FailureResult(failure),
    };
  }

  @override
  Future<Result<void>> removeMember({
    required int classroomId,
    required int userId,
  }) async {
    final result =
        await _api.delete('/classrooms/$classroomId/members/$userId');
    return switch (result) {
      Success() => const Success(null),
      FailureResult(:final failure) => FailureResult(failure),
    };
  }

  @override
  Future<Result<List<ClassroomAssignment>>> listAssignments(
    int classroomId,
  ) async {
    final result = await _api.get('/classrooms/$classroomId/assignments');
    return switch (result) {
      Success(:final value) => _parseList(value, ClassroomAssignment.fromJson),
      FailureResult(:final failure) => FailureResult(failure),
    };
  }

  @override
  Future<Result<ClassroomAssignment>> assignAssessment({
    required int classroomId,
    required int assessmentId,
    DateTime? dueAtUtc,
    int? durationMinutes,
  }) async {
    final body = <String, dynamic>{
      'assessmentId': assessmentId,
      'durationMinutes': durationMinutes,
    };
    if (dueAtUtc != null) {
      body['dueAtUtc'] = dueAtUtc.toUtc().toIso8601String();
    }
    final result = await _api.post(
      '/classrooms/$classroomId/assignments',
      body: body,
    );
    return switch (result) {
      Success(:final value) => _parseOne(value, ClassroomAssignment.fromJson),
      FailureResult(:final failure) => FailureResult(failure),
    };
  }

  @override
  Future<Result<void>> deleteAssignment({
    required int classroomId,
    required int assignmentId,
  }) async {
    final result = await _api.delete(
      '/classrooms/$classroomId/assignments/$assignmentId',
    );
    return switch (result) {
      Success() => const Success(null),
      FailureResult(:final failure) => FailureResult(failure),
    };
  }

  @override
  Future<Result<List<AssignmentProgressRow>>> assignmentProgress({
    required int classroomId,
    required int assignmentId,
  }) async {
    final result = await _api.get(
      '/classrooms/$classroomId/assignments/$assignmentId/progress',
    );
    return switch (result) {
      Success(:final value) =>
        _parseList(value, AssignmentProgressRow.fromJson),
      FailureResult(:final failure) => FailureResult(failure),
    };
  }

  Result<T> _parseOne<T>(
    Map<String, dynamic> envelope,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final data = envelope['data'];
    if (data is! Map<String, dynamic>) {
      return const FailureResult(ApiFailure('Invalid classroom response.'));
    }
    return Success(fromJson(data));
  }

  Result<List<T>> _parseList<T>(
    Map<String, dynamic> envelope,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final data = envelope['data'];
    if (data is! List) {
      return const FailureResult(ApiFailure('Invalid classrooms response.'));
    }
    return Success([
      for (final item in data)
        if (item is Map<String, dynamic>) fromJson(item),
    ]);
  }
}
