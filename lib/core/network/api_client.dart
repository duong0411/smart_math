import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:eduself_study_app/core/error/result.dart';
import 'package:http/http.dart' as http;

typedef TokenPair = ({String accessToken, String refreshToken});

/// Shared HTTP client for the EduSelf Workers API.
///
/// Handles Bearer auth and a single-flight refresh on HTTP 401.
class ApiClient {
  ApiClient({
    required this.resolveBaseUrl,
    required this.readAccessToken,
    required this.readRefreshToken,
    required this.persistTokens,
    required this.clearTokens,
    http.Client? httpClient,
    this.defaultTimeout = const Duration(seconds: 30),
  }) : _http = httpClient ?? http.Client();

  final String Function() resolveBaseUrl;
  final Future<String?> Function() readAccessToken;
  final Future<String?> Function() readRefreshToken;
  final Future<void> Function(TokenPair tokens) persistTokens;
  final Future<void> Function() clearTokens;
  final Duration defaultTimeout;
  final http.Client _http;

  Future<bool>? _refreshInFlight;

  Future<Result<Map<String, dynamic>>> get(
    String path, {
    Duration? timeout,
    bool auth = true,
  }) {
    return _send('GET', path, auth: auth, timeout: timeout);
  }

  Future<Result<Map<String, dynamic>>> post(
    String path, {
    Object? body,
    Duration? timeout,
    bool auth = true,
  }) {
    return _send('POST', path, body: body, auth: auth, timeout: timeout);
  }

  Future<Result<Map<String, dynamic>>> patch(
    String path, {
    Object? body,
    Duration? timeout,
    bool auth = true,
  }) {
    return _send('PATCH', path, body: body, auth: auth, timeout: timeout);
  }

  Future<Result<Map<String, dynamic>>> delete(
    String path, {
    Object? body,
    Duration? timeout,
    bool auth = true,
  }) {
    return _send('DELETE', path, body: body, auth: auth, timeout: timeout);
  }

  /// Uploads raw bytes (e.g. `PUT /media/:id/content`).
  Future<Result<Map<String, dynamic>>> putBytes(
    String path, {
    required List<int> bytes,
    required String contentType,
    Duration? timeout,
    bool auth = true,
  }) {
    return _sendBytes(
      'PUT',
      path,
      bytes: bytes,
      contentType: contentType,
      auth: auth,
      timeout: timeout,
    );
  }

