import 'package:eduself_study_app/features/math_games/domain/grade_question_bank.dart';
import 'package:eduself_study_app/shared/utils/supported_grades.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SupportedGrades', () {
    test('normalize clamps to 6–9', () {
      expect(SupportedGrades.normalize(null), 8);
      expect(SupportedGrades.normalize(1), 6);
      expect(SupportedGrades.normalize(5), 6);
      expect(SupportedGrades.normalize(6), 6);
      expect(SupportedGrades.normalize(9), 9);
      expect(SupportedGrades.normalize(12), 9);
    });

    test('only 6–9 are supported', () {
      expect(SupportedGrades.all, [6, 7, 8, 9]);
      expect(SupportedGrades.isSupported(8), isTrue);
      expect(SupportedGrades.isSupported(5), isFalse);
      expect(SupportedGrades.isSupported(10), isFalse);
    });
  });

  group('GradeQuestionBank', () {
    test('next produces valid MCQ for grades 6–9', () {
      for (final grade in SupportedGrades.all) {
        for (var i = 0; i < 40; i++) {
          final q = GradeQuestionBank.next(grade);
          expect(q.prompt, isNotEmpty, reason: 'grade $grade empty prompt');
          expect(q.choices, hasLength(4), reason: 'grade $grade choices');
          expect(
            q.choices.contains(q.answer),
            isTrue,
            reason: 'grade $grade answer missing from choices: ${q.prompt}',
          );
          expect(
            q.choices.toSet(),
            hasLength(4),
            reason: 'grade $grade duplicate choices: ${q.prompt}',
          );
        }
      }
    });

    test('out-of-range grades fall back into 6–9 bank', () {
      final q = GradeQuestionBank.next(3);
      expect(q.choices.contains(q.answer), isTrue);
      final q2 = GradeQuestionBank.next(11);
      expect(q2.choices.contains(q2.answer), isTrue);
    });
  });
}
