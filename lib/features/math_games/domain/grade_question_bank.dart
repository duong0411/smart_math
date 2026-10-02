import 'dart:math';

/// Câu hỏi Toán 8 bám SGK *Kết nối tri thức với cuộc sống* (tập 1 + tập 2).
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

  static GradeQuestion nextGrade8() {
    final generators = <GradeQuestion Function()>[
      // Tập 1
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
      // Tập 2
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
    return generators[_rng.nextInt(generators.length)]();
  }

  // —— Ch1 Đa thức ——
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

  // —— Ch2 Hằng đẳng thức ——
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

  // —— Ch3 Tứ giác ——
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

  static GradeQuestion _squareDiagonalRelated() {
    // For square side a, if we ask a² (area) when side given
    final a = 3 + _rng.nextInt(10);
    return _q(
      'Diện tích hình vuông cạnh $a là?',
      a * a,
      chapter: 'Ch3 · Tứ giác',
      hint: 'Hình vuông: S = a².',
    );
  }

  // —— Ch4 Thalès / đường trung bình ——
  static GradeQuestion _thalesMidline() {
    // Midline of triangle = half the third side
    final base = 2 * (4 + _rng.nextInt(12)); // even for integer half
    return _q(
      'Đường trung bình của tam giác song song cạnh đáy $base thì dài bao nhiêu?',
      base ~/ 2,
      chapter: 'Ch4 · Đường trung bình',
      hint: 'Đường trung bình = 1/2 cạnh thứ ba.',
    );
  }

  // —— Ch5 Thống kê ——
  static GradeQuestion _statsMean() {
    final a = 4 + _rng.nextInt(10);
    final b = 4 + _rng.nextInt(10);
    final c = 4 + _rng.nextInt(10);
    final d = 4 + _rng.nextInt(10);
    // Ensure divisible mean
    final sum = a + b + c + d;
    final adj = sum % 4;
    final d2 = d - adj + (adj == 0 ? 0 : 4);
    final mean = (a + b + c + d2) ~/ 4;
    return _q(
      'Trung bình cộng của $a, $b, $c, $d2 là?',
      mean,
      chapter: 'Ch5 · Dữ liệu & biểu đồ',
      hint: 'Trung bình = tổng chia số số liệu.',
    );
  }

  static GradeQuestion _statsRange() {
    final values = List.generate(5, (_) => 5 + _rng.nextInt(30))..sort();
    final range = values.last - values.first;
    return _q(
      'Khoảng biến thiên của ${values.join(', ')} là?',
      range,
      chapter: 'Ch5 · Dữ liệu & biểu đồ',
      hint: 'Khoảng biến thiên = max − min.',
    );
  }

  // —— Ch6 Phân thức ——
  static GradeQuestion _rationalSimplifyValue() {
    final k = 2 + _rng.nextInt(6);
    final a = 2 + _rng.nextInt(8);
    // (k*a)/(k) = a when evaluated as number if nums
    return _q(
      'Rút gọn phân số ${k * a}/$k được tử số (mẫu = 1) là?',
      a,
      chapter: 'Ch6 · Phân thức đại số',
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
      chapter: 'Ch6 · Phân thức đại số',
      hint: 'Cùng mẫu: cộng tử, giữ mẫu.',
    );
  }

  // —— Ch7 PT & hàm số bậc nhất ——
  static GradeQuestion _linearEquation() {
    final a = 2 + _rng.nextInt(9);
    final x = -8 + _rng.nextInt(17);
    if (x == 0) return _linearEquation();
    return _q(
      '${a}x = ${a * x}  ⇒  x = ?',
      x,
      chapter: 'Ch7 · Phương trình bậc nhất',
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
      chapter: 'Ch7 · Phương trình bậc nhất',
      hint: 'Chuyển vế số hạng tự do rồi chia.',
    );
  }

  static GradeQuestion _wordLinearAge() {
    // "Tuổi con hiện nay x, bố hơn con 25 tuổi, tổng 2 tuổi 61 → x?"
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

  // —— Ch8 Xác suất ——
  static GradeQuestion _probabilityFavorable() {
    // P = favorable/total as percent integer, or favorable count
    final total = [6, 8, 10, 12][_rng.nextInt(4)];
    final fav = 1 + _rng.nextInt(total - 1);
    // Ask số kết quả thuận lợi khi P = fav/total và tổng = total
    return _q(
      'Gieo xúc xắc/túi có $total kết quả khả dĩ, xác suất biến cố = $fav/$total. Số kết quả thuận lợi?',
      fav,
      chapter: 'Ch8 · Xác suất',
      hint: 'P = (số thuận lợi) / (số khả dĩ).',
    );
  }

  // —— Ch9 Đồng dạng + Pythagore ——
  static GradeQuestion _similarTriangleSide() {
    // Triangles ratio 2: sides 3,4,5 → 6,8,10 ask corresponding
    final k = 2 + _rng.nextInt(4);
    final small = 3 + _rng.nextInt(6);
    return _q(
      'Hai tam giác đồng dạng tỉ số $k : 1. Cạnh nhỏ $small thì cạnh tương ứng?',
      small * k,
      chapter: 'Ch9 · Tam giác đồng dạng',
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
        hint: 'a² + b² = c².',
      );
    }
    return _q(
      'Tam giác vuông: cạnh góc vuông ${t[0]}, cạnh huyền ${t[2]}. Cạnh góc vuông còn lại?',
      t[1],
      chapter: 'Ch9 · Pythagore',
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
      chapter: 'Ch9 · Pythagore',
      hint: 'c = √(a² + b²).',
    );
  }

  // —— Ch10 Hình khối ——
  static GradeQuestion _pyramidEdges() {
    // Tam giác đều: 6 cạnh; tứ giác đều: 8 cạnh
    final isTri = _rng.nextBool();
    if (isTri) {
      return _q(
        'Hình chóp tam giác đều có bao nhiêu cạnh?',
        6,
        chapter: 'Ch10 · Hình khối',
        hint: 'Đáy 3 cạnh + 3 cạnh bên.',
      );
    }
    return _q(
      'Hình chóp tứ giác đều có bao nhiêu cạnh?',
      8,
      chapter: 'Ch10 · Hình khối',
      hint: 'Đáy 4 cạnh + 4 cạnh bên.',
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
        if (chapter != null) chapter,
        if (hint != null) hint,
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
