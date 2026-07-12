class IpaWordList {
  const IpaWordList({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.level,
    required this.createdAtUtc,
  });

  final int id;
  final int ownerId;
  final String title;
  final String level;
  final DateTime createdAtUtc;

  factory IpaWordList.fromJson(Map<String, dynamic> json) {
    return IpaWordList(
      id: json['id'] as int,
      ownerId: json['ownerId'] as int,
      title: json['title'] as String,
      level: json['level'] as String? ?? 'beginner',
      createdAtUtc: DateTime.parse(json['createdAtUtc'] as String),
    );
  }
}
