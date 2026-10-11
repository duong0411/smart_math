import 'package:eduself_study_app/core/ai/gemini_client.dart';
import 'package:eduself_study_app/core/config/app_config.dart';
import 'package:eduself_study_app/core/error/result.dart';
import 'package:eduself_study_app/core/settings/app_settings_store.dart';
import 'package:eduself_study_app/features/math_ai/infrastructure/math_local_store.dart';
import 'package:eduself_study_app/features/settings/presentation/providers/settings_providers.dart';
import 'package:eduself_study_app/shared/utils/supported_grades.dart';
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
  int? gradeLevel,
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
  final rawGrade = gradeLevel ?? profile?.gradeLevel;
  final effectiveGrade =
      rawGrade == null ? null : SupportedGrades.normalize(rawGrade);
  final profileBlock = StringBuffer();
  if (profile != null) {
    if (profile.displayName.trim().isNotEmpty) {
      profileBlock.writeln('Tên học sinh: ${profile.displayName.trim()}');
    }
    if (profile.focusTopics.isNotEmpty) {
      profileBlock.writeln(
        'Chủ đề quan tâm: ${profile.focusTopics.join(', ')}',
      );
    }
  }
  if (effectiveGrade != null) {
    profileBlock.writeln('Lớp: $effectiveGrade');
    profileBlock.writeln(
      'Chỉ dạy / ra đề / giải thích phù hợp chương trình STEM Toán lớp $effectiveGrade '
      '(THCS, GDPT Việt Nam). Điều chỉnh độ khó và thuật ngữ theo lớp này.',
    );
  }
  if (extraSystemContext != null && extraSystemContext.trim().isNotEmpty) {
    profileBlock.writeln(extraSystemContext.trim());
  }

  final systemPrompt = profileBlock.isEmpty
      ? basePrompt
      : '$basePrompt\n\n## Thông tin học sinh hiện tại\n$profileBlock';

  final reinforced = '$systemPrompt\n\n'
      '## NGUYÊN TẮC BẮT BUỘC CHO LƯỢT NÀY:\n'
      '1. BẠN LÀ CHATBOT HỖ TRỢ HỌC TẬP STEM MÔN TOÁN. TUYỆT ĐỐI CHỈ TRẢ LỜI CÁC NỘI DUNG VỀ TOÁN HỌC VÀ ỨNG DỤNG STEM LIÊN QUAN ĐẾN TOÁN.\n'
      '2. NẾU HỌC SINH HỎI NỘI DUNG KHÔNG LIÊN QUAN (tán gẫu, đời tư, phim ảnh, ca nhạc, chính trị, game không liên quan, làm thơ, chuyện phiếm...): TUYỆT ĐỐI KHÔNG TRẢ LỜI LAN MAN. Hãy từ chối lịch sự và nhắc học sinh quay lại môn Toán.\n'
      '3. NẾU HỌC SINH GỬI ẢNH KHÔNG LIÊN QUAN ĐẾN TOÁN HỌC (ảnh người, đồ vật, thú cưng, ảnh rác, ảnh mờ...): TUYỆT ĐỐI TỪ CHỐI, KHÔNG SUY DIỄN VÀ KHÔNG CHẤM ĐÚNG.\n'
      '4. ĐỘ CHÍNH XÁC: Luôn giải nháp trước để kiểm tra phép tính; dùng LaTeX \$...\$ hoặc \$\$...\$\$ cho biểu thức toán.';

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
  final name = (documentName == null || documentName.trim().isEmpty)
      ? 'tài liệu'
      : documentName.trim();
  final docBlock = doc.isNotEmpty
      ? '\n\n--- Nội dung tệp đính kèm ($name) ---\n$doc\n--- Hết nội dung tệp ---'
      : '';

  if (text.isNotEmpty) {
    if (hasImage) {
      return '$text\n\n(Học sinh kèm hình ảnh bài làm/đề bài. Hãy kiểm tra ảnh: nếu ảnh chứa bài toán thì phân tích và hướng dẫn giải; nếu ảnh không liên quan đến Toán học thì từ chối lịch sự và nhắc học sinh gửi đúng ảnh bài tập Toán.)$docBlock';
    }
    return '$text$docBlock';
  }

  // Khi học sinh không gõ chữ mà gửi ảnh hoặc tệp:
  if (hasImage && doc.isNotEmpty) {
    return 'Học sinh gửi ảnh và tệp "$name". Hãy kiểm tra xem có chứa đề bài hoặc bài giải Toán không: nếu có thì phân tích và hướng dẫn; nếu không liên quan đến Toán học thì từ chối lịch sự.$docBlock';
  }

  if (hasImage) {
    return 'Học sinh gửi 1 hình ảnh (không kèm lời nhắn). '
        'Hãy quan sát kỹ ảnh:\n'
        '1. Nếu ảnh chứa đề bài toán hoặc bài làm toán: Hãy tóm tắt lại đề bài và hướng dẫn phương pháp giải từng bước (chưa vội đưa đáp số cuối cùng).\n'
        '2. NẾU ẢNH KHÔNG LIÊN QUAN ĐẾN TOÁN HỌC (ảnh người, phong cảnh, thú cưng, đồ vật, meme, ảnh rác, ảnh mờ không đọc được): BẮT BUỘC TỪ CHỐI LỊCH SỰ: thông báo ảnh không chứa bài tập môn Toán và nhắc học sinh chụp rõ đề bài Toán.';
  }

  if (doc.isNotEmpty) {
    return 'Học sinh gửi tệp "$name" chứa tài liệu học tập. '
        'Hãy đọc kỹ nội dung tệp: nếu chứa đề bài hoặc bài tập Toán thì tóm tắt và hướng dẫn giải từng bước; nếu nội dung không liên quan đến môn Toán thì từ chối lịch sự.$docBlock';
  }

  return text;
}
