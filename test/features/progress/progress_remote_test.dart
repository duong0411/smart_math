import 'dart:convert';

import 'package:eduself_study_app/core/network/api_client.dart';
import 'package:eduself_study_app/features/progress/infrastructure/repositories/progress_repository_impl.dart';
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
  test('getChildSummary hits /progress/summary/:id', () async {
    final repo = ProgressRepositoryImpl(
      api: _api((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/progress/summary/9');
        return http.Response(
          jsonEncode({
            'data': {
              'userId': 9,
              'fromUtc': '2026-01-01T00:00:00.000Z',
              'toUtc': '2026-01-08T00:00:00.000Z',
              'totalEvents': 4,
              'totalDurationSec': 240,
              'byType': <String, dynamic>{},
              'bySubject': <String, dynamic>{},
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final result = await repo.getChildSummary(9);
    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull!.userId, 9);
    expect(result.valueOrNull!.totalEvents, 4);
  });
}
