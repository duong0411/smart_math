import 'package:eduself_study_app/features/progress/domain/entities/progress_summary.dart';

class StudyMinutesDay {
  const StudyMinutesDay({
    required this.dateUtc,
    required this.minutes,
  });

  final String dateUtc;
  final double minutes;

  factory StudyMinutesDay.fromJson(Map<String, dynamic> json) {
    return StudyMinutesDay(
      dateUtc: json['dateUtc'] as String,
      minutes: (json['minutes'] as num?)?.toDouble() ?? 0,
    );
  }
}

class AssessmentSubjectStat {
  const AssessmentSubjectStat({
    required this.subject,
    required this.attemptCount,
    this.avgScorePercent,
  });

  final String subject;
  final int attemptCount;
  final double? avgScorePercent;
}

class WeeklyReportCharts {
  const WeeklyReportCharts({
    required this.progress,
    required this.attemptCount,
    required this.gradedCount,
    this.avgScorePercent,
    required this.studyMinutesByDay,
    this.assessmentBySubject = const {},
    this.suggestions = const [],
  });

  final ProgressSummary progress;
  final int attemptCount;
  final int gradedCount;
  final double? avgScorePercent;
  final List<StudyMinutesDay> studyMinutesByDay;
  final Map<String, AssessmentSubjectStat> assessmentBySubject;
  final List<String> suggestions;

  factory WeeklyReportCharts.fromJson(Map<String, dynamic> json) {
    final assessments = json['assessments'] as Map<String, dynamic>? ?? {};
    final days = json['studyMinutesByDay'] as List<dynamic>? ?? [];
    final bySubjectRaw = assessments['bySubject'];
    final assessmentBySubject = <String, AssessmentSubjectStat>{};
    if (bySubjectRaw is Map) {
      for (final entry in bySubjectRaw.entries) {
        final value = entry.value;
        if (value is! Map) continue;
        assessmentBySubject[entry.key.toString()] = AssessmentSubjectStat(
          subject: entry.key.toString(),
          attemptCount: value['attemptCount'] as int? ?? 0,
          avgScorePercent: (value['avgScorePercent'] as num?)?.toDouble(),
        );
      }
    }
    final suggestionsRaw = json['suggestions'];
    final suggestions = suggestionsRaw is List
        ? suggestionsRaw
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList(growable: false)
        : const <String>[];
    return WeeklyReportCharts(
      progress: ProgressSummary.fromJson(
        json['progress'] as Map<String, dynamic>,
      ),
      attemptCount: assessments['attemptCount'] as int? ?? 0,
      gradedCount: assessments['gradedCount'] as int? ?? 0,
      avgScorePercent: (assessments['avgScorePercent'] as num?)?.toDouble(),
      studyMinutesByDay: days
          .whereType<Map<String, dynamic>>()
          .map(StudyMinutesDay.fromJson)
          .toList(growable: false),
      assessmentBySubject: assessmentBySubject,
      suggestions: suggestions,
    );
  }
}

class WeeklyReportPreview {
  const WeeklyReportPreview({
    required this.studentId,
    this.studentDisplayName,
    required this.weekStartUtc,
    required this.weekEndUtc,
    required this.charts,
    required this.narrativeText,
    this.persistedReportId,
  });

  final int studentId;
  final String? studentDisplayName;
  final DateTime weekStartUtc;
  final DateTime weekEndUtc;
  final WeeklyReportCharts charts;
  final String narrativeText;
  final int? persistedReportId;

  factory WeeklyReportPreview.fromJson(Map<String, dynamic> json) {
    return WeeklyReportPreview(
      studentId: json['studentId'] as int,
      studentDisplayName: json['studentDisplayName'] as String?,
      weekStartUtc: DateTime.parse(json['weekStartUtc'] as String),
      weekEndUtc: DateTime.parse(json['weekEndUtc'] as String),
      charts: WeeklyReportCharts.fromJson(
        json['charts'] as Map<String, dynamic>,
      ),
      narrativeText: json['narrativeText'] as String? ?? '',
      persistedReportId: json['persistedReportId'] as int?,
    );
  }
}

class WeeklyReport {
  const WeeklyReport({
    required this.id,
    required this.parentId,
    required this.studentId,
    required this.weekStartUtc,
    required this.weekEndUtc,
    required this.charts,
    required this.narrativeText,
    required this.exportStatus,
    this.exportMediaId,
    required this.createdAtUtc,
    required this.updatedAtUtc,
  });

  final int id;
  final int parentId;
  final int studentId;
  final DateTime weekStartUtc;
  final DateTime weekEndUtc;
  final WeeklyReportCharts charts;
  final String narrativeText;
  final String exportStatus;
  final int? exportMediaId;
  final DateTime createdAtUtc;
  final DateTime updatedAtUtc;

  /// Vietnamese label for parents UI (never show raw `none`).
  String get exportStatusLabelVi => switch (exportStatus) {
        'ready' => 'Đã xuất',
        'pending' => 'Đang xuất',
        'failed' => 'Xuất lỗi',
        _ => 'Chưa xuất',
      };

  factory WeeklyReport.fromJson(Map<String, dynamic> json) {
    return WeeklyReport(
      id: json['id'] as int,
      parentId: json['parentId'] as int,
      studentId: json['studentId'] as int,
      weekStartUtc: DateTime.parse(json['weekStartUtc'] as String),
      weekEndUtc: DateTime.parse(json['weekEndUtc'] as String),
      charts: WeeklyReportCharts.fromJson(
        json['charts'] as Map<String, dynamic>,
      ),
      narrativeText: json['narrativeText'] as String? ?? '',
      exportStatus: json['exportStatus'] as String? ?? 'none',
      exportMediaId: json['exportMediaId'] as int?,
      createdAtUtc: DateTime.parse(json['createdAtUtc'] as String),
      updatedAtUtc: DateTime.parse(json['updatedAtUtc'] as String),
    );
  }
}
