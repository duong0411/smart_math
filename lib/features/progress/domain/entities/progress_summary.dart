class ProgressBucket {
  const ProgressBucket({
    required this.count,
    required this.durationSec,
    this.avgScore,
  });

  final int count;
  final int durationSec;
  final double? avgScore;

  factory ProgressBucket.fromJson(Map<String, dynamic> json) {
    return ProgressBucket(
      count: json['count'] as int? ?? 0,
      durationSec: json['durationSec'] as int? ?? 0,
      avgScore: (json['avgScore'] as num?)?.toDouble(),
    );
  }
}

class ProgressSummary {
  const ProgressSummary({
    required this.userId,
    required this.fromUtc,
    required this.toUtc,
    required this.totalEvents,
    required this.totalDurationSec,
    required this.byType,
    required this.bySubject,
  });

  final int userId;
  final DateTime fromUtc;
  final DateTime toUtc;
  final int totalEvents;
  final int totalDurationSec;
  final Map<String, ProgressBucket> byType;
  final Map<String, ProgressBucket> bySubject;

  factory ProgressSummary.fromJson(Map<String, dynamic> json) {
    Map<String, ProgressBucket> parseMap(Object? raw) {
      if (raw is! Map) return {};
      return {
        for (final entry in raw.entries)
          if (entry.value is Map<String, dynamic>)
            entry.key.toString():
                ProgressBucket.fromJson(entry.value as Map<String, dynamic>),
      };
    }

    return ProgressSummary(
      userId: json['userId'] as int,
      fromUtc: DateTime.parse(json['fromUtc'] as String),
      toUtc: DateTime.parse(json['toUtc'] as String),
      totalEvents: json['totalEvents'] as int? ?? 0,
      totalDurationSec: json['totalDurationSec'] as int? ?? 0,
      byType: parseMap(json['byType']),
      bySubject: parseMap(json['bySubject']),
    );
  }
}

/// Row used by the progress list UI.
class ProgressListRow {
  const ProgressListRow({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;
}
