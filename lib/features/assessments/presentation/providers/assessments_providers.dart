import 'package:eduself_study_app/core/error/result.dart';
import 'package:eduself_study_app/core/network/network_providers.dart';
import 'package:eduself_study_app/features/assessments/domain/entities/assessment_models.dart';
import 'package:eduself_study_app/features/assessments/domain/repositories/assessments_repository.dart';
import 'package:eduself_study_app/features/assessments/domain/usecases/assessment_usecases.dart';
import 'package:eduself_study_app/features/assessments/infrastructure/repositories/assessments_repository_impl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final assessmentsRepositoryProvider = Provider<AssessmentsRepository>((ref) {
  return AssessmentsRepositoryImpl(api: ref.watch(apiClientProvider));
});

final listDiscoverableAssessmentsProvider =
    Provider<ListDiscoverableAssessments>((ref) {
  return ListDiscoverableAssessments(ref.watch(assessmentsRepositoryProvider));
});

final getAssessmentProvider = Provider<GetAssessment>((ref) {
  return GetAssessment(ref.watch(assessmentsRepositoryProvider));
});

final startAssessmentAttemptProvider = Provider<StartAssessmentAttempt>((ref) {
  return StartAssessmentAttempt(ref.watch(assessmentsRepositoryProvider));
});

final saveAssessmentAnswerProvider = Provider<SaveAssessmentAnswer>((ref) {
  return SaveAssessmentAnswer(ref.watch(assessmentsRepositoryProvider));
});

final submitAssessmentAttemptProvider =
    Provider<SubmitAssessmentAttempt>((ref) {
  return SubmitAssessmentAttempt(ref.watch(assessmentsRepositoryProvider));
});

final getAssessmentAttemptProvider = Provider<GetAssessmentAttempt>((ref) {
  return GetAssessmentAttempt(ref.watch(assessmentsRepositoryProvider));
});

final getMyAssessmentAttemptProvider = Provider<GetMyAssessmentAttempt>((ref) {
  return GetMyAssessmentAttempt(ref.watch(assessmentsRepositoryProvider));
});

final assessmentsProvider =
    FutureProvider.autoDispose<List<AssessmentSummary>>((ref) async {
  final result = await ref.watch(listDiscoverableAssessmentsProvider)();
  return switch (result) {
    Success(:final value) => value,
    FailureResult(:final failure) => throw Exception(failure.message),
  };
});

final assessmentDetailProvider =
    FutureProvider.autoDispose.family<AssessmentDetail, int>((ref, id) async {
  final result = await ref.watch(getAssessmentProvider)(id);
  return switch (result) {
    Success(:final value) => value,
    FailureResult(:final failure) => throw Exception(failure.message),
  };
});

final myAssessmentAttemptProvider = FutureProvider.autoDispose
    .family<AssessmentAttempt?, int>((ref, assessmentId) async {
  final result = await ref.watch(getMyAssessmentAttemptProvider)(assessmentId);
  return switch (result) {
    Success(:final value) => value,
    FailureResult(:final failure) => throw Exception(failure.message),
  };
});

final assessmentAttemptResultProvider = FutureProvider.autoDispose
    .family<AssessmentAttempt, int>((ref, attemptId) async {
  final result = await ref.watch(getAssessmentAttemptProvider)(attemptId);
  return switch (result) {
    Success(:final value) => value,
    FailureResult(:final failure) => throw Exception(failure.message),
  };
});
