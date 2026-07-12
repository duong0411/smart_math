import 'package:eduself_study_app/core/config/app_config.dart';
import 'package:eduself_study_app/core/error/result.dart';
import 'package:eduself_study_app/core/network/api_client.dart';
import 'package:eduself_study_app/features/tutoring/domain/entities/chat_message.dart';
import 'package:eduself_study_app/features/tutoring/domain/repositories/tutoring_repository.dart';

class TutoringRepositoryImpl implements TutoringRepository {
  TutoringRepositoryImpl({required ApiClient api}) : _api = api;

  final ApiClient _api;

  @override
  Future<Result<ChatSession>> createSession({
    required int userId,
    String? title,
  }) async {
    final result = await _api.post(
      '/tutoring/sessions',
      body: {
        if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
      },
    );
    return switch (result) {
      Success(:final value) => _parseSession(value),
      FailureResult(:final failure) => FailureResult(failure),
    };
  }

  @override
  Future<Result<List<ChatSession>>> listSessions(int userId) async {
    final result = await _api.get('/tutoring/sessions');
    return switch (result) {
      Success(:final value) => _parseSessionList(value),
      FailureResult(:final failure) => FailureResult(failure),
    };
  }

  @override
  Future<Result<List<ChatMessage>>> getMessages(int sessionId) async {
    final result = await _api.get('/tutoring/sessions/$sessionId/messages');
    return switch (result) {
      Success(:final value) => _parseMessageList(value),
      FailureResult(:final failure) => FailureResult(failure),
    };
  }

  @override
  Future<Result<ChatMessage>> sendMessage({
    required int sessionId,
    required String content,
    List<ChatMessage>? history,
    List<int>? mediaIds,
  }) async {
    final body = <String, Object?>{
      'sessionId': sessionId,
      'userMessage': content.trim(),
    };
    if (mediaIds != null && mediaIds.isNotEmpty) {
      body['mediaIds'] = mediaIds;
    }
    if (history != null && history.isNotEmpty) {
      body['history'] = history
          .where((m) => m.content.trim().isNotEmpty)
          .map(
            (m) => {
              'role': m.role == ChatRole.user ? 'user' : 'model',
              'content': m.content.trim(),
            },
          )
          .toList();
    }

    final result = await _api.post(
      '/ai/tutor/reply',
      body: body,
      timeout: AppConfig.aiGatewayTimeout,
    );

    return switch (result) {
      Success(:final value) => _parseTutorReply(value),
      FailureResult(:final failure) => FailureResult(failure),
    };
  }

  @override
  Future<Result<void>> deleteMessage({
    required int sessionId,
    required int messageId,
  }) async {
    final result = await _api.delete(
      '/tutoring/sessions/$sessionId/messages/$messageId',
    );
    return switch (result) {
      Success() => const Success(null),
      FailureResult(:final failure) => FailureResult(failure),
    };
  }

  @override
  Future<Result<void>> deleteSession(int sessionId) async {
    final result = await _api.delete('/tutoring/sessions/$sessionId');
    return switch (result) {
      Success() => const Success(null),
      FailureResult(:final failure) => FailureResult(failure),
    };
  }

  Result<ChatSession> _parseSession(Map<String, dynamic> envelope) {
    final data = envelope['data'];
    if (data is! Map<String, dynamic>) {
      return const FailureResult(ApiFailure('Invalid session response.'));
    }
    return Success(ChatSession.fromJson(data));
  }

  Result<List<ChatSession>> _parseSessionList(Map<String, dynamic> envelope) {
    final data = envelope['data'];
    if (data is! List) {
      return const FailureResult(ApiFailure('Invalid sessions response.'));
    }
    return Success([
      for (final item in data)
        if (item is Map<String, dynamic>) ChatSession.fromJson(item),
    ]);
  }

  Result<List<ChatMessage>> _parseMessageList(Map<String, dynamic> envelope) {
    final data = envelope['data'];
    if (data is! List) {
      return const FailureResult(ApiFailure('Invalid messages response.'));
    }
    return Success([
      for (final item in data)
        if (item is Map<String, dynamic>) ChatMessage.fromJson(item),
    ]);
  }

  Result<ChatMessage> _parseTutorReply(Map<String, dynamic> envelope) {
    final data = envelope['data'];
    if (data is! Map<String, dynamic>) {
      return const FailureResult(ApiFailure('Invalid AI reply response.'));
    }
    final modelMessage = data['modelMessage'];
    if (modelMessage is Map<String, dynamic>) {
      return Success(ChatMessage.fromJson(modelMessage));
    }
    final reply = (data['reply'] as String?)?.trim();
    if (reply == null || reply.isEmpty) {
      return const FailureResult(AiFailure());
    }
    // Fallback if older gateway shape is returned.
    return Success(
      ChatMessage(
        id: 0,
        sessionId: 0,
        role: ChatRole.model,
        content: reply,
        createdAtUtc: DateTime.now().toUtc(),
      ),
    );
  }
}
