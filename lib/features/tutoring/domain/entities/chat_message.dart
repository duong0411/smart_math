enum ChatRole {
  user,
  model;

  String get storageValue => name;

  static ChatRole fromStorage(String value) {
    return ChatRole.values.firstWhere(
      (role) => role.name == value,
      orElse: () => ChatRole.user,
    );
  }
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.sessionId,
    required this.role,
    required this.content,
    required this.createdAtUtc,
    this.mediaIds = const [],
  });

  final int id;
  final int sessionId;
  final ChatRole role;
  final String content;
  final DateTime createdAtUtc;
  final List<int> mediaIds;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final mediaRaw = json['mediaIds'];
    return ChatMessage(
      id: json['id'] as int,
      sessionId: json['sessionId'] as int,
      role: ChatRole.fromStorage(json['role'] as String? ?? 'user'),
      content: json['content'] as String? ?? '',
      createdAtUtc: DateTime.parse(json['createdAtUtc'] as String),
      mediaIds: [
        if (mediaRaw is List)
          for (final id in mediaRaw)
            if (id is int) id,
      ],
    );
  }
}

class ChatSession {
  const ChatSession({
    required this.id,
    required this.userId,
    required this.title,
    required this.createdAtUtc,
    required this.updatedAtUtc,
  });

  final int id;
  final int userId;
  final String title;
  final DateTime createdAtUtc;
  final DateTime updatedAtUtc;

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'] as int,
      userId: json['userId'] as int,
      title: json['title'] as String? ?? 'Buổi học mới',
      createdAtUtc: DateTime.parse(json['createdAtUtc'] as String),
      updatedAtUtc: DateTime.parse(json['updatedAtUtc'] as String),
    );
  }
}
