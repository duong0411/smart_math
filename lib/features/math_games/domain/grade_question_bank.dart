import 'dart:math';

import 'package:eduself_study_app/shared/utils/supported_grades.dart';

/// Câu hỏi Ngữ văn THCS (lớp 6–9).
/// Đáp án là số 1–4 tương ứng các lựa chọn trong đề.
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

  /// Câu hỏi ngẫu nhiên theo lớp 6–9 (ngoài khoảng → lớp 8).
  static GradeQuestion next(int gradeLevel) {
    final grade = SupportedGrades.normalize(gradeLevel);
    final bank = _bankFor(grade);
    final item = bank[_rng.nextInt(bank.length)];
    return _shuffled(item);
  }

  @Deprecated('Dùng GradeQuestionBank.next(8)')
  static GradeQuestion nextGrade8() => next(8);

  static String bandLabel(int gradeLevel) => 'Ngữ văn THCS';

  static String curriculumHint(int gradeLevel) {
    final g = SupportedGrades.normalize(gradeLevel);
    return switch (g) {
      6 => 'KNTT 6: truyền thuyết, cổ tích, kể chuyện, chính tả, so sánh – nhân hóa.',
      7 => 'KNTT 7: ngụ ngôn, thành ngữ, miêu tả, biểu cảm.',
      8 => 'KNTT 8: Thu điếu, Hịch tướng sĩ, thơ trào phúng, nghị luận đời sống.',
      _ => 'KNTT 9: Truyện Kiều, Nam Xương, Lục Vân Tiên, nghị luận văn học.',
    };
  }

  /// Đề và phương án gốc (chưa xáo) — dùng để kiểm tra không lẫn môn khác.
  static Iterable<String> surfaceTexts(int grade) sync* {
    for (final item in _bankFor(SupportedGrades.normalize(grade))) {
      yield item.stem;
      yield* item.options;
    }
  }

  static List<_LitItem> _bankFor(int grade) {
    return switch (grade) {
      6 => _grade6,
      7 => _grade7,
      9 => _grade9,
      _ => _grade8,
    };
  }

  static GradeQuestion _shuffled(_LitItem item) {
    final options = List<String>.from(item.options);
    final correctText = options[item.correctIndex];
    options.shuffle(_rng);
    final answer = options.indexOf(correctText) + 1;
    final buf = StringBuffer(item.stem);
    for (var i = 0; i < options.length; i++) {
      buf.write('\n${i + 1}. ${options[i]}');
    }
    return GradeQuestion(
      prompt: buf.toString(),
      answer: answer,
      choices: const [1, 2, 3, 4],
      chapter: item.chapter,
      storyHint: item.hint,
    );
  }

  // —— Lớp 6 ——
  static final List<_LitItem> _grade6 = [
    _LitItem(
      'Từ nào viết đúng chính tả?',
      ['xúc động', 'súc động', 'xúc dộng', 'súc dộng'],
      0,
      chapter: 'Chính tả',
      hint: 'Chú ý phân biệt s/x và d/gi.',
    ),
    _LitItem(
      'Câu nào dùng dấu hỏi đúng?',
      [
        'Em đi đâu vậy?',
        'Em đi đâu vậy!',
        'Em đi đâu vậy.',
        'Em đi đâu vậy,',
      ],
      0,
      chapter: 'Dấu câu',
    ),
    _LitItem(
      'Biện pháp tu từ trong câu "Mặt trời thức dậy sau núi" là gì?',
      ['Nhân hóa', 'So sánh', 'Điệp ngữ', 'Ẩn dụ'],
      0,
      chapter: 'Biện pháp tu từ',
      hint: 'Gán hành động của người cho sự vật.',
    ),
    _LitItem(
      'Thể loại nào sau đây thuộc văn xuôi?',
      ['Truyện ngắn', 'Thơ lục bát', 'Thơ thất ngôn', 'Ca dao'],
      0,
      chapter: 'Thể loại',
    ),
    _LitItem(
      'Câu nào là câu kể chuyện?',
      [
        'Hôm qua em đi thăm ông bà.',
        'Hãy tả khu vườn nhà em.',
        'Em hãy nêu ý nghĩa của tình bạn.',
        'Hãy giải thích nghĩa của từ "cần cù".',
      ],
      0,
      chapter: 'Tập làm văn',
    ),
    _LitItem(
      'Từ nào là từ đồng nghĩa với "vui vẻ"?',
      ['hân hoan', 'buồn bã', 'tức giận', 'lo lắng'],
      0,
      chapter: 'Từ vựng',
    ),
    _LitItem(
      'Trong câu "Hoa nở như nụ cười", biện pháp tu từ chính là?',
      ['So sánh', 'Nhân hóa', 'Điệp từ', 'Nói quá'],
      0,
      chapter: 'Biện pháp tu từ',
    ),
    _LitItem(
      'Phần mở bài của bài văn thường làm gì?',
      [
        'Giới thiệu vấn đề / mở đầu câu chuyện',
        'Kết thúc và nêu bài học',
        'Liệt kê toàn bộ chi tiết cuối cùng',
        'Chỉ viết một từ duy nhất',
      ],
      0,
      chapter: 'Bố cục',
    ),
    _LitItem(
      'Câu tục ngữ nào khuyên con người phải chăm chỉ?',
      [
        'Có công mài sắt, có ngày nên kim',
        'Ăn quả nhớ kẻ trồng cây',
        'Gần mực thì đen, gần đèn thì sáng',
        'Một cây làm chẳng nên non',
      ],
      0,
      chapter: 'Tục ngữ',
    ),
    _LitItem(
      'Từ trái nghĩa với "siêng năng" là?',
      ['lười biếng', 'chăm chỉ', 'cần cù', 'kiên trì'],
      0,
      chapter: 'Từ vựng',
    ),
    _LitItem(
      'Trong Ngữ văn 6 Kết nối tri thức, Thánh Gióng thuộc thể loại nào?',
      ['Truyền thuyết', 'Truyện ngắn', 'Thơ tự do', 'Kịch'],
      0,
      chapter: 'KNTT 6 — Thánh Gióng',
    ),
    _LitItem(
      'Thạch Sanh trong Ngữ văn 6 Kết nối tri thức thuộc thể loại nào?',
      ['Truyện cổ tích', 'Văn bản nghị luận', 'Thơ Đường luật', 'Tin tức'],
      0,
      chapter: 'KNTT 6 — Thạch Sanh',
    ),
    _LitItem(
      'Đọc Sơn Tinh, Thủy Tinh (Ngữ văn 6) chủ yếu để hiểu điều gì?',
      [
        'Ước muốn chế ngự thiên tai của người xưa',
        'Cách viết một lá đơn xin nghỉ',
        'Cách đặt dấu phẩy trong câu ghép',
        'Đặc điểm của thơ tám chữ',
      ],
      0,
      chapter: 'KNTT 6 — Sơn Tinh, Thủy Tinh',
    ),
  ];

  // —— Lớp 7 ——
  static final List<_LitItem> _grade7 = [
    _LitItem(
      'Biện pháp tu từ trong câu "Làn gió thì thầm bên tai" là?',
      ['Nhân hóa', 'So sánh', 'Hoán dụ', 'Điệp ngữ'],
      0,
      chapter: 'Biện pháp tu từ',
    ),
    _LitItem(
      'Đặc điểm nổi bật của văn miêu tả là gì?',
      [
        'Tái hiện đặc điểm sự vật, con người bằng giác quan',
        'Chứng minh một luận điểm bằng lý lẽ',
        'Kể lại chuỗi sự kiện có xung đột',
        'Chỉ liệt kê số liệu thống kê',
      ],
      0,
      chapter: 'Tập làm văn',
    ),
    _LitItem(
      'Thành ngữ "nước mắt cá sấu" dùng để nói về?',
      [
        'Sự giả tạo, giả dối trong cảm xúc',
        'Niềm vui chân thành',
        'Sự chăm chỉ học tập',
        'Tình bạn thủy chung',
      ],
      0,
      chapter: 'Thành ngữ',
    ),
    _LitItem(
      'Câu nào dùng dấu phẩy đúng hơn?',
      [
        'Hôm nay trời đẹp, em đi dạo công viên.',
        'Hôm nay trời đẹp em đi dạo công viên?',
        'Hôm nay, trời đẹp em đi dạo, công viên!',
        'Hôm nay trời đẹp; em đi dạo công viên?',
      ],
      0,
      chapter: 'Dấu câu',
    ),
    _LitItem(
      'Khi viết đoạn văn tả người, cần chú ý điều gì?',
      [
        'Ngoại hình, cử chỉ, tính cách nổi bật',
        'Chỉ nêu tên và tuổi',
        'Chỉ kể ngày tháng',
        'Chỉ ghi một dòng chữ không tả gì',
      ],
      0,
      chapter: 'Miêu tả',
    ),
    _LitItem(
      'Từ nào thuộc nhóm từ tượng thanh?',
      ['rì rào', 'xanh ngắt', 'rất đẹp', 'cao lớn'],
      0,
      chapter: 'Từ tượng thanh',
    ),
    _LitItem(
      'Chủ đề của bài văn thường trả lời câu hỏi nào?',
      [
        'Bài văn nói về vấn đề gì?',
        'Bài văn có bao nhiêu dấu chấm?',
        'Bài văn viết bằng mực gì?',
        'Bài văn dài bao nhiêu trang?',
      ],
      0,
      chapter: 'Đọc hiểu',
    ),
    _LitItem(
      'Câu nào dùng phép so sánh?',
      [
        'Mắt em trong như hồ nước mùa thu.',
        'Mắt em rất đẹp.',
        'Em có đôi mắt.',
        'Em nhìn xung quanh.',
      ],
      0,
      chapter: 'Biện pháp tu từ',
    ),
    _LitItem(
      'Tục ngữ "Ăn quả nhớ kẻ trồng cây" khuyên điều gì?',
      [
        'Biết ơn người đã giúp mình',
        'Chỉ nghĩ đến bản thân',
        'Không cần giúp đỡ ai',
        'Tránh tiếp xúc với mọi người',
      ],
      0,
      chapter: 'Tục ngữ',
    ),
    _LitItem(
      'Phần kết bài của bài văn thường?',
      [
        'Khái quát ý nghĩa hoặc cảm xúc chung',
        'Đưa thêm nhân vật mới không liên quan',
        'Bắt đầu kể lại từ đầu',
        'Chỉ viết dấu chấm hỏi',
      ],
      0,
      chapter: 'Bố cục',
    ),
    _LitItem(
      'Truyện "Ếch ngồi đáy giếng" (Ngữ văn 7 Kết nối tri thức) khuyên điều gì?',
      [
        'Không nên chủ quan, cho mình là nhất',
        'Nên bỏ dở bài viết giữa chừng',
        'Chỉ cần tả ngoại hình, không cần ý',
        'Mở bài phải viết thành một bài thơ',
      ],
      0,
      chapter: 'KNTT 7 — Ngụ ngôn',
    ),
  ];

  // —— Lớp 8 ——
  static final List<_LitItem> _grade8 = [
    _LitItem(
      'Nghị luận xã hội thường bàn về vấn đề nào?',
      [
        'Hiện tượng đời sống, đạo đức, lối sống',
        'Một câu thơ không có ý kiến cần bàn',
        'Một đoạn chỉ kể chuyện cổ tích',
        'Một bài chính tả không nêu luận điểm',
      ],
      0,
      chapter: 'Nghị luận',
    ),
    _LitItem(
      'Trong câu "Áo nâu thật đẹp trong nắng", từ "nâu" thuộc từ loại nào?',
      ['Tính từ', 'Danh từ', 'Động từ', 'Số từ'],
      0,
      chapter: 'Tiếng Việt',
    ),
    _LitItem(
      'Phép điệp ngữ thường có tác dụng gì?',
      [
        'Nhấn mạnh ý, tạo nhịp điệu',
        'Làm câu ngắn hơn bằng cách xóa chữ',
        'Thay thế dấu câu',
        'Chỉ dùng trong bảng số liệu',
      ],
      0,
      chapter: 'Biện pháp tu từ',
    ),
    _LitItem(
      'Khi phân tích một đoạn văn, cần ưu tiên làm gì trước?',
      [
        'Xác định nội dung chính và nghệ thuật nổi bật',
        'Đếm số chữ rồi dừng lại',
        'Chỉ chép lại nguyên văn không nhận xét',
        'Bỏ đoạn văn, không nhận xét gì',
      ],
      0,
      chapter: 'Đọc hiểu',
    ),
    _LitItem(
      'Câu nào thể hiện phép hoán dụ rõ hơn?',
      [
        'Áo xanh ấy vẫn bền bỉ trên công trường.',
        'Trời xanh như tấm thảm.',
        'Gió thì thầm bên tai em.',
        'Em vui như mở hội.',
      ],
      0,
      chapter: 'Biện pháp tu từ',
      hint: 'Lấy đặc điểm gắn với người/vật để chỉ đối tượng.',
    ),
    _LitItem(
      'Luận điểm trong bài nghị luận là gì?',
      [
        'Ý kiến then chốt cần chứng minh',
        'Một câu chuyện cổ tích dài',
        'Một bài thơ lục bát',
        'Một câu tục ngữ không cần chứng minh',
      ],
      0,
      chapter: 'Nghị luận',
    ),
    _LitItem(
      'Để chứng minh luận điểm, học sinh cần?',
      [
        'Đưa lý lẽ và dẫn chứng phù hợp',
        'Chỉ viết cảm xúc không có ý',
        'Chỉ liệt kê tên riêng ngẫu nhiên',
        'Bỏ qua phần thân bài',
      ],
      0,
      chapter: 'Nghị luận',
    ),
    _LitItem(
      'Từ "bền bỉ" gần nghĩa nhất với từ nào?',
      ['kiên trì', 'nông nổi', 'hời hợt', 'lười biếng'],
      0,
      chapter: 'Từ vựng',
    ),
    _LitItem(
      'Khi viết đoạn văn nghị luận khoảng 200 chữ, điều quan trọng là?',
      [
        'Rõ luận điểm, có lý lẽ – dẫn chứng, kết đoạn gọn',
        'Viết càng dài càng tốt không cần ý',
        'Chỉ kể chuyện không liên quan đề',
        'Chỉ viết một câu không có luận điểm',
      ],
      0,
      chapter: 'Tập làm văn',
    ),
    _LitItem(
      'Câu nào dùng phép nói quá (cường điệu)?',
      [
        'Nỗi buồn ấy nặng trĩu cả trời đất.',
        'Em buồn một chút.',
        'Trời hôm nay dịu.',
        'Em đi học bình thường.',
      ],
      0,
      chapter: 'Biện pháp tu từ',
    ),
    _LitItem(
      'Bài thơ "Thu điếu" trong Ngữ văn 8 Kết nối tri thức là của ai?',
      ['Nguyễn Khuyến', 'Nguyễn Du', 'Hồ Xuân Hương', 'Tố Hữu'],
      0,
      chapter: 'KNTT 8 — Thu điếu',
    ),
    _LitItem(
      '"Hịch tướng sĩ" trong Ngữ văn 8 là văn bản của ai?',
      ['Trần Quốc Tuấn', 'Nguyễn Trãi', 'Nguyễn Du', 'Nguyễn Đình Chiểu'],
      0,
      chapter: 'KNTT 8 — Hịch tướng sĩ',
    ),
    _LitItem(
      '"Nam quốc sơn hà" thuộc thể thơ nào?',
      ['Thất ngôn tứ tuyệt', 'Lục bát', 'Song thất lục bát', 'Thơ tự do'],
      0,
      chapter: 'KNTT 8 — Nam quốc sơn hà',
    ),
  ];

  // —— Lớp 9 ——
  static final List<_LitItem> _grade9 = [
    _LitItem(
      'Khi cảm nhận một khổ thơ, cần kết hợp yếu tố nào?',
      [
        'Nội dung cảm xúc và nghệ thuật biểu đạt',
        'Chỉ đếm số dòng thơ',
        'Chỉ nêu tên tác giả rồi kết thúc',
        'Chỉ chép lại khổ thơ rồi dừng',
      ],
      0,
      chapter: 'Cảm nhận văn học',
    ),
    _LitItem(
      'Nghị luận văn học thường yêu cầu học sinh?',
      [
        'Phân tích, đánh giá giá trị nội dung – nghệ thuật của tác phẩm',
        'Kể một câu chuyện không liên quan tác phẩm',
        'Chép nguyên văn cả bài không phân tích',
        'Chỉ nêu cảm xúc chung chung',
      ],
      0,
      chapter: 'Nghị luận văn học',
    ),
    _LitItem(
      'Tác giả Truyện Kiều là ai?',
      ['Nguyễn Du', 'Nguyễn Trãi', 'Hồ Xuân Hương', 'Nguyễn Đình Chiểu'],
      0,
      chapter: 'Tác giả – tác phẩm',
    ),
    _LitItem(
      'Thể thơ lục bát có đặc điểm số chữ lần lượt là?',
      ['6 – 8', '7 – 7', '5 – 7', '8 – 8'],
      0,
      chapter: 'Thể loại thơ',
    ),
    _LitItem(
      'Trong bài nghị luận, dẫn chứng văn học nên?',
      [
        'Gắn với luận điểm, trích dẫn ngắn, phân tích rõ',
        'Chép dài cả chương không nhận xét',
        'Bịa tên tác phẩm không tồn tại',
        'Chỉ nêu số trang sách giáo khoa',
      ],
      0,
      chapter: 'Kỹ năng làm bài',
    ),
    _LitItem(
      'Phép ẩn dụ khác so sánh ở điểm nào?',
      [
        'Không có từ so sánh rõ (như, là, tựa…)',
        'Luôn có từ "như"',
        'Chỉ dùng trong bảng biểu',
        'Không liên quan đến hình ảnh',
      ],
      0,
      chapter: 'Biện pháp tu từ',
    ),
    _LitItem(
      'Mở bài nghị luận văn học thường nên?',
      [
        'Dẫn dắt vào tác phẩm / vấn đề cần bàn',
        'Viết kết luận ngay từ câu đầu',
        'Kể chuyện không liên quan dài dòng',
        'Chỉ ghi tên mình',
      ],
      0,
      chapter: 'Bố cục bài văn',
    ),
    _LitItem(
      'Câu nào thể hiện phép đối rõ hơn?',
      [
        'Trên thuận hòa, dưới yên ấm.',
        'Trời hôm nay đẹp.',
        'Em học bài.',
        'Hoa nở rất nhiều.',
      ],
      0,
      chapter: 'Biện pháp tu từ',
    ),
    _LitItem(
      'Khi nhận xét nghệ thuật của một đoạn văn, nên tránh?',
      [
        'Nêu nhận xét chung chung không có dẫn chứng',
        'Chỉ ra biện pháp tu từ cụ thể',
        'Phân tích tác dụng thẩm mỹ',
        'Gắn nghệ thuật với nội dung',
      ],
      0,
      chapter: 'Kỹ năng phân tích',
    ),
    _LitItem(
      'Mục tiêu của phần kết bài nghị luận là?',
      [
        'Khái quát giá trị và liên hệ ngắn gọn',
        'Mở thêm một đề bài mới hoàn toàn',
        'Xóa bỏ toàn bộ luận điểm đã nêu',
        'Chỉ viết một dấu chấm than',
      ],
      0,
      chapter: 'Bố cục bài văn',
    ),
    _LitItem(
      'Đoạn "Kim — Kiều gặp gỡ" trong Ngữ văn 9 Kết nối tri thức trích từ tác phẩm nào?',
      ['Truyện Kiều', 'Lục Vân Tiên', 'Chinh phụ ngâm', 'Truyện Lục Vân Tiên'],
      0,
      chapter: 'KNTT 9 — Truyện Kiều',
      hint: 'Tác giả Nguyễn Du, thể lục bát.',
    ),
    _LitItem(
      '"Chuyện người con gái Nam Xương" kể về nhân vật nào?',
      ['Vũ Nương', 'Thúy Kiều', 'Kiều Nguyệt Nga', 'Thúy Vân'],
      0,
      chapter: 'KNTT 9 — Nam Xương',
    ),
    _LitItem(
      'Bài "Tự tình" (bài 2) trong Ngữ văn 9 là của ai?',
      ['Hồ Xuân Hương', 'Nguyễn Khuyến', 'Xuân Diệu', 'Tố Hữu'],
      0,
      chapter: 'KNTT 9 — Tự tình',
    ),
    _LitItem(
      '"Lục Vân Tiên cứu Kiều Nguyệt Nga" là đoạn trích của tác giả nào?',
      ['Nguyễn Đình Chiểu', 'Nguyễn Du', 'Nguyễn Dữ', 'Nguyễn Trãi'],
      0,
      chapter: 'KNTT 9 — Lục Vân Tiên',
    ),
  ];
}

class _LitItem {
  const _LitItem(
    this.stem,
    this.options,
    this.correctIndex, {
    this.chapter,
    this.hint,
  });

  final String stem;
  final List<String> options;
  final int correctIndex;
  final String? chapter;
  final String? hint;
}
