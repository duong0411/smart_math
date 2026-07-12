import 'package:eduself_study_app/core/error/result.dart';
import 'package:eduself_study_app/features/assessments/domain/entities/assessment_enums.dart';
import 'package:eduself_study_app/features/exam_matrices/domain/entities/exam_matrix.dart';

abstract class ExamMatricesRepository {
  Future<Result<List<ExamMatrix>>> list();

  Future<Result<ExamMatrix>> create({
    required String title,
    String? subject,
    int? gradeLevel,
    String? description,
  });

  Future<Result<ExamMatrixDetail>> get(int id);

  Future<Result<ExamMatrix>> update({
    required int id,
    String? title,
    String? subject,
    int? gradeLevel,
    String? description,
  });

  Future<Result<void>> delete(int id);

  Future<Result<ExamMatrixOutcome>> addOutcome({
    required int matrixId,
    required String code,
    required String title,
    String? description,
    int? sortOrder,
  });

  Future<Result<ExamMatrixOutcome>> updateOutcome({
    required int matrixId,
    required int outcomeId,
    String? code,
    String? title,
    String? description,
    int? sortOrder,
  });

  Future<Result<void>> deleteOutcome({
    required int matrixId,
    required int outcomeId,
  });

  Future<Result<ExamMatrixCell>> addCell({
    required int matrixId,
    required int outcomeId,
    required AssessmentItemType itemType,
    int? targetCount,
    double? targetPoints,
    int? sortOrder,
  });

  Future<Result<ExamMatrixCell>> updateCell({
    required int matrixId,
    required int cellId,
    int? targetCount,
    double? targetPoints,
    int? sortOrder,
  });

  Future<Result<void>> deleteCell({
    required int matrixId,
    required int cellId,
  });

  Future<Result<void>> linkAssessment({
    required int matrixId,
    required int assessmentId,
  });

  Future<Result<void>> unlinkAssessment({
    required int matrixId,
    required int assessmentId,
  });

  Future<Result<MatrixCoverage>> coverage({
    required int matrixId,
    required int assessmentId,
  });

  Future<Result<void>> tagItemOutcome({
    required int assessmentId,
    required int itemId,
    required int outcomeId,
  });

  Future<Result<void>> untagItemOutcome({
    required int assessmentId,
    required int itemId,
    required int outcomeId,
  });
}
