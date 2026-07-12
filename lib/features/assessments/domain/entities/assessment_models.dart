import 'package:eduself_study_app/features/assessments/domain/entities/assessment_enums.dart';

class AssessmentSummary {
  const AssessmentSummary({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.subject,
    required this.gradeLevel,
    required this.status,
    required this.createdAtUtc,
    this.updatedAtUtc,
    this.source = AssessmentListSource.owned,
    this.classroomId,
    this.assignmentId,
    this.classroomName,
    this.dueAtUtc,
    this.durationMinutes,
  });

  final int id;
  final int ownerId;
  final String title;
  final String? subject;
  final int? gradeLevel;
  final AssessmentStatus status;
  final DateTime createdAtUtc;
  final DateTime? updatedAtUtc;
  final AssessmentListSource source;
  final int? classroomId;
  final int? assignmentId;
  final String? classroomName;
  final DateTime? dueAtUtc;
  final int? durationMinutes;

  factory AssessmentSummary.fromJson(
    Map<String, dynamic> json, {
    AssessmentListSource source = AssessmentListSource.owned,
    int? classroomId,
    int? assignmentId,
    String? classroomName,
    DateTime? dueAtUtc,
    int? durationMinutes,
  }) {
    return AssessmentSummary(
      id: json['id'] as int,
      ownerId: json['ownerId'] as int? ?? 0,
      title: json['title'] as String? ??
          json['assessmentTitle'] as String? ??
          'Đề kiểm tra',
      subject: json['subject'] as String?,
      gradeLevel: json['gradeLevel'] as int?,
      status: AssessmentStatus.fromApi(
        json['status'] as String? ??
            json['assessmentStatus'] as String? ??
            'draft',
      ),
      createdAtUtc: DateTime.parse(
        (json['createdAtUtc'] as String?) ??
            (json['assignedAtUtc'] as String?) ??
            DateTime.now().toUtc().toIso8601String(),
      ),
      updatedAtUtc: json['updatedAtUtc'] != null
          ? DateTime.parse(json['updatedAtUtc'] as String)
          : null,
      source: source,
      classroomId: classroomId,
      assignmentId: assignmentId,
      classroomName: classroomName,
      dueAtUtc: dueAtUtc,
      durationMinutes: durationMinutes ?? json['durationMinutes'] as int?,
    );
  }
}

/// Label for assignment / attempt time limit (`null` = unlimited).
String examDurationLabelVi(int? durationMinutes) {
  if (durationMinutes == null) return 'Không giới hạn';
  return '$durationMinutes phút';
}

/// Formats remaining attempt time as `mm:ss` (hours fold into minutes).
String formatAttemptCountdown(Duration remaining) {
  final totalSeconds = remaining.isNegative ? 0 : remaining.inSeconds;
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  final mm = minutes.toString().padLeft(2, '0');
  final ss = seconds.toString().padLeft(2, '0');
  return '$mm:$ss';
}

enum AssessmentListSource { owned, assigned }

class AssessmentItem {
  const AssessmentItem({
    required this.id,
    required this.assessmentId,
    required this.itemType,
    required this.prompt,
    required this.options,
    required this.answerKey,
    required this.points,
    required this.sortOrder,
  });

  final int id;
  final int assessmentId;
  final AssessmentItemType itemType;
  final String prompt;
  final Object? options;
  final Map<String, dynamic>? answerKey;
  final double points;
  final int sortOrder;

  List<({String id, String text})> get mcqChoices {
    final opts = options;
    if (opts is! Map) return const [];
    final choices = opts['choices'];
    if (choices is! List) return const [];
    return [
      for (final c in choices)
        if (c is Map)
          (
            id: (c['id'] ?? '').toString(),
            text: (c['text'] ?? '').toString(),
          ),
    ].where((c) => c.id.isNotEmpty).toList(growable: false);
  }

