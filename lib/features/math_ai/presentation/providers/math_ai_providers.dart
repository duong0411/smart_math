import 'package:eduself_study_app/core/ai/gemini_client.dart';
import 'package:eduself_study_app/core/config/app_config.dart';
import 'package:eduself_study_app/core/error/result.dart';
import 'package:eduself_study_app/core/settings/app_settings_store.dart';
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
    final trimmed = AppSettingsStore.sanitizeSecret(key);
    if (trimmed.isEmpty) {
      await clear();
      return;
    }
    state = AsyncData(trimmed);
    try {
      await ref.read(appSettingsStoreProvider).writeGeminiApiKey(trimmed);
      // Confirm round-trip so desktop file / prefs failures surface early.
      final stored =
          await ref.read(appSettingsStoreProvider).readGeminiApiKey();
      if (stored == null || stored.trim().isEmpty) {
        throw StateError('Không lưu được API key trên máy.');
      }
    } on Object {
      // Keep in-memory value for this session even if disk write failed.
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
  String? documentText,
  String? documentName,
}) async {
  // Always await — valueOrNull is null while the key is still loading.
  final apiKeyRaw = await ref.read(geminiApiKeyProvider.future);
  final apiKey = apiKeyRaw == null
      ? ''
      : AppSettingsStore.sanitizeSecret(apiKeyRaw);
  if (apiKey.isEmpty) {
    return const FailureResult(
      ValidationFailure(
        'Chưa có Gemini API key. Vào Cài đặt → dán API key rồi bấm Lưu.',
      ),
    );
  }
  if (!AppSettingsStore.looksLikeGeminiApiKey(apiKey)) {
    return const FailureResult(
      ValidationFailure(
        'API key đang lưu không hợp lệ (Gemini key thường bắt đầu bằng AIza… hoặc AQ.…). '
        'Vào Cài đặt → lấy key mới từ Google AI Studio → Lưu lại.',
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
      '- Ưu tiên đúng kiến thức Địa lí; bám sát chương trình GDPT cấp THCS (Lớp 6, 7, 8, 9).\n'
      '- Trả lời bằng tiếng Việt, rõ ràng, phân tích khoa học, giải thích hiện tượng và số liệu địa lý.';

  final message = _composeUserMessage(
    userMessage: userMessage,
    documentText: documentText,
    documentName: documentName,
    hasImage: image != null,
  );

  return ref.read(geminiClientProvider).generate(
        apiKey: apiKey,
        systemPrompt: reinforced,
        history: history,
        userMessage: message,
        image: image,
        timeout: AppConfig.aiGatewayTimeout,
      );
}

String _composeUserMessage({
  required String userMessage,
  String? documentText,
  String? documentName,
  required bool hasImage,
}) {
  final text = userMessage.trim();
  final doc = documentText?.trim() ?? '';
  if (doc.isEmpty) return text;

  final name = (documentName == null || documentName.trim().isEmpty)
      ? 'tài liệu'
      : documentName.trim();
  final block = '\n\n--- Nội dung tệp đính kèm ($name) ---\n$doc\n--- Hết nội dung tệp ---';

  if (text.isNotEmpty) return '$text$block';
  if (hasImage) {
    return 'Em kèm ảnh và tệp "$name". Hãy đọc cả hai rồi hướng dẫn giải từng bước.$block';
  }
  return 'Em gửi tệp "$name" chứa nội dung / câu hỏi môn Địa lí. '
      'Hãy đọc kỹ nội dung tệp, nêu lại yêu cầu ngắn gọn nếu cần, '
      'rồi hướng dẫn em tìm hiểu và trả lời từng bước (chưa đưa đáp án ngay trừ khi em yêu cầu).$block';
}
