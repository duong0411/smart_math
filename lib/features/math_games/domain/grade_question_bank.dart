import 'dart:math';

import 'package:eduself_study_app/shared/utils/supported_grades.dart';

/// Câu hỏi Toán THCS bám SGK **Kết nối tri thức với cuộc sống** (lớp 6–9).
/// Chỉ dùng đáp án số nguyên để phù hợp chọn đáp án trong game.
class GradeQuestion {
  const GradeQuestion({
    required this.prompt,
    required this.answer,
    required this.choices,
    this.storyHint,
    this.chapter,
  });

  final String prompt;
  final int answer;
  final List<int> choices;
  final String? storyHint;
  final String? chapter;
}

abstract final class GradeQuestionBank {
  static final _rng = Random();

  /// Chapters đúng KNTT theo lớp — dùng để kiểm thử không lẫn kiến thức.
  static const knttChaptersByGrade = <int, Set<String>>{
    6: {
      'Số nguyên',
      'Phần trăm',
      'Tỉ lệ',
      'Phương trình',
      'Hình phẳng',
    },
    7: {
      'Biểu thức',
      'Lũy thừa',
      'Tam giác',
      'Tỉ lệ thức',
      'Căn bậc hai số học',
      'Đa thức một biến',
    },
    8: {
      'Ch1 · Đa thức',
      'Ch2 · Hằng đẳng thức',
      'Ch2 · Phân tích nhân tử',
      'Ch3 · Tứ giác',
      'Ch4 · Đường trung bình',
      'Ch5 · Thống kê',
      'Ch6 · Phân thức',
      'Ch7 · PT bậc nhất',
      'Ch7 · Lập phương trình',
      'Ch7 · Hàm số bậc nhất',
      'Ch7 · Hệ số góc',
      'Ch8 · Xác suất',
      'Ch9 · Đồng dạng',
      'Ch9 · Pythagore',
      'Ch10 · Hình chóp',
    },
    9: {
      'Ch1 · Hệ PT',
      'Ch2 · Bất phương trình',
      'Ch3 · Căn bậc hai',
      'Ch3 · Căn bậc ba',
      'Ch4 · Lượng giác',
      'Ch5 · Đường tròn',
      'Ch6 · PT bậc hai',
      'Ch6 · Hàm số y = ax²',
      'Ch10 · Hình trụ',
    },
  };

  /// Câu hỏi ngẫu nhiên theo lớp 6–9 (ngoài khoảng → lớp 8).
  static GradeQuestion next(int gradeLevel) {
    final grade = SupportedGrades.normalize(gradeLevel);
    final generators = _generatorsFor(grade);
    return generators[_rng.nextInt(generators.length)]();
  }

  /// Sinh bộ câu hỏi trắc nghiệm ôn tập (đáp án đã xáo thứ tự).
  static List<GradeQuestion> pickQuestions({
    required int count,
    required int gradeLevel,
  }) {
    final grade = SupportedGrades.normalize(gradeLevel);
    final n = count.clamp(1, 40);
    final seen = <String>{};
    final out = <GradeQuestion>[];
    var guard = 0;
    while (out.length < n && guard < n * 40) {
      guard++;
      final q = next(grade);
      final key = '${q.prompt}|${q.answer}';
      if (seen.add(key)) out.add(q);
    }
    while (out.length < n) {
      out.add(next(grade));
    }
    return out;
  }

  @Deprecated('Dùng GradeQuestionBank.next(8)')
  static GradeQuestion nextGrade8() => next(8);

  static String bandLabel(int gradeLevel) => 'KNTT';

  static String curriculumHint(int gradeLevel) {
    final g = SupportedGrades.normalize(gradeLevel);
    return switch (g) {
      6 => 'SGK KNTT lớp 6: số nguyên, tỉ lệ, phần trăm, hình phẳng.',
      7 =>
        'SGK KNTT lớp 7: biểu thức, lũy thừa, tỉ lệ thức, tam giác, căn bậc hai số học.',
      8 =>
        'SGK KNTT lớp 8: đa thức, hằng đẳng thức, phân thức, PT/hàm bậc nhất, đồng dạng, Pythagore, hình chóp.',
      _ =>
        'SGK KNTT lớp 9: hệ PT, căn, lượng giác, đường tròn, PT bậc hai, hình trụ.',
    };
  }

