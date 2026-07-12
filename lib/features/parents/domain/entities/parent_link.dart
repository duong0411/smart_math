class ParentLink {
  const ParentLink({
    required this.id,
    required this.parentId,
    required this.studentId,
    required this.status,
    required this.linkedAtUtc,
  });

  final int id;
  final int parentId;
  final int studentId;
  final String status;
  final DateTime linkedAtUtc;

  factory ParentLink.fromJson(Map<String, dynamic> json) {
    return ParentLink(
      id: json['id'] as int,
      parentId: json['parentId'] as int,
      studentId: json['studentId'] as int,
      status: json['status'] as String,
      linkedAtUtc: DateTime.parse(json['linkedAtUtc'] as String),
    );
  }
}
