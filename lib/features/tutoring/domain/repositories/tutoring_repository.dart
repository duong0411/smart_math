import 'package:eduself_study_app/core/error/result.dart';
import 'package:eduself_study_app/features/tutoring/domain/entities/chat_message.dart';

abstract interface class TutoringRepository {
  Future<Result<ChatSession>> createSession({
    required int userId,
    String? title,
  });

  Future<Result<List<ChatSession>>> listSessions(int userId);

  Future<Result<List<ChatMessage>>> getMessages(int sessionId);

  /// Sends one AI turn via `POST /ai/tutor/reply` (server persists user + model).
  Future<Result<ChatMessage>> sendMessage({
    required int sessionId,
    required String content,
    List<ChatMessage>? history,
    List<int>? mediaIds,
  });

  Future<Result<void>> deleteMessage({
    required int sessionId,
    required int messageId,
  });

  Future<Result<void>> deleteSession(int sessionId);
}
