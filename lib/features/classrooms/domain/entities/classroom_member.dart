class ClassroomMember {
  const ClassroomMember({
    required this.id,
    required this.classroomId,
    required this.studentId,
    this.studentEmail,
    this.gradeLevel,
    required this.status,
    required this.joinedAtUtc,
  });

  final int id;
  final int classroomId;
  final int studentId;
  final String? studentEmail;
  final int? gradeLevel;
  final String status;
  final DateTime joinedAtUtc;

  factory ClassroomMember.fromJson(Map<String, dynamic> json) {
    return ClassroomMember(
      id: json['id'] as int,
      classroomId: json['classroomId'] as int,
      studentId: json['studentId'] as int,
      studentEmail: json['studentEmail'] as String?,
      gradeLevel: json['gradeLevel'] as int?,
      status: json['status'] as String? ?? 'active',
      joinedAtUtc: DateTime.parse(json['joinedAtUtc'] as String),
    );
  }
}
