import 'package:eduself_study_app/core/error/result.dart';
import 'package:eduself_study_app/features/ipa/domain/entities/ipa_word_list.dart';

abstract class IpaRepository {
  Future<Result<List<IpaWordList>>> listLists();
}
