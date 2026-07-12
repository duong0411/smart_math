import 'package:eduself_study_app/core/config/app_config.dart';
import 'package:eduself_study_app/core/network/api_client.dart';
import 'package:eduself_study_app/features/settings/presentation/providers/settings_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  final store = ref.watch(appSettingsStoreProvider);

  return ApiClient(
    resolveBaseUrl: () =>
        ref.read(apiBaseUrlProvider).valueOrNull ??
        AppConfig.fallbackApiBaseUrl,
    readAccessToken: () async {
      final memory = ref.read(apiAccessTokenProvider).valueOrNull;
      if (memory != null && memory.trim().isNotEmpty) return memory.trim();
      return store.readApiAccessToken();
    },
    readRefreshToken: store.readApiRefreshToken,
    persistTokens: (tokens) async {
      await store.writeApiAccessToken(tokens.accessToken);
      await store.writeApiRefreshToken(tokens.refreshToken);
      // Keep Riverpod memory in sync without awaiting notifier rebuild races.
      ref.read(apiAccessTokenProvider.notifier).setMemory(tokens.accessToken);
    },
    clearTokens: () async {
      await store.clearApiTokens();
      await ref.read(apiAccessTokenProvider.notifier).clear();
    },
  );
});
