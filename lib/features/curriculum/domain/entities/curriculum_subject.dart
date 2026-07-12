class CurriculumSubject {
  const CurriculumSubject({
    required this.id,
    required this.code,
    required this.name,
    required this.gradeBand,
    required this.sortOrder,
  });

  final int id;
  final String code;
  final String name;
  final String gradeBand;
  final int sortOrder;

  factory CurriculumSubject.fromJson(Map<String, dynamic> json) {
    return CurriculumSubject(
      id: json['id'] as int,
      code: json['code'] as String,
      name: json['name'] as String,
      gradeBand: json['gradeBand'] as String,
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }
}
