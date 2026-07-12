import 'package:eduself_study_app/core/error/result.dart';
import 'package:eduself_study_app/core/network/network_providers.dart';
import 'package:eduself_study_app/features/parents/domain/entities/linked_child.dart';
import 'package:eduself_study_app/features/parents/domain/entities/weekly_report.dart';
import 'package:eduself_study_app/features/parents/domain/repositories/parents_repository.dart';
import 'package:eduself_study_app/features/parents/infrastructure/repositories/parents_repository_impl.dart';
import 'package:eduself_study_app/features/progress/domain/entities/progress_summary.dart';
import 'package:eduself_study_app/features/progress/presentation/providers/progress_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final parentsRepositoryProvider = Provider<ParentsRepository>((ref) {
  return ParentsRepositoryImpl(api: ref.watch(apiClientProvider));
});

final linkedChildrenProvider =
    FutureProvider.autoDispose<List<LinkedChild>>((ref) async {
  final result = await ref.watch(parentsRepositoryProvider).listChildren();
  return switch (result) {
    Success(:final value) => value,
    FailureResult(:final failure) => throw Exception(failure.message),
  };
});

final childProgressProvider =
    FutureProvider.autoDispose.family<ProgressSummary, int>((ref, studentId) async {
  final result =
      await ref.watch(progressRepositoryProvider).getChildSummary(studentId);
  return switch (result) {
    Success(:final value) => value,
    FailureResult(:final failure) => throw Exception(failure.message),
  };
});

final reportsProvider =
    FutureProvider.autoDispose<List<WeeklyReport>>((ref) async {
  final result = await ref.watch(parentsRepositoryProvider).listReports();
  return switch (result) {
    Success(:final value) => value,
    FailureResult(:final failure) => throw Exception(failure.message),
  };
});

final reportDetailProvider =
    FutureProvider.autoDispose.family<WeeklyReport, int>((ref, id) async {
  final result = await ref.watch(parentsRepositoryProvider).getReport(id);
  return switch (result) {
    Success(:final value) => value,
    FailureResult(:final failure) => throw Exception(failure.message),
  };
});
