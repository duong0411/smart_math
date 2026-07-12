import 'package:eduself_study_app/core/error/result.dart';
import 'package:eduself_study_app/core/network/network_providers.dart';
import 'package:eduself_study_app/features/curriculum/domain/entities/curriculum_subject.dart';
import 'package:eduself_study_app/features/curriculum/domain/repositories/curriculum_repository.dart';
import 'package:eduself_study_app/features/curriculum/infrastructure/repositories/curriculum_repository_impl.dart';
import 'package:eduself_study_app/features/student/presentation/providers/student_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final curriculumRepositoryProvider = Provider<CurriculumRepository>((ref) {
  return CurriculumRepositoryImpl(api: ref.watch(apiClientProvider));
});

final curriculumSubjectsProvider =
    FutureProvider<List<CurriculumSubject>>((ref) async {
  final grade = ref.watch(studentProfileProvider).valueOrNull?.gradeLevel;
  final result = await ref
      .watch(curriculumRepositoryProvider)
      .listSubjects(gradeLevel: grade);
  return switch (result) {
    Success(:final value) => value,
    FailureResult(:final failure) => throw Exception(failure.message),
  };
});
