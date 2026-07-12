import 'dart:convert';

import 'package:eduself_study_app/core/network/api_client.dart';
import 'package:eduself_study_app/features/student/domain/entities/student_profile.dart';
import 'package:eduself_study_app/features/student/infrastructure/repositories/student_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('getProfile calls GET /profile', () async {
    final api = ApiClient(
      resolveBaseUrl: () => 'http://localhost:8787',
      readAccessToken: () async => 'token',
      readRefreshToken: () async => 'refresh',
      persistTokens: (_) async {},
      clearTokens: () async {},
      httpClient: MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/profile');
        return http.Response(
          jsonEncode({
            'data': {
              'userId': 1,
              'displayName': 'Minh',
              'gradeLevel': 6,
              'subjects': ['Toán'],
              'preferences': <String, dynamic>{},
              'updatedAtUtc': '2026-01-01T00:00:00.000Z',
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final repo = StudentRepositoryImpl(api: api);
    final result = await repo.getProfile();
    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull?.displayName, 'Minh');
    expect(result.valueOrNull?.gradeLevel, 6);
  });

  test('updateProfile calls PATCH /profile', () async {
    final api = ApiClient(
      resolveBaseUrl: () => 'http://localhost:8787',
      readAccessToken: () async => 'token',
      readRefreshToken: () async => 'refresh',
      persistTokens: (_) async {},
      clearTokens: () async {},
      httpClient: MockClient((request) async {
        expect(request.method, 'PATCH');
        expect(request.url.path, '/profile');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['displayName'], 'Lan');
        expect(body['gradeLevel'], 8);
        return http.Response(
          jsonEncode({
            'data': {
              'userId': 1,
              'displayName': 'Lan',
              'gradeLevel': 8,
              'subjects': <String>[],
              'preferences': <String, dynamic>{},
              'updatedAtUtc': '2026-01-01T00:00:00.000Z',
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final repo = StudentRepositoryImpl(api: api);
    final result = await repo.updateProfile(
      const UpdateStudentProfileInput(displayName: 'Lan', gradeLevel: 8),
    );
    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull?.displayName, 'Lan');
  });
}
