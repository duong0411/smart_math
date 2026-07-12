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

Map<String, dynamic> _assessmentJson({
  int id = 5,
  String status = 'draft',
}) =>
    {
      'id': id,
      'ownerId': 1,
      'title': 'Đề mới',
      'subject': 'Toán',
      'gradeLevel': 6,
      'status': status,
      'createdAtUtc': '2026-01-01T00:00:00.000Z',
      'updatedAtUtc': '2026-01-01T00:00:00.000Z',
    };

void main() {
  test('createAssessment posts title', () async {
    final repo = AssessmentsRepositoryImpl(
      api: _api((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/assessments');
        return http.Response(
          jsonEncode({'data': _assessmentJson()}),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    final result = await repo.createAssessment(title: 'Đề mới', subject: 'Toán');
    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull!.id, 5);
  });

  test('addItem posts mcq payload', () async {
    final repo = AssessmentsRepositoryImpl(
      api: _api((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/assessments/5/items');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['itemType'], 'mcq');
        expect(body['answerKey']['correctOptionId'], 'b');
        return http.Response(
          jsonEncode({
            'data': {
              'id': 10,
              'assessmentId': 5,
              'itemType': 'mcq',
              'prompt': '2+2?',
              'options': {
                'choices': [
                  {'id': 'a', 'text': '3'},
                  {'id': 'b', 'text': '4'},
                ]
              },
              'answerKey': {'correctOptionId': 'b'},
              'points': 1,
              'sortOrder': 0,
              'createdAtUtc': '2026-01-01T00:00:00.000Z',
              'updatedAtUtc': '2026-01-01T00:00:00.000Z',
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    final result = await repo.addItem(
      assessmentId: 5,
      itemType: AssessmentItemType.mcq,
      prompt: '2+2?',
      options: {
        'choices': [
          {'id': 'a', 'text': '3'},
          {'id': 'b', 'text': '4'},
        ]
      },
      answerKey: {'correctOptionId': 'b'},
    );
    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull!.id, 10);
  });

  test('publishAssessment posts publish', () async {
    final repo = AssessmentsRepositoryImpl(
      api: _api((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/assessments/5/publish');
        return http.Response(
          jsonEncode({'data': _assessmentJson(status: 'published')}),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    final result = await repo.publishAssessment(5);
    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull!.status, AssessmentStatus.published);
  });

  test('gradeAnswer patches answer', () async {
    final repo = AssessmentsRepositoryImpl(
      api: _api((request) async {
        expect(request.method, 'PATCH');
        expect(request.url.path, '/assessments/attempts/42/answers/7');
        return http.Response(
          jsonEncode({
            'data': {
              'id': 42,
              'assessmentId': 5,
              'userId': 9,
              'status': 'graded',
              'score': 4,
              'maxScore': 5,
              'startedAtUtc': '2026-01-01T00:00:00.000Z',
              'submittedAtUtc': '2026-01-01T01:00:00.000Z',
              'gradedAtUtc': '2026-01-01T02:00:00.000Z',
              'answers': [],
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    final result = await repo.gradeAnswer(
      attemptId: 42,
      answerId: 7,
      pointsAwarded: 2,
      feedback: 'Tốt',
    );
    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull!.status, AttemptStatus.graded);
  });
}
