import 'package:eduself_study_app/features/assessments/domain/entities/assessment_enums.dart';

class ExamMatrix {
  const ExamMatrix({
    required this.id,
    required this.ownerId,
    required this.title,
    this.subject,
    this.gradeLevel,
    this.description,
    required this.createdAtUtc,
    required this.updatedAtUtc,
  });

  final int id;
  final int ownerId;
  final String title;
  final String? subject;
  final int? gradeLevel;
  final String? description;
  final DateTime createdAtUtc;
  final DateTime updatedAtUtc;

  factory ExamMatrix.fromJson(Map<String, dynamic> json) {
    return ExamMatrix(
      id: json['id'] as int,
      ownerId: json['ownerId'] as int,
      title: json['title'] as String,
      subject: json['subject'] as String?,
      gradeLevel: json['gradeLevel'] as int?,
      description: json['description'] as String?,
      createdAtUtc: DateTime.parse(json['createdAtUtc'] as String),
      updatedAtUtc: DateTime.parse(json['updatedAtUtc'] as String),
    );
  }
}

class ExamMatrixOutcome {
  const ExamMatrixOutcome({
    required this.id,
    required this.matrixId,
    required this.code,
    required this.title,
    this.description,
    required this.sortOrder,
    required this.createdAtUtc,
  });

  final int id;
  final int matrixId;
  final String code;
  final String title;
  final String? description;
  final int sortOrder;
  final DateTime createdAtUtc;

  factory ExamMatrixOutcome.fromJson(Map<String, dynamic> json) {
    return ExamMatrixOutcome(
      id: json['id'] as int,
      matrixId: json['matrixId'] as int,
      code: json['code'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      sortOrder: json['sortOrder'] as int? ?? 0,
      createdAtUtc: DateTime.parse(json['createdAtUtc'] as String),
    );
  }
}

class ExamMatrixCell {
  const ExamMatrixCell({
    required this.id,
    required this.matrixId,
    required this.outcomeId,
    required this.itemType,
    required this.targetCount,
    required this.targetPoints,
    required this.sortOrder,
    required this.createdAtUtc,
  });

  final int id;
  final int matrixId;
  final int outcomeId;
  final AssessmentItemType itemType;
  final int targetCount;
  final double targetPoints;
  final int sortOrder;
  final DateTime createdAtUtc;

  factory ExamMatrixCell.fromJson(Map<String, dynamic> json) {
    return ExamMatrixCell(
      id: json['id'] as int,
      matrixId: json['matrixId'] as int,
      outcomeId: json['outcomeId'] as int,
      itemType: AssessmentItemType.fromApi(json['itemType'] as String? ?? 'mcq'),
      targetCount: json['targetCount'] as int? ?? 0,
      targetPoints: (json['targetPoints'] as num?)?.toDouble() ?? 0,
      sortOrder: json['sortOrder'] as int? ?? 0,
      createdAtUtc: DateTime.parse(json['createdAtUtc'] as String),
    );
  }
}

class ExamMatrixDetail {
  const ExamMatrixDetail({
    required this.matrix,
    required this.outcomes,
    required this.cells,
    required this.linkedAssessmentIds,
  });

  final ExamMatrix matrix;
  final List<ExamMatrixOutcome> outcomes;
  final List<ExamMatrixCell> cells;
  final List<int> linkedAssessmentIds;

  factory ExamMatrixDetail.fromJson(Map<String, dynamic> json) {
    final outcomesRaw = json['outcomes'];
    final cellsRaw = json['cells'];
    final linkedRaw = json['linkedAssessmentIds'];
    return ExamMatrixDetail(
      matrix: ExamMatrix.fromJson(json),
      outcomes: [
        if (outcomesRaw is List)
          for (final o in outcomesRaw)
            if (o is Map<String, dynamic>) ExamMatrixOutcome.fromJson(o),
      ],
      cells: [
        if (cellsRaw is List)
          for (final c in cellsRaw)
            if (c is Map<String, dynamic>) ExamMatrixCell.fromJson(c),
      ],
      linkedAssessmentIds: [
        if (linkedRaw is List)
          for (final id in linkedRaw)
            if (id is int) id,
      ],
    );
  }
}

class MatrixCoverageCell {
  const MatrixCoverageCell({
    required this.cellId,
    required this.outcomeId,
    required this.outcomeCode,
    required this.itemType,
    required this.targetCount,
    required this.actualCount,
    required this.targetPoints,
    required this.actualPoints,
    required this.met,
  });

  final int cellId;
  final int outcomeId;
  final String outcomeCode;
  final AssessmentItemType itemType;
  final int targetCount;
  final int actualCount;
  final double targetPoints;
  final double actualPoints;
  final bool met;

  factory MatrixCoverageCell.fromJson(Map<String, dynamic> json) {
    return MatrixCoverageCell(
      cellId: json['cellId'] as int,
      outcomeId: json['outcomeId'] as int,
      outcomeCode: json['outcomeCode'] as String,
      itemType: AssessmentItemType.fromApi(json['itemType'] as String? ?? 'mcq'),
      targetCount: json['targetCount'] as int? ?? 0,
      actualCount: json['actualCount'] as int? ?? 0,
      targetPoints: (json['targetPoints'] as num?)?.toDouble() ?? 0,
      actualPoints: (json['actualPoints'] as num?)?.toDouble() ?? 0,
      met: json['met'] as bool? ?? false,
    );
  }
}

class MatrixCoverage {
  const MatrixCoverage({
    required this.matrixId,
    required this.assessmentId,
    required this.cells,
    required this.overallMet,
  });

  final int matrixId;
  final int assessmentId;
  final List<MatrixCoverageCell> cells;
  final bool overallMet;

  factory MatrixCoverage.fromJson(Map<String, dynamic> json) {
    final cellsRaw = json['cells'];
    return MatrixCoverage(
      matrixId: json['matrixId'] as int,
      assessmentId: json['assessmentId'] as int,
      cells: [
        if (cellsRaw is List)
          for (final c in cellsRaw)
            if (c is Map<String, dynamic>) MatrixCoverageCell.fromJson(c),
      ],
      overallMet: json['overallMet'] as bool? ?? false,
    );
  }
}
