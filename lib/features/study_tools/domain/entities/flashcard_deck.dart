class FlashcardCard {
  const FlashcardCard({
    required this.id,
    required this.deckId,
    required this.front,
    required this.back,
    required this.hint,
    required this.sortOrder,
  });

  final int id;
  final int deckId;
  final String front;
  final String back;
  final String? hint;
  final int sortOrder;

  factory FlashcardCard.fromJson(Map<String, dynamic> json) {
    return FlashcardCard(
      id: json['id'] as int,
      deckId: json['deckId'] as int,
      front: json['front'] as String,
      back: json['back'] as String,
      hint: json['hint'] as String?,
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }
}

class FlashcardDeckDetail {
  const FlashcardDeckDetail({
    required this.id,
    required this.title,
    required this.subject,
    required this.gradeLevel,
    required this.cards,
  });

  final int id;
  final String title;
  final String? subject;
  final int? gradeLevel;
  final List<FlashcardCard> cards;

  factory FlashcardDeckDetail.fromJson(Map<String, dynamic> json) {
    final cardsRaw = json['cards'];
    return FlashcardDeckDetail(
      id: json['id'] as int,
      title: json['title'] as String,
      subject: json['subject'] as String?,
      gradeLevel: json['gradeLevel'] as int?,
      cards: [
        if (cardsRaw is List)
          for (final item in cardsRaw)
            if (item is Map<String, dynamic>) FlashcardCard.fromJson(item),
      ],
    );
  }
}

class MindmapDetail {
  const MindmapDetail({
    required this.id,
    required this.title,
    required this.subject,
    required this.graph,
  });

  final int id;
  final String title;
  final String? subject;
  final Map<String, dynamic> graph;

  factory MindmapDetail.fromJson(Map<String, dynamic> json) {
    final graphRaw = json['graph'];
    return MindmapDetail(
      id: json['id'] as int,
      title: json['title'] as String,
      subject: json['subject'] as String?,
      graph: graphRaw is Map<String, dynamic>
          ? Map<String, dynamic>.from(graphRaw)
          : const {},
    );
  }
}
