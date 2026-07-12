import 'dart:convert';

import 'package:eduself_study_app/core/network/api_client.dart';
import 'package:eduself_study_app/features/assessments/domain/entities/assessment_enums.dart';
import 'package:eduself_study_app/features/exam_matrices/infrastructure/repositories/exam_matrices_repository_impl.dart';
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
  test('list parses matrices', () async {
    final repo = ExamMatricesRepositoryImpl(
      api: _api((request) async {
        expect(request.url.path, '/exam-matrices');
        return http.Response(
          jsonEncode({
            'data': [
              {
                'id': 1,
                'ownerId': 2,
                'title': 'Ma trận HK1',
                'subject': 'Toán',
                'gradeLevel': 6,
                'description': null,
                'createdAtUtc': '2026-01-01T00:00:00.000Z',
                'updatedAtUtc': '2026-01-01T00:00:00.000Z',
              }
            ]
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    final result = await repo.list();
    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull!.first.title, 'Ma trận HK1');
  });

  test('create posts title', () async {
    final repo = ExamMatricesRepositoryImpl(
      api: _api((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/exam-matrices');
        return http.Response(
          jsonEncode({
            'data': {
              'id': 1,
              'ownerId': 2,
              'title': 'MT',
              'subject': null,
              'gradeLevel': null,
              'description': null,
              'createdAtUtc': '2026-01-01T00:00:00.000Z',
              'updatedAtUtc': '2026-01-01T00:00:00.000Z',
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    final result = await repo.create(title: 'MT');
    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull!.id, 1);
  });

  test('get parses detail with outcomes and cells', () async {
    final repo = ExamMatricesRepositoryImpl(
      api: _api((request) async {
        expect(request.url.path, '/exam-matrices/1');
        return http.Response(
          jsonEncode({
            'data': {
              'id': 1,
              'ownerId': 2,
              'title': 'MT',
              'subject': null,
              'gradeLevel': null,
              'description': null,
              'createdAtUtc': '2026-01-01T00:00:00.000Z',
              'updatedAtUtc': '2026-01-01T00:00:00.000Z',
              'outcomes': [
                {
                  'id': 10,
                  'matrixId': 1,
                  'code': 'C1',
                  'title': 'Chuẩn 1',
                  'description': null,
                  'sortOrder': 0,
                  'createdAtUtc': '2026-01-01T00:00:00.000Z',
                }
              ],
              'cells': [
                {
                  'id': 20,
                  'matrixId': 1,
                  'outcomeId': 10,
                  'itemType': 'mcq',
                  'targetCount': 2,
                  'targetPoints': 2,
                  'sortOrder': 0,
                  'createdAtUtc': '2026-01-01T00:00:00.000Z',
                }
              ],
              'linkedAssessmentIds': [5],
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    final result = await repo.get(1);
    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull!.outcomes.first.code, 'C1');
    expect(result.valueOrNull!.cells.first.itemType, AssessmentItemType.mcq);
    expect(result.valueOrNull!.linkedAssessmentIds, [5]);
  });

  test('coverage parses overallMet', () async {
    final repo = ExamMatricesRepositoryImpl(
      api: _api((request) async {
        expect(request.url.path, '/exam-matrices/1/coverage');
        expect(request.url.queryParameters['assessmentId'], '5');
        return http.Response(
          jsonEncode({
            'data': {
              'matrixId': 1,
              'assessmentId': 5,
              'cells': [
                {
                  'cellId': 20,
                  'outcomeId': 10,
                  'outcomeCode': 'C1',
                  'itemType': 'mcq',
                  'targetCount': 2,
                  'actualCount': 1,
                  'targetPoints': 2,
                  'actualPoints': 1,
                  'met': false,
                }
              ],
              'byItemType': <String, dynamic>{},
              'overallMet': false,
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    final result = await repo.coverage(matrixId: 1, assessmentId: 5);
    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull!.overallMet, isFalse);
    expect(result.valueOrNull!.cells.first.outcomeCode, 'C1');
  });

  test('tagItemOutcome posts body', () async {
    final repo = ExamMatricesRepositoryImpl(
      api: _api((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/exam-matrices/item-outcomes');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['assessmentId'], 5);
        expect(body['itemId'], 10);
        expect(body['outcomeId'], 3);
        return http.Response(
          jsonEncode({'data': {'ok': true}}),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    final result = await repo.tagItemOutcome(
      assessmentId: 5,
      itemId: 10,
      outcomeId: 3,
    );
    expect(result.isSuccess, isTrue);
  });
}
