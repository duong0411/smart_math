/// Khối lớp Toán được hỗ trợ trong app (THCS).
abstract final class SupportedGrades {
  static const int min = 6;
  static const int max = 9;
  static const int fallback = 8;
  static const List<int> all = [6, 7, 8, 9];

  static const String labelShort = 'Lớp 6–9';
  static const String labelLong = 'chương trình Toán THCS lớp 6–9';

  /// Ép về lớp hợp lệ; `null` → [fallback].
  static int normalize(int? grade) {
    if (grade == null) return fallback;
    return grade.clamp(min, max);
  }

  static bool isSupported(int? grade) {
    if (grade == null) return false;
    return grade >= min && grade <= max;
  }
}
