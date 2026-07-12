import 'package:eduself_study_app/core/error/result.dart';
import 'package:eduself_study_app/core/network/api_client.dart';
import 'package:eduself_study_app/features/parents/domain/entities/linked_child.dart';
import 'package:eduself_study_app/features/parents/domain/entities/parent_invite_code.dart';
import 'package:eduself_study_app/features/parents/domain/entities/parent_link.dart';
import 'package:eduself_study_app/features/parents/domain/entities/weekly_report.dart';
import 'package:eduself_study_app/features/parents/domain/repositories/parents_repository.dart';

class ParentsRepositoryImpl implements ParentsRepository {
  ParentsRepositoryImpl({required this._api});

  final ApiClient _api;

  @override
  Future<Result<ParentInviteCode>> createInviteCode() async {
    final result = await _api.post('/parents/invite-codes', body: {});
    return switch (result) {
      Success(:final value) => _mapData(value, ParentInviteCode.fromJson),
      FailureResult(:final failure) => FailureResult(failure),
    };
  }

  @override
  Future<Result<ParentLink>> linkChild(String inviteCode) async {
    final result = await _api.post(
      '/parents/link',
      body: {'inviteCode': inviteCode.trim()},
    );
    return switch (result) {
      Success(:final value) => _mapData(value, ParentLink.fromJson),
      FailureResult(:final failure) => FailureResult(failure),
    };
  }

  @override
  Future<Result<List<LinkedChild>>> listChildren() async {
    final result = await _api.get('/parents/children');
    return switch (result) {
      Success(:final value) => _mapList(value, LinkedChild.fromJson),
      FailureResult(:final failure) => FailureResult(failure),
    };
  }

  @override
  Future<Result<void>> unlinkChild(int studentId) async {
    final result = await _api.delete('/parents/children/$studentId');
    return switch (result) {
      Success() => const Success(null),
      FailureResult(:final failure) => FailureResult(failure),
    };
  }

  @override
  Future<Result<WeeklyReportPreview>> previewWeeklyReport({
    required int studentId,
    DateTime? weekStartUtc,
  }) async {
    final query = StringBuffer('/reports/weekly?studentId=$studentId');
    if (weekStartUtc != null) {
      query.write('&weekStartUtc=${Uri.encodeQueryComponent(weekStartUtc.toUtc().toIso8601String())}');
    }
    final result = await _api.get(query.toString());
    return switch (result) {
      Success(:final value) => _mapData(value, WeeklyReportPreview.fromJson),
      FailureResult(:final failure) => FailureResult(failure),
    };
  }

  @override
  Future<Result<WeeklyReport>> generateWeeklyReport({
    required int studentId,
    DateTime? weekStartUtc,
  }) async {
    final body = <String, dynamic>{'studentId': studentId};
    if (weekStartUtc != null) {
      body['weekStartUtc'] = weekStartUtc.toUtc().toIso8601String();
    }
    final result = await _api.post('/reports/weekly', body: body);
    return switch (result) {
      Success(:final value) => _mapData(value, WeeklyReport.fromJson),
      FailureResult(:final failure) => FailureResult(failure),
    };
  }

  @override
  Future<Result<List<WeeklyReport>>> listReports() async {
    final result = await _api.get('/reports');
    return switch (result) {
      Success(:final value) => _mapList(value, WeeklyReport.fromJson),
      FailureResult(:final failure) => FailureResult(failure),
    };
  }

  @override
  Future<Result<WeeklyReport>> getReport(int id) async {
    final result = await _api.get('/reports/$id');
    return switch (result) {
      Success(:final value) => _mapData(value, WeeklyReport.fromJson),
      FailureResult(:final failure) => FailureResult(failure),
    };
  }

  @override
  Future<Result<WeeklyReport>> exportReport(int id) async {
    final result = await _api.post('/reports/$id/export', body: {});
    return switch (result) {
      Success(:final value) => _mapData(value, WeeklyReport.fromJson),
      FailureResult(:final failure) => FailureResult(failure),
    };
  }

  Result<T> _mapData<T>(
    Map<String, dynamic> envelope,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final data = envelope['data'];
    if (data is! Map<String, dynamic>) {
      return const FailureResult(ApiFailure('Invalid parents API response.'));
    }
    return Success(fromJson(data));
  }

  Result<List<T>> _mapList<T>(
    Map<String, dynamic> envelope,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final data = envelope['data'];
    if (data is! List) {
      return const FailureResult(ApiFailure('Invalid parents list response.'));
    }
    return Success(
      data
          .whereType<Map<String, dynamic>>()
          .map(fromJson)
          .toList(growable: false),
    );
  }
}
