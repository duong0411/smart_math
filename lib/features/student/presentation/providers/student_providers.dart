import 'package:eduself_study_app/core/error/result.dart';
import 'package:eduself_study_app/core/network/network_providers.dart';
import 'package:eduself_study_app/features/student/domain/entities/student_profile.dart';
import 'package:eduself_study_app/features/student/domain/repositories/student_repository.dart';
import 'package:eduself_study_app/features/student/domain/usecases/student_usecases.dart';
import 'package:eduself_study_app/features/student/infrastructure/repositories/student_repository_impl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final studentRepositoryProvider = Provider<StudentRepository>((ref) {
  return StudentRepositoryImpl(api: ref.watch(apiClientProvider));
});

final getStudentProfileProvider = Provider<GetStudentProfile>((ref) {
  return GetStudentProfile(ref.watch(studentRepositoryProvider));
});

final updateStudentProfileProvider = Provider<UpdateStudentProfile>((ref) {
  return UpdateStudentProfile(ref.watch(studentRepositoryProvider));
});

final studentProfileProvider = FutureProvider<StudentProfile>((ref) async {
  final result = await ref.watch(getStudentProfileProvider)();
  return switch (result) {
    Success(:final value) => value,
    FailureResult(:final failure) => throw Exception(failure.message),
  };
});
