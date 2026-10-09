import 'dart:math';

/// Câu hỏi trắc nghiệm Địa lí THCS (Lớp 6, 7, 8, 9) theo chương trình GDPT Việt Nam.
class GradeQuestion {
  const GradeQuestion({
    required this.prompt,
    required this.answer,
    required this.choices,
    this.storyHint,
    this.chapter,
  });

  final String prompt;
  final String answer;
  final List<String> choices;
  final String? storyHint;
  final String? chapter;
}

abstract final class GradeQuestionBank {
  static final _rng = Random();

  /// Ngân hàng câu hỏi mẫu phủ khắp các lớp THCS (6, 7, 8, 9)
  static final List<GradeQuestion> _allQuestions = [
    // === LỚP 6: TRÁI ĐẤT & BẢN ĐỒ ===
    const GradeQuestion(
      prompt: 'Trái Đất là hành tinh thứ mấy tính theo thứ tự xa dần Mặt Trời?',
      answer: 'Thứ 3',
      choices: ['Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5'],
      chapter: 'Địa lí 6 · Trái Đất',
      storyHint: 'Nằm giữa sao Kim và sao Hỏa.',
    ),
    const GradeQuestion(
      prompt: 'Hiện tượng ngày và đêm luân phiên trên Trái Đất là hệ quả của chuyển động nào?',
      answer: 'Tự quay quanh trục',
      choices: ['Tự quay quanh trục', 'Quay quanh Mặt Trời', 'Mặt Trời chuyển động', 'Trục nghiêng đổi chiều'],
      chapter: 'Địa lí 6 · Trái Đất',
      storyHint: 'Mất khoảng 24 giờ cho một vòng.',
    ),
    const GradeQuestion(
      prompt: 'Trái Đất tự quay quanh trục theo hướng nào?',
      answer: 'Từ Tây sang Đông',
      choices: ['Từ Tây sang Đông', 'Từ Đông sang Tây', 'Từ Bắc xuống Nam', 'Từ Nam lên Bắc'],
      chapter: 'Địa lí 6 · Trái Đất',
      storyHint: 'Vì thế Mặt Trời mọc ở hướng Đông.',
    ),
    const GradeQuestion(
      prompt: 'Vĩ tuyến 0 độ trên Trái Đất còn được gọi là đường gì?',
      answer: 'Đường Xích đạo',
      choices: ['Đường Xích đạo', 'Chí tuyến Bắc', 'Chí tuyến Nam', 'Vòng cực'],
      chapter: 'Địa lí 6 · Bản đồ',
      storyHint: 'Chia Trái Đất thành hai bán cầu Bắc và Nam.',
    ),
    const GradeQuestion(
      prompt: 'Kinh tuyến gốc (0 độ) đi qua đài thiên văn Greenwich thuộc quốc gia nào?',
      answer: 'Vương quốc Anh',
      choices: ['Vương quốc Anh', 'Pháp', 'Hoa Kỳ', 'Tây Ban Nha'],
      chapter: 'Địa lí 6 · Bản đồ',
      storyHint: 'Nằm ở ngoại ô Luân Đôn.',
    ),
    const GradeQuestion(
      prompt: 'Trên bản đồ có tỉ lệ 1:100.000, 1 cm đo được trên bản đồ tương ứng ngoài thực địa là?',
      answer: '1 km',
      choices: ['100 m', '1 km', '10 km', '100 km'],
      chapter: 'Địa lí 6 · Kỹ năng bản đồ',
      storyHint: '100.000 cm = 1.000 m = 1 km.',
    ),
    const GradeQuestion(
      prompt: 'Hiện tượng mây, mưa, sấm, chớp diễn ra chủ yếu ở tầng nào của khí quyển?',
      answer: 'Tầng đối lưu',
      choices: ['Tầng đối lưu', 'Tầng bình lưu', 'Tầng ion', 'Tầng nhiệt'],
      chapter: 'Địa lí 6 · Khí quyển',
      storyHint: 'Tầng thấp nhất tiếp giáp bề mặt Trái Đất.',
    ),
    const GradeQuestion(
      prompt: 'Đại dương chiếm khoảng bao nhiêu phần trăm diện tích bề mặt Trái Đất?',
      answer: 'Khoảng 71%',
      choices: ['Khoảng 29%', 'Khoảng 50%', 'Khoảng 71%', 'Khoảng 85%'],
      chapter: 'Địa lí 6 · Thủy quyển',
      storyHint: 'Lục địa chỉ chiếm khoảng 29%.',
    ),
    const GradeQuestion(
      prompt: 'Trên Trái Đất có bao nhiêu đới khí hậu cơ bản (đới nhiệt)?',
      answer: '5 đới',
      choices: ['3 đới', '4 đới', '5 đới', '7 đới'],
      chapter: 'Địa lí 6 · Khí hậu',
      storyHint: '1 đới nóng, 2 đới ôn hòa, 2 đới lạnh.',
    ),

    // === LỚP 7: ĐỊA LÍ CÁC CHÂU LỤC TRÊN THẾ GIỚI ===
    const GradeQuestion(
      prompt: 'Châu lục nào có diện tích và dân số lớn nhất trên thế giới?',
      answer: 'Châu Á',
      choices: ['Châu Á', 'Châu Mỹ', 'Châu Phi', 'Châu Âu'],
      chapter: 'Địa lí 7 · Châu Á',
      storyHint: 'Diện tích khoảng 44,4 triệu km².',
    ),
    const GradeQuestion(
      prompt: 'Đỉnh Everest (nóc nhà thế giới) thuộc dãy núi nào ở châu Á?',
      answer: 'Dãy Himalaya',
      choices: ['Dãy Himalaya', 'Dãy Andes', 'Dãy Alps', 'Dãy Rocky'],
      chapter: 'Địa lí 7 · Châu Á',
      storyHint: 'Cao 8848 m so với mực nước biển.',
    ),
    const GradeQuestion(
      prompt: 'Sa mạc cát Sahara lớn nhất thế giới nằm ở khu vực nào của châu Phi?',
      answer: 'Bắc Phi',
      choices: ['Bắc Phi', 'Nam Phi', 'Đông Phi', 'Tây Phi'],
      chapter: 'Địa lí 7 · Châu Phi',
      storyHint: 'Khí hậu cực kỳ khô nóng quanh năm.',
    ),
    const GradeQuestion(
      prompt: 'Con sông dài nhất thế giới chảy qua châu Phi đổ ra Địa Trung Hải là?',
      answer: 'Sông Nin (Nile)',
      choices: ['Sông Nin (Nile)', 'Sông Amazon', 'Sông Dương Tử', 'Sông Mississippi'],
      chapter: 'Địa lí 7 · Châu Phi',
      storyHint: 'Gắn liền với nền văn minh Ai Cập cổ đại.',
    ),
    const GradeQuestion(
      prompt: 'Rừng mưa nhiệt đới Amazon - "lá phổi xanh của Trái Đất" nằm ở châu lục nào?',
      answer: 'Nam Mỹ',
      choices: ['Nam Mỹ', 'Bắc Mỹ', 'Châu Phi', 'Châu Á'],
      chapter: 'Địa lí 7 · Châu Mỹ',
      storyHint: 'Lưu vực sông Amazon rộng lớn.',
    ),
    const GradeQuestion(
      prompt: 'Châu lục nào lạnh nhất và không có dân cư định cư thường xuyên?',
      answer: 'Châu Nam Cực',
      choices: ['Châu Nam Cực', 'Châu Âu', 'Châu Đại Dương', 'Bắc Băng Dương'],
      chapter: 'Địa lí 7 · Châu Nam Cực',
      storyHint: 'Bao phủ bởi lớp băng khổng lồ.',
    ),
    const GradeQuestion(
      prompt: 'Loài động vật có túi đặc trưng biểu tượng của lục địa Australia là gì?',
      answer: 'Kanguru',
      choices: ['Kanguru', 'Gấu Bắc Cực', 'Hươu cao cổ', 'Chim cánh cụt'],
      chapter: 'Địa lí 7 · Châu Đại Dương',
      storyHint: 'Có khả năng nhảy xa và nuôi con trong túi.',
    ),

    // === LỚP 8: ĐỊA LÍ TỰ NHIÊN VIỆT NAM ===
    const GradeQuestion(
      prompt: 'Việt Nam nằm ở rìa phía đông của bán đảo nào?',
      answer: 'Bán đảo Đông Dương',
      choices: ['Bán đảo Đông Dương', 'Bán đảo Mã Lai', 'Bán đảo Triều Tiên', 'Bán đảo Ấn Độ'],
      chapter: 'Địa lí 8 · Vị trí địa lí',
      storyHint: 'Nằm trong khu vực Đông Nam Á.',
    ),
    const GradeQuestion(
      prompt: 'Điểm cực Bắc trên đất liền của nước ta thuộc tỉnh nào?',
      answer: 'Hà Giang',
      choices: ['Hà Giang', 'Lào Cai', 'Cao Bằng', 'Lạng Sơn'],
      chapter: 'Địa lí 8 · Lãnh thổ Việt Nam',
      storyHint: 'Tại xã Lũng Cú, huyện Đồng Văn.',
    ),
    const GradeQuestion(
      prompt: 'Điểm cực Nam trên đất liền của nước ta thuộc tỉnh nào?',
      answer: 'Cà Mau',
      choices: ['Cà Mau', 'Kiên Giang', 'Bạc Liêu', 'Sóc Trăng'],
      chapter: 'Địa lí 8 · Lãnh thổ Việt Nam',
      storyHint: 'Mũi Cà Mau, xã Đất Mũi.',
    ),
    const GradeQuestion(
      prompt: 'Địa hình đồi núi chiếm bao nhiêu phần diện tích đất liền của Việt Nam?',
      answer: '3/4 diện tích',
      choices: ['1/4 diện tích', '1/2 diện tích', '2/3 diện tích', '3/4 diện tích'],
      chapter: 'Địa lí 8 · Địa hình Việt Nam',
      storyHint: 'Đồng bằng chỉ chiếm khoảng 1/4.',
    ),
    const GradeQuestion(
      prompt: 'Đỉnh núi cao nhất Việt Nam ("nóc nhà Đông Dương") là đỉnh nào?',
      answer: 'Phan-xi-păng (3143 m)',
      choices: ['Phan-xi-păng (3143 m)', 'Tây Côn Lĩnh', 'Ngọc Linh', 'Bạch Mộc Lương Tử'],
      chapter: 'Địa lí 8 · Địa hình Việt Nam',
      storyHint: 'Thuộc dãy Hoàng Liên Sơn hùng vĩ.',
    ),
    const GradeQuestion(
      prompt: 'Đặc điểm chung nổi bật của khí hậu Việt Nam là gì?',
      answer: 'Nhiệt đới ẩm gió mùa',
      choices: ['Nhiệt đới ẩm gió mùa', 'Ôn đới hải dương', 'Cận nhiệt khô', 'Hàn đới'],
      chapter: 'Địa lí 8 · Khí hậu Việt Nam',
      storyHint: 'Nhiệt độ cao, độ ẩm lớn và có gió mùa hoạt động.',
    ),
    const GradeQuestion(
      prompt: 'Dãy núi nào được coi là ranh giới khí hậu tự nhiên giữa miền Bắc và miền Nam?',
      answer: 'Dãy Bạch Mã',
      choices: ['Dãy Bạch Mã', 'Dãy Hoàng Liên Sơn', 'Dãy Hoành Sơn', 'Dãy Đông Triều'],
      chapter: 'Địa lí 8 · Khí hậu Việt Nam',
      storyHint: 'Chặn gió mùa Đông Bắc tràn sâu xuống phía Nam.',
    ),
    const GradeQuestion(
      prompt: 'Hai hướng dòng chảy chính của mạng lưới sông ngòi Việt Nam là?',
      answer: 'Tây Bắc - Đông Nam và vòng cung',
      choices: ['Tây Bắc - Đông Nam và vòng cung', 'Bắc - Nam và Tây - Đông', 'Đông Bắc - Tây Nam', 'Vòng cung và hướng kinh tuyến'],
      chapter: 'Địa lí 8 · Thuỷ văn Việt Nam',
      storyHint: 'Quy định bởi hướng nghiêng của địa hình.',
    ),
    const GradeQuestion(
      prompt: 'Hai quần đảo xa bờ lớn thuộc chủ quyền thiêng liêng của Việt Nam ở Biển Đông là?',
      answer: 'Hoàng Sa và Trường Sa',
      choices: ['Hoàng Sa và Trường Sa', 'Côn Đảo và Phú Quốc', 'Cô Tô và Cát Bà', 'Lý Sơn và Thổ Chu'],
      chapter: 'Địa lí 8 · Biển Đảo Việt Nam',
      storyHint: 'Hai quần đảo nằm giữa Biển Đông.',
    ),

    // === LỚP 9: ĐỊA LÍ DÂN CƯ & CÁC VÙNG KINH TẾ VIỆT NAM ===
    const GradeQuestion(
      prompt: 'Nước ta hiện có bao nhiêu dân tộc anh em cùng chung sống?',
      answer: '54 dân tộc',
      choices: ['54 dân tộc', '50 dân tộc', '56 dân tộc', '64 dân tộc'],
      chapter: 'Địa lí 9 · Dân cư Việt Nam',
      storyHint: 'Người Kinh chiếm khoảng 85% dân số.',
    ),
    const GradeQuestion(
      prompt: 'Hiện nay Việt Nam có bao nhiêu tỉnh và thành phố trực thuộc Trung ương?',
      answer: '63 tỉnh/thành',
      choices: ['63 tỉnh/thành', '61 tỉnh/thành', '64 tỉnh/thành', '65 tỉnh/thành'],
      chapter: 'Địa lí 9 · Hành chính Việt Nam',
      storyHint: 'Gồm 58 tỉnh và 5 thành phố trực thuộc Trung ương.',
    ),
    const GradeQuestion(
      prompt: 'Vùng sản xuất lương thực và xuất khẩu gạo lớn nhất cả nước là?',
      answer: 'Đồng bằng sông Cửu Long',
      choices: ['Đồng bằng sông Cửu Long', 'Đồng bằng sông Hồng', 'Duyên hải Nam Trung Bộ', 'Đông Nam Bộ'],
      chapter: 'Địa lí 9 · Các vùng kinh tế',
      storyHint: 'Được mệnh danh là vựa lúa lớn nhất miền Tây Nam Bộ.',
    ),
    const GradeQuestion(
      prompt: 'Vùng kinh tế dẫn đầu cả nước về GDP, giá trị công nghiệp và thu hút đầu tư nước ngoài là?',
      answer: 'Đông Nam Bộ',
      choices: ['Đông Nam Bộ', 'Đồng bằng sông Hồng', 'Bắc Trung Bộ', 'Tây Nguyên'],
      chapter: 'Địa lí 9 · Các vùng kinh tế',
      storyHint: 'Có đầu tàu kinh tế là TP. Hồ Chí Minh.',
    ),
    const GradeQuestion(
      prompt: 'Vùng chuyên canh cây cà phê lớn nhất nước ta là vùng nào?',
      answer: 'Tây Nguyên',
      choices: ['Tây Nguyên', 'Trung du miền núi Bắc Bộ', 'Đông Nam Bộ', 'Bắc Trung Bộ'],
      chapter: 'Địa lí 9 · Nông nghiệp Việt Nam',
      storyHint: 'Nhờ có diện tích đất đỏ bazan màu mỡ.',
    ),
    const GradeQuestion(
      prompt: 'Vùng có mật độ dân số cao nhất cả nước ta là vùng nào?',
      answer: 'Đồng bằng sông Hồng',
      choices: ['Đồng bằng sông Hồng', 'Đông Nam Bộ', 'Đồng bằng sông Cửu Long', 'Duyên hải miền Trung'],
      chapter: 'Địa lí 9 · Dân cư Việt Nam',
      storyHint: 'Đô thị hóa cao và có thủ đô Hà Nội.',
    ),
    const GradeQuestion(
      prompt: 'Hai nhà máy thủy điện lớn Hòa Bình và Sơn La được xây dựng trên con sông nào?',
      answer: 'Sông Đà',
      choices: ['Sông Đà', 'Sông Hồng', 'Sông Lô', 'Sông Chảy'],
      chapter: 'Địa lí 9 · Công nghiệp',
      storyHint: 'Phụ lưu lớn nhất của sông Hồng.',
    ),
    const GradeQuestion(
      prompt: 'Đồng bằng sông Hồng là vựa lúa lớn thứ mấy của cả nước?',
      answer: 'Thứ 2',
      choices: ['Thứ 1', 'Thứ 2', 'Thứ 3', 'Thứ 4'],
      chapter: 'Địa lí 9 · Các vùng kinh tế',
      storyHint: 'Chỉ đứng sau Đồng bằng sông Cửu Long.',
    ),
  ];

  /// Lấy câu hỏi ngẫu nhiên trong ngân hàng câu hỏi Địa lí THCS
  static GradeQuestion nextQuestion() {
    final idx = _rng.nextInt(_allQuestions.length);
    final q = _allQuestions[idx];
    return _shuffledChoices(q);
  }

  /// Alias tương thích ngược cho các trang gọi `nextGrade8()`
  static GradeQuestion nextGrade8() => nextQuestion();

  /// Đảo thứ tự đáp án ngẫu nhiên để tăng tính thử thách
  static GradeQuestion _shuffledChoices(GradeQuestion q) {
    final choices = List<String>.from(q.choices)..shuffle(_rng);
    return GradeQuestion(
      prompt: q.prompt,
      answer: q.answer,
      choices: choices,
      storyHint: q.storyHint,
      chapter: q.chapter,
    );
  }
}
