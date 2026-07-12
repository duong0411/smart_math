import 'package:eduself_study_app/core/error/result.dart';
import 'package:eduself_study_app/core/network/api_client.dart';
import 'package:eduself_study_app/features/study_tools/domain/entities/flashcard_deck.dart';
import 'package:eduself_study_app/features/study_tools/domain/entities/study_tool_item.dart';
import 'package:eduself_study_app/features/study_tools/domain/repositories/study_tools_repository.dart';

class StudyToolsRepositoryImpl implements StudyToolsRepository {
  StudyToolsRepositoryImpl({required ApiClient api}) : _api = api;

  final ApiClient _api;

  @override
  Future<Result<List<StudyToolItem>>> listTools() async {
    final decksResult = await _api.get('/study-tools/flashcards/decks');
    final mindmapsResult = await _api.get('/study-tools/mindmaps');

    return switch ((decksResult, mindmapsResult)) {
      (FailureResult(:final failure), _) => FailureResult(failure),
      (_, FailureResult(:final failure)) => FailureResult(failure),
      (Success(:final value), Success(value: final mindmapsEnvelope)) => () {
          final decks = _parseDecks(value);
          if (decks is FailureResult<List<StudyToolItem>>) return decks;
          final mindmaps = _parseMindmaps(mindmapsEnvelope);
          if (mindmaps is FailureResult<List<StudyToolItem>>) return mindmaps;
          return Success<List<StudyToolItem>>([
            ...decks.valueOrNull!,
            ...mindmaps.valueOrNull!,
          ]);
        }(),
    };
  }

  @override
  Future<Result<FlashcardDeckDetail>> getDeck(int id) async {
    final result = await _api.get('/study-tools/flashcards/decks/$id');
    return switch (result) {
      Success(:final value) => _parseDeckDetail(value),
      FailureResult(:final failure) => FailureResult(failure),
    };
  }

  @override
  Future<Result<MindmapDetail>> getMindmap(int id) async {
    final result = await _api.get('/study-tools/mindmaps/$id');
    return switch (result) {
      Success(:final value) => _parseMindmapDetail(value),
      FailureResult(:final failure) => FailureResult(failure),
    };
  }

  Result<List<StudyToolItem>> _parseDecks(Map<String, dynamic> envelope) {
    final data = envelope['data'];
    if (data is! List) {
      return const FailureResult(ApiFailure('Invalid decks response.'));
    }
    return Success([
      for (final item in data)
        if (item is Map<String, dynamic>) FlashcardDeckItem.fromJson(item),
    ]);
  }

  Result<List<StudyToolItem>> _parseMindmaps(Map<String, dynamic> envelope) {
    final data = envelope['data'];
    if (data is! List) {
      return const FailureResult(ApiFailure('Invalid mindmaps response.'));
    }
    return Success([
      for (final item in data)
        if (item is Map<String, dynamic>) MindmapItem.fromJson(item),
    ]);
  }

  Result<FlashcardDeckDetail> _parseDeckDetail(Map<String, dynamic> envelope) {
    final data = envelope['data'];
    if (data is! Map<String, dynamic>) {
      return const FailureResult(ApiFailure('Invalid deck response.'));
    }
    return Success(FlashcardDeckDetail.fromJson(data));
  }

  Result<MindmapDetail> _parseMindmapDetail(Map<String, dynamic> envelope) {
    final data = envelope['data'];
    if (data is! Map<String, dynamic>) {
      return const FailureResult(ApiFailure('Invalid mindmap response.'));
    }
    return Success(MindmapDetail.fromJson(data));
  }
}
