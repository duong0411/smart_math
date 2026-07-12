import 'dart:convert';

import 'package:eduself_study_app/core/network/api_client.dart';
import 'package:eduself_study_app/features/tutoring/domain/entities/chat_message.dart';
import 'package:eduself_study_app/features/tutoring/infrastructure/repositories/tutoring_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('sendMessage calls /ai/tutor/reply once and returns model message',
      () async {
    final calls = <String>[];
    final api = ApiClient(
      resolveBaseUrl: () => 'http://localhost:8787',
      readAccessToken: () async => 'token',
      readRefreshToken: () async => 'refresh',
      persistTokens: (_) async {},
      clearTokens: () async {},
      httpClient: MockClient((request) async {
        calls.add('${request.method} ${request.url.path}');
        expect(request.url.path, '/ai/tutor/reply');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['sessionId'], 7);
        expect(body['userMessage'], 'Xin chào');
        return http.Response(
          jsonEncode({
            'data': {
              'reply': 'Chào em!',
              'model': 'gemini-3.1-flash-lite',
              'userMessage': {
                'id': 1,
                'sessionId': 7,
                'role': 'user',
                'content': 'Xin chào',
                'createdAtUtc': '2026-01-01T00:00:00.000Z',
              },
              'modelMessage': {
                'id': 2,
                'sessionId': 7,
                'role': 'model',
                'content': 'Chào em!',
                'createdAtUtc': '2026-01-01T00:00:01.000Z',
              },
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final repo = TutoringRepositoryImpl(api: api);
    final result = await repo.sendMessage(
      sessionId: 7,
      content: 'Xin chào',
      history: const [],
    );

    expect(calls, ['POST /ai/tutor/reply']);
    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull?.role, ChatRole.model);
    expect(result.valueOrNull?.content, 'Chào em!');
    expect(result.valueOrNull?.id, 2);
  });

  test('createSession posts to /tutoring/sessions', () async {
    final api = ApiClient(
      resolveBaseUrl: () => 'http://localhost:8787',
      readAccessToken: () async => 'token',
      readRefreshToken: () async => 'refresh',
      persistTokens: (_) async {},
      clearTokens: () async {},
      httpClient: MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/tutoring/sessions');
        return http.Response(
          jsonEncode({
            'data': {
              'id': 3,
              'userId': 1,
              'title': 'Buổi học mới',
              'createdAtUtc': '2026-01-01T00:00:00.000Z',
              'updatedAtUtc': '2026-01-01T00:00:00.000Z',
            },
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final repo = TutoringRepositoryImpl(api: api);
    final result = await repo.createSession(userId: 1);
    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull?.id, 3);
  });
  test('sendMessage can include mediaIds', () async {
    final api = ApiClient(
      resolveBaseUrl: () => 'http://localhost:8787',
      readAccessToken: () async => 'token',
      readRefreshToken: () async => 'refresh',
      persistTokens: (_) async {},
      clearTokens: () async {},
      httpClient: MockClient((request) async {
        expect(request.url.path, '/ai/tutor/reply');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['mediaIds'], [42]);
        return http.Response(
          jsonEncode({
            'data': {
              'reply': 'Thầy thấy ảnh rồi.',
              'model': 'gemini-3.1-flash-lite',
              'userMessage': {
                'id': 1,
                'sessionId': 7,
                'role': 'user',
                'content': 'Em gửi ảnh',
                'mediaIds': [42],
                'createdAtUtc': '2026-01-01T00:00:00.000Z',
              },
              'modelMessage': {
                'id': 2,
                'sessionId': 7,
                'role': 'model',
                'content': 'Thầy thấy ảnh rồi.',
                'mediaIds': <int>[],
                'createdAtUtc': '2026-01-01T00:00:01.000Z',
              },
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final repo = TutoringRepositoryImpl(api: api);
    final result = await repo.sendMessage(
      sessionId: 7,
      content: 'Em gửi ảnh',
      mediaIds: const [42],
    );
    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull?.content, 'Thầy thấy ảnh rồi.');
  });
}
