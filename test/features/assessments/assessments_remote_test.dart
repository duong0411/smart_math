import 'dart:convert';

import 'package:eduself_study_app/core/network/api_client.dart';
import 'package:eduself_study_app/features/assessments/domain/entities/assessment_enums.dart';
import 'package:eduself_study_app/features/assessments/infrastructure/repositories/assessments_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

ApiClient _api(Future<http.Response> Function(http.Request) handler) {
  return ApiClient(
    resolveBaseUrl: () => 'http://localhost:8787',
    readAccessToken: () async => 'token',
    readRefreshToken: () async => 'refresh',
    persistTokens: (_) async {},
    clearTokens: () async {},
    httpClient: MockClient(handler),
  );
}

void main() {
  test('getAssessment parses detail with items', () async {
    final repo = AssessmentsRepositoryImpl(
      api: _api((request) async {
        expect(request.url.path, '/assessments/5');
        return http.Response(
          jsonEncode({
            'data': {
              'id': 5,
              'ownerId': 1,
              'title': 'Kiểm tra giữa kỳ',
              'subject': 'Toán',
              'gradeLevel': 6,
              'status': 'published',
              'createdAtUtc': '2026-01-01T00:00:00.000Z',
              'updatedAtUtc': '2026-01-01T00:00:00.000Z',
              'items': [
                {
                  'id': 10,
                  'assessmentId': 5,
                  'itemType': 'mcq',
                  'prompt': '2+2=?',
                  'options': {
                    'choices': [
                      {'id': 'a', 'text': '3'},
                      {'id': 'b', 'text': '4'},
                    ],
                  },
                  'points': 1,
                  'sortOrder': 0,
                  'createdAtUtc': '2026-01-01T00:00:00.000Z',
                  'updatedAtUtc': '2026-01-01T00:00:00.000Z',
                },
              ],
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final result = await repo.getAssessment(5);
    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull?.items.first.itemType, AssessmentItemType.mcq);
    expect(result.valueOrNull?.items.first.mcqChoices.length, 2);
  });

  test('startAttempt posts to attempts', () async {
    final repo = AssessmentsRepositoryImpl(
      api: _api((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/assessments/5/attempts');
        return http.Response(
          jsonEncode({
            'data': {
              'id': 42,
              'assessmentId': 5,
              'userId': 7,
              'status': 'in_progress',
              'score': null,
              'maxScore': null,
              'startedAtUtc': '2026-01-01T00:00:00.000Z',
              'submittedAtUtc': null,
              'gradedAtUtc': null,
              'timeLimitMinutes': 45,
              'endsAtUtc': '2026-01-01T00:45:00.000Z',
            },
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final result = await repo.startAttempt(5);
    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull?.id, 42);
    expect(result.valueOrNull?.status, AttemptStatus.inProgress);
    expect(result.valueOrNull?.timeLimitMinutes, 45);
    expect(
      result.valueOrNull?.endsAtUtc,
      DateTime.parse('2026-01-01T00:45:00.000Z'),
    );
  });

  test('saveAnswer and submitAttempt parse responses', () async {
    final calls = <String>[];
    final repo = AssessmentsRepositoryImpl(
      api: _api((request) async {
        calls.add('${request.method} ${request.url.path}');
        if (request.url.path.endsWith('/answers')) {
          return http.Response(
            jsonEncode({
              'data': {
                'id': 99,
                'attemptId': 42,
                'itemId': 10,
                'response': {'selectedOptionId': 'b'},
                'isCorrect': null,
                'pointsAwarded': null,
                'feedback': null,
                'gradedAtUtc': null,
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(
          jsonEncode({
            'data': {
              'id': 42,
              'assessmentId': 5,
              'userId': 7,
              'status': 'graded',
              'score': 1,
              'maxScore': 1,
              'startedAtUtc': '2026-01-01T00:00:00.000Z',
              'submittedAtUtc': '2026-01-01T00:05:00.000Z',
              'gradedAtUtc': '2026-01-01T00:05:00.000Z',
              'answers': [
                {
                  'id': 99,
                  'attemptId': 42,
                  'itemId': 10,
                  'response': {'selectedOptionId': 'b'},
                  'isCorrect': true,
                  'pointsAwarded': 1,
                  'feedback': null,
                  'gradedAtUtc': '2026-01-01T00:05:00.000Z',
                },
              ],
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final saved = await repo.saveAnswer(
      attemptId: 42,
      itemId: 10,
      response: const {'selectedOptionId': 'b'},
    );
    expect(saved.isSuccess, isTrue);

    final submitted = await repo.submitAttempt(42);
    expect(submitted.isSuccess, isTrue);
    expect(submitted.valueOrNull?.score, 1);
    expect(submitted.valueOrNull?.answers.first.isCorrect, isTrue);
    expect(calls, [
      'POST /assessments/attempts/42/answers',
      'POST /assessments/attempts/42/submit',
    ]);
  });
}
