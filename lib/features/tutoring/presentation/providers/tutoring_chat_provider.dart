import 'package:eduself_study_app/features/auth/presentation/providers/auth_session_provider.dart';
import 'package:eduself_study_app/features/tutoring/domain/entities/chat_message.dart';
import 'package:eduself_study_app/features/tutoring/presentation/providers/tutoring_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final tutoringSessionsProvider =
    FutureProvider.autoDispose<List<ChatSession>>((ref) async {
  final user = ref.watch(authSessionProvider).valueOrNull;
  if (user == null) return const [];
  final result = await ref.watch(listTutoringSessionsProvider)(user.id);
  return result.when(
    success: (sessions) => sessions,
    failure: (failure) => throw Exception(failure.message),
  );
});

class TutoringChatNotifier
    extends AutoDisposeFamilyAsyncNotifier<List<ChatMessage>, int> {
  @override
  Future<List<ChatMessage>> build(int sessionId) async {
    final result = await ref.read(getTutoringMessagesProvider)(sessionId);
    return result.when(
      success: (messages) => messages,
      failure: (failure) => throw Exception(failure.message),
    );
  }

  Future<String?> send(
    String content, {
    List<int>? mediaIds,
  }) async {
    final previous = state.valueOrNull ?? const <ChatMessage>[];
    state = AsyncData([
      ...previous,
      ChatMessage(
        id: -1,
        sessionId: arg,
        role: ChatRole.user,
        content: content.trim(),
        createdAtUtc: DateTime.now().toUtc(),
        mediaIds: mediaIds ?? const [],
      ),
    ]);

    final result = await ref.read(sendTutoringMessageProvider)(
      sessionId: arg,
      content: content,
      history: previous,
      mediaIds: mediaIds,
    );

    // Always reload from API — server may have saved the user message even
    // when Gemini fails.
    final refreshed = await ref.read(getTutoringMessagesProvider)(arg);
    state = refreshed.when(
      success: AsyncData.new,
      failure: (failure) =>
          result.isFailure
              ? AsyncData(previous)
              : AsyncError(failure, StackTrace.current),
    );
    ref.invalidate(tutoringSessionsProvider);

    if (result.isFailure) {
      return result.failureOrNull!.message;
    }
    return null;
  }

  Future<String?> deleteMessage(int messageId) async {
    final previous = state.valueOrNull ?? const <ChatMessage>[];
    state = AsyncData(
      previous.where((message) => message.id != messageId).toList(),
    );

    final result = await ref.read(deleteTutoringMessageProvider)(
      sessionId: arg,
      messageId: messageId,
    );

    if (result.isFailure) {
      state = AsyncData(previous);
      return result.failureOrNull!.message;
    }

    ref.invalidate(tutoringSessionsProvider);
    return null;
  }
}

final tutoringChatProvider = AsyncNotifierProvider.autoDispose
    .family<TutoringChatNotifier, List<ChatMessage>, int>(
  TutoringChatNotifier.new,
);
