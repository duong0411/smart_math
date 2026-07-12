import 'package:eduself_study_app/core/error/result.dart';
import 'package:eduself_study_app/features/study_tools/domain/entities/flashcard_deck.dart';
import 'package:eduself_study_app/features/study_tools/domain/entities/study_tool_item.dart';

abstract class StudyToolsRepository {
  Future<Result<List<StudyToolItem>>> listTools();
  Future<Result<FlashcardDeckDetail>> getDeck(int id);
  Future<Result<MindmapDetail>> getMindmap(int id);
}
