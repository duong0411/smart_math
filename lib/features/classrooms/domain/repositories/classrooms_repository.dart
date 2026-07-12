import 'package:eduself_study_app/core/error/result.dart';
import 'package:eduself_study_app/features/assessments/domain/entities/assessment_models.dart';
import 'package:eduself_study_app/features/classrooms/domain/entities/assignment_progress_row.dart';
import 'package:eduself_study_app/features/classrooms/domain/entities/classroom_member.dart';
import 'package:eduself_study_app/features/classrooms/domain/entities/classroom_summary.dart';

abstract class ClassroomsRepository {
  Future<Result<List<ClassroomSummary>>> listClassrooms();

  Future<Result<void>> joinClassroom(String joinCode);

  Future<Result<ClassroomSummary>> createClassroom(String name);

  Future<Result<ClassroomSummary>> getClassroom(int id);

  Future<Result<List<ClassroomMember>>> listMembers(int classroomId);

  Future<Result<ClassroomMember>> updateMemberGrade({
    required int classroomId,
    required int userId,
    required int? gradeLevel,
  });

  Future<Result<void>> removeMember({
    required int classroomId,
    required int userId,
  });

  Future<Result<List<ClassroomAssignment>>> listAssignments(int classroomId);

  Future<Result<ClassroomAssignment>> assignAssessment({
    required int classroomId,
    required int assessmentId,
    DateTime? dueAtUtc,
    int? durationMinutes,
  });

  Future<Result<void>> deleteAssignment({
    required int classroomId,
    required int assignmentId,
  });

  Future<Result<List<AssignmentProgressRow>>> assignmentProgress({
    required int classroomId,
    required int assignmentId,
  });
}