  Map<String, String> get matchingLeftRight {
    final opts = options;
    if (opts is Map) {
      final left = opts['left'];
      if (left is List && left.isNotEmpty) {
        // Left bank for the student UI; values come from the attempt response.
        return {
          for (final l in left) l.toString(): '',
        };
      }
      final pairsOpt = opts['pairs'];
      if (pairsOpt is Map) {
        return {
          for (final e in pairsOpt.entries)
            e.key.toString(): e.value.toString(),
        };
      }
    }
    final key = answerKey?['pairs'];
    if (key is Map) {
      return {
        for (final e in key.entries) e.key.toString(): e.value.toString(),
      };
    }
    return const {};
  }

  List<String> get matchingRightBank {
    final opts = options;
    if (opts is Map && opts['right'] is List) {
      return [
        for (final r in opts['right'] as List) r.toString(),
      ];
    }
    final pairs = matchingLeftRight;
    return pairs.values.where((v) => v.isNotEmpty).toSet().toList()..sort();
  }

  factory AssessmentItem.fromJson(Map<String, dynamic> json) {
    final keyRaw = json['answerKey'];
    return AssessmentItem(
      id: json['id'] as int,
      assessmentId: json['assessmentId'] as int,
      itemType: AssessmentItemType.fromApi(json['itemType'] as String? ?? 'mcq'),
      prompt: json['prompt'] as String,
      options: json['options'],
      answerKey: keyRaw is Map<String, dynamic>
          ? Map<String, dynamic>.from(keyRaw)
          : null,
      points: (json['points'] as num?)?.toDouble() ?? 1,
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }
}

class AssessmentDetail {
  const AssessmentDetail({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.subject,
    required this.gradeLevel,
    required this.status,
    required this.items,
    required this.createdAtUtc,
    required this.updatedAtUtc,
  });

  final int id;
  final int ownerId;
  final String title;
  final String? subject;
  final int? gradeLevel;
  final AssessmentStatus status;
  final List<AssessmentItem> items;
  final DateTime createdAtUtc;
  final DateTime updatedAtUtc;

  factory AssessmentDetail.fromJson(Map<String, dynamic> json) {
    final itemsRaw = json['items'];
    return AssessmentDetail(
      id: json['id'] as int,
      ownerId: json['ownerId'] as int,
      title: json['title'] as String,
      subject: json['subject'] as String?,
      gradeLevel: json['gradeLevel'] as int?,
      status: AssessmentStatus.fromApi(json['status'] as String? ?? 'draft'),
      items: [
        if (itemsRaw is List)
          for (final item in itemsRaw)
            if (item is Map<String, dynamic>) AssessmentItem.fromJson(item),
      ]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
      createdAtUtc: DateTime.parse(json['createdAtUtc'] as String),
      updatedAtUtc: DateTime.parse(json['updatedAtUtc'] as String),
    );
  }
}

class AttemptAnswer {
  const AttemptAnswer({
    required this.id,
    required this.attemptId,
    required this.itemId,
    required this.response,
    required this.isCorrect,
    required this.pointsAwarded,
    required this.feedback,
    required this.gradedAtUtc,
  });

  final int id;
  final int attemptId;
  final int itemId;
  final Map<String, dynamic> response;
  final bool? isCorrect;
  final double? pointsAwarded;
  final String? feedback;
  final DateTime? gradedAtUtc;

  factory AttemptAnswer.fromJson(Map<String, dynamic> json) {
    final responseRaw = json['response'];
    return AttemptAnswer(
      id: json['id'] as int,
      attemptId: json['attemptId'] as int,
      itemId: json['itemId'] as int,
      response: responseRaw is Map<String, dynamic>
          ? Map<String, dynamic>.from(responseRaw)
          : const {},
      isCorrect: json['isCorrect'] as bool?,
      pointsAwarded: (json['pointsAwarded'] as num?)?.toDouble(),
      feedback: json['feedback'] as String?,
      gradedAtUtc: json['gradedAtUtc'] != null
          ? DateTime.parse(json['gradedAtUtc'] as String)
          : null,
    );
  }
}

class AssessmentAttempt {
  const AssessmentAttempt({
    required this.id,
    required this.assessmentId,
    required this.userId,
    required this.status,
    required this.score,
    required this.maxScore,
    required this.startedAtUtc,
    required this.submittedAtUtc,
    required this.gradedAtUtc,
    this.timeLimitMinutes,
    this.endsAtUtc,
    this.answers = const [],
  });

