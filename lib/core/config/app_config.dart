import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

abstract final class AppConfig {
  static const appName = 'EduSelf STEM Toán AI';
  static const appVersion = '2.1.0';
  static const appTagline =
      'Ứng dụng AI hỗ trợ học tập STEM và giám sát môn Toán';
  static const storageMode = 'Local + Gemini API';
  static const aiGatewayTimeout = Duration(seconds: 45);
  static const _apiBaseUrlKey = 'API_BASE_URL';
  static const _apiAccessTokenKey = 'API_ACCESS_TOKEN';
  static const _geminiApiKeyKey = 'GEMINI_API_KEY';

  /// Reliability-first chain for desktop/free-tier, then stronger models.
  /// Each model has separate quota; failover on rate-limit / overload / 404.
  static const geminiModelChain = <String>[
    'gemini-2.5-flash',
    'gemini-2.0-flash',
    'gemini-2.5-flash-lite',
    'gemini-2.5-pro',
  ];

  /// Default Cloudflare Workers API (legacy / optional).
  static const defaultApiBaseUrl = 'http://localhost:8787';

  static Future<void> load() async {
    await dotenv.load(fileName: 'assets/env/gemini.env', isOptional: true);
  }

  static String get fallbackApiBaseUrl {
    const fromDefine = String.fromEnvironment(_apiBaseUrlKey);
    if (fromDefine.isNotEmpty) return fromDefine;
    final fromEnv = dotenv.maybeGet(_apiBaseUrlKey);
    if (fromEnv != null && fromEnv.trim().isNotEmpty) return fromEnv.trim();
    return defaultApiBaseUrl;
  }

  /// Optional bootstrapped JWT for local/dev via dart-define / env file.
  static String? get fallbackApiAccessToken {
    const fromDefine = String.fromEnvironment(_apiAccessTokenKey);
    if (fromDefine.isNotEmpty) return fromDefine;
    final fromEnv = dotenv.maybeGet(_apiAccessTokenKey);
    if (fromEnv != null && fromEnv.trim().isNotEmpty) return fromEnv.trim();
    return null;
  }

  /// Optional Gemini key from dart-define / env file (user can also paste in app).
  static String? get fallbackGeminiApiKey {
    const fromDefine = String.fromEnvironment(_geminiApiKeyKey);
    if (fromDefine.isNotEmpty) return fromDefine;
    final fromEnv = dotenv.maybeGet(_geminiApiKeyKey);
    if (fromEnv != null && fromEnv.trim().isNotEmpty) return fromEnv.trim();
    return null;
  }

  static Future<String> loadSystemPrompt() {
    return rootBundle.loadString('assets/prompts/eduself_system_prompt.md');
  }
}
