import 'package:eduself_study_app/features/math_ai/infrastructure/math_local_store.dart';
import 'package:eduself_study_app/features/math_ai/presentation/providers/math_ai_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> logMathGameResult(
  WidgetRef ref, {
  required String topic,
  required String detail,
  required bool success,
}) async {
  await ref.read(mathLocalStoreProvider).addEvent(
        MathStudyEvent(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: MathStudyEventType.game,
          topic: topic,
          detail: detail,
          correct: success,
          at: DateTime.now().toUtc(),
        ),
      );
  ref.invalidate(mathEventsProvider);

  if (success) {
    await ref.read(studyStreakStoreProvider).recordMeaningfulStudy(
          reason: 'Thắng game: $topic',
        );
    await ref.read(studyStreakStoreProvider).addEssence(15);
    ref.invalidate(studyStreakProvider);
  }
}
