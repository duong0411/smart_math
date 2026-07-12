import 'package:eduself_study_app/core/error/result.dart';
import 'package:eduself_study_app/core/network/network_providers.dart';
import 'package:eduself_study_app/features/study_tools/domain/entities/flashcard_deck.dart';
import 'package:eduself_study_app/features/study_tools/domain/entities/study_tool_item.dart';
import 'package:eduself_study_app/features/study_tools/domain/repositories/study_tools_repository.dart';
import 'package:eduself_study_app/features/study_tools/infrastructure/repositories/study_tools_repository_impl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final studyToolsRepositoryProvider = Provider<StudyToolsRepository>((ref) {
  return StudyToolsRepositoryImpl(api: ref.watch(apiClientProvider));
});

final studyToolsProvider = FutureProvider<List<StudyToolItem>>((ref) async {
  final result = await ref.watch(studyToolsRepositoryProvider).listTools();
  return switch (result) {
    Success(:final value) => value,
    FailureResult(:final failure) => throw Exception(failure.message),
  };
});

final flashcardDeckProvider =
    FutureProvider.family<FlashcardDeckDetail, int>((ref, id) async {
  final result = await ref.watch(studyToolsRepositoryProvider).getDeck(id);
  return switch (result) {
    Success(:final value) => value,
    FailureResult(:final failure) => throw Exception(failure.message),
  };
});

final mindmapDetailProvider =
    FutureProvider.family<MindmapDetail, int>((ref, id) async {
  final result = await ref.watch(studyToolsRepositoryProvider).getMindmap(id);
  return switch (result) {
    Success(:final value) => value,
    FailureResult(:final failure) => throw Exception(failure.message),
  };
});
