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

    test('poly multiply prompts keep variable x (not substituted value)', () {
      var sawPoly = false;
      for (var i = 0; i < 200; i++) {
        final q = GradeQuestionBank.next(8);
        if (!q.prompt.contains('khi x =') || !q.prompt.contains('x(')) {
          continue;
        }
        sawPoly = true;
        expect(
          q.prompt,
          matches(RegExp(r'\d+x\(x \+ \d+\) khi x = \d+')),
          reason: 'prompt should keep symbolic x: ${q.prompt}',
        );
        expect(
          q.prompt,
          isNot(matches(RegExp(r'\d+x\(\d+ \+ \d+\) khi x ='))),
          reason: 'value must not replace x inside expression: ${q.prompt}',
        );
      }
      expect(sawPoly, isTrue, reason: 'expected at least one poly multiply draw');
    });

    test('each grade only uses its KNTT chapter labels', () {
      for (final grade in SupportedGrades.all) {
        final allowed = GradeQuestionBank.knttChaptersByGrade[grade]!;
        for (var i = 0; i < 120; i++) {
          final q = GradeQuestionBank.next(grade);
          expect(
            q.chapter,
            isNotNull,
            reason: 'grade $grade missing chapter: ${q.prompt}',
          );
          expect(
            allowed.contains(q.chapter),
            isTrue,
            reason:
                'grade $grade got foreign chapter "${q.chapter}": ${q.prompt}',
          );
        }
      }
    });

    test('grade 8 never yields exclusive grade-9 topics', () {
      const banned = {
        'Ch1 · Hệ PT',
        'Ch2 · Bất phương trình',
        'Ch3 · Căn bậc hai',
        'Ch3 · Căn bậc ba',
        'Ch4 · Lượng giác',
        'Ch5 · Đường tròn',
        'Ch6 · PT bậc hai',
        'Ch6 · Hàm số y = ax²',
        'Ch10 · Hình trụ',
      };
      for (var i = 0; i < 200; i++) {
        final q = GradeQuestionBank.next(8);
        expect(
          banned.contains(q.chapter),
          isFalse,
          reason: 'lớp 8 dính lớp 9: ${q.chapter} · ${q.prompt}',
        );
      }
    });

    test('grade 9 never yields exclusive grade-8 algebra/geometry chapters', () {
      const banned = {
        'Ch1 · Đa thức',
        'Ch2 · Hằng đẳng thức',
        'Ch2 · Phân tích nhân tử',
        'Ch6 · Phân thức',
        'Ch7 · PT bậc nhất',
        'Ch7 · Hàm số bậc nhất',
        'Ch9 · Pythagore',
        'Ch10 · Hình chóp',
      };
      for (var i = 0; i < 200; i++) {
        final q = GradeQuestionBank.next(9);
        expect(
          banned.contains(q.chapter),
          isFalse,
          reason: 'lớp 9 dính lớp 8: ${q.chapter} · ${q.prompt}',
        );
      }
    });
  });
}
