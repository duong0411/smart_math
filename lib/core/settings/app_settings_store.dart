import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsStore {
  AppSettingsStore({
    SharedPreferences? prefs,
    FlutterSecureStorage? secureStorage,
    Map<String, String>? memorySecure,
  })  : _prefsOverride = prefs,
        _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _memorySecure = memorySecure;

  final SharedPreferences? _prefsOverride;
  final FlutterSecureStorage _secureStorage;
  final Map<String, String>? _memorySecure;
  SharedPreferences? _prefsCache;

  static const _themeKey = 'theme_mode';
  static const _apiBaseUrlKey = 'api_base_url';
  static const _apiAccessTokenKey = 'api_access_token';
  static const _apiRefreshTokenKey = 'api_refresh_token';

  Future<SharedPreferences> _preferences() async {
    return _prefsCache ??=
        _prefsOverride ?? await SharedPreferences.getInstance();
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

  Future<String?> readApiAccessToken() {
    final memory = _memorySecure;
    if (memory != null) {
      return Future.value(memory[_apiAccessTokenKey]);
    }
    return _secureStorage.read(key: _apiAccessTokenKey);
  }

  Future<void> writeApiAccessToken(String token) {
    final memory = _memorySecure;
    if (memory != null) {
      memory[_apiAccessTokenKey] = token.trim();
      return Future.value();
    }
    return _secureStorage.write(key: _apiAccessTokenKey, value: token.trim());
  }

  Future<void> clearApiAccessToken() {
    final memory = _memorySecure;
    if (memory != null) {
      memory.remove(_apiAccessTokenKey);
      return Future.value();
    }
    return _secureStorage.delete(key: _apiAccessTokenKey);
  }

  Future<String?> readApiRefreshToken() {
    final memory = _memorySecure;
    if (memory != null) {
      return Future.value(memory[_apiRefreshTokenKey]);
    }
    return _secureStorage.read(key: _apiRefreshTokenKey);
  }

  Future<void> writeApiRefreshToken(String token) {
    final memory = _memorySecure;
    if (memory != null) {
      memory[_apiRefreshTokenKey] = token.trim();
      return Future.value();
    }
    return _secureStorage.write(key: _apiRefreshTokenKey, value: token.trim());
  }

  Future<void> clearApiRefreshToken() {
    final memory = _memorySecure;
    if (memory != null) {
      memory.remove(_apiRefreshTokenKey);
      return Future.value();
    }
    return _secureStorage.delete(key: _apiRefreshTokenKey);
  }

  Future<void> clearApiTokens() async {
    await clearApiAccessToken();
    await clearApiRefreshToken();
  }
}