  static List<GradeQuestion Function()> _generatorsFor(int grade) {
    return switch (grade) {
      6 => _grade6Generators,
      7 => _grade7Generators,
      9 => _grade9Generators,
      _ => _grade8Generators,
    };
  }

  // —— Lớp 6 (KNTT) ——
  static final List<GradeQuestion Function()> _grade6Generators = [
    _intAdd,
    _intMul,
    _percentOf,
    _ratioValue,
    _simpleLinear,
    _rectanglePerimeterG6,
    _squareAreaG6,
  ];

  // —— Lớp 7 (KNTT) ——
  static final List<GradeQuestion Function()> _grade7Generators = [
    _exprValue,
    _powerValue,
    _triangleAngleSum,
    _proportion,
    _sqrtPerfectG7,
    _monoDegreeOneVar,
  ];

  // —— Lớp 8 (KNTT) ——
  static final List<GradeQuestion Function()> _grade8Generators = [
    _monomialDegree,
    _polyAddCoeff,
    _polyMultiplyValue,
    _identityDiffSquares,
    _identitySquareSum,
    _identitySquareDiff,
    _factorCommon,
    _rectanglePerimeter,
    _rhombusPerimeter,
    _parallelogramArea,
    _squareAreaG8,
    _thalesMidline,
    _statsMean,
    _statsRange,
    _rationalSimplifyValue,
    _rationalAddSameDen,
    _linearEquation,
    _linearEquationWithConst,
    _wordLinearAge,
    _functionValue,
    _slopeOfLine,
    _probabilityFavorable,
    _similarTriangleSide,
    _pythagoreanLeg,
    _pythagoreanHyp,
    _pyramidEdges,
  ];

  // —— Lớp 9 (KNTT) —— chỉ chương lớp 9, không lấy trọng tâm lớp 8
  static final List<GradeQuestion Function()> _grade9Generators = [
    _systemSum,
    _inequalityMaxInt,
    _sqrtPerfectG9,
    _cubeRootPerfect,
    _trigTan45,
    _trigSin30Times,
    _circleCircumferenceCoeff,
    _circleDiameter,
    _quadraticRootSum,
    _quadraticProduct,
    _parabolaValue,
    _cylinderLateralCoeff,
  ];

  // ========== Lớp 6 ==========

  static GradeQuestion _percentOf() {
    final p = [10, 20, 25, 50][_rng.nextInt(4)];
    final whole = [20, 40, 60, 80, 100][_rng.nextInt(5)];
    return _q(
      '$p% của $whole là?',
      whole * p ~/ 100,
      chapter: 'Phần trăm',
      hint: 'a% của N = a × N / 100.',
    );
  }

  static GradeQuestion _intAdd() {
    final a = -20 + _rng.nextInt(41);
    final b = -20 + _rng.nextInt(41);
    final bStr = b >= 0 ? '+ $b' : '− ${-b}';
    return _q(
      '$a $bStr = ?',
      a + b,
      chapter: 'Số nguyên',
      hint: 'Cộng đại số.',
    );
  }

  static GradeQuestion _intMul() {
    final a = -8 + _rng.nextInt(17);
    if (a == 0) return _intMul();
    final b = -8 + _rng.nextInt(17);
    if (b == 0) return _intMul();
    return _q(
      '($a) × ($b) = ?',
      a * b,
      chapter: 'Số nguyên',
      hint: 'Cùng dấu dương, trái dấu âm.',
    );
  }

  static GradeQuestion _ratioValue() {
    final a = 2 + _rng.nextInt(6);
    final b = 2 + _rng.nextInt(6);
    final k = 2 + _rng.nextInt(5);
    return _q(
      'Tỉ số $a : $b. Nếu số thứ nhất = ${a * k} thì số thứ hai?',
      b * k,
      chapter: 'Tỉ lệ',
      hint: 'Nhân cùng một số k.',
    );
  }

