import 'package:eduself_study_app/core/error/result.dart';
import 'package:eduself_study_app/core/network/network_providers.dart';
import 'package:eduself_study_app/features/assessments/domain/entities/assessment_models.dart';
import 'package:eduself_study_app/features/classrooms/domain/entities/assignment_progress_row.dart';
import 'package:eduself_study_app/features/classrooms/domain/entities/classroom_member.dart';
import 'package:eduself_study_app/features/classrooms/domain/entities/classroom_summary.dart';
import 'package:eduself_study_app/features/classrooms/domain/repositories/classrooms_repository.dart';
import 'package:eduself_study_app/features/classrooms/infrastructure/repositories/classrooms_repository_impl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final classroomsRepositoryProvider = Provider<ClassroomsRepository>((ref) {
  return ClassroomsRepositoryImpl(api: ref.watch(apiClientProvider));
});

final classroomsProvider =
    FutureProvider.autoDispose<List<ClassroomSummary>>((ref) async {
  final result = await ref.watch(classroomsRepositoryProvider).listClassrooms();
  return switch (result) {
    Success(:final value) => value,
    FailureResult(:final failure) => throw Exception(failure.message),
  };
});

final classroomDetailProvider =
    FutureProvider.autoDispose.family<ClassroomSummary, int>((ref, id) async {
  final result = await ref.watch(classroomsRepositoryProvider).getClassroom(id);
  return switch (result) {
    Success(:final value) => value,
    FailureResult(:final failure) => throw Exception(failure.message),
  };
});

final classroomMembersProvider =
    FutureProvider.autoDispose.family<List<ClassroomMember>, int>((ref, id) async {
  final result = await ref.watch(classroomsRepositoryProvider).listMembers(id);
  return switch (result) {
    Success(:final value) => value,
    FailureResult(:final failure) => throw Exception(failure.message),
  };
});

final classroomAssignmentsProvider = FutureProvider.autoDispose
    .family<List<ClassroomAssignment>, int>((ref, id) async {
  final result =
      await ref.watch(classroomsRepositoryProvider).listAssignments(id);
  return switch (result) {
    Success(:final value) => value,
    FailureResult(:final failure) => throw Exception(failure.message),
  };
});

final assignmentProgressProvider = FutureProvider.autoDispose
    .family<List<AssignmentProgressRow>, ({int classroomId, int assignmentId})>(
  (ref, ids) async {
    final result =
        await ref.watch(classroomsRepositoryProvider).assignmentProgress(
              classroomId: ids.classroomId,
              assignmentId: ids.assignmentId,
            );
    return switch (result) {
      Success(:final value) => value,
      FailureResult(:final failure) => throw Exception(failure.message),
    };
  },
);
