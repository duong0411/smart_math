import 'dart:convert';

import 'package:eduself_study_app/core/network/api_client.dart';
import 'package:eduself_study_app/features/media/domain/entities/media_asset.dart';
import 'package:eduself_study_app/features/media/infrastructure/repositories/media_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('upload creates media then PUTs bytes', () async {
    final calls = <String>[];
    final api = ApiClient(
      resolveBaseUrl: () => 'http://localhost:8787',
      readAccessToken: () async => 'token',
      readRefreshToken: () async => 'refresh',
      persistTokens: (_) async {},
      clearTokens: () async {},
      httpClient: MockClient((request) async {
        calls.add('${request.method} ${request.url.path}');
        if (request.method == 'POST' && request.url.path == '/media') {
          return http.Response(
            jsonEncode({
              'data': {
                'id': 42,
                'ownerId': 1,
                'kind': 'image',
                'contentType': 'image/jpeg',
                'filename': 'hw.jpg',
                'sizeBytes': 3,
                'status': 'pending',
                'uploadPath': '/media/42/content',
                'contentPath': '/media/42/content',
                'createdAtUtc': '2026-01-01T00:00:00.000Z',
                'updatedAtUtc': '2026-01-01T00:00:00.000Z',
              },
            }),
            201,
            headers: {'content-type': 'application/json'},
          );
        }
        expect(request.method, 'PUT');
        expect(request.url.path, '/media/42/content');
        expect(request.headers['content-type'], 'image/jpeg');
        return http.Response(
          jsonEncode({
            'data': {
              'id': 42,
              'ownerId': 1,
              'kind': 'image',
              'contentType': 'image/jpeg',
              'filename': 'hw.jpg',
              'sizeBytes': 3,
              'status': 'ready',
              'uploadPath': '/media/42/content',
              'contentPath': '/media/42/content',
              'createdAtUtc': '2026-01-01T00:00:00.000Z',
              'updatedAtUtc': '2026-01-01T00:00:01.000Z',
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final repo = MediaRepositoryImpl(api: api);
    final result = await repo.upload(
      const UploadMediaInput(
        bytes: [1, 2, 3],
        filename: 'hw.jpg',
        contentType: 'image/jpeg',
      ),
    );

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull?.status, 'ready');
    expect(calls, ['POST /media', 'PUT /media/42/content']);
  });
}