  static GradeQuestion _simpleLinear() {
    final a = 2 + _rng.nextInt(8);
    final x = 1 + _rng.nextInt(12);
    return _q(
      '${a}x = ${a * x}  ⇒  x = ?',
      x,
      chapter: 'Phương trình',
      hint: 'Chia cả hai vế cho $a.',
    );
  }

  static GradeQuestion _rectanglePerimeterG6() {
    final l = 5 + _rng.nextInt(12);
    final w = 3 + _rng.nextInt(10);
    return _q(
      'Chu vi hình chữ nhật kích thước $l × $w là?',
      2 * (l + w),
      chapter: 'Hình phẳng',
      hint: 'Chu vi HCN = 2(dài + rộng).',
    );
  }

  static GradeQuestion _squareAreaG6() {
    final a = 3 + _rng.nextInt(10);
    return _q(
      'Diện tích hình vuông cạnh $a là?',
      a * a,
      chapter: 'Hình phẳng',
      hint: 'S = a².',
    );
  }

  // ========== Lớp 7 ==========

  static GradeQuestion _exprValue() {
    final a = 1 + _rng.nextInt(8);
    final b = 1 + _rng.nextInt(8);
    final x = 1 + _rng.nextInt(6);
    return _q(
      'Giá trị ${a}x + $b khi x = $x?',
      a * x + b,
      chapter: 'Biểu thức',
      hint: 'Thay x rồi tính.',
    );
  }

  static GradeQuestion _powerValue() {
    final a = 2 + _rng.nextInt(5);
    final n = 2 + _rng.nextInt(3);
    var value = 1;
    for (var i = 0; i < n; i++) {
      value *= a;
    }
    return _q(
      '$a^$n = ?',
      value,
      chapter: 'Lũy thừa',
      hint: 'Nhân $a với chính nó $n lần.',
    );
  }

  static GradeQuestion _triangleAngleSum() {
    final a = 30 + _rng.nextInt(60);
    final b = 20 + _rng.nextInt(70);
    if (a + b >= 170) return _triangleAngleSum();
    final c = 180 - a - b;
    return _q(
      'Tam giác có hai góc $a° và $b°. Góc thứ ba?',
      c,
      chapter: 'Tam giác',
      hint: 'Tổng 3 góc = 180°.',
    );
  }

  static GradeQuestion _proportion() {
    final a = 2 + _rng.nextInt(8);
    final b = 2 + _rng.nextInt(8);
    final k = 2 + _rng.nextInt(6);
    return _q(
      'a/b = $a/$b. Nếu a = ${a * k} thì b = ?',
      b * k,
      chapter: 'Tỉ lệ thức',
      hint: 'Hai tỉ số bằng nhau.',
    );
  }

  /// KNTT lớp 7 Ch2 — căn bậc hai số học (số chính phương).
  static GradeQuestion _sqrtPerfectG7() {
    final a = 2 + _rng.nextInt(12);
    return _q(
      'Căn bậc hai số học của ${a * a} bằng?',
      a,
      chapter: 'Căn bậc hai số học',
      hint: '√(a²) = a với a > 0.',
    );
  }

  static GradeQuestion _monoDegreeOneVar() {
    final n = 1 + _rng.nextInt(5);
    final a = 2 + _rng.nextInt(6);
    return _q(
      'Bậc của đa thức ${a}x^$n (một biến) là?',
      n,
      chapter: 'Đa thức một biến',
      hint: 'Bậc = số mũ cao nhất.',
    );
  }

  // ========== Lớp 8 ==========

  static GradeQuestion _monomialDegree() {
    final a = 2 + _rng.nextInt(5);
    final b = 1 + _rng.nextInt(4);
    return _q(
      'Bậc của đơn thức ${a}x^$b là?',
      b,
      chapter: 'Ch1 · Đa thức',
      hint: 'Bậc đơn thức = tổng số mũ các biến.',
    );
  }

