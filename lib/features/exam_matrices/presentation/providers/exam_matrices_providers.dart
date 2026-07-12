import 'package:eduself_study_app/core/error/result.dart';
import 'package:eduself_study_app/core/network/network_providers.dart';
import 'package:eduself_study_app/features/exam_matrices/domain/entities/exam_matrix.dart';
import 'package:eduself_study_app/features/exam_matrices/domain/repositories/exam_matrices_repository.dart';
import 'package:eduself_study_app/features/exam_matrices/infrastructure/repositories/exam_matrices_repository_impl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final examMatricesRepositoryProvider = Provider<ExamMatricesRepository>((ref) {
  return ExamMatricesRepositoryImpl(api: ref.watch(apiClientProvider));
});

final examMatricesProvider =
    FutureProvider.autoDispose<List<ExamMatrix>>((ref) async {
  final result = await ref.watch(examMatricesRepositoryProvider).list();
  return switch (result) {
    Success(:final value) => value,
    FailureResult(:final failure) => throw Exception(failure.message),
  };
});

final examMatrixDetailProvider =
    FutureProvider.autoDispose.family<ExamMatrixDetail, int>((ref, id) async {
  final result = await ref.watch(examMatricesRepositoryProvider).get(id);
  return switch (result) {
    Success(:final value) => value,
    FailureResult(:final failure) => throw Exception(failure.message),
  };
});
