/// Phạm vi duy nhất của nhánh Ngữ văn: THCS lớp 6–9, SGK Kết nối tri thức.
abstract final class LiteratureScope {
  static const hardRule = '''
PHẠM VI DUY NHẤT — NGỮ VĂN THCS (LỚP 6–9), BỘ KẾT NỐI TRI THỨC VỚI CUỘC SỐNG:
- Chỉ được ra đề, hướng dẫn, chữa và chấm ba mạch: đọc hiểu văn bản, tiếng Việt, tập làm văn.
- CẤM chấm Đúng cho Toán, Vật lí, Hóa học, Sinh học, Lịch sử, Địa lí, Tin học, Tiếng Anh, GDCD, thể dục — kể cả khi nội dung môn đó là sự thật.
- Nếu đề hoặc bài làm thuộc môn khác: correct = false. Không giải môn đó, không nêu đáp án môn đó. Chỉ mời học sinh quay lại bài Ngữ văn.
- Văn bản sử–địa nằm trong SGK Ngữ văn (Hịch tướng sĩ, Nam quốc sơn hà, Chiếu dời đô, Quang Trung đại phá quân Thanh…) chỉ được hỏi về đọc hiểu, thể loại, nghệ thuật, tiếng Việt và cách viết. Không chấm năm–tháng–địa danh như bài Sử hoặc Địa.
- Không bịa tác giả, tác phẩm, thể loại ngoài sách Kết nối tri thức và chương trình GDPT 2018.
- Với lớp 8: bám đúng mục lục Ngữ văn 8 Kết nối tri thức (Bài 1–10). Không gắn nhầm văn bản ngoài bộ (ví dụ Qua Đèo Ngang không thuộc mục lục KNTT 8).
''';

  static String curriculumFor(int grade) {
    final g = grade < 6 ? 6 : (grade > 9 ? 9 : grade);
    return switch (g) {
      6 =>
        'Ngữ văn 6 Kết nối tri thức với cuộc sống: các chủ đề tôi và các bạn, yêu thương – chia sẻ, quê hương, truyền thuyết – cổ tích (Thánh Gióng, Sơn Tinh – Thủy Tinh, Thạch Sanh…); tiếng Việt và kể chuyện, tả, thuyết minh mức lớp 6.',
      7 =>
        'Ngữ văn 7 Kết nối tri thức với cuộc sống: đọc hiểu, miêu tả, biểu cảm, thành ngữ – tục ngữ, truyện ngụ ngôn (Ếch ngồi đáy giếng, Đẽo cày giữa đường…); biện pháp so sánh, nhân hóa. Chưa yêu cầu nghị luận văn học như lớp 9.',
      8 =>
        'Ngữ văn 8 Kết nối tri thức với cuộc sống (đúng mục lục SGK): '
        'Bài 1 Câu chuyện của lịch sử (Lá cờ thêu sáu chữ vàng – Nguyễn Huy Tưởng; Quang Trung đại phá quân Thanh – Ngô gia văn phái; Ta đi tới – Tố Hữu; viết kể chuyến đi di tích; giới thiệu truyện lịch sử); '
        'Bài 2 Vẻ đẹp cổ điển (Thu điếu – Nguyễn Khuyến; Thiên Trường vãn vọng – Trần Nhân Tông; Ca Huế trên sông Hương – Hà Ánh Minh; viết phân tích thơ thất ngôn bát cú/tứ tuyệt Đường luật); '
        'Bài 3 Lời sông núi (Hịch tướng sĩ – Trần Quốc Tuấn; Tinh thần yêu nước của nhân dân ta – Hồ Chí Minh; Nam quốc sơn hà; viết nghị luận đời sống về trách nhiệm với cộng đồng, đất nước); '
        'Bài 4 Tiếng cười trào phúng trong thơ; Bài 5 Những câu chuyện hài (Trưởng giả học làm sang, truyện cười dân gian, ca dao trào phúng); '
        'Bài 6 Chân dung cuộc sống (Mắt sói; Lặng lẽ Sa Pa – Nguyễn Thành Long; Bếp lửa – Bằng Việt); '
        'Bài 7 Tin yêu và ước vọng (Đồng chí – Chính Hữu; Lá đỏ; Những ngôi sao xa xôi); '
        'Bài 8 Nhà văn và trang viết; Bài 9 Hôm nay và ngày mai (văn bản về môi trường, thuyết minh hiện tượng tự nhiên); '
        'Bài 10 Sách – người bạn đồng hành.',
      _ =>
        'Ngữ văn 9 Kết nối tri thức với cuộc sống: Chuyện người con gái Nam Xương, Truyện Kiều (Nguyễn Du), Lục Vân Tiên (Nguyễn Đình Chiểu), Tự tình bài 2 (Hồ Xuân Hương), thơ lục bát / song thất lục bát; viết nghị luận văn học và nghị luận đời sống mức lớp 9.',
    };
  }