  static GradeQuestion _polyAddCoeff() {
    final a = 1 + _rng.nextInt(9);
    final b = 1 + _rng.nextInt(9);
    final c = 1 + _rng.nextInt(9);
    final d = 1 + _rng.nextInt(9);
    return _q(
      'Hệ số của x trong ($a x + $b) + ($c x + $d) là?',
      a + c,
      chapter: 'Ch1 · Đa thức',
      hint: 'Cộng các hạng tử đồng dạng.',
    );
  }

  static GradeQuestion _polyMultiplyValue() {
    final a = 2 + _rng.nextInt(6);
    final b = 1 + _rng.nextInt(5);
    final x = 1 + _rng.nextInt(5);
    return _q(
      'Giá trị ${a}x(x + $b) khi x = $x là?',
      a * x * (x + b),
      chapter: 'Ch1 · Đa thức',
      hint: 'Nhân phân phối rồi thay số.',
    );
  }

  static GradeQuestion _identityDiffSquares() {
    final a = 4 + _rng.nextInt(10);
    final b = 1 + _rng.nextInt(a - 1);
    return _q(
      '($a − $b)($a + $b) = ?',
      a * a - b * b,
      chapter: 'Ch2 · Hằng đẳng thức',
      hint: 'A² − B² = (A − B)(A + B).',
    );
  }

  static GradeQuestion _identitySquareSum() {
    final a = 2 + _rng.nextInt(8);
    final b = 1 + _rng.nextInt(6);
    return _q(
      '($a + $b)² = ?',
      (a + b) * (a + b),
      chapter: 'Ch2 · Hằng đẳng thức',
      hint: '(A + B)² = A² + 2AB + B².',
    );
  }

  static GradeQuestion _identitySquareDiff() {
    final a = 5 + _rng.nextInt(8);
    final b = 1 + _rng.nextInt(4);
    return _q(
      '($a − $b)² = ?',
      (a - b) * (a - b),
      chapter: 'Ch2 · Hằng đẳng thức',
      hint: '(A − B)² = A² − 2AB + B².',
    );
  }

  static GradeQuestion _factorCommon() {
    final a = 4 + _rng.nextInt(20);
    final b = 4 + _rng.nextInt(20);
    final g = _gcd(a, b);
    return _q(
      'Đặt nhân tử chung của ${a}x + $b (số nguyên dương lớn nhất) là?',
      g,
      chapter: 'Ch2 · Phân tích nhân tử',
      hint: 'Tìm ước chung lớn nhất của các hệ số.',
    );
  }

  static int _gcd(int a, int b) {
    var x = a.abs();
    var y = b.abs();
    while (y != 0) {
      final t = x % y;
      x = y;
      y = t;
    }
    return x == 0 ? 1 : x;
  }

  static GradeQuestion _rectanglePerimeter() {
    final l = 5 + _rng.nextInt(12);
    final w = 3 + _rng.nextInt(10);
    return _q(
      'Chu vi hình chữ nhật kích thước $l × $w là?',
      2 * (l + w),
      chapter: 'Ch3 · Tứ giác',
      hint: 'Chu vi HCN = 2(dài + rộng).',
    );
  }

  static GradeQuestion _rhombusPerimeter() {
    final side = 3 + _rng.nextInt(14);
    return _q(
      'Chu vi hình thoi cạnh $side là?',
      4 * side,
      chapter: 'Ch3 · Tứ giác',
      hint: 'Hình thoi có 4 cạnh bằng nhau.',
    );
  }

  static GradeQuestion _parallelogramArea() {
    final base = 4 + _rng.nextInt(12);
    final height = 3 + _rng.nextInt(10);
    return _q(
      'Diện tích hình bình hành đáy $base, chiều cao $height là?',
      base * height,
      chapter: 'Ch3 · Tứ giác',
      hint: 'S = đáy × chiều cao.',
    );
  }

  static GradeQuestion _squareAreaG8() {
    final a = 3 + _rng.nextInt(10);
    return _q(
      'Diện tích hình vuông cạnh $a là?',
      a * a,
      chapter: 'Ch3 · Tứ giác',
      hint: 'Hình vuông: S = a².',
    );
  }

