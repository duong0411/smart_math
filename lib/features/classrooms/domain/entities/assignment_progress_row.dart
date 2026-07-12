class AssignmentProgressRow {
  const AssignmentProgressRow({
    required this.studentId,
    required this.studentEmail,
    this.attemptId,
    this.attemptStatus,
    this.score,
    this.maxScore,
    this.submittedAtUtc,
  });

  final int studentId;
  final String studentEmail;
  final int? attemptId;
  final String? attemptStatus;
  final double? score;
  final double? maxScore;
  final DateTime? submittedAtUtc;

  factory AssignmentProgressRow.fromJson(Map<String, dynamic> json) {
    return AssignmentProgressRow(
      studentId: json['studentId'] as int,
      studentEmail: json['studentEmail'] as String? ?? '',
      attemptId: json['attemptId'] as int?,
      attemptStatus: json['attemptStatus'] as String?,
      score: (json['score'] as num?)?.toDouble(),
      maxScore: (json['maxScore'] as num?)?.toDouble(),
      submittedAtUtc: json['submittedAtUtc'] != null
          ? DateTime.parse(json['submittedAtUtc'] as String)
          : null,
    );
  }
}
