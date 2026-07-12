class LibraryDocument {
  const LibraryDocument({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.description,
    required this.gradeLevel,
    required this.subject,
    required this.mediaId,
    required this.sourceUrl,
    required this.visibility,
    required this.contentPath,
    required this.createdAtUtc,
    required this.updatedAtUtc,
  });

  final int id;
  final int ownerId;
  final String title;
  final String? description;
  final int? gradeLevel;
  final String? subject;
  final int? mediaId;
  final String? sourceUrl;
  final String visibility;
  final String? contentPath;
  final DateTime createdAtUtc;
  final DateTime updatedAtUtc;

  bool get hasReadableContent =>
      (contentPath != null && contentPath!.isNotEmpty) ||
      (sourceUrl != null && sourceUrl!.isNotEmpty);

  factory LibraryDocument.fromJson(Map<String, dynamic> json) {
    return LibraryDocument(
      id: json['id'] as int,
      ownerId: json['ownerId'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      gradeLevel: json['gradeLevel'] as int?,
      subject: json['subject'] as String?,
      mediaId: json['mediaId'] as int?,
      sourceUrl: json['sourceUrl'] as String?,
      visibility: json['visibility'] as String? ?? 'private',
      contentPath: json['contentPath'] as String?,
      createdAtUtc: DateTime.parse(json['createdAtUtc'] as String),
      updatedAtUtc: DateTime.parse(
        (json['updatedAtUtc'] as String?) ?? json['createdAtUtc'] as String,
      ),
    );
  }
}