  static GradeQuestion _thalesMidline() {
    final base = 2 * (4 + _rng.nextInt(12));
    return _q(
      'Đường trung bình của tam giác song song cạnh đáy $base thì dài bao nhiêu?',
      base ~/ 2,
      chapter: 'Ch4 · Đường trung bình',
      hint: 'Đường trung bình = 1/2 cạnh thứ ba.',
    );
  }

  static GradeQuestion _statsMean() {
    final a = 4 + _rng.nextInt(10);
    final b = 4 + _rng.nextInt(10);
    final c = 4 + _rng.nextInt(10);
    final d = 4 + _rng.nextInt(10);
    final sum = a + b + c + d;
    final adj = sum % 4;
    final d2 = d - adj + (adj == 0 ? 0 : 4);
    final mean = (a + b + c + d2) ~/ 4;
    return _q(
      'Trung bình cộng của $a, $b, $c, $d2 là?',
      mean,
      chapter: 'Ch5 · Thống kê',
      hint: 'Trung bình = tổng chia số số liệu.',
    );
  }

  static GradeQuestion _statsRange() {
    final values = List.generate(5, (_) => 5 + _rng.nextInt(30))..sort();
    final range = values.last - values.first;
    return _q(
      'Khoảng biến thiên của ${values.join(', ')} là?',
      range,
      chapter: 'Ch5 · Thống kê',
      hint: 'Khoảng biến thiên = max − min.',
    );
  }

  static GradeQuestion _rationalSimplifyValue() {
    final k = 2 + _rng.nextInt(6);
    final a = 2 + _rng.nextInt(8);
    return _q(
      'Rút gọn phân thức ${k * a}/$k được tử số (mẫu = 1) là?',
      a,
      chapter: 'Ch6 · Phân thức',
      hint: 'Chia tử và mẫu cho ước chung.',
    );
  }

  static GradeQuestion _rationalAddSameDen() {
    final d = 2 + _rng.nextInt(9);
    final a = 1 + _rng.nextInt(8);
    final b = 1 + _rng.nextInt(8);
    return _q(
      'Tử số của $a/$d + $b/$d (sau khi cùng mẫu $d) là?',
      a + b,
      chapter: 'Ch6 · Phân thức',
      hint: 'Cùng mẫu: cộng tử, giữ mẫu.',
    );
  }

  static GradeQuestion _linearEquation() {
    final a = 2 + _rng.nextInt(9);
    final x = -8 + _rng.nextInt(17);
    if (x == 0) return _linearEquation();
    return _q(
      '${a}x = ${a * x}  ⇒  x = ?',
      x,
      chapter: 'Ch7 · PT bậc nhất',
      hint: 'Chia cả hai vế cho hệ số của x.',
    );
  }

  static GradeQuestion _linearEquationWithConst() {
    final a = 1 + _rng.nextInt(8);
    final x = -6 + _rng.nextInt(13);
    final b = -9 + _rng.nextInt(19);
    final c = a * x + b;
    final bStr = b >= 0 ? '+ $b' : '− ${-b}';
    return _q(
      '${a}x $bStr = $c  ⇒  x = ?',
      x,
      chapter: 'Ch7 · PT bậc nhất',
      hint: 'Chuyển vế số hạng tự do rồi chia.',
    );
  }

  static GradeQuestion _wordLinearAge() {
    final child = 8 + _rng.nextInt(12);
    const diff = 25;
    final total = child + (child + diff);
    return _q(
      'Tuổi con là x, bố hơn con $diff tuổi, tổng hai tuổi = $total. Tìm x.',
      child,
      chapter: 'Ch7 · Lập phương trình',
      hint: 'x + (x + $diff) = $total.',
    );
  }

  static GradeQuestion _functionValue() {
    final a = -4 + _rng.nextInt(9);
    if (a == 0) return _functionValue();
    final b = -8 + _rng.nextInt(17);
    final x = -3 + _rng.nextInt(7);
    final bStr = b >= 0 ? '+ $b' : '− ${-b}';
    return _q(
      'y = ${a}x $bStr · khi x = $x thì y = ?',
      a * x + b,
      chapter: 'Ch7 · Hàm số bậc nhất',
      hint: 'Thay x vào biểu thức hàm số.',
    );
  }

