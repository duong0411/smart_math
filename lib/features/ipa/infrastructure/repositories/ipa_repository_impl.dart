import 'package:eduself_study_app/core/error/result.dart';
import 'package:eduself_study_app/core/network/api_client.dart';
import 'package:eduself_study_app/features/ipa/domain/entities/ipa_word_list.dart';
import 'package:eduself_study_app/features/ipa/domain/repositories/ipa_repository.dart';

class IpaRepositoryImpl implements IpaRepository {
  IpaRepositoryImpl({required ApiClient api}) : _api = api;

  final ApiClient _api;

  @override
  Future<Result<List<IpaWordList>>> listLists() async {
    final result = await _api.get('/ipa/lists');
    return switch (result) {
      Success(:final value) => _parseList(value),
      FailureResult(:final failure) => FailureResult(failure),
    };
  }

  Result<List<IpaWordList>> _parseList(Map<String, dynamic> envelope) {
    final data = envelope['data'];
    if (data is! List) {
      return const FailureResult(ApiFailure('Invalid IPA lists response.'));
    }
    return Success([
      for (final item in data)
        if (item is Map<String, dynamic>) IpaWordList.fromJson(item),
    ]);
  }
}
