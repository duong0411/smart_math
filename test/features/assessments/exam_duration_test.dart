import 'package:eduself_study_app/features/assessments/domain/entities/assessment_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('examDurationLabelVi maps minutes and unlimited', () {
    expect(examDurationLabelVi(45), '45 phút');
    expect(examDurationLabelVi(null), 'Không giới hạn');
  });

  test('formatAttemptCountdown pads mm:ss', () {
    expect(formatAttemptCountdown(const Duration(minutes: 5, seconds: 3)), '05:03');
    expect(formatAttemptCountdown(Duration.zero), '00:00');
    expect(formatAttemptCountdown(const Duration(seconds: -1)), '00:00');
  });

  test('AssessmentAttempt.fromJson parses endsAtUtc', () {
    final attempt = AssessmentAttempt.fromJson({
      'id': 1,
      'assessmentId': 2,
      'userId': 3,
      'status': 'in_progress',
      'score': null,
      'maxScore': null,
      'startedAtUtc': '2026-01-01T00:00:00.000Z',
      'submittedAtUtc': null,
      'gradedAtUtc': null,
      'timeLimitMinutes': 45,
      'endsAtUtc': '2026-01-01T00:45:00.000Z',
    });
    expect(attempt.timeLimitMinutes, 45);
    expect(attempt.endsAtUtc, DateTime.parse('2026-01-01T00:45:00.000Z'));
  });

  test('ClassroomAssignment.fromJson parses durationMinutes', () {
    final assignment = ClassroomAssignment.fromJson({
      'id': 1,
      'classroomId': 2,
      'assessmentId': 3,
      'assessmentTitle': 'Đề A',
      'assessmentStatus': 'published',
      'dueAtUtc': null,
      'durationMinutes': 60,
      'assignedAtUtc': '2026-01-01T00:00:00.000Z',
      'createdBy': 9,
    });
    expect(assignment.durationMinutes, 60);
    expect(assignment.toSummary().durationMinutes, 60);
  });
}
