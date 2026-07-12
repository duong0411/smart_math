import 'package:eduself_study_app/core/error/result.dart';
import 'package:eduself_study_app/features/parents/domain/entities/linked_child.dart';
import 'package:eduself_study_app/features/parents/domain/entities/parent_invite_code.dart';
import 'package:eduself_study_app/features/parents/domain/entities/parent_link.dart';
import 'package:eduself_study_app/features/parents/domain/entities/weekly_report.dart';

abstract class ParentsRepository {
  Future<Result<ParentInviteCode>> createInviteCode();

  Future<Result<ParentLink>> linkChild(String inviteCode);

  Future<Result<List<LinkedChild>>> listChildren();

  Future<Result<void>> unlinkChild(int studentId);

  Future<Result<WeeklyReportPreview>> previewWeeklyReport({
    required int studentId,
    DateTime? weekStartUtc,
  });

  Future<Result<WeeklyReport>> generateWeeklyReport({
    required int studentId,
    DateTime? weekStartUtc,
  });

  Future<Result<List<WeeklyReport>>> listReports();

  Future<Result<WeeklyReport>> getReport(int id);

  Future<Result<WeeklyReport>> exportReport(int id);
}
