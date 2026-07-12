import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

abstract final class AppConfig {
  static const appName = 'EduSelf Study';
  static const appVersion = '1.0.0';
  static const storageMode = 'API (Cloudflare Workers)';
  static const aiGatewayTimeout = Duration(seconds: 55);
  static const _apiBaseUrlKey = 'API_BASE_URL';
  static const _apiAccessTokenKey = 'API_ACCESS_TOKEN';

  /// Default Cloudflare Workers API (production).
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

  static Future<String> loadSystemPrompt() {
    return rootBundle.loadString('assets/prompts/eduself_system_prompt.md');
  }
}
