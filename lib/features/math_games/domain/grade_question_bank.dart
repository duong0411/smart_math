import 'dart:math';

enum GradeBand {
  primaryEarly, // 1-3
  primaryLate, // 4-5
  secondary, // 6-9
  high, // 10-12
}

extension GradeBandX on GradeBand {
  String get labelVi => switch (this) {
        GradeBand.primaryEarly => 'Lớp 1–3',
        GradeBand.primaryLate => 'Lớp 4–5',
        GradeBand.secondary => 'Lớp 6–9',
        GradeBand.high => 'Lớp 10–12',
      };

  String get blurb => switch (this) {
        GradeBand.primaryEarly => 'Cộng trừ · hình · đếm vui',
        GradeBand.primaryLate => 'Nhân chia · phân số · đo đạc',
        GradeBand.secondary => 'Số nguyên · phương trình · tỷ lệ',
        GradeBand.high => 'Bậc hai · hàm số · suy luận nhanh',
      };

  static GradeBand fromGrade(int? grade) {
    if (grade == null) return GradeBand.primaryLate;
    if (grade <= 3) return GradeBand.primaryEarly;
    if (grade <= 5) return GradeBand.primaryLate;
    if (grade <= 9) return GradeBand.secondary;
    return GradeBand.high;
  }
}

class GradeQuestion {
  const GradeQuestion({
    required this.prompt,
    required this.answer,
    required this.choices,
    this.storyHint,
  });

  final String prompt;
  final int answer;
  final List<int> choices;
  final String? storyHint;
}

abstract final class GradeQuestionBank {
  static final _rng = Random();

  static GradeQuestion next(int grade) {
    final band = GradeBandX.fromGrade(grade);
    return switch (band) {
      GradeBand.primaryEarly => _primaryEarly(),
      GradeBand.primaryLate => _primaryLate(),
      GradeBand.secondary => _secondary(),
      GradeBand.high => _high(),
    };
  }

  static GradeQuestion _primaryEarly() {
    final roll = _rng.nextInt(5);
    switch (roll) {
      case 0:
        final a = 1 + _rng.nextInt(20);
        final b = 1 + _rng.nextInt(20);
        return _q('$a + $b = ?', a + b, hint: 'Nhặt thêm sao trên đường!');
      case 1:
        final a = 8 + _rng.nextInt(22);
        final b = 1 + _rng.nextInt(a);
        return _q('$a − $b = ?', a - b, hint: 'Còn bao nhiêu viên kẹo?');
      case 2:
        final a = 2 + _rng.nextInt(5);
        final b = 2 + _rng.nextInt(5);
        return _q('$a × $b = ?', a * b, hint: 'Mỗi hộp có $b cái.');
      case 3:
        final sides = [3, 4, 5, 6][_rng.nextInt(4)];
        return _q(
          'Hình có $sides cạnh gọi là hình mấy giác? (điền số)',
          sides,
          hint: 'Đếm cạnh nào!',
        );
      default:
        final tens = (1 + _rng.nextInt(9)) * 10;
        final ones = 1 + _rng.nextInt(9);
        return _q('$tens + $ones = ?', tens + ones, hint: 'Ghép chục và đơn vị.');
    }
  }

  static GradeQuestion _primaryLate() {
    final roll = _rng.nextInt(5);
    switch (roll) {
      case 0:
        final a = 6 + _rng.nextInt(12);
        final b = 3 + _rng.nextInt(12);
        return _q('$a × $b = ?', a * b, hint: 'Nhân nhanh để mở cửa kho báu!');
      case 1:
        final b = 2 + _rng.nextInt(9);
        final q = 2 + _rng.nextInt(12);
        return _q('${b * q} ÷ $b = ?', q, hint: 'Chia đều cho $b bạn.');
      case 2:
        final l = 4 + _rng.nextInt(12);
        final w = 3 + _rng.nextInt(10);
        return _q(
          'Chu vi hình chữ nhật $l×$w là?',
          2 * (l + w),
          hint: 'Chu vi = 2 × (dài + rộng)',
        );
      case 3:
        final l = 3 + _rng.nextInt(10);
        final w = 2 + _rng.nextInt(8);
        return _q(
          'Diện tích hình chữ nhật $l×$w là?',
          l * w,
          hint: 'Diện tích = dài × rộng',
        );
      default:
        final den = [2, 4, 5][_rng.nextInt(3)];
        final whole = den * (2 + _rng.nextInt(8));
        final num = 1 + _rng.nextInt(den - 1);
        final ans = whole * num ~/ den;
        return _q(
          '$num/$den của $whole bằng bao nhiêu?',
          ans,
          hint: 'Lấy tổng chia mẫu rồi nhân tử.',
        );
    }
  }

