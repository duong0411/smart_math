import 'dart:convert';

import 'package:eduself_study_app/core/network/api_client.dart';
import 'package:eduself_study_app/features/classrooms/infrastructure/repositories/classrooms_repository_impl.dart';
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
  test('createClassroom posts name', () async {
    final repo = ClassroomsRepositoryImpl(
      api: _api((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/classrooms');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['name'], 'Lớp 6A');
        return http.Response(
          jsonEncode({
            'data': {
              'id': 1,
              'teacherId': 2,
              'name': 'Lớp 6A',
              'joinCode': 'ABC123',
              'createdAtUtc': '2026-01-01T00:00:00.000Z',
              'updatedAtUtc': '2026-01-01T00:00:00.000Z',
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    final result = await repo.createClassroom('Lớp 6A');
    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull!.joinCode, 'ABC123');
  });

  test('listMembers gets classroom members', () async {
    final repo = ClassroomsRepositoryImpl(
      api: _api((request) async {
        expect(request.url.path, '/classrooms/1/members');
        return http.Response(
          jsonEncode({
            'data': [
              {
                'id': 10,
                'classroomId': 1,
                'studentId': 9,
                'studentEmail': 'hs@example.com',
                'gradeLevel': 6,
                'status': 'active',
                'joinedAtUtc': '2026-01-01T00:00:00.000Z',
              }
            ]
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    final result = await repo.listMembers(1);
    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull!.first.studentId, 9);
  });

  test('assignAssessment posts assessmentId and durationMinutes', () async {
    final repo = ClassroomsRepositoryImpl(
      api: _api((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/classrooms/1/assignments');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['assessmentId'], 5);
        expect(body['durationMinutes'], 45);
        return http.Response(
          jsonEncode({
            'data': {
              'id': 3,
              'classroomId': 1,
              'assessmentId': 5,
              'assessmentTitle': 'Kiểm tra',
              'assessmentStatus': 'published',
              'dueAtUtc': null,
              'durationMinutes': 45,
              'assignedAtUtc': '2026-01-01T00:00:00.000Z',
              'createdBy': 2,
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    final result = await repo.assignAssessment(
      classroomId: 1,
      assessmentId: 5,
      durationMinutes: 45,
    );
    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull!.assessmentId, 5);
    expect(result.valueOrNull!.durationMinutes, 45);
  });

  test('assignmentProgress parses rows', () async {
    final repo = ClassroomsRepositoryImpl(
      api: _api((request) async {
        expect(
          request.url.path,
          '/classrooms/1/assignments/3/progress',
        );
        return http.Response(
          jsonEncode({
            'data': [
              {
                'studentId': 9,
                'studentEmail': 'hs@example.com',
                'attemptId': 42,
                'attemptStatus': 'submitted',
                'score': 2,
                'maxScore': 5,
                'submittedAtUtc': '2026-01-02T00:00:00.000Z',
              }
            ]
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    final result = await repo.assignmentProgress(
      classroomId: 1,
      assignmentId: 3,
    );
    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull!.first.attemptId, 42);
  });
}
