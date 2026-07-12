sealed class StudyToolItem {
  const StudyToolItem({
    required this.id,
    required this.title,
    required this.kind,
    this.subject,
  });

  final int id;
  final String title;
  final String kind;
  final String? subject;
}

class FlashcardDeckItem extends StudyToolItem {
  const FlashcardDeckItem({
    required super.id,
    required super.title,
    super.subject,
    this.gradeLevel,
  }) : super(kind: 'flashcard');

  final int? gradeLevel;

  factory FlashcardDeckItem.fromJson(Map<String, dynamic> json) {
    return FlashcardDeckItem(
      id: json['id'] as int,
      title: json['title'] as String,
      subject: json['subject'] as String?,
      gradeLevel: json['gradeLevel'] as int?,
    );
  }
}

class MindmapItem extends StudyToolItem {
  const MindmapItem({
    required super.id,
    required super.title,
    super.subject,
  }) : super(kind: 'mindmap');

  factory MindmapItem.fromJson(Map<String, dynamic> json) {
    return MindmapItem(
      id: json['id'] as int,
      title: json['title'] as String,
      subject: json['subject'] as String?,
    );
  }
}
