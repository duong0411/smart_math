import 'package:eduself_study_app/core/error/result.dart';
import 'package:eduself_study_app/features/progress/domain/entities/progress_summary.dart';

abstract class ProgressRepository {
  Future<Result<ProgressSummary>> getSummary();

  Future<Result<ProgressSummary>> getChildSummary(
    int studentId, {
    DateTime? from,
    DateTime? to,
  });
}
