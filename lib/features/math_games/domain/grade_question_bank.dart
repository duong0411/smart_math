import 'dart:math';

/// Câu hỏi Toán theo chương trình GDPT Việt Nam (lớp 1–12).
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

  /// Câu hỏi ngẫu nhiên theo lớp (1–12). Lớp ngoài khoảng được kẹp về 1–12.
  static GradeQuestion next(int gradeLevel) {
    final grade = gradeLevel.clamp(1, 12);
    final generators = _generatorsFor(grade);
    return generators[_rng.nextInt(generators.length)]();
  }

  @Deprecated('Dùng GradeQuestionBank.next(8)')
  static GradeQuestion nextGrade8() => next(8);

  static String bandLabel(int gradeLevel) {
    final g = gradeLevel.clamp(1, 12);
    if (g <= 5) return 'Tiểu học';
    if (g <= 9) return 'THCS';
    return 'THPT';
  }

  static String curriculumHint(int gradeLevel) {
    final g = gradeLevel.clamp(1, 12);
    return switch (g) {
      1 || 2 => 'Cộng trừ trong phạm vi đã học, đếm số.',
      3 || 4 => 'Nhân chia, chu vi, phân số đơn giản.',
      5 => 'Phân số, diện tích, thể tích khối lập phương.',
      6 => 'Số nguyên, tỉ lệ, phần trăm, phương trình đơn giản.',
      7 => 'Biểu thức, tỉ lệ thức, góc trong tam giác, lũy thừa.',
      8 => 'Đa thức, hằng đẳng thức, PT bậc nhất, Pythagore…',
      9 => 'Căn bậc hai, PT bậc hai, hệ PT, đường tròn.',
      10 => 'Hàm số, phương trình, lượng giác giá trị đặc biệt.',
      11 => 'Tổ hợp, cấp số, logarit cơ bản, xác suất.',
      _ => 'Dãy số, tổ hợp, xác suất, hàm số nâng cao.',
    };
  }

  static List<GradeQuestion Function()> _generatorsFor(int grade) {
    return switch (grade) {
      1 => [_addSmall, _subSmall, _countForward],
      2 => [_addSmall, _subSmall, _addTens, _doubleNumber],
      3 => [_mulSmall, _divExact, _rectPerimeter, _addThree],
      4 => [_mulSmall, _divExact, _rectArea, _rectPerimeter, _fractionOf],
      5 => [_rectArea, _cubeVolume, _fractionOf, _percentOf, _divExact],
      6 => [
          _intAdd,
          _intMul,
          _percentOf,
          _ratioValue,
          _simpleLinear,
        ],
      7 => [
          _exprValue,
          _powerValue,
          _triangleAngleSum,
          _proportion,
          _simpleLinear,
          _intMul,
        ],
      8 => _grade8Generators,
      9 => [
          _sqrtPerfect,
          _quadraticRootSum,
          _systemSum,
          _circleCircumferenceCoeff,
          _pythagoreanHyp,
          _pythagoreanLeg,
          _identityDiffSquares,
        ],
      10 => [
          _trigSpecial,
          _linearFunctionValue,
          _slopeOfLine,
          _quadraticRootSum,
          _arithmeticTerm,
          _powerValue,
        ],
      11 => [
          _combinationC,
          _permutationP,
          _arithmeticTerm,
          _geometricTerm,
          _logBasePower,
          _probabilityFavorable,
        ],
      _ => [
          _combinationC,
          _permutationP,
          _arithmeticTerm,
          _geometricTerm,
          _probabilityFavorable,
          _limitSequenceSimple,
          _trigSpecial,
        ],
    };
  }

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
    _squareDiagonalRelated,
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

  // —— Lớp 1–2 ——
  static GradeQuestion _addSmall() {
    final a = 1 + _rng.nextInt(9);
    final b = 1 + _rng.nextInt(10 - a);
    return _q('$a + $b = ?', a + b, chapter: 'Cộng', hint: 'Cộng hai số.');
  }

  static GradeQuestion _subSmall() {
    final a = 5 + _rng.nextInt(10);
    final b = 1 + _rng.nextInt(a);
    return _q('$a − $b = ?', a - b, chapter: 'Trừ', hint: 'Trừ số nhỏ hơn.');
  }

  static GradeQuestion _countForward() {
    final a = 1 + _rng.nextInt(18);
    return _q(
      'Số liền sau của $a là?',
      a + 1,
      chapter: 'Đếm số',
      hint: 'Số liền sau = số đó + 1.',
    );
  }

  static GradeQuestion _addTens() {
    final a = 10 * (1 + _rng.nextInt(5));
    final b = 10 * (1 + _rng.nextInt(4));
    return _q('$a + $b = ?', a + b, chapter: 'Cộng', hint: 'Cộng các chục.');
  }

  static GradeQuestion _doubleNumber() {
    final a = 2 + _rng.nextInt(15);
    return _q(
      'Gấp đôi của $a là?',
      a * 2,
      chapter: 'Nhân 2',
      hint: 'Gấp đôi = nhân 2.',
    );
  }

  // —— Lớp 3–5 ——
  static GradeQuestion _mulSmall() {
    final a = 2 + _rng.nextInt(9);
    final b = 2 + _rng.nextInt(9);
    return _q('$a × $b = ?', a * b, chapter: 'Nhân', hint: 'Bảng nhân.');
  }

  static GradeQuestion _divExact() {
    final b = 2 + _rng.nextInt(9);
    final q = 2 + _rng.nextInt(10);
    final a = b * q;
    return _q('$a ÷ $b = ?', q, chapter: 'Chia', hint: 'Chia hết.');
  }

  static GradeQuestion _addThree() {
    final a = 1 + _rng.nextInt(20);
    final b = 1 + _rng.nextInt(20);
    final c = 1 + _rng.nextInt(20);
    return _q(
      '$a + $b + $c = ?',
      a + b + c,
      chapter: 'Cộng',
      hint: 'Cộng lần lượt.',
    );
  }

  static GradeQuestion _rectPerimeter() {
    final l = 4 + _rng.nextInt(12);
    final w = 2 + _rng.nextInt(10);
    return _q(
      'Chu vi HCN $l × $w là?',
      2 * (l + w),
      chapter: 'Chu vi',
      hint: 'P = 2(dài + rộng).',
    );
  }

  static GradeQuestion _rectArea() {
    final l = 3 + _rng.nextInt(12);
    final w = 2 + _rng.nextInt(10);
    return _q(
      'Diện tích HCN $l × $w là?',
      l * w,
      chapter: 'Diện tích',
      hint: 'S = dài × rộng.',
    );
  }

  static GradeQuestion _fractionOf() {
    final den = [2, 3, 4, 5][_rng.nextInt(4)];
    final whole = den * (2 + _rng.nextInt(8));
    return _q(
      '1/$den của $whole là?',
      whole ~/ den,
      chapter: 'Phân số',
      hint: 'Chia đều thành $den phần bằng nhau.',
    );
  }

  static GradeQuestion _cubeVolume() {
    final a = 2 + _rng.nextInt(8);
    return _q(
      'Thể tích lập phương cạnh $a là?',
      a * a * a,
      chapter: 'Thể tích',
      hint: 'V = a³.',
    );
  }

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

  // —— Lớp 6–7 ——
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

  static GradeQuestion _exprValue() {
    final a = 1 + _rng.nextInt(8);
    final b = 1 + _rng.nextInt(8);
    final x = 1 + _rng.nextInt(6);
    return _q(
      'Giá trị $a x + $b khi x = $x?',
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

  // —— Lớp 8 (SGK KNTT) ——
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
      'Giá trị $a x($x + $b) khi x = $x là?',
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
      chapter: 'Hằng đẳng thức',
      hint: 'A² − B² = (A − B)(A + B).',
    );
  }

  static GradeQuestion _identitySquareSum() {
    final a = 2 + _rng.nextInt(8);
    final b = 1 + _rng.nextInt(6);
    return _q(
      '($a + $b)² = ?',
      (a + b) * (a + b),
      chapter: 'Hằng đẳng thức',
      hint: '(A + B)² = A² + 2AB + B².',
    );
  }

  static GradeQuestion _identitySquareDiff() {
    final a = 5 + _rng.nextInt(8);
    final b = 1 + _rng.nextInt(4);
    return _q(
      '($a − $b)² = ?',
      (a - b) * (a - b),
      chapter: 'Hằng đẳng thức',
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
      chapter: 'Phân tích nhân tử',
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
      chapter: 'Tứ giác',
      hint: 'Chu vi HCN = 2(dài + rộng).',
    );
  }

  static GradeQuestion _rhombusPerimeter() {
    final side = 3 + _rng.nextInt(14);
    return _q(
      'Chu vi hình thoi cạnh $side là?',
      4 * side,
      chapter: 'Tứ giác',
      hint: 'Hình thoi có 4 cạnh bằng nhau.',
    );
  }

  static GradeQuestion _parallelogramArea() {
    final base = 4 + _rng.nextInt(12);
    final height = 3 + _rng.nextInt(10);
    return _q(
      'Diện tích hình bình hành đáy $base, chiều cao $height là?',
      base * height,
      chapter: 'Tứ giác',
      hint: 'S = đáy × chiều cao.',
    );
  }

  static GradeQuestion _squareDiagonalRelated() {
    final a = 3 + _rng.nextInt(10);
    return _q(
      'Diện tích hình vuông cạnh $a là?',
      a * a,
      chapter: 'Tứ giác',
      hint: 'Hình vuông: S = a².',
    );
  }

  static GradeQuestion _thalesMidline() {
    final base = 2 * (4 + _rng.nextInt(12));
    return _q(
      'Đường trung bình của tam giác song song cạnh đáy $base thì dài bao nhiêu?',
      base ~/ 2,
      chapter: 'Đường trung bình',
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
      chapter: 'Thống kê',
      hint: 'Trung bình = tổng chia số số liệu.',
    );
  }

  static GradeQuestion _statsRange() {
    final values = List.generate(5, (_) => 5 + _rng.nextInt(30))..sort();
    final range = values.last - values.first;
    return _q(
      'Khoảng biến thiên của ${values.join(', ')} là?',
      range,
      chapter: 'Thống kê',
      hint: 'Khoảng biến thiên = max − min.',
    );
  }

  static GradeQuestion _rationalSimplifyValue() {
    final k = 2 + _rng.nextInt(6);
    final a = 2 + _rng.nextInt(8);
    return _q(
      'Rút gọn phân số ${k * a}/$k được tử số (mẫu = 1) là?',
      a,
      chapter: 'Phân thức',
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
      chapter: 'Phân thức',
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
      chapter: 'PT bậc nhất',
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
      chapter: 'PT bậc nhất',
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
      chapter: 'Lập phương trình',
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
      chapter: 'Hàm số bậc nhất',
      hint: 'Thay x vào biểu thức hàm số.',
    );
  }

  static GradeQuestion _slopeOfLine() {
    final a = 1 + _rng.nextInt(9);
    return _q(
      'Đường thẳng y = ${a}x − 2 có hệ số góc bằng?',
      a,
      chapter: 'Hệ số góc',
      hint: 'Với y = ax + b, hệ số góc là a.',
    );
  }

  static GradeQuestion _probabilityFavorable() {
    final total = [6, 8, 10, 12][_rng.nextInt(4)];
    final fav = 1 + _rng.nextInt(total - 1);
    return _q(
      'Có $total kết quả khả dĩ, xác suất = $fav/$total. Số kết quả thuận lợi?',
      fav,
      chapter: 'Xác suất',
      hint: 'P = (số thuận lợi) / (số khả dĩ).',
    );
  }

  static GradeQuestion _similarTriangleSide() {
    final k = 2 + _rng.nextInt(4);
    final small = 3 + _rng.nextInt(6);
    return _q(
      'Hai tam giác đồng dạng tỉ số $k : 1. Cạnh nhỏ $small thì cạnh tương ứng?',
      small * k,
      chapter: 'Đồng dạng',
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
        chapter: 'Pythagore',
        hint: 'a² + b² = c².',
      );
    }
    return _q(
      'Tam giác vuông: cạnh góc vuông ${t[0]}, cạnh huyền ${t[2]}. Cạnh góc vuông còn lại?',
      t[1],
      chapter: 'Pythagore',
      hint: 'a² + b² = c².',
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
      chapter: 'Pythagore',
      hint: 'c = √(a² + b²).',
    );
  }

  static GradeQuestion _pyramidEdges() {
    final isTri = _rng.nextBool();
    if (isTri) {
      return _q(
        'Hình chóp tam giác đều có bao nhiêu cạnh?',
        6,
        chapter: 'Hình khối',
        hint: 'Đáy 3 cạnh + 3 cạnh bên.',
      );
    }
    return _q(
      'Hình chóp tứ giác đều có bao nhiêu cạnh?',
      8,
      chapter: 'Hình khối',
      hint: 'Đáy 4 cạnh + 4 cạnh bên.',
    );
  }

  // —— Lớp 9+ ——
  static GradeQuestion _sqrtPerfect() {
    final a = 2 + _rng.nextInt(12);
    return _q(
      '√${a * a} = ?',
      a,
      chapter: 'Căn bậc hai',
      hint: '√(a²) = |a| (a > 0).',
    );
  }

  static GradeQuestion _quadraticRootSum() {
    // (x-p)(x-q)=0 → tổng nghiệm p+q
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
      chapter: 'PT bậc hai',
      hint: 'Với x² − Sx + P = 0, tổng nghiệm = S.',
    );
  }

  static GradeQuestion _systemSum() {
    final x = 1 + _rng.nextInt(9);
    final y = 1 + _rng.nextInt(9);
    return _q(
      'Hệ: x + y = ${x + y}, x − y = ${x - y}. Tìm x.',
      x,
      chapter: 'Hệ PT',
      hint: 'Cộng hai phương trình: 2x = …',
    );
  }

  static GradeQuestion _circleCircumferenceCoeff() {
    // Chu vi = 2πr → hỏi 2r (hệ số của π)
    final r = 2 + _rng.nextInt(12);
    return _q(
      'Chu vi đường tròn bán kính $r bằng kπ. k = ?',
      2 * r,
      chapter: 'Đường tròn',
      hint: 'C = 2πr.',
    );
  }

  static GradeQuestion _trigSpecial() {
    // sin/cos of special angles as integer percent? Better: sin30=1/2 → ask numerator
    final cases = <(String, int)>[
      ('sin 30° = a/2. a = ?', 1),
      ('cos 60° = a/2. a = ?', 1),
      ('tan 45° = ?', 1),
      ('sin 90° = ?', 1),
      ('cos 0° = ?', 1),
    ];
    final c = cases[_rng.nextInt(cases.length)];
    return _q(c.$1, c.$2, chapter: 'Lượng giác', hint: 'Giá trị đặc biệt.');
  }

  static GradeQuestion _linearFunctionValue() {
    final a = -5 + _rng.nextInt(11);
    if (a == 0) return _linearFunctionValue();
    final b = -8 + _rng.nextInt(17);
    final x = -4 + _rng.nextInt(9);
    final bStr = b >= 0 ? '+ $b' : '− ${-b}';
    return _q(
      'f(x) = ${a}x $bStr. f($x) = ?',
      a * x + b,
      chapter: 'Hàm số',
      hint: 'Thay x vào f.',
    );
  }

  static GradeQuestion _arithmeticTerm() {
    final a1 = 1 + _rng.nextInt(10);
    final d = 1 + _rng.nextInt(8);
    final n = 3 + _rng.nextInt(8);
    return _q(
      'Cấp số cộng: u1 = $a1, d = $d. u$n = ?',
      a1 + (n - 1) * d,
      chapter: 'Cấp số cộng',
      hint: 'un = u1 + (n−1)d.',
    );
  }

  static GradeQuestion _geometricTerm() {
    final a1 = 1 + _rng.nextInt(5);
    final q = 2 + _rng.nextInt(3);
    final n = 2 + _rng.nextInt(4);
    var value = a1;
    for (var i = 1; i < n; i++) {
      value *= q;
    }
    return _q(
      'Cấp số nhân: u1 = $a1, q = $q. u$n = ?',
      value,
      chapter: 'Cấp số nhân',
      hint: 'un = u1 · q^(n−1).',
    );
  }

  static GradeQuestion _combinationC() {
    // C(n,k) for small n
    final cases = <(int, int, int)>[
      (5, 2, 10),
      (6, 2, 15),
      (6, 3, 20),
      (7, 2, 21),
      (8, 2, 28),
      (5, 3, 10),
      (4, 2, 6),
    ];
    final c = cases[_rng.nextInt(cases.length)];
    return _q(
      'C(${c.$1}, ${c.$2}) = ?',
      c.$3,
      chapter: 'Tổ hợp',
      hint: 'C(n,k) = n! / (k!(n−k)!).',
    );
  }

  static GradeQuestion _permutationP() {
    final cases = <(int, int, int)>[
      (5, 2, 20),
      (6, 2, 30),
      (4, 3, 24),
      (5, 3, 60),
      (7, 2, 42),
    ];
    final c = cases[_rng.nextInt(cases.length)];
    return _q(
      'P(${c.$1}, ${c.$2}) = ?',
      c.$3,
      chapter: 'Chỉnh hợp',
      hint: 'P(n,k) = n! / (n−k)!.',
    );
  }

  static GradeQuestion _logBasePower() {
    final a = [2, 3, 5, 10][_rng.nextInt(4)];
    final n = 1 + _rng.nextInt(4);
    var value = 1;
    for (var i = 0; i < n; i++) {
      value *= a;
    }
    return _q(
      'log_$a ($value) = ?',
      n,
      chapter: 'Logarit',
      hint: 'log_a (a^n) = n.',
    );
  }

  static GradeQuestion _limitSequenceSimple() {
    // lim n→∞ of constant sequence? Ask u_n for arithmetic - or (n+3)/(n) → 1
    // Integer: lim of a_n = 5 for all n
    final c = 2 + _rng.nextInt(20);
    return _q(
      'Dãy u_n = $c (hằng số). lim(n→∞) u_n = ?',
      c,
      chapter: 'Giới hạn',
      hint: 'Dãy hằng hội tụ về chính giá trị đó.',
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