  static GradeQuestion _slopeOfLine() {
    final a = 1 + _rng.nextInt(9);
    return _q(
      'Đường thẳng y = ${a}x − 2 có hệ số góc bằng?',
      a,
      chapter: 'Ch7 · Hệ số góc',
      hint: 'Với y = ax + b, hệ số góc là a.',
    );
  }

  static GradeQuestion _probabilityFavorable() {
    final total = [6, 8, 10, 12][_rng.nextInt(4)];
    final fav = 1 + _rng.nextInt(total - 1);
    return _q(
      'Có $total kết quả khả dĩ, xác suất = $fav/$total. Số kết quả thuận lợi?',
      fav,
      chapter: 'Ch8 · Xác suất',
      hint: 'P = (số thuận lợi) / (số khả dĩ).',
    );
  }

  static GradeQuestion _similarTriangleSide() {
    final k = 2 + _rng.nextInt(4);
    final small = 3 + _rng.nextInt(6);
    return _q(
      'Hai tam giác đồng dạng tỉ số $k : 1. Cạnh nhỏ $small thì cạnh tương ứng?',
      small * k,
      chapter: 'Ch9 · Đồng dạng',
      hint: 'Cạnh tương ứng tỉ lệ với tỉ số đồng dạng.',
    );
  }

  static GradeQuestion _pythagoreanLeg() {
    const triples = [
      [3, 4, 5],
      [5, 12, 13],
      [6, 8, 10],
      [8, 15, 17],
      [9, 12, 15],
    ];
    final t = triples[_rng.nextInt(triples.length)];
    final askA = _rng.nextBool();
    if (askA) {
      return _q(
        'Tam giác vuông: cạnh góc vuông ${t[1]}, cạnh huyền ${t[2]}. Cạnh góc vuông còn lại?',
        t[0],
        chapter: 'Ch9 · Pythagore',
        hint: 'a² + b² = c² (KNTT lớp 8).',
      );
    }
    return _q(
      'Tam giác vuông: cạnh góc vuông ${t[0]}, cạnh huyền ${t[2]}. Cạnh góc vuông còn lại?',
      t[1],
      chapter: 'Ch9 · Pythagore',
      hint: 'a² + b² = c² (KNTT lớp 8).',
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
      chapter: 'Ch9 · Pythagore',
      hint: 'c² = a² + b² (không dùng căn thức lớp 9).',
    );
  }

  static GradeQuestion _pyramidEdges() {
    final isTri = _rng.nextBool();
    if (isTri) {
      return _q(
        'Hình chóp tam giác đều có bao nhiêu cạnh?',
        6,
        chapter: 'Ch10 · Hình chóp',
        hint: 'Đáy 3 cạnh + 3 cạnh bên.',
      );
    }
    return _q(
      'Hình chóp tứ giác đều có bao nhiêu cạnh?',
      8,
      chapter: 'Ch10 · Hình chóp',
      hint: 'Đáy 4 cạnh + 4 cạnh bên.',
    );
  }

  // ========== Lớp 9 ==========

  static GradeQuestion _systemSum() {
    final x = 1 + _rng.nextInt(9);
    final y = 1 + _rng.nextInt(9);
    return _q(
      'Hệ: x + y = ${x + y}, x − y = ${x - y}. Tìm x.',
      x,
      chapter: 'Ch1 · Hệ PT',
      hint: 'Cộng hai phương trình: 2x = …',
    );
  }

  static GradeQuestion _inequalityMaxInt() {
    final bound = 3 + _rng.nextInt(12);
    return _q(
      'Nghiệm nguyên lớn nhất của x < $bound là?',
      bound - 1,
      chapter: 'Ch2 · Bất phương trình',
      hint: 'x thuộc các số nguyên nhỏ hơn $bound.',
    );
  }

  static GradeQuestion _sqrtPerfectG9() {
    final a = 2 + _rng.nextInt(12);
    return _q(
      '√${a * a} = ?',
      a,
      chapter: 'Ch3 · Căn bậc hai',
      hint: '√(a²) = |a| (a > 0).',
    );
  }