  static GradeQuestion _secondary() {
    final roll = _rng.nextInt(6);
    switch (roll) {
      case 0:
        final a = -9 + _rng.nextInt(19);
        final b = -9 + _rng.nextInt(19);
        if (a == 0 && b == 0) return _secondary();
        return _q('$a + ($b) = ?', a + b, hint: 'Cộng số nguyên cẩn thận dấu.');
      case 1:
        final a = 2 + _rng.nextInt(9);
        final x = -6 + _rng.nextInt(13);
        final b = a * x;
        return _q('${a}x = $b ⇒ x = ?', x, hint: 'Chia cả hai vế cho $a.');
      case 2:
        final a = 1 + _rng.nextInt(8);
        final x = -5 + _rng.nextInt(11);
        final b = 1 + _rng.nextInt(10);
        final c = a * x + b;
        return _q('${a}x + $b = $c ⇒ x = ?', x, hint: 'Chuyển vế rồi chia.');
      case 3:
        final a = 2 + _rng.nextInt(12);
        return _q('$a² = ?', a * a, hint: 'Bình phương số tự nhiên.');
      case 4:
        final b = 2 + _rng.nextInt(9);
        final q = 3 + _rng.nextInt(12);
        return _q('${b * q} : $b = ?', q, hint: 'Tỷ lệ / chia hết.');
      default:
        final p = 10 + _rng.nextInt(40);
        final r = [10, 20, 25, 50][_rng.nextInt(4)];
        return _q('$r% của $p là?', p * r ~/ 100, hint: 'Phần trăm cơ bản.');
    }
  }

  static GradeQuestion _high() {
    final roll = _rng.nextInt(6);
    switch (roll) {
      case 0:
        final r1 = -4 + _rng.nextInt(9);
        final r2 = -4 + _rng.nextInt(9);
        final s = r1 + r2;
        final p = r1 * r2;
        final mid = s >= 0 ? '− ${s}x' : '+ ${-s}x';
        final constTerm = p >= 0 ? '+ $p' : '− ${-p}';
        return _q(
          'x² $mid $constTerm = 0 · tổng nghiệm?',
          s,
          hint: 'Với x² − Sx + P = 0 thì tổng nghiệm = S.',
        );
      case 1:
        final a = 1 + _rng.nextInt(6);
        final x = -4 + _rng.nextInt(9);
        return _q('f(x)=${a}x² · f($x)=?', a * x * x, hint: 'Thay số vào hàm.');
      case 2:
        final a = 2 + _rng.nextInt(8);
        final b = 1 + _rng.nextInt(8);
        return _q('($a+$b)² = ?', (a + b) * (a + b), hint: 'Nhẩm (a+b)².');
      case 3:
        final a = 3 + _rng.nextInt(10);
        final b = 1 + _rng.nextInt(a - 1);
        return _q('($a−$b)($a+$b) = ?', a * a - b * b, hint: 'a² − b².');
      case 4:
        final n = 2 + _rng.nextInt(5);
        final base = 2 + _rng.nextInt(4);
        var v = 1;
        for (var i = 0; i < n; i++) {
          v *= base;
        }
        return _q('$base^$n = ?', v, hint: 'Lũy thừa nguyên dương.');
      default:
        final a = 1 + _rng.nextInt(5);
        final b = -8 + _rng.nextInt(17);
        final c = -10 + _rng.nextInt(21);
        // ask a*2+b when x=2 for ax+b, or value
        return _q('Với x=2, ${a}x + ($b) + ($c) = ?', a * 2 + b + c,
            hint: 'Thay x=2 rồi tính.');
    }
  }

  static GradeQuestion _q(String prompt, int answer, {String? hint}) {
    return GradeQuestion(
      prompt: prompt,
      answer: answer,
      choices: _choices(answer),
      storyHint: hint,
    );
  }

  static List<int> _choices(int answer) {
    final set = <int>{answer};
    var i = 0;
    while (set.length < 4 && i < 50) {
      i++;
      final delta = 1 + _rng.nextInt(12);
      set.add(_rng.nextBool() ? answer + delta : answer - delta);
    }
    while (set.length < 4) {
      set.add(answer + set.length * 3 + 1);
    }
    final list = set.toList()..shuffle(_rng);
    return list;
  }
}
