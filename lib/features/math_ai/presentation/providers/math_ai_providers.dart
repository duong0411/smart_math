import 'package:eduself_study_app/core/ai/gemini_client.dart';
import 'package:eduself_study_app/core/config/app_config.dart';
import 'package:eduself_study_app/core/error/result.dart';
import 'package:eduself_study_app/features/math_ai/infrastructure/math_local_store.dart';
import 'package:eduself_study_app/features/settings/presentation/providers/settings_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final mathLocalStoreProvider = Provider<MathLocalStore>((ref) {
  return MathLocalStore();
});

final geminiClientProvider = Provider<GeminiClient>((ref) {
  return GeminiClient(
    models: AppConfig.geminiModelChain,
    temperature: 0.2,
  );
});

final systemPromptProvider = FutureProvider<String>((ref) {
  return AppConfig.loadSystemPrompt();
});

class GeminiApiKeyNotifier extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async {
    try {
      final stored =
          await ref.read(appSettingsStoreProvider).readGeminiApiKey();
      if (stored != null && stored.trim().isNotEmpty) return stored.trim();
    } on Object {
      // Secure storage may be unavailable in tests.
    }
    return AppConfig.fallbackGeminiApiKey;
  }

  Future<void> save(String key) async {
    final trimmed = key.trim();
    if (trimmed.isEmpty) {
      await clear();
      return;
    }
    state = AsyncData(trimmed);
    try {
      await ref.read(appSettingsStoreProvider).writeGeminiApiKey(trimmed);
    } on Object {
      // Memory value still works this session.
    }
  }

  Future<void> clear() async {
    state = const AsyncData(null);
    try {
      await ref.read(appSettingsStoreProvider).clearGeminiApiKey();
    } on Object {
      // ignore
    }
  }

  bool get hasKey {
    final value = state.valueOrNull;
    return value != null && value.trim().isNotEmpty;
  }
}

final geminiApiKeyProvider =
    AsyncNotifierProvider<GeminiApiKeyNotifier, String?>(
  GeminiApiKeyNotifier.new,
);

class MathProfileNotifier extends AsyncNotifier<MathStudentProfile> {
  @override
  Future<MathStudentProfile> build() {
    return ref.read(mathLocalStoreProvider).readProfile();
  }

  Future<void> save(MathStudentProfile profile) async {
    state = AsyncData(profile);
    await ref.read(mathLocalStoreProvider).writeProfile(profile);
  }
}

final mathProfileProvider =
    AsyncNotifierProvider<MathProfileNotifier, MathStudentProfile>(
  MathProfileNotifier.new,
);

final mathSessionsProvider =
    FutureProvider.autoDispose<List<MathTutorSession>>((ref) {
  return ref.watch(mathLocalStoreProvider).listSessions();
});

final mathEventsProvider =
    FutureProvider.autoDispose<List<MathStudyEvent>>((ref) {
  return ref.watch(mathLocalStoreProvider).listEvents();
});

final mathAttemptsProvider =
    FutureProvider.autoDispose<List<MathPracticeAttempt>>((ref) {
  return ref.watch(mathLocalStoreProvider).listAttempts();
});

/// Shared helper to call Gemini with profile context.
Future<Result<String>> askMathAi(
  WidgetRef ref, {
  required String userMessage,
  List<GeminiTurn> history = const [],
  String? extraSystemContext,
  GeminiImage? image,
}) async {
  final apiKey = ref.read(geminiApiKeyProvider).valueOrNull;
  if (apiKey == null || apiKey.trim().isEmpty) {
    return const FailureResult(
      ValidationFailure(
        'Chưa có Gemini API key. Vào Cài đặt → dán API key rồi thử lại.',
      ),
    );
  }

  final basePrompt = await ref.read(systemPromptProvider.future);
  final profile = ref.read(mathProfileProvider).valueOrNull;
  final profileBlock = StringBuffer();
  if (profile != null) {
    if (profile.displayName.trim().isNotEmpty) {
      profileBlock.writeln('Tên học sinh: ${profile.displayName.trim()}');
    }
    if (profile.gradeLevel != null) {
      profileBlock.writeln('Lớp: ${profile.gradeLevel}');
    }
    if (profile.focusTopics.isNotEmpty) {
      profileBlock.writeln(
        'Chủ đề quan tâm: ${profile.focusTopics.join(', ')}',
      );
    }
  }
  if (extraSystemContext != null && extraSystemContext.trim().isNotEmpty) {
    profileBlock.writeln(extraSystemContext.trim());
  }

  final systemPrompt = profileBlock.isEmpty
      ? basePrompt
      : '$basePrompt\n\n## Thông tin học sinh hiện tại\n$profileBlock';

  final reinforced = '$systemPrompt\n\n'
      '## Nhắc ngắn cho lượt này\n'
      '- Ưu tiên đúng kiến thức Toán; tự kiểm tra phép tính trước khi trả lời.\n'
      '- Trả lời bằng tiếng Việt, rõ ràng, dùng LaTeX cho biểu thức.';

  return ref.read(geminiClientProvider).generate(
        apiKey: apiKey,
        systemPrompt: reinforced,
        history: history,
        userMessage: userMessage,
        image: image,
        timeout: AppConfig.aiGatewayTimeout,
      );
}
