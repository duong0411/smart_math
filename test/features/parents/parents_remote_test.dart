import 'dart:convert';

import 'package:eduself_study_app/core/network/api_client.dart';
import 'package:eduself_study_app/features/parents/infrastructure/repositories/parents_repository_impl.dart';
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

Map<String, dynamic> _progressJson({int userId = 9}) => {
      'userId': userId,
      'fromUtc': '2026-01-01T00:00:00.000Z',
      'toUtc': '2026-01-08T00:00:00.000Z',
      'totalEvents': 3,
      'totalDurationSec': 120,
      'byType': <String, dynamic>{},
      'bySubject': <String, dynamic>{},
    };

void main() {
  test('listChildren parses linked children', () async {
    final repo = ParentsRepositoryImpl(
      api: _api((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/parents/children');
        return http.Response(
          jsonEncode({
            'data': [
              {
                'linkId': 1,
                'studentId': 9,
                'studentEmail': 'hs@example.com',
                'displayName': 'An',
                'gradeLevel': 6,
                'linkedAtUtc': '2026-01-01T00:00:00.000Z',
              }
            ]
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    final result = await repo.listChildren();
    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull!.first.studentId, 9);
    expect(result.valueOrNull!.first.displayName, 'An');
  });

  test('listChildren accepts legacy id field as linkId', () async {
    final repo = ParentsRepositoryImpl(
      api: _api((request) async {
        return http.Response(
          jsonEncode({
            'data': [
              {
                'id': 4,
                'studentId': 9,
                'studentEmail': 'hs@example.com',
                'displayName': null,
                'gradeLevel': null,
                'linkedAtUtc': '2026-01-01T00:00:00.000Z',
              }
            ]
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    final result = await repo.listChildren();
    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull!.first.linkId, 4);
    expect(result.valueOrNull!.first.gradeLevel, isNull);
  });

  test('linkChild posts invite code', () async {
    final repo = ParentsRepositoryImpl(
      api: _api((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/parents/link');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['inviteCode'], 'ABCD12');
        return http.Response(
          jsonEncode({
            'data': {
              'id': 3,
              'parentId': 2,
              'studentId': 9,
              'status': 'active',
              'linkedAtUtc': '2026-01-01T00:00:00.000Z',
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    final result = await repo.linkChild('ABCD12');
    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull!.studentId, 9);
  });

  test('createInviteCode posts to invite-codes', () async {
    final repo = ParentsRepositoryImpl(
      api: _api((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/parents/invite-codes');
        return http.Response(
          jsonEncode({
            'data': {
              'code': 'XYZ999',
              'expiresAtUtc': '2026-01-08T00:00:00.000Z',
              'createdAtUtc': '2026-01-01T00:00:00.000Z',
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    final result = await repo.createInviteCode();
    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull!.code, 'XYZ999');
  });

  test('previewWeeklyReport parses charts', () async {
    final repo = ParentsRepositoryImpl(
      api: _api((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/reports/weekly');
        expect(request.url.queryParameters['studentId'], '9');
        return http.Response(
          jsonEncode({
            'data': {
              'studentId': 9,
              'studentDisplayName': 'An',
              'weekStartUtc': '2026-01-01T00:00:00.000Z',
              'weekEndUtc': '2026-01-08T00:00:00.000Z',
              'charts': {
                'progress': _progressJson(),
                'assessments': {
                  'attemptCount': 2,
                  'gradedCount': 1,
                  'avgScorePercent': 80,
                  'bySubject': <String, dynamic>{},
                },
                'studyMinutesByDay': [
                  {'dateUtc': '2026-01-01', 'minutes': 30},
                ],
              },
              'narrativeText': 'Tóm tắt tuần',
              'persistedReportId': null,
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    final result = await repo.previewWeeklyReport(studentId: 9);
    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull!.charts.attemptCount, 2);
    expect(result.valueOrNull!.narrativeText, 'Tóm tắt tuần');
  });
}
