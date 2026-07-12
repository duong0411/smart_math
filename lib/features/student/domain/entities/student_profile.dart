class StudentProfile {
  const StudentProfile({
    required this.userId,
    required this.displayName,
    required this.gradeLevel,
    required this.subjects,
    required this.preferences,
    required this.updatedAtUtc,
  });

  final int userId;
  final String? displayName;
  final int? gradeLevel;
  final List<String> subjects;
  final Map<String, dynamic> preferences;
  final DateTime updatedAtUtc;

  bool get isIncomplete =>
      displayName == null ||
      displayName!.trim().isEmpty ||
      gradeLevel == null;

  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    final subjectsRaw = json['subjects'];
    final prefsRaw = json['preferences'];
    return StudentProfile(
      userId: json['userId'] as int,
      displayName: json['displayName'] as String?,
      gradeLevel: json['gradeLevel'] as int?,
      subjects: [
        if (subjectsRaw is List)
          for (final s in subjectsRaw)
            if (s is String) s,
      ],
      preferences: prefsRaw is Map<String, dynamic>
          ? Map<String, dynamic>.from(prefsRaw)
          : const {},
      updatedAtUtc: DateTime.parse(json['updatedAtUtc'] as String),
    );
  }
}

class UpdateStudentProfileInput {
  const UpdateStudentProfileInput({
    this.displayName,
    this.gradeLevel,
    this.subjects,
    this.preferences,
  });

  final String? displayName;
  final int? gradeLevel;
  final List<String>? subjects;
  final Map<String, dynamic>? preferences;

  Map<String, Object?> toJson() => {
        if (displayName != null) 'displayName': displayName,
        if (gradeLevel != null) 'gradeLevel': gradeLevel,
        if (subjects != null) 'subjects': subjects,
        if (preferences != null) 'preferences': preferences,
      };
}