  /// Downloads raw bytes (e.g. `GET /media/:id/content`).
  Future<Result<List<int>>> getBytes(
    String path, {
    Duration? timeout,
    bool auth = true,
    bool isRetry = false,
  }) async {
    final base = resolveBaseUrl().trim().replaceAll(RegExp(r'/+$'), '');
    if (base.isEmpty) {
      return const FailureResult(
        NetworkFailure('API base URL is not configured.'),
      );
    }

    final uri = Uri.parse('$base${path.startsWith('/') ? path : '/$path'}');
    final headers = <String, String>{
      'accept': '*/*',
      'accept-encoding': 'identity',
    };

    if (auth) {
      final token = (await readAccessToken())?.trim();
      if (token == null || token.isEmpty) {
        return const FailureResult(UnauthorizedFailure());
      }
      headers['authorization'] = 'Bearer $token';
    }

    try {
      final request = http.Request('GET', uri)..headers.addAll(headers);
      final streamed =
          await _http.send(request).timeout(timeout ?? defaultTimeout);
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 401 && auth && !isRetry) {
        final refreshed = await _refreshTokens();
        if (refreshed) {
          return getBytes(
            path,
            timeout: timeout,
            auth: auth,
            isRetry: true,
          );
        }
        await clearTokens();
        return const FailureResult(UnauthorizedFailure());
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final decoded = _decodeBodyBytes(
          response.bodyBytes,
          contentEncoding: response.headers['content-encoding'],
        );
        return FailureResult(_mapError(decoded, response.statusCode));
      }

      return Success(
        _inflateIfNeeded(
          response.bodyBytes,
          response.headers['content-encoding'],
        ),
      );
    } on TimeoutException {
      return const FailureResult(
        NetworkFailure('Request timed out. Please try again.'),
      );
    } on Object catch (e) {
      return FailureResult(NetworkFailure(e.toString()));
    }
  }

  Future<Result<Map<String, dynamic>>> _sendBytes(
    String method,
    String path, {
    required List<int> bytes,
    required String contentType,
    bool auth = true,
    Duration? timeout,
    bool isRetry = false,
  }) async {
    final base = resolveBaseUrl().trim().replaceAll(RegExp(r'/+$'), '');
    if (base.isEmpty) {
      return const FailureResult(
        NetworkFailure('API base URL is not configured.'),
      );
    }

    final uri = Uri.parse('$base${path.startsWith('/') ? path : '/$path'}');
    final headers = <String, String>{
      'accept': 'application/json',
      'content-type': contentType,
      'accept-encoding': 'identity',
      'content-length': '${bytes.length}',
    };

    if (auth) {
      final token = (await readAccessToken())?.trim();
      if (token == null || token.isEmpty) {
        return const FailureResult(UnauthorizedFailure());
      }
      headers['authorization'] = 'Bearer $token';
    }

    try {
      final request = http.Request(method, uri)
        ..headers.addAll(headers)
        ..bodyBytes = bytes;

      final streamed =
          await _http.send(request).timeout(timeout ?? defaultTimeout);
      final response = await http.Response.fromStream(streamed);
      final decoded = _decodeBodyBytes(
        response.bodyBytes,
        contentEncoding: response.headers['content-encoding'],
      );

      if (response.statusCode == 401 && auth && !isRetry) {
        final refreshed = await _refreshTokens();
        if (refreshed) {
          return _sendBytes(
            method,
            path,
            bytes: bytes,
            contentType: contentType,
            auth: auth,
            timeout: timeout,
            isRetry: true,
          );
        }
        await clearTokens();
        return const FailureResult(UnauthorizedFailure());
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return FailureResult(_mapError(decoded, response.statusCode));
      }

      if (decoded is Map<String, dynamic>) {
        return Success(decoded);
      }
      return const FailureResult(ApiFailure('Invalid API response.'));
    } on TimeoutException {
      return const FailureResult(
        NetworkFailure('Request timed out. Please try again.'),
      );
    } on Object catch (e) {
      return FailureResult(NetworkFailure(e.toString()));
    }
  }

  Future<Result<Map<String, dynamic>>> _send(
    String method,
    String path, {
    Object? body,
    bool auth = true,
    Duration? timeout,
    bool isRetry = false,
  }) async {
    final base = resolveBaseUrl().trim().replaceAll(RegExp(r'/+$'), '');
    if (base.isEmpty) {
      return const FailureResult(
        NetworkFailure('API base URL is not configured.'),
      );
    }

    final uri = Uri.parse('$base${path.startsWith('/') ? path : '/$path'}');
    final headers = <String, String>{
      'accept': 'application/json',
      'content-type': 'application/json',
      // Hono compress may gzip JSON; Dart http does not auto-inflate on
      // all platforms, so prefer plaintext and also inflate as a fallback.
      'accept-encoding': 'identity',
    };

    if (auth) {
      final token = (await readAccessToken())?.trim();
      if (token == null || token.isEmpty) {
        return const FailureResult(UnauthorizedFailure());
      }
      headers['authorization'] = 'Bearer $token';
    }

    try {
      final request = http.Request(method, uri)..headers.addAll(headers);
      if (body != null) {
        request.body = jsonEncode(body);
      }

      final streamed =
          await _http.send(request).timeout(timeout ?? defaultTimeout);
      final response = await http.Response.fromStream(streamed);
      final decoded = _decodeBodyBytes(
        response.bodyBytes,
        contentEncoding: response.headers['content-encoding'],
      );

      if (response.statusCode == 401 && auth && !isRetry) {
        final refreshed = await _refreshTokens();
        if (refreshed) {
          return _send(
            method,
            path,
            body: body,
            auth: auth,
            timeout: timeout,
            isRetry: true,
          );
        }
        await clearTokens();
        return const FailureResult(UnauthorizedFailure());
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return FailureResult(_mapError(decoded, response.statusCode));
      }

      if (decoded is Map<String, dynamic>) {
        return Success(decoded);
      }
      return const FailureResult(ApiFailure('Invalid API response.'));
    } on TimeoutException {
      return const FailureResult(
        NetworkFailure('Request timed out. Please try again.'),
      );
    } on Object catch (e) {
      return FailureResult(NetworkFailure(e.toString()));
    }
  }

  Future<bool> _refreshTokens() {
    return _refreshInFlight ??= _doRefresh().whenComplete(() {
      _refreshInFlight = null;
    });
  }

  Future<bool> _doRefresh() async {
    final refresh = (await readRefreshToken())?.trim();
    if (refresh == null || refresh.isEmpty) return false;

    final result = await _send(
      'POST',
      '/auth/refresh',
      body: {'refreshToken': refresh},
      auth: false,
      isRetry: true,
    );

    if (result case Success(:final value)) {
      final data = value['data'];
      if (data is! Map<String, dynamic>) return false;
      final access = (data['accessToken'] as String?)?.trim();
      final nextRefresh = (data['refreshToken'] as String?)?.trim();
      if (access == null ||
          access.isEmpty ||
          nextRefresh == null ||
          nextRefresh.isEmpty) {
        return false;
      }
      await persistTokens((
        accessToken: access,
        refreshToken: nextRefresh,
      ));
      return true;
    }
    return false;
  }

  Object? _decodeBodyBytes(
    List<int> bodyBytes, {
    String? contentEncoding,
  }) {
    if (bodyBytes.isEmpty) return null;
    try {
      final inflated = _inflateIfNeeded(bodyBytes, contentEncoding);
      final text = utf8.decode(inflated);
      if (text.isEmpty) return null;
      return jsonDecode(text);
    } on FormatException catch (e) {
      return {
        'raw': 'Invalid response encoding: ${e.message}',
      };
    } on Object {
      return {'raw': 'Invalid response body'};
    }
  }

  /// Inflates gzip when the server ignored `Accept-Encoding: identity`.
  List<int> _inflateIfNeeded(List<int> bytes, String? contentEncoding) {
    final encoding = contentEncoding?.toLowerCase() ?? '';
    final looksGzip =
        bytes.length >= 2 && bytes[0] == 0x1f && bytes[1] == 0x8b;
    if (encoding.contains('gzip') || looksGzip) {
      return gzip.decode(bytes);
    }
    return bytes;
  }

  Failure _mapError(Object? decoded, int statusCode) {
    if (decoded is Map<String, dynamic>) {
      final error = decoded['error'];
      if (error is Map<String, dynamic>) {
        final code = error['code'] as String?;
        final message = (error['message'] as String?)?.trim();
        final msg = message?.isNotEmpty == true ? message! : null;
        final friendly = _friendlyMessage(
          code: code,
          statusCode: statusCode,
          serverMessage: msg,
        );

        if (code == 'EMAIL_ALREADY_EXISTS' || statusCode == 409) {
          return EmailAlreadyExistsFailure(friendly);
        }
        if (code == 'INVALID_CREDENTIALS') {
          return InvalidCredentialsFailure(friendly);
        }
        if (code == 'UNAUTHORIZED' || statusCode == 401) {
          return UnauthorizedFailure(friendly);
        }
        if (code == 'VALIDATION_ERROR' || statusCode == 400) {
          return ValidationFailure(friendly);
        }
        if (code == 'NOT_FOUND' || statusCode == 404) {
          return NotFoundFailure(friendly);
        }
        if (code == 'AI_UPSTREAM_ERROR' ||
            code == 'AI_EMPTY_RESPONSE' ||
            code == 'AI_NOT_CONFIGURED' ||
            code == 'RATE_LIMITED' ||
            statusCode == 429) {
          return AiFailure(friendly);
        }
        return ApiFailure(friendly, code: code, statusCode: statusCode);
      }
    }
    return ApiFailure(
      _friendlyMessage(code: null, statusCode: statusCode, serverMessage: null),
      statusCode: statusCode,
    );
  }

  /// Maps API/upstream errors to short student-facing copy (VN).
  String _friendlyMessage({
    required String? code,
    required int statusCode,
    required String? serverMessage,
  }) {
    final technical = serverMessage != null && _looksTechnical(serverMessage);

    if (code == 'RATE_LIMITED' ||
        statusCode == 429 ||
        (serverMessage != null &&
            (serverMessage.toLowerCase().contains('quota') ||
                serverMessage.toLowerCase().contains('resource_exhausted') ||
                serverMessage.toLowerCase().contains('resource exhausted')))) {
      return 'Giáo viên AI đang bận hoặc đã hết lượt tạm thời. Em thử lại sau vài phút nhé.';
    }
    if (code == 'AI_NOT_CONFIGURED') {
      return 'Giáo viên AI chưa được cấu hình. Em báo người lớn giúp nhé.';
    }
    if (code == 'AI_EMPTY_RESPONSE' || code == 'AI_UPSTREAM_ERROR') {
      return 'Không thể nhận phản hồi từ giáo viên AI lúc này. Em thử lại nhé.';
    }
    if (code == 'INVALID_CREDENTIALS') {
      return technical
          ? 'Email hoặc mật khẩu chưa đúng.'
          : (serverMessage ?? 'Email hoặc mật khẩu chưa đúng.');
    }
    if (code == 'EMAIL_ALREADY_EXISTS' || statusCode == 409) {
      return technical
          ? 'Email này đã được dùng rồi.'
          : (serverMessage ?? 'Email này đã được dùng rồi.');
    }
    if (code == 'UNAUTHORIZED' || statusCode == 401) {
      return 'Phiên đăng nhập đã hết. Em đăng nhập lại nhé.';
    }
    if (code == 'NOT_FOUND' || statusCode == 404) {
      return technical
          ? 'Không tìm thấy nội dung này.'
          : (serverMessage ?? 'Không tìm thấy nội dung này.');
    }
    if (statusCode == 503 || statusCode == 502 || statusCode == 504) {
      return 'Máy chủ đang bận. Em thử lại sau một chút nhé.';
    }
    if (serverMessage != null && !technical) {
      return serverMessage;
    }
    return 'Có lỗi xảy ra. Em thử lại nhé.';
  }

  bool _looksTechnical(String message) {
    final trimmed = message.trim();
    if (trimmed.startsWith('{') || trimmed.startsWith('[')) return true;
    if (trimmed.contains('"error"') && trimmed.contains('"code"')) return true;
    if (trimmed.contains('RESOURCE_EXHAUSTED')) return true;
    if (trimmed.contains('ai.google.dev')) return true;
    if (trimmed.length > 220) return true;
    return false;
  }

  void close() => _http.close();
}