  /// Bài mẫu STEM số (lớp 8 KNTT) dùng trong hội thi / demo.
  static const demoUnitGrade8 = 'Bài 2. Vẻ đẹp cổ điển';
  static const demoTextGrade8 = 'Thu điếu';
  static const demoAuthorGrade8 = 'Nguyễn Khuyến';
  static const demoFocusGrade8 =
      'Đọc hiểu thơ thất ngôn bát cú Đường luật; nhận biết vẻ đẹp cổ điển; '
      'dùng Chatbot AI như công cụ hỗ trợ tư duy (không viết hộ bài).';

  static String suggestedPracticeTopics(int grade) {
    final g = grade < 6 ? 6 : (grade > 9 ? 9 : grade);
    return switch (g) {
      6 => 'Thánh Gióng; Sơn Tinh – Thủy Tinh; Thạch Sanh; kể chuyện; so sánh – nhân hóa',
      7 => 'Ngụ ngôn; thành ngữ – tục ngữ; miêu tả; biểu cảm',
      8 =>
        'Thu điếu (Nguyễn Khuyến); Thiên Trường vãn vọng; Hịch tướng sĩ; '
        'Nam quốc sơn hà; Lặng lẽ Sa Pa; Bếp lửa; Đồng chí; '
        'phân tích thơ Đường luật; nghị luận đời sống',
      _ => 'Truyện Kiều; Nam Xương; Lục Vân Tiên; Tự tình; nghị luận văn học',
    };
  }

  /// Bài làm hoặc đề đang nói về môn khác, không phải câu hỏi Ngữ văn.
  static bool leaksOtherSubject(String text) {
    final folded = _fold(text);
    if (folded.trim().isEmpty) return false;
    const needles = [
      'phuong trinh',
      'dao ham',
      'tich phan',
      'bat phuong trinh',
      'dinh ly py',
      'pitago',
      'pythagore',
      'cong thuc hoa',
      'cong thuc toan',
      'cong thuc vat',
      'h2so4',
      'dinh luat newton',
      'nhiem sac the',
      'quang hop',
      'ban do dia',
      'vi do',
      'kinh do',
      'lap trinh',
      'mon toan',
      'bai toan',
      'mon vat li',
      'mon vat ly',
      'mon hoa',
      'mon sinh',
      'mon lich su',
      'mon dia li',
      'mon dia ly',
      'mon tin hoc',
      'mon tieng anh',
      'thi nghiem hoa',
      'thi nghiem sinh',
    ];
    for (final needle in needles) {
      if (folded.contains(needle)) return true;
    }
    return false;
  }

  static const offSubjectFeedback =
      'Bài này không thuộc môn Ngữ văn THCS. EduSelf chỉ chấm đọc hiểu, tiếng Việt và tập làm văn theo sách Kết nối tri thức lớp 6–9. Em hãy gửi bài Ngữ văn nhé.';

  static String _fold(String input) {
    const from = 'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
    const to = 'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';
    final buffer = StringBuffer();
    for (final rune in input.toLowerCase().runes) {
      final char = String.fromCharCode(rune);
      final index = from.indexOf(char);
      buffer.write(index >= 0 ? to[index] : char);
    }
    return buffer.toString();
  }
}