  static GradeQuestion _cubeRootPerfect() {
    final a = 2 + _rng.nextInt(5);
    return _q(
      '∛${a * a * a} = ?',
      a,
      chapter: 'Ch3 · Căn bậc ba',
      hint: '∛(a³) = a.',
    );
  }

  static GradeQuestion _trigTan45() {
    return _q(
      'tan 45° = ?',
      1,
      chapter: 'Ch4 · Lượng giác',
      hint: 'tan 45° = 1.',
    );
  }

  static GradeQuestion _trigSin30Times() {
    final k = 2 + _rng.nextInt(10);
    // sin 30° = 1/2 → k · sin 30° = k/2; chỉ lấy k chẵn
    final even = k.isEven ? k : k + 1;
    return _q(
      '$even × sin 30° = ?',
      even ~/ 2,
      chapter: 'Ch4 · Lượng giác',
      hint: 'sin 30° = 1/2.',
    );
  }

  static GradeQuestion _circleCircumferenceCoeff() {
    final r = 2 + _rng.nextInt(12);
    return _q(
      'Chu vi đường tròn bán kính $r bằng kπ. k = ?',
      2 * r,
      chapter: 'Ch5 · Đường tròn',
      hint: 'C = 2πr.',
    );
  }

  static GradeQuestion _circleDiameter() {
    final r = 2 + _rng.nextInt(15);
    return _q(
      'Đường kính đường tròn bán kính $r bằng?',
      2 * r,
      chapter: 'Ch5 · Đường tròn',
      hint: 'd = 2r.',
    );
  }

  static GradeQuestion _quadraticRootSum() {
    final p = -5 + _rng.nextInt(11);
    final q = -5 + _rng.nextInt(11);
    if (p == 0 && q == 0) return _quadraticRootSum();
    final b = -(p + q);
    final c = p * q;
    final bStr = b >= 0 ? '+ $b' : '− ${-b}';
    final cStr = c >= 0 ? '+ $c' : '− ${-c}';
    return _q(
      'Tổng nghiệm của x² $bStr x $cStr = 0 là?',
      p + q,
      chapter: 'Ch6 · PT bậc hai',
      hint: 'Định lí Viète (KNTT lớp 9): tổng nghiệm = −(hệ số của x).',
    );
  }

  static GradeQuestion _quadraticProduct() {
    final p = -5 + _rng.nextInt(11);
    final q = -5 + _rng.nextInt(11);
    if (p == 0 && q == 0) return _quadraticProduct();
    final b = -(p + q);
    final c = p * q;
    final bStr = b >= 0 ? '+ $b' : '− ${-b}';
    final cStr = c >= 0 ? '+ $c' : '− ${-c}';
    return _q(
      'Tích nghiệm của x² $bStr x $cStr = 0 là?',
      p * q,
      chapter: 'Ch6 · PT bậc hai',
      hint: 'Định lí Viète: tích nghiệm = c.',
    );
  }

  static GradeQuestion _parabolaValue() {
    final a = 1 + _rng.nextInt(4);
    final x = 1 + _rng.nextInt(5);
    return _q(
      'y = ${a}x² khi x = $x thì y = ?',
      a * x * x,
      chapter: 'Ch6 · Hàm số y = ax²',
      hint: 'Thay x vào y = ax².',
    );
  }

  static GradeQuestion _cylinderLateralCoeff() {
    // Sxq = 2πrh → hỏi hệ số của π khi r,h nguyên
    final r = 2 + _rng.nextInt(8);
    final h = 2 + _rng.nextInt(10);
    return _q(
      'Diện tích xung quanh hình trụ bán kính $r, chiều cao $h bằng kπ. k = ?',
      2 * r * h,
      chapter: 'Ch10 · Hình trụ',
      hint: 'Sxq = 2πrh.',
    );
  }

  static GradeQuestion _q(
    String prompt,
    int answer, {
    String? hint,
    String? chapter,
  }) {
    return GradeQuestion(
      prompt: prompt,
      answer: answer,
      choices: _choices(answer),
      storyHint: [
        ?chapter,
        ?hint,
      ].join(' · '),
      chapter: chapter,
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
