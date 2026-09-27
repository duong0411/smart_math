import 'dart:convert';

import 'package:eduself_study_app/core/error/result.dart';
import 'package:http/http.dart' as http;

/// Direct Google Gemini API client (no backend required).
class GeminiClient {
  GeminiClient({
    http.Client? httpClient,
    this.model = 'gemini-2.0-flash',
  }) : _http = httpClient ?? http.Client();

  final http.Client _http;
  final String model;

  static const _base =
      'https://generativelanguage.googleapis.com/v1beta/models';

  Future<Result<String>> generate({
    required String apiKey,
    required String systemPrompt,
    required List<GeminiTurn> history,
    required String userMessage,
    Duration timeout = const Duration(seconds: 55),
  }) async {
    final key = apiKey.trim();
    if (key.isEmpty) {
      return const FailureResult(
        ValidationFailure('Chưa có Gemini API key. Vào Cài đặt để dán key.'),
      );
    }

    final contents = <Map<String, Object?>>[
      for (final turn in history)
        if (turn.text.trim().isNotEmpty)
          {
            'role': turn.role == GeminiRole.user ? 'user' : 'model',
            'parts': [
              {'text': turn.text.trim()},
            ],
          },
      {
        'role': 'user',
        'parts': [
          {'text': userMessage.trim()},
        ],
      },
    ];

    final uri = Uri.parse(
      '$_base/$model:generateContent?key=${Uri.encodeQueryComponent(key)}',
    );

    try {
      final response = await _http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'systemInstruction': {
                'parts': [
                  {'text': systemPrompt},
                ],
              },
              'contents': contents,
              'generationConfig': {
                'temperature': 0.7,
                'maxOutputTokens': 4096,
              },
            }),
          )
          .timeout(timeout);

      if (response.statusCode == 401 || response.statusCode == 403) {
        return const FailureResult(
          ApiFailure(
            'API key không hợp lệ hoặc bị từ chối. Kiểm tra lại key Gemini.',
            statusCode: 401,
          ),
        );
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final detail = _errorDetail(response.body);
        return FailureResult(
          ApiFailure(
            detail ??
                'Gemini lỗi HTTP ${response.statusCode}. Thử lại sau.',
            statusCode: response.statusCode,
          ),
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return const FailureResult(AiFailure());
      }

      final text = _extractText(decoded);
      if (text == null || text.trim().isEmpty) {
        return const FailureResult(AiFailure());
      }
      return Success(text.trim());
    } on Object catch (e) {
      return FailureResult(
        NetworkFailure('Không kết nối được Gemini: $e'),
      );
    }
  }

  String? _extractText(Map<String, dynamic> body) {
    final candidates = body['candidates'];
    if (candidates is! List || candidates.isEmpty) return null;
    final first = candidates.first;
    if (first is! Map) return null;
    final content = first['content'];
    if (content is! Map) return null;
    final parts = content['parts'];
    if (parts is! List) return null;
    final buffer = StringBuffer();
    for (final part in parts) {
      if (part is Map && part['text'] is String) {
        buffer.write(part['text'] as String);
      }
    }
    return buffer.toString();
  }

  String? _errorDetail(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['error'] is Map) {
        final msg = (decoded['error'] as Map)['message'];
        if (msg is String && msg.trim().isNotEmpty) return msg.trim();
      }
    } on Object {
      // ignore
    }
    return null;
  }
}

enum GeminiRole { user, model }

class GeminiTurn {
  const GeminiTurn({required this.role, required this.text});
  final GeminiRole role;
  final String text;
}
