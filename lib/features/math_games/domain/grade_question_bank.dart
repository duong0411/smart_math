import 'dart:math';

/// Câu hỏi Toán lớp 8 (GDPT): căn bậc hai, đa thức, PT bậc nhất,
/// hệ PT, hàm số bậc nhất, Pythagore, hình học phẳng.
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

  static GradeQuestion nextGrade8() {
    final generators = <GradeQuestion Function()>[
      _perfectSquareRoot,
      _squareOfBinomial,
      _differenceOfSquares,
      _linearEquation,
      _linearEquationWithConstant,
      _evaluateLinearFunction,
      _slopeInterceptValue,
      _pythagoreanLeg,
      _pythagoreanHyp,
      _rhombusPerimeter,
      _rectangleArea,
      _systemSubstitutionX,
      _rationalAddSimple,
      _expandDistribute,
    ];
    return generators[_rng.nextInt(generators.length)]();
  }

  /// √(a²) với a dương.
  static GradeQuestion _perfectSquareRoot() {
    final a = 2 + _rng.nextInt(15);
    return _q(
      '√(${a * a}) = ?',
      a,
      hint: 'Căn bậc hai của số chính phương.',
    );
  }

  /// (a+b)² = a² + 2ab + b² — hỏi giá trị số.
  static GradeQuestion _squareOfBinomial() {
    final a = 2 + _rng.nextInt(8);
    final b = 1 + _rng.nextInt(6);
    return _q(
      '($a + $b)² = ?',
      (a + b) * (a + b),
      hint: 'Hằng đẳng thức (A + B)².',
    );
  }

  static GradeQuestion _differenceOfSquares() {
    final a = 4 + _rng.nextInt(10);
    final b = 1 + _rng.nextInt(a - 1);
    return _q(
      '($a − $b)($a + $b) = ?',
      a * a - b * b,
      hint: 'Hằng đẳng thức A² − B².',
    );
  }

  /// ax = b
  static GradeQuestion _linearEquation() {
    final a = 2 + _rng.nextInt(9);
    final x = -8 + _rng.nextInt(17);
    if (x == 0) return _linearEquation();
    return _q(
      '${a}x = ${a * x}  ⇒  x = ?',
      x,
      hint: 'Phương trình bậc nhất: chia cả hai vế cho $a.',
    );
  }

  /// ax + b = c
  static GradeQuestion _linearEquationWithConstant() {
    final a = 1 + _rng.nextInt(8);
    final x = -6 + _rng.nextInt(13);
    final b = -9 + _rng.nextInt(19);
    final c = a * x + b;
    final bStr = b >= 0 ? '+ $b' : '− ${-b}';
    return _q(
      '${a}x $bStr = $c  ⇒  x = ?',
      x,
      hint: 'Chuyển vế số hạng tự do rồi chia.',
    );
  }

  /// y = ax + b tại x0
  static GradeQuestion _evaluateLinearFunction() {
    final a = -4 + _rng.nextInt(9);
    if (a == 0) return _evaluateLinearFunction();
    final b = -8 + _rng.nextInt(17);
    final x = -3 + _rng.nextInt(7);
    final bStr = b >= 0 ? '+ $b' : '− ${-b}';
    return _q(
      'y = ${a}x $bStr · khi x = $x thì y = ?',
      a * x + b,
      hint: 'Hàm số bậc nhất: thay x vào biểu thức.',
    );
  }

  /// Hệ số góc / giá trị tăng khi x tăng 1
  static GradeQuestion _slopeInterceptValue() {
    final a = 1 + _rng.nextInt(9);
    return _q(
      'Đường thẳng y = ${a}x − 3: khi x tăng 1 thì y tăng bao nhiêu?',
      a,
      hint: 'Hệ số góc của y = ax + b chính là a.',
    );
  }

  /// a² + b² = c² → tìm một cạnh góc vuông
  static GradeQuestion _pythagoreanLeg() {
    const triples = [
      [3, 4, 5],
      [5, 12, 13],
      [6, 8, 10],
      [8, 15, 17],
      [7, 24, 25],
      [9, 12, 15],
    ];
    final t = triples[_rng.nextInt(triples.length)];
    final askA = _rng.nextBool();
    if (askA) {
      return _q(
        'Tam giác vuông: một cạnh góc vuông ${t[1]}, cạnh huyền ${t[2]}. Cạnh góc vuông còn lại?',
        t[0],
        hint: 'Định lý Pythagore: a² + b² = c².',
      );
    }
    return _q(
      'Tam giác vuông: một cạnh góc vuông ${t[0]}, cạnh huyền ${t[2]}. Cạnh góc vuông còn lại?',
      t[1],
      hint: 'Định lý Pythagore: a² + b² = c².',
    );
  }

  static GradeQuestion _pythagoreanHyp() {
    const triples = [
      [3, 4, 5],
      [5, 12, 13],
      [6, 8, 10],
      [8, 15, 17],
      [9, 12, 15],
    ];
    final t = triples[_rng.nextInt(triples.length)];
    return _q(
      'Tam giác vuông có hai cạnh góc vuông ${t[0]} và ${t[1]}. Cạnh huyền?',
      t[2],
      hint: 'c = √(a² + b²) — nhớ bộ số Pythagore.',
    );
  }

  static GradeQuestion _rhombusPerimeter() {
    final side = 3 + _rng.nextInt(15);
    return _q(
      'Chu vi hình thoi cạnh $side là?',
      4 * side,
      hint: 'Hình thoi có 4 cạnh bằng nhau.',
    );
  }

  static GradeQuestion _rectangleArea() {
    final l = 5 + _rng.nextInt(14);
    final w = 3 + _rng.nextInt(12);
    return _q(
      'Diện tích hình chữ nhật $l × $w là?',
      l * w,
      hint: 'S = dài × rộng.',
    );
  }

  /// Hệ đơn giản: x + y = s ; x − y = d → x = (s+d)/2
  static GradeQuestion _systemSubstitutionX() {
    final x = 1 + _rng.nextInt(12);
    final y = 1 + _rng.nextInt(12);
    final s = x + y;
    final d = x - y;
    final dStr = d >= 0 ? '$d' : '($d)';
    return _q(
      'Hệ: x + y = $s và x − y = $dStr. Tìm x.',
      x,
      hint: 'Cộng hai phương trình: 2x = tổng hai vế phải.',
    );
  }

  /// √a + √a = 2√a — hỏi hệ số khi a là số chính phương nhỏ, hoặc √9+√16
  static GradeQuestion _rationalAddSimple() {
    final a = [4, 9, 16, 25, 36][_rng.nextInt(5)];
    final b = [4, 9, 16, 25, 36][_rng.nextInt(5)];
    final ans = _isqrt(a) + _isqrt(b);
    return _q(
      '√$a + √$b = ?',
      ans,
      hint: 'Rút căn từng số chính phương rồi cộng.',
    );
  }

  /// a(x + b) với x cho trước, hoặc khai triển hỏi hệ số — dùng giá trị số
  static GradeQuestion _expandDistribute() {
    final a = 2 + _rng.nextInt(8);
    final b = 1 + _rng.nextInt(9);
    final x = 1 + _rng.nextInt(8);
    return _q(
      'Giá trị $a(x + $b) khi x = $x là?',
      a * (x + b),
      hint: 'Nhân phân phối rồi thay số (đa thức lớp 8).',
    );
  }

  static int _isqrt(int n) {
    var r = 0;
    while ((r + 1) * (r + 1) <= n) {
      r++;
    }
    return r;
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
    while (set.length < 4 && i < 60) {
      i++;
      final delta = 1 + _rng.nextInt(14);
      set.add(_rng.nextBool() ? answer + delta : answer - delta);
    }
    while (set.length < 4) {
      set.add(answer + set.length * 3 + 1);
    }
    final list = set.toList()..shuffle(_rng);
    return list;
  }
}
