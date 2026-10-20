/// Phạm vi duy nhất của nhánh Ngữ văn: THCS lớp 6–9, SGK Kết nối tri thức.
abstract final class LiteratureScope {
  static const hardRule = '''
PHẠM VI DUY NHẤT — NGỮ VĂN THCS (LỚP 6–9), BỘ KẾT NỐI TRI THỨC VỚI CUỘC SỐNG:
- Chỉ được ra đề, hướng dẫn, chữa và chấm ba mạch: đọc hiểu văn bản, tiếng Việt, tập làm văn.
- CẤM chấm Đúng cho Toán, Vật lí, Hóa học, Sinh học, Lịch sử, Địa lí, Tin học, Tiếng Anh, GDCD, thể dục — kể cả khi nội dung môn đó là sự thật.
- Nếu đề hoặc bài làm thuộc môn khác: correct = false. Không giải môn đó, không nêu đáp án môn đó. Chỉ mời học sinh quay lại bài Ngữ văn.
- Văn bản sử–địa nằm trong SGK Ngữ văn (Hịch tướng sĩ, Nam quốc sơn hà, Chiếu dời đô, Quang Trung đại phá quân Thanh…) chỉ được hỏi về đọc hiểu, thể loại, nghệ thuật, tiếng Việt và cách viết. Không chấm năm–tháng–địa danh như bài Sử hoặc Địa.
- Không bịa tác giả, tác phẩm, thể loại ngoài sách Kết nối tri thức và chương trình GDPT 2018.
''';

  static String curriculumFor(int grade) {
    return switch (grade) {
      6 =>
        'Ngữ văn 6 Kết nối tri thức: Tôi và các bạn; Gõ cửa trái tim; Yêu thương và chia sẻ; Quê hương yêu dấu; Những nẻo đường xứ sở; Chuyện kể về những người anh hùng (Thánh Gióng, Sơn Tinh – Thủy Tinh, Bánh chưng bánh giầy); Thế giới cổ tích (Thạch Sanh, Cây khế, Sọ Dừa); tiếng Việt và kể chuyện, tả, thuyết minh sự kiện mức lớp 6.',
      7 =>
        'Ngữ văn 7 Kết nối tri thức: đọc hiểu, miêu tả, biểu cảm, thành ngữ – tục ngữ, truyện ngụ ngôn (Ếch ngồi đáy giếng, Đẽo cày giữa đường). Biện pháp so sánh, nhân hóa. Chưa yêu cầu nghị luận văn học như lớp 9.',
      8 =>
        'Ngữ văn 8 Kết nối tri thức: Thu điếu (Nguyễn Khuyến), Qua Đèo Ngang, Hịch tướng sĩ (Trần Quốc Tuấn), Nam quốc sơn hà, Tinh thần yêu nước của nhân dân ta, thơ trào phúng, truyện cười; Lặng lẽ Sa Pa, Đồng chí, Bếp lửa. Viết: kể chuyện, phân tích thơ Đường luật, nghị luận đời sống mức lớp 8.',
      _ =>
        'Ngữ văn 9 Kết nối tri thức: Chuyện người con gái Nam Xương (Vũ Nương), Nỗi niềm chinh phụ, Kim – Kiều gặp gỡ và Kiều ở lầu Ngưng Bích (Nguyễn Du), Lục Vân Tiên cứu Kiều Nguyệt Nga (Nguyễn Đình Chiểu), Tự tình bài 2 (Hồ Xuân Hương), thơ song thất lục bát và lục bát. Viết nghị luận văn học và nghị luận đời sống mức lớp 9.',
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
