import 'package:eduself_study_app/core/settings/desktop_settings_file_stub.dart'
    if (dart.library.io) 'package:eduself_study_app/core/settings/desktop_settings_file_io.dart'
    as desktop_file;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local settings store with durable desktop file fallback.
///
/// On desktop, the Gemini API key is also written under the user app-data
/// folder so persistence does not depend solely on SharedPreferences plugins.
class AppSettingsStore {
  AppSettingsStore({
    SharedPreferences? prefs,
    Map<String, String>? memorySecure,
  })  : _prefsOverride = prefs,
        _memorySecure = memorySecure;

  final SharedPreferences? _prefsOverride;
  final Map<String, String>? _memorySecure;
  SharedPreferences? _prefsCache;
  Map<String, String>? _fileCache;

  static const _themeKey = 'theme_mode';
  static const _apiBaseUrlKey = 'api_base_url';
  static const _apiAccessTokenKey = 'api_access_token';
  static const _apiRefreshTokenKey = 'api_refresh_token';
  static const _geminiApiKeyKey = 'gemini_api_key';

  Future<SharedPreferences> _preferences() async {
    return _prefsCache ??=
        _prefsOverride ?? await SharedPreferences.getInstance();
  }

  Future<Map<String, String>> _readDesktopFile() async {
    if (_fileCache != null) return _fileCache!;
    if (!desktop_file.supportsDesktopSettingsFile) {
      _fileCache = <String, String>{};
      return _fileCache!;
    }
    _fileCache = await desktop_file.readDesktopSettingsFile();
    return _fileCache!;
  }

  Future<void> _writeDesktopFile(Map<String, String> data) async {
    _fileCache = Map<String, String>.from(data);
    if (!desktop_file.supportsDesktopSettingsFile) return;
    await desktop_file.writeDesktopSettingsFile(data);
  }

  /// Strip copy/paste junk that often breaks Gemini auth on desktop.
  static String sanitizeSecret(String raw) {
    var value = raw.trim();
    value = value.replaceAll(RegExp(r'[\u200B-\u200D\uFEFF\u00A0]'), '');
    value = value.replaceAll(RegExp(r'\s+'), '');
    if (value.toLowerCase().startsWith('bearer')) {
      value = value.substring(6).trim();
    }
    // New AI Studio auth keys are "AQ.Ab…". Users often paste without "AQ.".
    if (value.startsWith('Ab') &&
        !value.startsWith('AQ.') &&
        value.length >= 30) {
      value = 'AQ.$value';
    }
    return value.trim();
  }

  /// Accepts classic `AIza…` keys and newer AI Studio auth keys `AQ.…`.
  static bool looksLikeGeminiApiKey(String raw) {
    final key = sanitizeSecret(raw);
    if (key.length < 20) return false;
    return key.startsWith('AIza') || key.startsWith('AQ.');
  }

  Future<String?> _readSecret(String key) async {
    final memory = _memorySecure;
    if (memory != null) return memory[key];

    if (desktop_file.supportsDesktopSettingsFile) {
      final fileMap = await _readDesktopFile();
      final fromFile = fileMap[key];
      if (fromFile != null && fromFile.trim().isNotEmpty) {
        return fromFile.trim();
      }
    }

    try {
      final prefs = await _preferences();
      final fromPrefs = prefs.getString(key);
      if (fromPrefs != null && fromPrefs.trim().isNotEmpty) {
        if (desktop_file.supportsDesktopSettingsFile) {
          final fileMap = await _readDesktopFile();
          fileMap[key] = fromPrefs.trim();
          await _writeDesktopFile(fileMap);
        }
        return fromPrefs.trim();
      }
    } on Object {
      // Prefer desktop file / memory.
    }
    return null;
  }

  Future<void> _writeSecret(String key, String value) async {
    final cleaned = sanitizeSecret(value);
    final memory = _memorySecure;
    if (memory != null) {
      memory[key] = cleaned;
      return;
    }

    if (desktop_file.supportsDesktopSettingsFile) {
      final fileMap = await _readDesktopFile();
      fileMap[key] = cleaned;
      await _writeDesktopFile(fileMap);
    }

    try {
      final prefs = await _preferences();
      await prefs.setString(key, cleaned);
    } on Object {
      // Desktop file already persisted when available.
    }
  }

  Future<void> _clearSecret(String key) async {
    final memory = _memorySecure;
    if (memory != null) {
      memory.remove(key);
      return;
    }

    if (desktop_file.supportsDesktopSettingsFile) {
      final fileMap = await _readDesktopFile();
      fileMap.remove(key);
      await _writeDesktopFile(fileMap);
    }

    try {
      final prefs = await _preferences();
      await prefs.remove(key);
    } on Object {
      // ignore
    }
  }

  Future<ThemeMode> readThemeMode() async {
    final prefs = await _preferences();
    final raw = prefs.getString(_themeKey);
    return switch (raw) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> writeThemeMode(ThemeMode mode) async {
    final prefs = await _preferences();
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await prefs.setString(_themeKey, value);
  }

  Future<String?> readApiBaseUrl() async {
    final prefs = await _preferences();
    return prefs.getString(_apiBaseUrlKey);
  }

  Future<void> writeApiBaseUrl(String url) async {
    final prefs = await _preferences();
    await prefs.setString(_apiBaseUrlKey, url.trim());
  }

  Future<void> clearApiBaseUrl() async {
    final prefs = await _preferences();
    await prefs.remove(_apiBaseUrlKey);
  }

  Future<String?> readApiAccessToken() => _readSecret(_apiAccessTokenKey);

  Future<void> writeApiAccessToken(String token) =>
      _writeSecret(_apiAccessTokenKey, token);

  Future<void> clearApiAccessToken() => _clearSecret(_apiAccessTokenKey);

  Future<String?> readApiRefreshToken() => _readSecret(_apiRefreshTokenKey);

  Future<void> writeApiRefreshToken(String token) =>
      _writeSecret(_apiRefreshTokenKey, token);

  Future<void> clearApiRefreshToken() => _clearSecret(_apiRefreshTokenKey);

  Future<void> clearApiTokens() async {
    await clearApiAccessToken();
    await clearApiRefreshToken();
  }

  Future<String?> readGeminiApiKey() => _readSecret(_geminiApiKeyKey);

  Future<void> writeGeminiApiKey(String key) =>
      _writeSecret(_geminiApiKeyKey, key);

  Future<void> clearGeminiApiKey() => _clearSecret(_geminiApiKeyKey);
}
