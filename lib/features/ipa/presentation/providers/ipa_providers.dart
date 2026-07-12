import 'package:eduself_study_app/core/error/result.dart';
import 'package:eduself_study_app/core/network/network_providers.dart';
import 'package:eduself_study_app/features/ipa/domain/entities/ipa_word_list.dart';
import 'package:eduself_study_app/features/ipa/domain/repositories/ipa_repository.dart';
import 'package:eduself_study_app/features/ipa/infrastructure/repositories/ipa_repository_impl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final ipaRepositoryProvider = Provider<IpaRepository>((ref) {
  return IpaRepositoryImpl(api: ref.watch(apiClientProvider));
});

final ipaListsProvider = FutureProvider<List<IpaWordList>>((ref) async {
  final result = await ref.watch(ipaRepositoryProvider).listLists();
  return switch (result) {
    Success(:final value) => value,
    FailureResult(:final failure) => throw Exception(failure.message),
  };
});
