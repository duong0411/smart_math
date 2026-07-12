import 'package:eduself_study_app/core/error/result.dart';
import 'package:eduself_study_app/features/tutoring/domain/entities/chat_message.dart';
import 'package:eduself_study_app/features/tutoring/domain/repositories/tutoring_repository.dart';

class CreateTutoringSession {
  const CreateTutoringSession(this._repository);

  final TutoringRepository _repository;

  Future<Result<ChatSession>> call({
    required int userId,
    String? title,
  }) {
    return _repository.createSession(userId: userId, title: title);
  }
}

class ListTutoringSessions {
  const ListTutoringSessions(this._repository);

  final TutoringRepository _repository;

  Future<Result<List<ChatSession>>> call(int userId) {
    return _repository.listSessions(userId);
  }
}

class GetTutoringMessages {
  const GetTutoringMessages(this._repository);

  final TutoringRepository _repository;

  Future<Result<List<ChatMessage>>> call(int sessionId) {
    return _repository.getMessages(sessionId);
  }
}

class SendTutoringMessage {
  const SendTutoringMessage(this._repository);

  final TutoringRepository _repository;

  Future<Result<ChatMessage>> call({
    required int sessionId,
    required String content,
    List<ChatMessage>? history,
    List<int>? mediaIds,
  }) {
    final trimmed = content.trim();
    final ids = mediaIds ?? const <int>[];
    if (trimmed.isEmpty && ids.isEmpty) {
      return Future.value(
        const FailureResult(ValidationFailure('Hãy nhập câu hỏi của em.')),
      );
    }
    return _repository.sendMessage(
      sessionId: sessionId,
      content: trimmed.isEmpty
          ? 'Em gửi bài tập này. Thầy giúp em từng bước nhé.'
          : trimmed,
      history: history,
      mediaIds: ids,
    );
  }
}

class DeleteTutoringMessage {
  const DeleteTutoringMessage(this._repository);

  final TutoringRepository _repository;

  Future<Result<void>> call({
    required int sessionId,
    required int messageId,
  }) {
    if (messageId <= 0) {
      return Future.value(
        const FailureResult(ValidationFailure('Cannot delete this message.')),
      );
    }
    return _repository.deleteMessage(
      sessionId: sessionId,
      messageId: messageId,
    );
  }
}

class DeleteTutoringSession {
  const DeleteTutoringSession(this._repository);

  final TutoringRepository _repository;

  Future<Result<void>> call(int sessionId) {
    if (sessionId <= 0) {
      return Future.value(
        const FailureResult(ValidationFailure('Cannot delete this session.')),
      );
    }
    return _repository.deleteSession(sessionId);
  }
}