  final int id;
  final int assessmentId;
  final int userId;
  final AttemptStatus status;
  final double? score;
  final double? maxScore;
  final DateTime startedAtUtc;
  final DateTime? submittedAtUtc;
  final DateTime? gradedAtUtc;
  final int? timeLimitMinutes;
  final DateTime? endsAtUtc;
  final List<AttemptAnswer> answers;

  factory AssessmentAttempt.fromJson(Map<String, dynamic> json) {
    final answersRaw = json['answers'];
    return AssessmentAttempt(
      id: json['id'] as int,
      assessmentId: json['assessmentId'] as int,
      userId: json['userId'] as int,
      status: AttemptStatus.fromApi(json['status'] as String? ?? 'in_progress'),
      score: (json['score'] as num?)?.toDouble(),
      maxScore: (json['maxScore'] as num?)?.toDouble(),
      startedAtUtc: DateTime.parse(json['startedAtUtc'] as String),
      submittedAtUtc: json['submittedAtUtc'] != null
          ? DateTime.parse(json['submittedAtUtc'] as String)
          : null,
      gradedAtUtc: json['gradedAtUtc'] != null
          ? DateTime.parse(json['gradedAtUtc'] as String)
          : null,
      timeLimitMinutes: json['timeLimitMinutes'] as int?,
      endsAtUtc: json['endsAtUtc'] != null
          ? DateTime.parse(json['endsAtUtc'] as String)
          : null,
      answers: [
        if (answersRaw is List)
          for (final a in answersRaw)
            if (a is Map<String, dynamic>) AttemptAnswer.fromJson(a),
      ],
    );
  }
}

class ClassroomAssignment {
  const ClassroomAssignment({
    required this.id,
    required this.classroomId,
    required this.assessmentId,
    required this.assessmentTitle,
    required this.assessmentStatus,
    required this.dueAtUtc,
    required this.assignedAtUtc,
    required this.createdBy,
    this.durationMinutes,
  });

  final int id;
  final int classroomId;
  final int assessmentId;
  final String assessmentTitle;
  final AssessmentStatus assessmentStatus;
  final DateTime? dueAtUtc;
  final int? durationMinutes;
  final DateTime assignedAtUtc;
  final int createdBy;

  AssessmentSummary toSummary({String? classroomName}) {
    return AssessmentSummary(
      id: assessmentId,
      ownerId: createdBy,
      title: assessmentTitle,
      subject: null,
      gradeLevel: null,
      status: assessmentStatus,
      createdAtUtc: assignedAtUtc,
      source: AssessmentListSource.assigned,
      classroomId: classroomId,
      assignmentId: id,
      classroomName: classroomName,
      dueAtUtc: dueAtUtc,
      durationMinutes: durationMinutes,
    );
  }

  factory ClassroomAssignment.fromJson(Map<String, dynamic> json) {
    return ClassroomAssignment(
      id: json['id'] as int,
      classroomId: json['classroomId'] as int,
      assessmentId: json['assessmentId'] as int,
      assessmentTitle: json['assessmentTitle'] as String? ?? 'Đề kiểm tra',
      assessmentStatus: AssessmentStatus.fromApi(
        json['assessmentStatus'] as String? ?? 'published',
      ),
      dueAtUtc: json['dueAtUtc'] != null
          ? DateTime.parse(json['dueAtUtc'] as String)
          : null,
      durationMinutes: json['durationMinutes'] as int?,
      assignedAtUtc: DateTime.parse(json['assignedAtUtc'] as String),
      createdBy: json['createdBy'] as int,
    );
  }
}
