import 'package:eduself_study_app/features/assessments/domain/entities/assessment_enums.dart';
import 'package:eduself_study_app/features/assessments/domain/entities/assessment_models.dart';

/// Human-readable Vietnamese summary of a student's answer payload.
String formatAttemptResponseVi(
  Map<String, dynamic> response, {
  AssessmentItem? item,
}) {
  if (response.isEmpty) return 'Chưa trả lời';

  final type = item?.itemType;

  if (type == AssessmentItemType.mcq ||
      response.containsKey('selectedOptionId')) {
    final id = response['selectedOptionId']?.toString();
    if (id == null || id.isEmpty) return 'Chưa chọn đáp án';
    final choice = item?.mcqChoices.where((c) => c.id == id).firstOrNull;
    if (choice != null && choice.text.isNotEmpty) {
      return 'Em chọn: ${id.toUpperCase()} — ${choice.text}';
    }
    return 'Em chọn: ${id.toUpperCase()}';
  }

  if (type == AssessmentItemType.trueFalse ||
      (response.containsKey('value') && response['value'] is bool)) {
    final value = response['value'];
    if (value is! bool) return 'Chưa chọn đúng/sai';
    return value ? 'Em chọn: Đúng' : 'Em chọn: Sai';
  }

  if (type == AssessmentItemType.matching || response.containsKey('pairs')) {
    final pairsRaw = response['pairs'];
    if (pairsRaw is! Map || pairsRaw.isEmpty) return 'Chưa nối cặp';
    final parts = <String>[];
    for (final e in pairsRaw.entries) {
      final left = e.key.toString().trim();
      final right = e.value.toString().trim();
      if (left.isEmpty || right.isEmpty) continue;
      parts.add('$left → $right');
    }
    if (parts.isEmpty) return 'Chưa nối cặp';
    return 'Em nối: ${parts.join('; ')}';
  }

  final text = (response['text'] ?? response['value'] ?? '').toString().trim();
  if (text.isNotEmpty) return 'Em trả lời: $text';

  return 'Đã trả lời';
}

String formatAnswerResultLabelVi(bool? isCorrect) {
  return switch (isCorrect) {
    true => 'Đúng',
    false => 'Sai',
    null => 'Chờ chấm',
  };
}
