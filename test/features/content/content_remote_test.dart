import 'dart:convert';

import 'package:eduself_study_app/core/network/api_client.dart';
import 'package:eduself_study_app/features/assessments/domain/entities/assessment_enums.dart';
import 'package:eduself_study_app/features/assessments/infrastructure/repositories/assessments_repository_impl.dart';
import 'package:eduself_study_app/features/curriculum/infrastructure/repositories/curriculum_repository_impl.dart';
import 'package:eduself_study_app/features/ipa/infrastructure/repositories/ipa_repository_impl.dart';
import 'package:eduself_study_app/features/library/infrastructure/repositories/library_repository_impl.dart';
import 'package:eduself_study_app/features/progress/infrastructure/repositories/progress_repository_impl.dart';
import 'package:eduself_study_app/features/study_tools/infrastructure/repositories/study_tools_repository_impl.dart';
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
  test('curriculum lists subjects', () async {
    final repo = CurriculumRepositoryImpl(
      api: _api((request) async {
        expect(request.url.path, '/curriculum/subjects');
        return http.Response(
          jsonEncode({
            'data': [
              {
                'id': 1,
                'code': 'math',
                'name': 'Toán',
                'gradeBand': 'lower_secondary',
                'sortOrder': 1,
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    final result = await repo.listSubjects();
    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull?.first.name, 'Toán');
  });

  test('library lists documents', () async {
    final repo = LibraryRepositoryImpl(
      api: _api((request) async {
        expect(request.url.path, '/library');
        expect(request.url.queryParameters['scope'], 'mine');
        return http.Response(
          jsonEncode({
            'data': [
              {
                'id': 2,
                'ownerId': 1,
                'title': 'SGK Toán 6',
                'description': null,
                'gradeLevel': 6,
                'subject': 'Toán',
                'mediaId': null,
                'sourceUrl': null,
                'visibility': 'private',
                'createdAtUtc': '2026-01-01T00:00:00.000Z',
                'updatedAtUtc': '2026-01-01T00:00:00.000Z',
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    final result = await repo.listDocuments();
    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull?.first.title, 'SGK Toán 6');
  });

  test('study tools merges decks and mindmaps', () async {
    final repo = StudyToolsRepositoryImpl(
      api: _api((request) async {
        if (request.url.path.endsWith('/flashcards/decks')) {
          return http.Response(
            jsonEncode({
              'data': [
                {
                  'id': 1,
                  'ownerId': 1,
                  'title': 'Từ vựng',
                  'subject': 'English',
                  'gradeLevel': 6,
                  'createdAtUtc': '2026-01-01T00:00:00.000Z',
                  'updatedAtUtc': '2026-01-01T00:00:00.000Z',
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(
          jsonEncode({
            'data': [
              {
                'id': 9,
                'ownerId': 1,
                'title': 'Sơ đồ phân số',
                'subject': 'Toán',
                'graph': <String, dynamic>{},
                'createdAtUtc': '2026-01-01T00:00:00.000Z',
                'updatedAtUtc': '2026-01-01T00:00:00.000Z',
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    final result = await repo.listTools();
    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull?.length, 2);
  });

  test('ipa lists word lists', () async {
    final repo = IpaRepositoryImpl(
      api: _api((request) async {
        expect(request.url.path, '/ipa/lists');
        return http.Response(
          jsonEncode({
            'data': [
              {
                'id': 3,
                'ownerId': 1,
                'title': 'Vowels',
                'level': 'beginner',
                'createdAtUtc': '2026-01-01T00:00:00.000Z',
                'updatedAtUtc': '2026-01-01T00:00:00.000Z',
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    final result = await repo.listLists();
    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull?.first.title, 'Vowels');
  });

  test('progress summary parses totals', () async {
    final repo = ProgressRepositoryImpl(
      api: _api((request) async {
        expect(request.url.path, '/progress/summary');
        return http.Response(
          jsonEncode({
            'data': {
              'userId': 1,
              'fromUtc': '2026-01-01T00:00:00.000Z',
              'toUtc': '2026-01-08T00:00:00.000Z',
              'totalEvents': 4,
              'totalDurationSec': 600,
              'byType': {
                'study': {'count': 4, 'durationSec': 600},
              },
              'bySubject': {
                'Toán': {'count': 4, 'durationSec': 600, 'avgScore': 80},
              },
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    final result = await repo.getSummary();
    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull?.totalEvents, 4);
    expect(result.valueOrNull?.bySubject['Toán']?.avgScore, 80);
  });

  test('assessments list parses items', () async {
    final repo = AssessmentsRepositoryImpl(
      api: _api((request) async {
        expect(request.url.path, '/assessments');
        return http.Response(
          jsonEncode({
            'data': [
              {
                'id': 5,
                'ownerId': 1,
                'title': 'Kiểm tra giữa kỳ',
                'subject': 'Toán',
                'gradeLevel': 6,
                'status': 'published',
                'createdAtUtc': '2026-01-01T00:00:00.000Z',
                'updatedAtUtc': '2026-01-01T00:00:00.000Z',
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    final result = await repo.listAssessments();
    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull?.first.title, 'Kiểm tra giữa kỳ');
    expect(result.valueOrNull?.first.status, AssessmentStatus.published);
  });
}
