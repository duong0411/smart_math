import 'package:eduself_study_app/core/config/app_config.dart';
import 'package:eduself_study_app/core/settings/app_settings_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appSettingsStoreProvider = Provider<AppSettingsStore>((ref) {
  return AppSettingsStore();
});

class ThemeModeNotifier extends AsyncNotifier<ThemeMode> {
  @override
  Future<ThemeMode> build() {
    return ref.read(appSettingsStoreProvider).readThemeMode();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = AsyncData(mode);
    try {
      await ref.read(appSettingsStoreProvider).writeThemeMode(mode);
    } on Object {
      // Keep in-memory theme even if persistence fails.
    }
  }
}

final themeModeProvider =
    AsyncNotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

class ApiBaseUrlNotifier extends AsyncNotifier<String> {
  @override
  Future<String> build() async {
    try {
      final stored = await ref.read(appSettingsStoreProvider).readApiBaseUrl();
      if (stored != null && stored.trim().isNotEmpty) return stored.trim();
    } on Object {
      // SharedPreferences may be unavailable in some test hosts.
    }
    return AppConfig.fallbackApiBaseUrl;
  }

  Future<void> save(String url) async {
    final trimmed = url.trim();
    final value =
        trimmed.isEmpty ? AppConfig.fallbackApiBaseUrl : trimmed;
    state = AsyncData(value);
    try {
      if (trimmed.isEmpty) {
        await ref.read(appSettingsStoreProvider).clearApiBaseUrl();
      } else {
        await ref.read(appSettingsStoreProvider).writeApiBaseUrl(value);
      }
    } on Object {
      // Memory value still applies this session.
    }
  }
}

final apiBaseUrlProvider =
    AsyncNotifierProvider<ApiBaseUrlNotifier, String>(ApiBaseUrlNotifier.new);

class ApiAccessTokenNotifier extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async {
    try {
      final stored =
          await ref.read(appSettingsStoreProvider).readApiAccessToken();
      if (stored != null && stored.trim().isNotEmpty) return stored.trim();
    } on Object {
      // Secure storage plugin may be unavailable until full restart.
    }
    return AppConfig.fallbackApiAccessToken;
  }

  void setMemory(String token) {
    state = AsyncData(token.trim());
  }

  Future<void> save(String token) async {
    final trimmed = token.trim();
    if (trimmed.isEmpty) {
      await clear();
      return;
    }
    state = AsyncData(trimmed);
    try {
      await ref.read(appSettingsStoreProvider).writeApiAccessToken(trimmed);
    } on Object {
      // Persistence failed — memory token still works.
    }
  }

  Future<void> clear() async {
    state = AsyncData(AppConfig.fallbackApiAccessToken);
    try {
      await ref.read(appSettingsStoreProvider).clearApiTokens();
    } on Object {
      // Ignore persistence errors.
    }
  }
}

final apiAccessTokenProvider =
    AsyncNotifierProvider<ApiAccessTokenNotifier, String?>(
  ApiAccessTokenNotifier.new,
);
