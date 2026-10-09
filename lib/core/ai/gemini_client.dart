import 'dart:convert';

import 'package:eduself_study_app/core/config/app_config.dart';
import 'package:eduself_study_app/core/error/result.dart';
import 'package:http/http.dart' as http;

/// Direct Google Gemini API client with multi-model failover.
///
/// Tries models in [models] order (accuracy-first). On rate-limit / quota /
/// overload errors, automatically switches to the next model.
class GeminiClient {
  GeminiClient({
    http.Client? httpClient,
    List<String>? models,
    this.temperature = 0.2,
    this.maxOutputTokens = 8192,
  })  : _http = httpClient ?? http.Client(),
        models = List.unmodifiable(
          (models == null || models.isEmpty)
              ? AppConfig.geminiModelChain
              : models,
        );

  final http.Client _http;

  /// Accuracy-first chain; later entries are quota/failover fallbacks.
  final List<String> models;
  final double temperature;
  final int maxOutputTokens;

  static const _base =
      'https://generativelanguage.googleapis.com/v1beta/models';

  /// Last model that successfully answered (useful for UI / debug).
  String? lastUsedModel;

  Future<Result<String>> generate({
    required String apiKey,
    required String systemPrompt,
    required List<GeminiTurn> history,
    required String userMessage,
    GeminiImage? image,
    Duration timeout = const Duration(seconds: 55),
    List<String>? modelOverride,
  }) async {
    final key = apiKey.trim();
    if (key.isEmpty) {
      return const FailureResult(
        ValidationFailure('Chưa có Gemini API key. Vào Cài đặt để dán key.'),
      );
    }

    final chain = (modelOverride == null || modelOverride.isEmpty)
        ? models
        : modelOverride;

    final userParts = <Map<String, Object?>>[
      if (image != null)
        {
          'inline_data': {
            'mime_type': image.mimeType,
            'data': image.base64,
          },
        },
      {
        'text': userMessage.trim().isEmpty
            ? (image != null
                ? 'Em gửi ảnh câu hỏi / biểu đồ / bản đồ bài tập Địa lí. Hãy đọc kỹ nội dung trên ảnh (OCR), nêu lại yêu cầu ngắn gọn, rồi hướng dẫn em suy luận từng bước (chưa đưa đáp án ngay trừ khi em yêu cầu).'
                : '')
            : userMessage.trim(),
      },
    ];

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
        'parts': userParts,
      },
    ];

    final body = jsonEncode({
      'systemInstruction': {
        'parts': [
          {'text': systemPrompt},
        ],
      },
      'contents': contents,
      'generationConfig': {
        'temperature': temperature,
        'topP': 0.95,
        'maxOutputTokens': maxOutputTokens,
      },
    });

    Failure? lastFailure;
    final tried = <String>[];

    for (final model in chain) {
      tried.add(model);
      // Prefer header auth — more reliable than query key on some networks.
      final uri = Uri.parse('$_base/$model:generateContent');

      try {
        final response = await _http
            .post(
              uri,
              headers: {
                'Content-Type': 'application/json',
                'x-goog-api-key': key,
              },
              body: body,
            )
            .timeout(timeout);

        if (response.statusCode == 401 || response.statusCode == 403) {
          final detail = _errorDetail(response.body);
          // Auth errors won't be fixed by switching models.
          return FailureResult(
            ApiFailure(
              detail == null || detail.isEmpty
                  ? 'API key bị từ chối (HTTP ${response.statusCode}). '
                      'Kiểm tra key còn hạn, đã bật Gemini API, và không bị giới hạn IP/ứng dụng.'
                  : 'API key bị từ chối: $detail',
              statusCode: response.statusCode,
            ),
          );
        }

        if (_shouldFailover(response.statusCode, response.body)) {
          lastFailure = ApiFailure(
            _errorDetail(response.body) ??
                'Model $model bị giới hạn (HTTP ${response.statusCode}).',
            statusCode: response.statusCode,
          );
          continue;
        }

        if (response.statusCode < 200 || response.statusCode >= 300) {
          lastFailure = ApiFailure(
            _errorDetail(response.body) ??
                'Gemini lỗi HTTP ${response.statusCode}. Thử lại sau.',
            statusCode: response.statusCode,
          );
          // Model missing / server errors: try next model in the chain.
          if (response.statusCode == 404 || response.statusCode >= 500) {
            continue;
          }
          return FailureResult(lastFailure);
        }

        final decoded = jsonDecode(response.body);
        if (decoded is! Map<String, dynamic>) {
          lastFailure = const AiFailure();
          continue;
        }

        // Blocked / empty candidates → try next model.
        if (_isBlockedOrEmpty(decoded)) {
          lastFailure = const AiFailure(
            'Model từ chối hoặc không trả lời được. Đang thử model khác…',
          );
          continue;
        }

        final text = _extractText(decoded);
        if (text == null || text.trim().isEmpty) {
          lastFailure = const AiFailure();
          continue;
        }

        lastUsedModel = model;
        return Success(text.trim());
      } on Object catch (e) {
        lastFailure = NetworkFailure('Không kết nối được Gemini ($model): $e');
        // Network blip: try next model.
        continue;
      }
    }

    final triedList = tried.join(' → ');
    final detail = lastFailure?.message ?? 'Không nhận được phản hồi AI.';
    final status = switch (lastFailure) {
      ApiFailure(:final statusCode) => statusCode,
      _ => null,
    };
    return FailureResult(
      ApiFailure(
        'Tất cả model đều thất bại ($triedList). $detail',
        statusCode: status,
      ),
    );
  }

  bool _shouldFailover(int statusCode, String body) {
    if (statusCode == 429) return true;
    if (statusCode == 503) return true;
    final lower = body.toLowerCase();
    const markers = [
      'resource_exhausted',
      'quota',
      'rate limit',
      'rate_limit',
      'exceeded',
      'too many requests',
      'high demand',
      'temporarily unavailable',
      'overloaded',
      'model is overloaded',
      'try again later',
    ];
    for (final m in markers) {
      if (lower.contains(m)) return true;
    }
    return false;
  }

  bool _isBlockedOrEmpty(Map<String, dynamic> body) {
    final candidates = body['candidates'];
    if (candidates is! List || candidates.isEmpty) {
      final feedback = body['promptFeedback'];
      if (feedback is Map && feedback['blockReason'] != null) return true;
      return true;
    }
    final first = candidates.first;
    if (first is! Map) return true;
    final finish = first['finishReason']?.toString().toUpperCase();
    if (finish == 'SAFETY' || finish == 'RECITATION' || finish == 'OTHER') {
      return true;
    }
    return false;
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
      if (part is! Map) continue;
      // Skip Gemini "thinking" parts when present.
      if (part['thought'] == true) continue;
      final text = part['text'];
      if (text is String && text.isNotEmpty) {
        buffer.write(text);
      }
    }
    final out = buffer.toString();
    if (out.trim().isNotEmpty) return out;
    // Fallback: some responses only expose text without thought flags.
    final fallback = StringBuffer();
    for (final part in parts) {
      if (part is Map && part['text'] is String) {
        fallback.write(part['text'] as String);
      }
    }
    return fallback.toString();
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

class GeminiImage {
  const GeminiImage({required this.base64, required this.mimeType});
  final String base64;
  final String mimeType;
}
