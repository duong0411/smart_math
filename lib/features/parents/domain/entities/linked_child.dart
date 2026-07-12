class LinkedChild {
  const LinkedChild({
    required this.linkId,
    required this.studentId,
    required this.studentEmail,
    this.displayName,
    this.gradeLevel,
    required this.linkedAtUtc,
  });

  final int linkId;
  final int studentId;
  final String studentEmail;
  final String? displayName;
  final int? gradeLevel;
  final DateTime linkedAtUtc;

  factory LinkedChild.fromJson(Map<String, dynamic> json) {
    return LinkedChild(
      linkId: _requireInt(json['linkId'] ?? json['id'], 'linkId'),
      studentId: _requireInt(json['studentId'], 'studentId'),
      studentEmail: (json['studentEmail'] as String?) ?? '',
      displayName: json['displayName'] as String?,
      gradeLevel: _optionalInt(json['gradeLevel']),
      linkedAtUtc: DateTime.parse(json['linkedAtUtc'] as String),
    );
  }
}

int _requireInt(Object? value, String field) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  throw FormatException('LinkedChild.$field expected int, got $value');
}

int? _optionalInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return null;
}
