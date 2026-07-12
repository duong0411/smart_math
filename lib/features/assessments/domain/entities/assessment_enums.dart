enum AssessmentStatus {
  draft,
  published,
  archived;

  static AssessmentStatus fromApi(String value) {
    return AssessmentStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => AssessmentStatus.draft,
    );
  }
  String get labelVi => switch (this) {
        AssessmentStatus.draft => 'Nháp',
        AssessmentStatus.published => 'Đã xuất bản',
        AssessmentStatus.archived => 'Lưu trữ',
      };
}

enum AssessmentItemType {
  mcq,
  essay,
  trueFalse,
  matching,
  fillBlank;

  static AssessmentItemType fromApi(String value) {
    return switch (value) {
      'true_false' => AssessmentItemType.trueFalse,
      'fill_blank' => AssessmentItemType.fillBlank,
      'matching' => AssessmentItemType.matching,
      'essay' => AssessmentItemType.essay,
      _ => AssessmentItemType.mcq,
    };
  }

  String get apiValue => switch (this) {
        AssessmentItemType.trueFalse => 'true_false',
        AssessmentItemType.fillBlank => 'fill_blank',
        AssessmentItemType.matching => 'matching',
        AssessmentItemType.essay => 'essay',
        AssessmentItemType.mcq => 'mcq',
      };

  String get labelVi => switch (this) {
        AssessmentItemType.mcq => 'Trắc nghiệm',
        AssessmentItemType.trueFalse => 'Đúng / Sai',
        AssessmentItemType.fillBlank => 'Điền khuyết',
        AssessmentItemType.matching => 'Nối cặp',
        AssessmentItemType.essay => 'Tự luận',
      };
}

enum AttemptStatus {
  inProgress,
  submitted,
  graded;

  static AttemptStatus fromApi(String value) {
    return switch (value) {
      'submitted' => AttemptStatus.submitted,
      'graded' => AttemptStatus.graded,
      _ => AttemptStatus.inProgress,
    };
  }

  String get labelVi => switch (this) {
        AttemptStatus.inProgress => 'Đang làm',
        AttemptStatus.submitted => 'Đã nộp (chờ chấm)',
        AttemptStatus.graded => 'Đã chấm',
      };
}
