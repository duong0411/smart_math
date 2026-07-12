import 'package:eduself_study_app/core/error/result.dart';
import 'package:eduself_study_app/core/network/api_client.dart';
import 'package:eduself_study_app/features/progress/domain/entities/progress_summary.dart';
import 'package:eduself_study_app/features/progress/domain/repositories/progress_repository.dart';

class ProgressRepositoryImpl implements ProgressRepository {
  ProgressRepositoryImpl({required ApiClient api}) : _api = api;

  final ApiClient _api;

  @override
  Future<Result<ProgressSummary>> getSummary() async {
    final result = await _api.get('/progress/summary');
    return switch (result) {
      Success(:final value) => _parse(value),
      FailureResult(:final failure) => FailureResult(failure),
    };
  }

  @override
  Future<Result<ProgressSummary>> getChildSummary(
    int studentId, {
    DateTime? from,
    DateTime? to,
  }) async {
    final query = StringBuffer('/progress/summary/$studentId');
    final params = <String>[];
    if (from != null) {
      params.add(
        'from=${Uri.encodeQueryComponent(from.toUtc().toIso8601String())}',
      );
    }
    if (to != null) {
      params.add(
        'to=${Uri.encodeQueryComponent(to.toUtc().toIso8601String())}',
      );
    }
    if (params.isNotEmpty) {
      query.write('?${params.join('&')}');
    }
    final result = await _api.get(query.toString());
    return switch (result) {
      Success(:final value) => _parse(value),
      FailureResult(:final failure) => FailureResult(failure),
    };
  }

  Result<ProgressSummary> _parse(Map<String, dynamic> envelope) {
    final data = envelope['data'];
    if (data is! Map<String, dynamic>) {
      return const FailureResult(ApiFailure('Invalid progress response.'));
    }
    return Success(ProgressSummary.fromJson(data));
  }
}
