class ClassroomSummary {
  const ClassroomSummary({
    required this.id,
    required this.teacherId,
    required this.name,
    required this.joinCode,
    required this.createdAtUtc,
    required this.updatedAtUtc,
  });

  final int id;
  final int teacherId;
  final String name;
  final String joinCode;
  final DateTime createdAtUtc;
  final DateTime updatedAtUtc;

  factory ClassroomSummary.fromJson(Map<String, dynamic> json) {
    return ClassroomSummary(
      id: json['id'] as int,
      teacherId: json['teacherId'] as int,
      name: json['name'] as String,
      joinCode: json['joinCode'] as String? ?? '',
      createdAtUtc: DateTime.parse(json['createdAtUtc'] as String),
      updatedAtUtc: DateTime.parse(json['updatedAtUtc'] as String),
    );
  }
}
