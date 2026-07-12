import 'package:eduself_study_app/core/network/network_providers.dart';
import 'package:eduself_study_app/features/tutoring/domain/repositories/tutoring_repository.dart';
import 'package:eduself_study_app/features/tutoring/domain/usecases/tutoring_usecases.dart';
import 'package:eduself_study_app/features/tutoring/infrastructure/repositories/tutoring_repository_impl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final tutoringRepositoryProvider = Provider<TutoringRepository>((ref) {
  return TutoringRepositoryImpl(api: ref.watch(apiClientProvider));
});

final createTutoringSessionProvider = Provider<CreateTutoringSession>((ref) {
  return CreateTutoringSession(ref.watch(tutoringRepositoryProvider));
});

final listTutoringSessionsProvider = Provider<ListTutoringSessions>((ref) {
  return ListTutoringSessions(ref.watch(tutoringRepositoryProvider));
});

final getTutoringMessagesProvider = Provider<GetTutoringMessages>((ref) {
  return GetTutoringMessages(ref.watch(tutoringRepositoryProvider));
});

final sendTutoringMessageProvider = Provider<SendTutoringMessage>((ref) {
  return SendTutoringMessage(ref.watch(tutoringRepositoryProvider));
});

final deleteTutoringMessageProvider = Provider<DeleteTutoringMessage>((ref) {
  return DeleteTutoringMessage(ref.watch(tutoringRepositoryProvider));
});

final deleteTutoringSessionProvider = Provider<DeleteTutoringSession>((ref) {
  return DeleteTutoringSession(ref.watch(tutoringRepositoryProvider));
});
