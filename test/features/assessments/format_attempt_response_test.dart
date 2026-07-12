import 'package:eduself_study_app/features/assessments/domain/entities/assessment_enums.dart';
import 'package:eduself_study_app/features/assessments/domain/entities/assessment_models.dart';
import 'package:eduself_study_app/features/assessments/domain/format_attempt_response.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats mcq response with choice text', () {
    final item = AssessmentItem(
      id: 1,
      assessmentId: 1,
      itemType: AssessmentItemType.mcq,
      prompt: '2+2?',
      options: {
        'choices': [
          {'id': 'a', 'text': '3'},
          {'id': 'b', 'text': '4'},
        ],
      },
      answerKey: const {'correctOptionId': 'b'},
      points: 1,
      sortOrder: 0,
    );

    expect(
      formatAttemptResponseVi(
        {'selectedOptionId': 'b'},
        item: item,
      ),
      'Em chọn: B — 4',
    );
  });

  test('formats true/false and essay', () {
    expect(
      formatAttemptResponseVi({'value': true}),
      'Em chọn: Đúng',
    );
    expect(
      formatAttemptResponseVi({'text': 'Hà Nội'}),
      'Em trả lời: Hà Nội',
    );
  });

  test('formats matching pairs', () {
    expect(
      formatAttemptResponseVi({
        'pairs': {'A': '1', 'B': '2'},
      }),
      'Em nối: A → 1; B → 2',
    );
  });
}
